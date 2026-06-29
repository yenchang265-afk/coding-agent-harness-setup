---
name: explore
description: Discover and scope work. Either fetches tasks assigned to you from Azure DevOps or accepts a task you describe inline. Breaks large tasks into PR-sized subtasks, builds a dependency graph, and always writes the exploration record (including DoD and test plan) to docs/loop/exploration/.
---

# Explore

Surfaces pending work and produces an actionable, PR-sized task breakdown.
All outputs — task graph, exploration record, DoD, and test plan — are always
written to `docs/loop/exploration/`.

## Step 0 — Load or initialise loop configuration

Check whether `docs/loop/exploration/explore-config.json` exists.

### If the file exists — load and skip question

Read `source` from the file and print one line:

```
Loop config loaded (source: <source>). Skipping setup question.
```

Then jump immediately to the mode's section and run it in full.

### If the file does NOT exist — ask once, then save

This is the first loop initiation. Ask exactly one question:

> Where should I look for tasks?
> 1. **Azure DevOps** — fetch tasks assigned to me from ADO
> 2. **I'll describe it** — I'll type a task description now

If the caller already pre-specified `ado` or `manual` in `$ARGUMENTS`, use
that value and skip the question.

Save the answer to `docs/loop/exploration/explore-config.json` before
proceeding (create `docs/loop/exploration/` if it does not exist).
`source` is either `"ado"` or `"manual"`:

```json
{ "source": "ado" }
```

### Mode routing

| `source` | Mode to run |
|----------|-------------|
| `ado` | `ado` — ADO exploration lifecycle |
| `manual` | `manual` — inline task capture |

Jump to the chosen mode's section below and run it in full.


---

# Mode: ado — ADO exploration lifecycle

Run every step in order, every time. Never skip a step.

If the ADO MCP server is unavailable or not configured at any point,
tell the user and stop — do NOT fall back to another mode silently.

## Step A1 — Sync existing graph against ADO

Read `docs/loop/exploration/task-graph.json` if it exists. For every node whose `ado_id`
is non-null, call `wit_get_work_item` to get its current ADO state.
Apply these transitions:

| ADO State | Graph status to set |
|-----------|-------------------|
| Closed / Resolved / Done / Removed | `done` |
| Active / In Progress / Committed | `in_progress` |
| New / Approved / To Do | `pending` |

Write the updated graph back to `docs/loop/exploration/task-graph.json`. Then print the current state of all known tasks:

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

Handle these cases:

- **New tasks exist** — display them and ask: "Which task(s) should I scope?
  (Enter IDs, 'all', or press Enter to work from the ready list above)"
- **No new tasks, ready tasks exist in graph** — tell the user which task is
  ready and ask: "Continue with [<id>] <title>? Or pick a different one."
  Skip to **Decompose** if they confirm.
- **No new tasks, no ready tasks** — tell the user:
  "No new tasks found and no tasks are ready to start.
   In progress: <list> / Blocked: <list> / Done: <list>.
   Nothing to do this cycle." and stop.

## Step A4 — Fetch full detail for selected tasks

For each selected ID call `wit_get_work_item` (expand=all) to retrieve the
full description, acceptance criteria, and story points.

## Step A5 — Enrich work items with DoD and test plan

For each selected work item, inspect its description field. If it does not
already contain a `## Definition of Done` section AND a `## Test Plan` section,
generate both using the **DoD and test plan template** section
from the task's title, description, and acceptance criteria, then append to the
existing description and patch via `wit_update_work_item`.

If BOTH sections already exist, skip the update for that item — never
overwrite existing DoD or test plan content.

Proceed to **Decompose**.


---

# Mode: manual — user-provided task

## Step M1 — Capture the task

If any of the following are missing, ask for them before continuing:
- **Title** — one-line summary (this becomes the `<parent-task-name>` in the output filename)
- **Description** — what needs to be done and why
- **Acceptance criteria** — how to know it's done (draft one if the user skips)

