---
name: explore
description: Discover and scope work. Either fetches tasks assigned to you from Azure DevOps, or accepts a task you describe inline. Breaks large tasks into PR-sized subtasks and builds a dependency graph. Saves the graph and a timestamped exploration record to docs/ (local), or creates an Azure DevOps work item with Definition of Done and a test plan (remote).
---

# Explore

Surfaces pending work and produces an actionable, PR-sized task breakdown.

## Step 0 — Load or initialise loop configuration

Check whether `docs/explore-config.json` exists.

### If the file exists — load and skip questions

Read the file and extract `source` and `save_locally`. Print one line:

```
Loop config loaded (source: <source>, save_locally: <true|false>). Skipping setup questions.
```

Then jump immediately to the mode's section and run it in full.

### If the file does NOT exist — ask once, then save

This is the first loop initiation. Ask these two questions in order and wait
for both answers before continuing.

**Question 1 — Task source**

> Where should I look for tasks?
> 1. **Azure DevOps** — fetch tasks assigned to me from ADO
> 2. **I'll describe it** — I'll type a task description now

If the caller already pre-specified `ado` or `manual` in `$ARGUMENTS`, use
that value and skip this question.

**Question 2 — Where to keep the task graph and exploration record**
*(ask only if Question 1 answer is "I'll describe it")*

> Should I save the task breakdown and dependency graph locally in `docs/`?
> 1. **Yes** — write `docs/task-graph.json` and `docs/explorations/…`
> 2. **No** — create an Azure DevOps task with Definition of Done and a suggested test plan instead

If Question 1 answer is `ado`, `save_locally` is implicitly `true` — ADO is
the source of truth and the graph must stay in sync.

**Save the answers** to `docs/explore-config.json` before proceeding:

```json
{
  "source": "ado" | "manual",
  "save_locally": true | false
}
```

Create `docs/` if it does not exist.

### Mode routing

| `source` | `save_locally` | Mode to run |
|----------|---------------|-------------|
| `ado` | `true` (always) | `ado` |
| `manual` | `true` | `manual` with graph + record written to `docs/` |
| `manual` | `false` | `manual` → skip graph/record, go straight to Step M3 (create ADO work item with DoD + test plan) |

Jump to the chosen mode's section below and run it in full.


---

# Mode: ado — ADO exploration lifecycle

Run every step in order, every time. Never skip a step.

If the ADO MCP server is unavailable or not configured at any point,
tell the user and stop — do NOT fall back to another mode silently.

## Step A1 — Sync existing graph against ADO

Read `docs/task-graph.json` if it exists. For every node whose `ado_id`
is non-null, call `wit_get_work_item` to get its current ADO state.
Apply these transitions:

| ADO State | Graph status to set |
|-----------|-------------------|
| Closed / Resolved / Done / Removed | `done` |
| Active / In Progress / Committed | `in_progress` |
| New / Approved / To Do | `pending` |

Write the updated graph back. Then print the current state of all known tasks:

```
Graph sync complete (<N> tasks updated).

Ready to start:
  → [<id>] <title>

In progress:
  ~ [<id>] <title>

Blocked (waiting on dependencies):
  · [<id>] depends on: <ids>

Done:
  ✓ [<id>] <title>
```

If the graph file does not exist yet, print "No existing graph — starting fresh."
and continue.

## Step A2 — Fetch newly assigned ADO work items

Call `wit_list_work_items` (or `wit_query_work_items` with WIQL) filtered to:
- **Assigned To** = `@Me`
- **State** ≠ Closed, Resolved, Done, Removed
- **Work Item Type** = Task, User Story, Bug (not Epic/Feature)

Exclude any IDs already present in the graph (they were handled in A1).

## Step A3 — Display new tasks

For each new work item print:
```
[<ID>] <Title>  (<Type> · <State>)
  Area: <AreaPath>  |  Parent: <ParentTitle if any>
  Description: <first 2 sentences>
```

