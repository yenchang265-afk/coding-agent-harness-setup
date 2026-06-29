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

Map the answer to one mode: `ado` / `local` / `manual`.
Then jump to that mode's section below and run it in full.
