---
name: pre-pr-review
description: Run before opening a pull request. Self-reviews the current diff against the team's global rules, runs the formatter/linter/tests, and produces a short readiness checklist.
---

# Pre-PR review

Use this when the user is about to open a PR, or asks "is this ready to push?".

## Steps
1. Show the diff scope: `git status` and `git diff --stat` against the base branch.
2. Check the diff against the global rules:
   - No secrets, no committed `.env`.
   - No string-concatenated SQL; parameterized queries only.
   - Change is focused — no unrelated reformatting or drive-by refactors.
3. Run the gates for the detected project kind:
   - Node: `npm run lint && npm test`
   - Gradle: `./gradlew spotlessCheck check test`
   - Maven: `./mvnw spotless:check verify`
4. Report a checklist: what passed, what failed, and any rule violations found.
   Do NOT claim ready if any gate failed — say what's blocking instead.
