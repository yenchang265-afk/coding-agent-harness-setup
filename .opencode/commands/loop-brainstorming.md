---
description: "/brainstorming — turn a raw idea into an approved design before planning. Gated: no code, and no /plan, until the user approves the design. Branches into a general path or a domain-knowledge path. The first stage of the loop."
---

## Step 0 — Discover the task (skip if a task was provided)

**If `$ARGUMENTS` is blank or empty**, invoke the `loop-explorer` subagent
before doing anything else:

```
opencode run --agent loop-explorer
```

Wait for it to complete and parse its `EXPLORE_RESULT … EXPLORE_RESULT_END`
block. Extract `title`, `scope`, `ado_id`, and `graph_path`. Use `title` +
`scope` as the task input for the rest of this command (treat them as if the
user had typed them as `$ARGUMENTS`). If `title` is `none`, tell the user
"No ready tasks found." and stop — do not continue to brainstorming.

**If `$ARGUMENTS` is non-empty**, skip Step 0 entirely and use `$ARGUMENTS`
as the task input.

---

**Brainstorm** the idea below into an approved design. This is the first stage of
the brainstorming → plan → goal → close loop — it runs *before* `/plan` and
produces the design that `/plan` then breaks into tasks.

Idea / goal: $ARGUMENTS (or the title+scope from loop-explorer above)

This stage has two paths. **General** projects lean on knowledge you already have
(common frameworks, standard patterns) — drive them with the **`brainstorming`
skill** (vendored from superpowers); if it's available in this harness, invoke it
and follow it. **Domain** projects hinge on knowledge that is *not* in your
training — the user's own glossary, business rules, and the reasons behind past
decisions — so they need relentless grilling and durable capture. Both paths are
inlined below and share the same gate, context scan, and terminal step.

<HARD-GATE>
Do NOT write code, scaffold anything, take any implementation action, or move on
to `/plan` until you have presented a design and the user has approved it. This
holds for every change regardless of how simple it looks — "too simple to design"
is where unexamined assumptions waste the most work. The design can be short, but
it MUST be presented and approved.
</HARD-GATE>

## Shared head

1. **Explore context (read-only).** Ground yourself in what exists — codegraph
   MCP for structure, grep/glob/read for the rest, plus recent commits and docs.
   Don't infer from names. While exploring, also look for domain docs: a root
   `CONTEXT.md`, a `CONTEXT-MAP.md` (signals a multi-context repo), and
   `docs/adr/`.
2. **Classify the path.** Decide whether this work hinges on domain knowledge you
   can't get from open-world training plus the repo. Signals for the **domain
   path**: an existing `CONTEXT.md`/`CONTEXT-MAP.md`/`docs/adr/`, specialized
   jargon you can't define precisely, or the user framing it as business-specific.
   When it's genuinely ambiguous, ask exactly one question:
   *"General build, or does this hinge on domain rules specific to your business
   that I should learn and document as we go?"* Then take the matching path.

## Path A — General

3a. **Clarify, one question at a time.** Surface purpose, constraints, and success
   criteria. Ask the single most-informative open question, wait for the answer,
   then the next. Don't batch. Before settling, **state your assumptions
   explicitly** — list what you're taking for granted and invite correction
   ("correct me now or I proceed with these") rather than silently filling gaps.
4a. **Propose 2-3 approaches.** Each must cite the concrete repo path/pattern it
   builds on (from step 1) — not "the standard way." Mark any approach that leans
   on assumed or external knowledge as **unverified** and say what you'd confirm.
   Give each a one-line summary, key tradeoffs, anything irreversible or
   high-blast-radius. State your recommendation and *why* — surface conflicts,
   don't average them.

## Path B — Domain

3b. **Grill the plan relentlessly**, one question at a time, waiting for each
   answer. Walk every branch of the design tree, resolving dependencies one by
   one; for each question give your recommended answer. If a question can be
   answered by reading the codebase, read it instead of asking. Specifically:
   - **Sharpen fuzzy language.** When the user uses a vague or overloaded term,
     propose one precise canonical term and list the aliases to avoid
     ("'account' — do you mean Customer or User? Those differ").
   - **Challenge against the glossary.** If a term conflicts with `CONTEXT.md`,
     call it out immediately and resolve it.
   - **Cross-reference code.** When the user states how something works, check the
     code agrees; surface contradictions ("your code cancels whole Orders, but you
     said partial cancellation is possible — which is right?").
   - **Stress-test with scenarios.** Invent concrete edge cases that force
     precision about boundaries between concepts.
4b. **Capture knowledge inline, lazily** — as decisions crystallize, not batched:
   - **`CONTEXT.md` (glossary only).** When a term resolves, write it down now.
     Create the file the first time a term is resolved (root `CONTEXT.md`, or the
     right per-context file if a `CONTEXT-MAP.md` exists). Format: a `## Language`
     section with bold **Term** → one/two-sentence definition + `_Avoid_:` aliases.
     Keep it a glossary — no implementation details, no general programming
     concepts, only terms specific to this domain.
   - **ADR** (`docs/adr/NNNN-slug.md`, sequential; create dir lazily). Offer one
     ONLY when all three hold: **hard to reverse**, **surprising without context**,
     and **the result of a real trade-off**. If any is missing, skip it. Format:
     `# {decision title}` + 1-3 sentences (context, what was decided, why).
5b. Then **propose 2-3 approaches** as in Path A (step 4a), now grounded in the
   sharpened terms.

## Shared tail

5. **Present the design** in sections scaled to their complexity, and get the
   user's approval. Revise until they approve. State the **success criteria** as
   specific, testable conditions (reframe vague requirements — "faster" becomes
   "p95 < 200ms"), since the loop runs until these are met.
6. **Write the design doc.** Save the approved design to
   `docs/designs/YYYY-MM-DD-<topic>-design.md`. Keep it tight: the decision, the
   chosen approach, success criteria, and what's explicitly out of scope. On the
   domain path the design doc is *in addition to* the `CONTEXT.md`/ADR updates,
   which stay the living source of domain truth for later stages.

Favor the minimum that satisfies the goal — nothing speculative. End by suggesting
`/plan` as the next stage, pointed at the design doc you just wrote.
