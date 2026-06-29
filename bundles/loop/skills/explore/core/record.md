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
