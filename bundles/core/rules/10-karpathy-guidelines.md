## Karpathy guidelines — 12 rules (extended)

Distilled from Andrej Karpathy's observations on LLM coding pitfalls.
Source: gist.github.com/Planxnx/64b173bacf2c8c43435c4333d0b9bd94

1. **Think before coding** — Don't assume, don't hide confusion, surface tradeoffs. State assumptions explicitly and offer simpler approaches.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative: no unneeded features, abstractions, or error handling beyond requirements.
3. **Surgical changes** — Touch only what you must. Match existing style; remove only code your change makes obsolete.
4. **Goal-driven execution** — Define success criteria, then loop until verified. Turn tasks into verifiable goals with clear checkpoints.
5. **Use the model only for judgment calls** — Classification, drafting, summarization. Don't use it for routing, retries, or deterministic transforms.
6. **Token budgets are not advisory** — Per task ~4,000 tokens; per session ~30,000. Surface a breach rather than overrunning silently.
7. **Surface conflicts, don't average them** — When codebase patterns contradict, pick one and explain; never blend code to satisfy both.
8. **Read before you write** — Review exports, callers, and utilities before adding code. Ask if the structure is unclear.
9. **Tests verify intent, not just behavior** — Encode WHY the behavior matters, not only WHAT it does.
10. **Checkpoint after every significant step** — Summarize what's done, how it was verified, and what remains.
11. **Match the codebase's conventions, even if you disagree** — Conform to existing style; raise disagreements separately.
12. **Fail loud** — State uncertainty rather than hiding it. Disclose skipped records, untested cases, or incomplete verification.
