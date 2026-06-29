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
