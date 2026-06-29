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