If there are no new tasks and there are already ready tasks in the graph,
tell the user which task is ready and ask: "Continue with [<id>] <title>?
Or pick a different one." Skip to **Decompose** if they confirm.

Otherwise ask: "Which task(s) should I scope? (Enter IDs, 'all', or press
Enter to work from the ready list above)"

## Step A4 — Fetch full detail for selected tasks

For each selected ID call `wit_get_work_item` (expand=all) to retrieve the
full description, acceptance criteria, and story points.

## Step A5 — Enrich work items with DoD and test plan

For each selected work item, inspect its description field. If it does not
already contain a `## Definition of Done` section AND a `## Test Plan` section,
generate both from the task's title, description, and acceptance criteria, then
patch the work item via `wit_update_work_item`.

Use this description structure (append to existing content, do not overwrite):

```markdown
## Definition of Done
- [ ] <concrete, verifiable acceptance criterion — derived from the task description>
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

If BOTH sections already exist, skip the update for that item — never
overwrite existing DoD or test plan content.

Proceed to **Decompose**.


---

# Mode: manual — user-provided task

## Step M1 — Capture the task

If any of the following are missing, ask for them before continuing:
- **Title** — one-line summary
- **Description** — what needs to be done and why
- **Acceptance criteria** — how to know it's done (draft one if the user skips)

Do NOT ask for the parent feature ID yet — request it only after decomposition
if nesting is needed.

## Step M2 — Decompose (see Decompose section)

## Step M3 — Create ADO work item(s)

After decomposition, create one work item per subtask (or the single task if no
split was needed). Use the ADO work item tools section.

**If nesting under a feature:** ask "Do you have a parent Feature or Epic work
item ID? (optional)". If provided, verify via `wit_get_work_item` before linking.

### Fields to set

| Field | Value |
|-------|-------|
| Work Item Type | Task (default) or User Story if user says so |
| Title | Subtask title |
| Description | Structured description (template below) |
| Assigned To | Current user (ask if unsure) |
| Area Path | Copy from parent if provided, else ask |
| Parent | Parent feature/epic ID (if provided) |

### Work item description template

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

After creation, print the new work item ID and URL.


---

# Decompose — break into PR-sized subtasks

Apply this to any task(s) surfaced by any mode.

## What fits in one PR

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

## When to split

Split when the task:
- Spans multiple independent subsystems or services
- Mixes a refactor with new behaviour
- Includes a schema/data migration that must land before application code
- Is open-ended ("improve performance", "add tests") with no bounded scope

## Splitting rules

1. Each subtask must be independently mergeable and not break main when merged alone.
2. Order subtasks so each one builds on the previous (add a sequence number).
3. Prefer vertical slices (end-to-end thin feature) over horizontal layers.
4. Keep shared setup (migrations, config changes) as subtask 1.

## Output format (when splitting)

```
Splitting "<original title>" into <N> subtasks:

  [1] <Subtask title>
      Scope: <one sentence — what this PR will change>
      Why here: <why this must land before the next subtask>

  [2] <Subtask title>
      ...

