---
description: "/explore — discover what to work on next. Pulls tasks assigned to you from Azure DevOps (or accepts a manually described task), breaks large tasks into PR-sized subtasks, builds a dependency graph in .claude/task-graph.json, and tells you which task is ready to start. Run this before /brainstorming. The first stage of the explore → brainstorming → plan → goal → close loop."
---

Invoke the `loop-explorer` subagent to discover and scope the next unit of work:

```
opencode run --agent loop-explorer
```

$ARGUMENTS may optionally pre-seed the task description. Pass it through to
the subagent as context if provided; otherwise the subagent will either query
Azure DevOps or ask the user for a task.

Wait for the subagent to complete. It will:

1. Surface pending ADO tasks assigned to you **or** accept your manual task description
2. Break large tasks into PR-sized subtasks
3. Detect dependencies between subtasks and write `.claude/task-graph.json`
4. Print the ready list — tasks with zero unresolved dependencies

Parse the `EXPLORE_RESULT … EXPLORE_RESULT_END` block from the subagent output
and display a summary to the user:

```
Explore complete.

Next task ready to start:
  Title: <title>
  Scope: <scope>
  ADO ID: <ado_id or "not yet created">

Dependency graph: <graph_path or "none">
Ready tasks: <ready_count>

Run /brainstorming "<title>" to design this task, or pick a different one.
```

If `title` is `none`, tell the user "No ready tasks found — all pending tasks
have unresolved dependencies, or there are no tasks assigned to you." and stop.
