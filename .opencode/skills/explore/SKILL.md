---
name: explore
description: Discover and scope work. Supports three sources — Azure DevOps (pulls tasks assigned to you), local docs (reads task notes from docs/), or manual (user describes a task inline). Breaks large tasks into PR-sized subtasks, builds a dependency graph in .claude/task-graph.json, and writes a timestamped exploration record to docs/explorations/. For manual tasks, also creates the ADO work item with Definition of Done and a test plan.
---

# Explore

Surfaces pending work and produces an actionable, PR-sized task breakdown.

## Step 0 — Choose a source

If the source was not specified by the caller, ask the user exactly once:

> Where should I look for tasks?
> 1. **Azure DevOps** — fetch tasks assigned to me from ADO
> 2. **Local docs** — read task notes I've written in `docs/`
> 3. **Describe now** — I'll type a task description inline

Map the answer to one mode: `ado` / `local` / `manual`. Then run ONLY that mode's section below.

---

## Mode: ado — ADO exploration lifecycle

Run every step in order, every time. Never skip a step.

If the ADO MCP server is unavailable or not configured at any point,
tell the user and stop — do NOT fall back to another mode silently.

### Step A1 — Sync existing graph against ADO

Read `.claude/task-graph.json` if it exists. For every node whose `ado_id`
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

### Step A2 — Fetch newly assigned ADO work items

Call `wit_list_work_items` (or `wit_query_work_items` with WIQL) filtered to:
- **Assigned To** = `@Me`
- **State** ≠ Closed, Resolved, Done, Removed
- **Work Item Type** = Task, User Story, Bug (not Epic/Feature)

Exclude any IDs already present in the graph (they were handled in A1).

### Step A3 — Display new tasks

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

### Step A4 — Fetch full detail for selected tasks

For each selected ID call `wit_get_work_item` (expand=all) to retrieve the
full description, acceptance criteria, and story points.

Proceed to **Decompose** below.

---

## Mode: local — read task notes from docs/

Use this when the user maintains their own task notes in the `docs/` folder
(e.g. a backlog, feature notes, or previous exploration records) and wants to
pick work from there instead of ADO.

### Step 1 — Scan docs/ for task content

Search these locations in order; stop as soon as you find content:

| Priority | Path | What to look for |
|----------|------|-----------------|
| 1 | `docs/backlog.md` | Any file named backlog; treat H2/H3 headings as task titles |
| 2 | `docs/tasks.md` / `docs/todo.md` | Same heading convention |
| 3 | `docs/explorations/` | Most-recent exploration record (`YYYY-MM-DD_*`); re-surface its "Tasks discovered" table |
| 4 | `docs/**/*.md` | Any markdown file with a `## Tasks`, `## Backlog`, or `## TODO` section |

If nothing is found, tell the user "No task notes found in docs/ — try 'ado' or 'describe now'." and stop.

### Step 2 — Display discovered tasks

For each task found print:
```
[<slug or line ref>] <Title>
  Source file: <relative path>
  Notes: <first 2 sentences of the task's body, if any>
```

Ask the user: "Which task(s) should I scope? (Enter slugs/numbers, or 'all')"

### Step 3 — Collect full detail

Read the full body of each selected task from its source file. Extract or ask for:
- **Title** (from the heading)
- **Description** (body text under the heading)
- **Acceptance criteria** (look for a checklist or "done when" paragraph; draft one if missing)

Proceed to **Decompose** below. Do NOT create ADO work items in local mode
unless the user explicitly asks ("also create ADO items for these").

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

After outputting the breakdown, proceed to **Dependency graph** below.

---

## Dependency graph

Build and persist a dependency graph whenever the task was split into subtasks (skip if no split).

### When to add a dependency edge

Add an edge `A → B` (meaning "B depends on A; A must merge before B starts") when ANY of:
- B references code, types, or interfaces introduced by A
- B's tests exercise behaviour that A's changes enable
- B modifies a schema/config that A migrates or creates
- You stated "Why here: …" in the decomposition above (that reason is an edge)

Do NOT add speculative edges. Only add edges that are certain from the task description.

### Graph file — `.claude/task-graph.json`

Read the file if it exists; create it if not. Merge the new nodes and edges into the existing graph (never overwrite unrelated nodes). Write the result back.

#### Schema

```jsonc
{
  "version": 1,
  "tasks": {
    "<id>": {
      "id": "<string>",          // ADO work item ID, or a slug like "task-1" for manual tasks before creation
      "title": "<string>",
      "status": "pending" | "in_progress" | "done",
      "ado_id": <number> | null, // set after ADO work item is created
      "depends_on": ["<id>", …]  // IDs of tasks that must reach status=done first
    }
  }
}
```

#### Status lifecycle

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started; waiting for all `depends_on` tasks to reach `done` |
| `in_progress` | Actively being worked on (set this when `/goal` starts the task) |
| `done` | PR merged; no longer blocks anything |

A task is **ready** when `status == "pending"` AND every task in `depends_on` has `status == "done"`.

#### Example

```json
{
  "version": 1,
  "tasks": {
    "task-1": {
      "id": "task-1",
      "title": "Add DB migration for user_roles table",
      "status": "pending",
      "ado_id": 4201,
      "depends_on": []
    },
    "task-2": {
      "id": "task-2",
      "title": "Implement role-based access control middleware",
      "status": "pending",
      "ado_id": 4202,
      "depends_on": ["task-1"]
    },
    "task-3": {
      "id": "task-3",
      "title": "Add role selector to settings UI",
      "status": "pending",
      "ado_id": 4203,
      "depends_on": ["task-2"]
    }
  }
}
```

### After writing the graph — print the ready list

```
Task graph written to .claude/task-graph.json
Ready to start (zero unresolved dependencies):
  → [task-1] Add DB migration for user_roles table

Blocked (waiting on dependencies):
  · [task-2] depends on: task-1
  · [task-3] depends on: task-2
```

The `/goal` command picks up the first item in the ready list on the next loop invocation.

---

## Exploration record

After completing all steps (graph written, ready list printed), write a record
of this exploration run to:

```
docs/explorations/YYYY-MM-DD_HHMMSS_<username>.md
```

**Timestamp:** ISO-8601 local datetime at the moment of writing
(`YYYY-MM-DD_HHMMSS`, e.g. `2026-06-29_143022`).

**Username:** resolve in this order:
1. ADO `displayName` of the current user (from the identity returned by any ADO
   MCP call, lowercased, spaces and dots replaced with hyphens)
2. `git config user.name` (same normalisation)
3. Literal `unknown` if neither is available

Create `docs/explorations/` if it does not exist.

### File content template

```markdown
# Exploration — <YYYY-MM-DD HH:MM:SS> · <username>

## Source
<!-- ado | local | manual -->
<source>

## Tasks discovered
| ID | Title | Type | State | Source |
|----|-------|------|-------|--------|
| <ado_id or —> | <title> | <type> | <state> | ADO \| Local \| Manual |

## Picked for this loop
**[<id>] <title>**
Scope: <one-sentence scope>

## Dependency analysis
<!-- If no split: "Single task — no dependency graph needed." -->
<!-- If split: list each node and its blocker(s) -->
- <id> (<ado_id>) — <depends_on summary or "no dependencies → ready">
- …

## Graph file
<!-- path to .claude/task-graph.json, or "not written (no split)" -->
<graph_path> — written/updated at <HH:MM:SS>
```

Do not write the record if the user cancelled or no tasks were found (`title: none`).

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
