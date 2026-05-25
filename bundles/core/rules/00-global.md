## Global engineering rules

These apply to every repository regardless of stack. The numbered **working
principles** (distilled from Andrej Karpathy's guidance on coding with LLMs —
gist.github.com/Planxnx/64b173bacf2c8c43435c4333d0b9bd94) cover *how* to work;
the sections after them add team-specific specifics.

### Working principles
1. **Think before coding** — Don't assume, don't hide confusion, surface tradeoffs. State assumptions explicitly and offer simpler approaches.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative: no unneeded features, abstractions, or error handling beyond requirements.
3. **Surgical changes** — Touch only what you must, and don't reformat unrelated lines. Remove only code your change makes obsolete.
4. **Goal-driven execution** — Define success criteria, then loop until verified. Turn tasks into verifiable goals with clear checkpoints.
5. **Use the model only for judgment calls** — Classification, drafting, summarization. Don't use it for routing, retries, or deterministic transforms.
6. **Token budgets are not advisory** — Per task ~4,000 tokens; per session ~30,000. Surface a breach rather than overrunning silently.
7. **Surface conflicts, don't average them** — When codebase patterns contradict, pick one and explain; never blend code to satisfy both.
8. **Read before you write** — Review exports, callers, and utilities before adding code. Ask if the structure is unclear.
9. **Tests verify intent, not just behavior** — Encode WHY the behavior matters, not only WHAT it does.
10. **Checkpoint after every significant step** — Summarize what's done, how it was verified, and what remains.
11. **Match the codebase's conventions, even if you disagree** — Conform to existing style; raise disagreements separately.
12. **Fail loud** — State uncertainty rather than hiding it. Disclose skipped records, untested cases, or incomplete verification.

### Team specifics
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