Suggested merge order: 1 → 2 → … → N
```

After the breakdown:
- **manual mode, Q2=Yes (save locally)** — write the dependency graph, then write the exploration record.
- **manual mode, Q2=No (create ADO task)** — proceed directly to Step M3 (create ADO work items); skip graph and record.
- **ado mode** — ask "Should I create subtask work items in ADO for any of these?", then write the graph and record.

Then proceed to **Dependency graph**.

---

# Dependency graph

**Skip this entire section** if the user answered "No — create ADO task" to
Question 2 in Step 0. In that case go directly to Step M3 in the manual mode
section to create the ADO work item with DoD and test plan.

Build and persist a dependency graph whenever the task was split (skip if no split).

## When to add a dependency edge

Add an edge `A → B` ("B depends on A; A must merge before B starts") when ANY of:
- B references code, types, or interfaces introduced by A
- B's tests exercise behaviour that A's changes enable
- B modifies a schema/config that A migrates or creates
- You stated "Why here: …" in the decomposition above (that reason is an edge)

Do NOT add speculative edges.

## Graph file location

| Source mode | Q2 answer | Graph path |
|-------------|-----------|------------|
| `ado` | always yes | `docs/task-graph.json` |
| `manual` | Yes — save locally | `docs/task-graph.json` |
| `manual` | No — create ADO task | *(skip — no graph written)* |

Read the file at the chosen path if it exists; create it if not. Merge new
nodes into the existing graph (never overwrite unrelated nodes). Write the
result back.

### Schema

```jsonc
{
  "version": 1,
  "tasks": {
    "<id>": {
      "id": "<string>",          // ADO work item ID, or a slug for pre-creation items
      "title": "<string>",
      "status": "pending" | "in_progress" | "done",
      "ado_id": <number> | null,
      "depends_on": ["<id>", …]
    }
  }
}
```

A task is **ready** when `status == "pending"` AND every `depends_on` task is `"done"`.

### After writing — print the ready list

```
Task graph written to docs/task-graph.json
Ready to start (zero unresolved dependencies):
  → [task-1] <title>

Blocked (waiting on dependencies):
  · [task-2] depends on: task-1
```

---

# Exploration record

**Skip this entire section** if the user answered "No — create ADO task" to
Question 2 in Step 0 (ADO item creation is the record in that path).

After all steps complete (graph written, ready list printed), write:

```
docs/explorations/YYYY-MM-DD_HHMMSS_<username>.md
```

**Timestamp:** local datetime at moment of writing (`YYYY-MM-DD_HHMMSS`).

**Username:** ADO `displayName` (lowercased, spaces→hyphens) → `git config user.name`
(same normalisation) → `unknown`.

Create `docs/explorations/` if it does not exist.

## File template

```markdown
# Exploration — <YYYY-MM-DD HH:MM:SS> · <username>

## Source
<!-- ado | manual -->
<source>

## Tasks discovered
| ID | Title | Type | State | Source |
|----|-------|------|-------|--------|
| <ado_id or —> | <title> | <type> | <state> | ADO \| Manual |

## Picked for this loop
**[<id>] <title>**
Scope: <one-sentence scope>

## Definition of Done
- [ ] <concrete, verifiable acceptance criterion 1>
- [ ] <criterion 2 — derived from the task's acceptance criteria or description>
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

## Dependency analysis
- <id> (<ado_id>) — <depends_on summary or "no dependencies → ready">

## Graph file
<!-- docs/task-graph.json, or "not written" -->
<graph_path or "not written"> — written/updated at <HH:MM:SS>
```

Do not write the record if the user cancelled or no tasks were found.


---

# ADO work item MCP tools

Tool IDs may be prefixed by the server name (`azure-devops_…`, `ado_…`, `mcp_ado_…`).
Match by purpose.

| Step | Tool (canonical id) | Key params | Notes |
|------|---------------------|------------|-------|
| Query assigned items | `wit_query_work_items` | wiql | `WHERE [Assigned To] = @Me AND [State] NOT IN (...)` |
| List items (simple) | `wit_list_work_items` | project, assignedTo, states | Alternative to raw WIQL |
| Get one item | `wit_get_work_item` | id, expand=all | Full fields incl. description, acceptance criteria, parent |
| Create item | `wit_create_work_item` | project, type, fields | Set Title, Description, AssignedTo, relations |
| Update item | `wit_update_work_item` | id, operations (JSON Patch) | Add parent link after creation if needed |

## Parent link format

```json
{
  "rel": "System.LinkTypes.Hierarchy-Reverse",
  "url": "https://<org>.visualstudio.com/<project>/_apis/wit/workItems/<parentId>"
}
```

## OFF-LIMITS
- Never delete or close work items.
- Never change the assigned-to field of existing items.
- Never modify items owned by other users without explicit user confirmation.
