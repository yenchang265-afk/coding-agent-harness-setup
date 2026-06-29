# Mode: local — read task notes from docs/

Use this when the user maintains their own task notes in `docs/` and wants to
pick work from there instead of ADO.

## Step L1 — Scan docs/ for task content

Search these locations in order; stop as soon as you find content:

| Priority | Path | What to look for |
|----------|------|-----------------|
| 1 | `docs/backlog.md` | H2/H3 headings as task titles |
| 2 | `docs/tasks.md` / `docs/todo.md` | Same heading convention |
| 3 | `docs/explorations/` | Most-recent record (`YYYY-MM-DD_*`); re-surface its "Tasks discovered" table |
| 4 | `docs/**/*.md` | Any file with a `## Tasks`, `## Backlog`, or `## TODO` section |

If nothing is found, tell the user "No task notes found in docs/ — try 'ado' or
'describe now'." and stop.

## Step L2 — Display discovered tasks

For each task found print:
```
[<slug or line ref>] <Title>
  Source file: <relative path>
  Notes: <first 2 sentences of the task's body, if any>
```

Ask the user: "Which task(s) should I scope? (Enter slugs/numbers, or 'all')"

## Step L3 — Collect full detail

Read the full body of each selected task from its source file. Extract or ask for:
- **Title** (from the heading)
- **Description** (body text under the heading)
- **Acceptance criteria** (look for a checklist or "done when" paragraph; draft one if missing)

Do NOT create ADO work items in local mode unless the user explicitly asks
("also create ADO items for these").

Proceed to **Decompose**.
