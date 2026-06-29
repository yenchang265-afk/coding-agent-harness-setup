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

After the breakdown:
- **manual mode, Q2=Yes (save locally)** — write the dependency graph, then write the exploration record.
- **manual mode, Q2=No (create ADO task)** — proceed directly to Step M3 (create ADO work items); skip graph and record.
- **ado mode** — ask "Should I create subtask work items in ADO for any of these?", then write the graph and record.

Then proceed to **Dependency graph**.

---

# Dependency graph

**Skip this entire section** if the user answered "No — create ADO task" to
Question 2 in Step 0. In that case go directly to Step M3 in the manual mode
section to create the ADO work item with DoD and test plan.

Build and persist a dependency graph whenever the task was split (skip if no split).

## When to add a dependency edge

Add an edge `A → B` ("B depends on A; A must merge before B starts") when ANY of:
- B references code, types, or interfaces introduced by A
- B's tests exercise behaviour that A's changes enable
- B modifies a schema/config that A migrates or creates
- You stated "Why here: …" in the decomposition above (that reason is an edge)

Do NOT add speculative edges.

## Graph file location

| Source mode | Q2 answer | Graph path |
|-------------|-----------|------------|
| `ado` | always yes | `docs/task-graph.json` |
| `manual` | Yes — save locally | `docs/task-graph.json` |
| `manual` | No — create ADO task | *(skip — no graph written)* |

Read the file at the chosen path if it exists; create it if not. Merge new
nodes into the existing graph (never overwrite unrelated nodes). Write the
result back.

### Schema

```jsonc
{
  "version": 1,
  "tasks": {
    "<id>": {
      "id": "<string>",          // ADO work item ID, or a slug for pre-creation items
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
Task graph written to docs/task-graph.json
Ready to start (zero unresolved dependencies):
  → [task-1] <title>

Blocked (waiting on dependencies):
  · [task-2] depends on: task-1
```

---

# Exploration record

**Skip this entire section** if the user answered "No — create ADO task" to
Question 2 in Step 0 (ADO item creation is the record in that path).

After all steps complete (graph written, ready list printed), write:

```
docs/explorations/YYYY-MM-DD_HHMMSS_<username>.md
```

**Timestamp:** local datetime at moment of writing (`YYYY-MM-DD_HHMMSS`).

**Username:** ADO `displayName` (lowercased, spaces→hyphens) → `git config user.name`
(same normalisation) → `unknown`.

Create `docs/explorations/` if it does not exist.

## File template

```markdown
# Exploration — <YYYY-MM-DD HH:MM:SS> · <username>

## Source
<!-- ado | local | manual -->
<source>

## Tasks discovered
| ID | Title | Type | State | Source |
|----|-------|------|-------|--------|
| <ado_id or —> | <title> | <type> | <state> | ADO \| Local \| Manual |

## Picked for this loop
**[<id>] <title>**
Scope: <one-sentence scope>

## Dependency analysis
- <id> (<ado_id>) — <depends_on summary or "no dependencies → ready">

## Graph file
<!-- docs/task-graph.json, or "not written" -->
<graph_path or "not written"> — written/updated at <HH:MM:SS>
```

Do not write the record if the user cancelled or no tasks were found.