## Step M2 — Generate DoD and test plan

Using the **DoD and test plan template** section, generate the Definition of Done
and Test Plan from the captured title, description, and acceptance criteria.
These will be embedded in the exploration record.

Proceed to **Decompose**, then write the dependency graph and exploration record.


---

# DoD and test plan template

Use this template wherever a Definition of Done and test plan must be written
(exploration record and ADO work item enrichment). Generate the content from
the task's title, description, and acceptance criteria.

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

For **ado mode** only: after the breakdown ask "Should I create subtask work
items in ADO for any of these?"

After Decompose, proceed to **Dependency graph**.


---

# Dependency graph

Build and persist a dependency graph whenever the task was split (skip if no split).

## When to add a dependency edge

Add an edge `A → B` ("B depends on A; A must merge before B starts") when ANY of:
- B references code, types, or interfaces introduced by A
- B's tests exercise behaviour that A's changes enable
- B modifies a schema/config that A migrates or creates
- You stated "Why here: …" in the decomposition above (that reason is an edge)

Do NOT add speculative edges.

## Graph file

Always `docs/loop/exploration/task-graph.json`.

Read the file if it exists; create it if not. Merge new nodes into the
existing graph (never overwrite unrelated nodes). Write the result back.

### Schema

```jsonc
{
  "version": 1,
  "tasks": {
    "<id>": {
      "id": "<string>",
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
Task graph written to docs/loop/exploration/task-graph.json
Ready to start (zero unresolved dependencies):
  → [task-1] <title>

Blocked (waiting on dependencies):
  · [task-2] depends on: task-1
```

After the graph, proceed to **Exploration record**.


---

# Exploration record

After all steps complete, write one file per exploration run to:

```
docs/loop/exploration/YYYY-MM-DD_HHMMSS_<parent-task-slug>.md
```

**Filename components:**
- `YYYY-MM-DD_HHMMSS` — local datetime at moment of writing
- `<parent-task-slug>` — the original (unsplit) task title, lowercased,
  spaces and special characters replaced with hyphens, max 40 characters

**Username for the header:** ADO `displayName` (lowercased, spaces→hyphens)
→ `git config user.name` (same normalisation) → `unknown`.

Create `docs/loop/exploration/` if it does not exist.

## File template

```markdown
# Exploration — <YYYY-MM-DD HH:MM:SS> · <username>

## Source
<!-- ado | manual -->
<source>

## Parent task
**[<id>] <title>**
Scope: <one-sentence scope>

## Subtasks
<!-- If no split: "Single task — no subtasks." -->
| # | Title | Scope | Depends on |
|---|-------|-------|-----------|
| 1 | <title> | <scope> | — |
| 2 | <title> | <scope> | 1 |

## Definition of Done
<generate using the DoD and test plan template section — one DoD block per subtask if split, otherwise one for the parent task>

## Test Plan
<generate using the DoD and test plan template section — one Test Plan block per subtask if split, otherwise one for the parent task>

## Dependency graph
<!-- "not written (no split)" or path + timestamp -->
docs/loop/exploration/task-graph.json — written/updated at <HH:MM:SS>
```

Do not write the record if the user cancelled or no tasks were found.


---

# ADO work item MCP tools

Tool IDs may be prefixed by the server name (`azure-devops_…`, `ado_…`, `mcp_ado_…`).
Match by purpose.

| Step | Tool (canonical id) | Key params | Notes |
|------|---------------------|------------|-------|
| Query assigned items | `wit_query_work_items` | wiql | `WHERE [Assigned To] = @Me AND [State] NOT IN ('Closed','Resolved','Done','Removed') AND [Work Item Type] IN ('Task','User Story','Bug')` |
| List items (simple) | `wit_list_work_items` | project, assignedTo, states | Alternative to WIQL; exclude states: Closed, Resolved, Done, Removed |
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
