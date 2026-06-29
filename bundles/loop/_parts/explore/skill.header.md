---
name: explore
description: Discover and scope work. Supports three sources — Azure DevOps (pulls tasks assigned to you), local docs (reads task notes from docs/), or manual (user describes a task inline). Breaks large tasks into PR-sized subtasks, builds a dependency graph in .claude/task-graph.json, and writes a timestamped exploration record to docs/explorations/. For manual tasks, also creates the ADO work item with Definition of Done and a test plan.
---

# Explore

Surfaces pending work and produces an actionable, PR-sized task breakdown.

## Step 0 — Two questions before starting

Ask these two questions in order. Do not proceed until both are answered.

**Question 1 — Task source**

> Where should I look for tasks?
> 1. **Azure DevOps** — fetch tasks assigned to me from ADO
> 2. **I'll describe it** — I'll type a task description now

If the caller already specified `ado` or `manual` in `$ARGUMENTS`, skip this
question and use that value.

**Question 2 — Where to keep the task graph and exploration record**
*(ask only if Question 1 answer is "I'll describe it")*

> Should I save the task breakdown and dependency graph locally in `docs/`?
> 1. **Yes** — write `docs/task-graph.json` and `docs/explorations/…`
> 2. **No** — create an Azure DevOps task with Definition of Done and a suggested test plan instead

If Question 1 answer is `ado`, always write the graph and record (answer is
implicitly "Yes" — ADO is the source of truth and the graph must stay in sync).

**Mode routing**

| Q1 answer | Q2 answer | Mode to run |
|-----------|-----------|-------------|
| Azure DevOps | — (always yes) | `ado` |
| I'll describe it | Yes — save locally | `manual` with graph + record in `docs/` |
| I'll describe it | No — create ADO task | `manual` → skip graph/record, go straight to Step M3 (create ADO work item with DoD + test plan) |

Jump to the chosen mode's section below and run it in full.
