# Mode: manual — user-provided task

## Step M1 — Capture the task

If any of the following are missing, ask for them before continuing:
- **Title** — one-line summary
- **Description** — what needs to be done and why
- **Acceptance criteria** — how to know it's done (draft one if the user skips)

Do NOT ask for the parent feature ID yet — request it only after decomposition
if nesting is needed.

## Step M2 — Decompose (see Decompose section)

## Step M3 — Create ADO work item(s)

After decomposition, create one work item per subtask (or the single task if no
split was needed). Use the ADO work item tools section.

**If nesting under a feature:** ask "Do you have a parent Feature or Epic work
item ID? (optional)". If provided, verify via `wit_get_work_item` before linking.

### Fields to set

| Field | Value |
|-------|-------|
| Work Item Type | Task (default) or User Story if user says so |
| Title | Subtask title |
| Description | Structured description (template below) |
| Assigned To | Current user (ask if unsure) |
| Area Path | Copy from parent if provided, else ask |
| Parent | Parent feature/epic ID (if provided) |

### Work item description template

```markdown
## Description
<what and why>

## Definition of Done
- [ ] <concrete, verifiable acceptance criterion 1>
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

After creation, print the new work item ID and URL.
