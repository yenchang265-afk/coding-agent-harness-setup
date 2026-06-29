---
name: explore
description: Discover and scope work. Either pulls tasks assigned to you from Azure DevOps, or accepts a task you describe manually. Breaks large tasks into PR-sized subtasks. For manual tasks, creates the Azure DevOps work item with Definition of Done and a test plan (parent feature ID required if nesting under a feature).
---

# Explore

Surfaces pending work and produces an actionable, PR-sized task breakdown.

## Pick ONE entry mode

- **ado** — no task description provided; discover tasks from Azure DevOps assigned to the current user.
- **manual** — the user describes the task inline (e.g. "add dark-mode toggle to settings page").

Run the full skill for the chosen mode. Do NOT mix steps from both modes.

---

## Mode: ado — discover tasks from Azure DevOps

### Step 1 — Fetch assigned work items

Call `wit_list_work_items` (or equivalent WIQL query via `wit_query_work_items`) filtered to:
- **Assigned To** = current user (`@Me`)
- **State** ≠ Closed, Resolved, Done, Removed
- **Work Item Type** = Task, User Story, Bug (anything actionable, not Epic/Feature)

If the ADO MCP server is unavailable or not configured, tell the user and fall back to manual mode.

### Step 2 — Display discovered tasks

For each work item print:
```
[<ID>] <Title>  (<Type> · <State>)
  Area: <AreaPath>  |  Parent: <ParentTitle if any>
  Description: <first 2 sentences>
```

Ask the user: "Which task(s) should I scope? (Enter IDs, or 'all', or type a new task instead)"

### Step 3 — Fetch full detail for selected tasks

For each selected ID call `wit_get_work_item` to retrieve the full description, acceptance criteria, and story points (or effort estimate).

Proceed to **Decompose** below.

---

## Mode: manual — user-provided task

### Step 1 — Capture the task

The user has already described the task. If any of the following are missing, ask for them before continuing:
- **Title** — one-line summary
- **Description** — what needs to be done and why
- **Acceptance criteria** — how to know it's done (can be drafted by you if user skips)

Do NOT ask for the parent feature ID yet — request it only if you determine in Step 2 that the task should be nested.

### Step 2 — Decompose (see section below)

### Step 3 — Create ADO work item(s)

After decomposition, create one work item per subtask (or the single task if no split needed).

#### If nesting under a feature

Ask: "Do you have a parent Feature or Epic work item ID to link this under? (optional)"

If the user provides one, verify it exists via `wit_get_work_item` and confirm the title before linking.

#### Work item fields to set

| Field | Value |
|-------|-------|
| Work Item Type | Task (default) or User Story if user says so |
| Title | Subtask title |
| Description | Full description (see template below) |
| Assigned To | Current user (ask if unsure) |
| Area Path | Copy from parent if provided, else ask |
| Parent | Parent feature/epic ID (if provided) |

#### Work item description template

```markdown
## Description
<what and why>

## Definition of Done
- [ ] <concrete, verifiable acceptance criterion 1>
- [ ] <criterion 2>
- [ ] Code reviewed and approved
- [ ] All CI checks pass
- [ ] No new lint/type errors introduced
- [ ] Relevant tests added or updated

## Test Plan
### Happy path
- <step-by-step scenario for the primary use case>

### Edge cases
- <edge case 1 and expected outcome>
- <edge case 2 and expected outcome>

### Out of scope
- <what this task explicitly does NOT cover>
```

Create each work item via `wit_create_work_item`. After creation, print the new work item ID and URL.

---

## Decompose — break into PR-sized subtasks

Apply this to any task(s) surfaced by either mode.

### What fits in one PR

A task fits in one PR if ALL of the following are true:
- Touches ≤ 3 logical areas (e.g. model + controller + one view)
- Reviewable in under 30 minutes (rough proxy: ≤ 400 lines of meaningful diff)
- Has one clear, testable outcome
- Does not mix unrelated concerns (e.g. refactor + feature + migration)

If the task already fits, **do not split**. Output:

```
✓ Fits in one PR — no split needed.
Task: <title>
Scope: <one sentence>
```

### When to split

Split when the task:
- Spans multiple independent subsystems or services
- Mixes a refactor with new behaviour
- Includes a schema/data migration that must land before application code
- Is open-ended ("improve performance", "add tests") with no bounded scope

### Splitting rules

1. Each subtask must be independently mergeable and not break main when merged alone.
2. Order subtasks so each one builds on the previous (add a sequence number).
3. Prefer vertical slices (end-to-end thin feature) over horizontal layers (all models first, then all views).
4. Keep shared setup (migrations, config changes) as subtask 1.

### Output format (when splitting)

```
Splitting "<original title>" into <N> subtasks:

  [1] <Subtask title>
      Scope: <one sentence — what this PR will change>
      Why here: <why this must land before the next subtask>

  [2] <Subtask title>
      ...

Suggested merge order: 1 → 2 → … → N
```

If in **manual mode**, proceed to Step 3 (create work items) after producing this output.
If in **ado mode**, present the breakdown and ask: "Should I create subtask work items in ADO for any of these?"

---

## ADO work item MCP tools

Tool IDs may be prefixed by the server name (`azure-devops_…`, `ado_…`, `mcp_ado_…`). Match by purpose.

| Step | Tool (canonical id) | Key params | Notes |
|------|---------------------|------------|-------|
| Query assigned items | `wit_query_work_items` | wiql (WIQL string) | Use `WHERE [Assigned To] = @Me AND [State] NOT IN (...)` |
| List items (simple) | `wit_list_work_items` | project, assignedTo, states | Alternative to raw WIQL |
| Get one item | `wit_get_work_item` | id, expand=all | Fetches full fields incl. description, acceptance criteria, parent |
| Create item | `wit_create_work_item` | project, type, fields | Set `/fields/System.Title`, `/fields/System.Description`, `/fields/System.AssignedTo`, `/relations/…` for parent link |
| Update item | `wit_update_work_item` | id, operations (JSON Patch) | Use to add parent link after creation if needed |
| Get parent feature | `wit_get_work_item` | id | Confirm title before linking |

### Parent link format (for `wit_create_work_item` relations)

```json
{
  "rel": "System.LinkTypes.Hierarchy-Reverse",
  "url": "https://<org>.visualstudio.com/<project>/_apis/wit/workItems/<parentId>"
}
```

### OFF-LIMITS
- Never delete or close work items.
- Never change the assigned-to field of existing items.
- Never modify items owned by other users without explicit user confirmation.
