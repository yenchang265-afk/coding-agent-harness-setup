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
