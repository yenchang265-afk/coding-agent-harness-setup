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
