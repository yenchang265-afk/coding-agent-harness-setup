## Global engineering rules

These apply to every repository regardless of stack.

### Working agreement
- Make the smallest change that solves the task. No speculative abstractions or unrequested refactors.
- Match the surrounding code's style; do not reformat unrelated lines.
- Never commit secrets. Use the team secret store / Vault, never `.env` committed to git.
- All dependencies resolve from the internal registry. Do not add a dependency that is not mirrored internally without flagging it.

### Before you finish a task
- Run the formatter, linter, and the tests covering the code you touched.
- Leave the build green. If you cannot, say so explicitly rather than reporting success.

### Commits & reviews
- Write commit messages that explain the "why", not the "what".
- Keep PRs focused; unrelated cleanups go in their own PR.

### Security baseline (OWASP)
- Validate and encode all input crossing a trust boundary (HTTP, SQL, file, shell).
- Use parameterized queries everywhere — never string-concatenate SQL.
- Never log credentials, tokens, or full PII.
