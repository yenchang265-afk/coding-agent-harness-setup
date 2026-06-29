# Mode: ado — ADO exploration lifecycle

Run every step in order, every time. Never skip a step.

If the ADO MCP server is unavailable or not configured at any point,
tell the user and stop — do NOT fall back to another mode silently.

## Step A1 — Sync existing graph against ADO

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

Proceed to **Decompose**.
