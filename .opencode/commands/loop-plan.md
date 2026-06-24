---
description: "/plan — turn the request into an ordered list of small, verifiable tasks with acceptance criteria. Read-only scan first, no edits."
---
**Plan** the work below. This is the second stage of the brainstorming → plan →
goal → close loop — it turns the design from `/brainstorming` (read the design doc
if one exists) into tasks. Start with a quick **read-only scan** of the relevant
code (codegraph MCP
for structure; grep/glob/read for the rest) to ground the plan in what actually
exists — don't infer from names. **Do not edit, commit, or push** — this stage
only produces the plan.

Task / goal: $ARGUMENTS

## Produce the plan
1. **Success criteria** — state, up front, what "done and verified" means for
   this goal (observable behavior + how it's checked). The loop runs until these
   are met.
2. **Tasks** — break the work into the smallest steps that each land and verify
   independently. For every task give:
   - a one-line description of the change,
   - the file(s)/area it touches,
   - its **acceptance check** (the test or observable result that proves it),
   - dependencies on earlier tasks (order them so each builds on green).
3. **Risks & decisions** — call out tradeoffs, anything irreversible or
   high-blast-radius (flag for confirmation before `/goal` runs it), and any
   simpler alternative worth considering. Surface conflicts; don't average them.
4. **Out of scope** — what this change deliberately does not do.

Favor the minimum that satisfies the goal — nothing speculative. Keep tasks
small enough that the `/goal` build phase can implement, test, and review each
one before moving on. End by suggesting `/goal` as the next stage.
