---
name: harness-rules-core
description: Always-on team coding standards (immutability, small files, error handling, security, testing). Consult before writing or reviewing any code.
---

## Global engineering rules

Apply to every repository regardless of stack. **Hard rules** are
non-negotiable; **working principles** are guidance.

### Hard rules (never violate)
- Never commit secrets — use the team secret store / Vault, never a `.env` in git.
- Validate and encode every input crossing a trust boundary (HTTP, SQL, file, shell); use parameterized queries — never string-concatenate SQL.
- Never log credentials, tokens, or full PII.
- Resolve all dependencies from the internal registry; never add an unmirrored dependency without flagging it.
- Never weaken, skip, delete, or hardcode around a test to get a green build. Fix the root cause, or report it as unresolved.
- Leave the build green: run the formatter, linter, and the tests covering what you touched. If you can't, say so explicitly — don't report success.

### Stop and ask first
Pause and confirm before irreversible or high-blast-radius actions: deleting
data or branches, force-push, history rewrites, schema/data migrations, sending
external messages (Slack, email, PRs), or anything affecting shared
infrastructure. Match the scope of your actions to what was asked.

### Working principles
1. **Think before coding** — Don't assume, don't hide confusion, surface tradeoffs. State assumptions and offer simpler approaches.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative: no unneeded features, abstractions, or error handling.
3. **Surgical changes** — Touch only what you must; don't reformat unrelated lines. Remove only code your change makes obsolete.
4. **Goal-driven execution** — Define success criteria, then loop until verified.
5. **Use the model only for judgment calls** — Classification, drafting, summarization; not routing, retries, or deterministic transforms.
6. **Be economical with context** — Keep changes and explanations tight; surface when a task is ballooning rather than grinding on silently.
7. **Surface conflicts, don't average them** — When patterns contradict, pick one and explain; never blend code to satisfy both.
8. **Read before you write** — Review exports, callers, and utilities before adding code. Ask if the structure is unclear.
9. **Tests verify intent, not just behavior** — Encode WHY the behavior matters, not only WHAT it does.
10. **Checkpoint after significant steps** — Note what's done, how it was verified, and what remains.
11. **Match the codebase's conventions, even if you disagree** — Conform to existing style; raise disagreements separately.
12. **Fail loud** — State uncertainty rather than hiding it. Disclose skipped records, untested cases, or incomplete verification.

### Commits & reviews
- Write commit messages that explain the "why", not the "what".
- Keep PRs focused; unrelated cleanups go in their own PR.
