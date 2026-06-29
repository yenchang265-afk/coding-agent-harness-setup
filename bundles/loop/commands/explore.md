---
description: "/explore [ado|manual] — discover what to work on next. Optionally pass 'ado' to fetch from Azure DevOps or 'manual' to describe a task inline. Always writes the task graph, exploration record, DoD, and test plan to docs/loop/exploration/. The first stage of the explore → brainstorming → plan → goal → close loop."
---

Invoke the `loop-explorer` subagent to discover and scope the next unit of work.
Use whatever mechanism your platform provides to run a named subagent
(e.g. `opencode run --agent loop-explorer`, the Task tool with agent `loop-explorer`,
or an equivalent).

`$ARGUMENTS` may be `ado` or `manual` to pre-select the task source.
Pass it through to the subagent as context. If omitted, the subagent will ask
the user to choose (once, then save to `docs/loop/exploration/explore-config.json`).

Wait for the subagent to complete. It will:

1. Surface pending ADO tasks assigned to you **or** accept your manual task description
2. Break large tasks into PR-sized subtasks
3. Detect dependencies between subtasks and write `docs/loop/exploration/task-graph.json`
4. Print the ready list — tasks with zero unresolved dependencies

Parse the `EXPLORE_RESULT … EXPLORE_RESULT_END` block from the subagent output
and display a summary to the user:

```
Explore complete.

Next task ready to start:
  Title: <title>
  Scope: <scope>
  ADO ID: <ado_id, or "n/a" when null (manual mode)>

Outputs written to docs/loop/exploration/:
  Graph:  <graph_path or "none (no split)">
  Record: <record_path>
Ready tasks: <ready_count>

Run /brainstorming "<title>" to design this task, or pick a different one.
```

If `title` is `none`, tell the user "No ready tasks found — all pending tasks
have unresolved dependencies, or there are no tasks assigned to you." and stop.
