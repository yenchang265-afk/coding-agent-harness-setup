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

Based on `source`, read the corresponding reference file and follow every
instruction in it before proceeding to **Decompose**:

| `source` | Reference file to read |
|----------|------------------------|
| `ado` | `references/mode-ado.md` |
| `manual` | `references/mode-manual.md` |

Read ONLY the file for the chosen mode. Do not read the other.
