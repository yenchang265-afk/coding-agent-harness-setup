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
proceeding (create `docs/loop/exploration/` if it does not exist):

```json
{ "source": "ado" | "manual" }
```

### Mode routing

| `source` | Mode to run |
|----------|-------------|
| `ado` | `ado` — ADO exploration lifecycle |
| `manual` | `manual` — inline task capture |

Jump to the chosen mode's section below and run it in full.
