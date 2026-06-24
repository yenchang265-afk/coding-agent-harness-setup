---
description: "/close — drive my active Azure DevOps PRs to merge: triage comments, fix + push, auto-fix CI, reply. The closing stage of the brainstorming → plan → goal → close loop."
agent: loop-closer
subtask: false
---
Run a single **close** pass NOW over my active Azure DevOps pull requests — the
`/close` stage after `/goal` opened the PR.

Follow your standard workflow and guardrails: collect unresolved review
comments that are waiting on me, decide whether each needs a code change, make
minimal changes + commit + push where warranted, and reply on each thread
(resolving only those you actually addressed). Verify the CI gate on every
active PR every pass — even when there are no comments and you make no code
changes — and treat a blocked gate like an active comment that needs attention;
auto-fix it within the bounded fix-cycle cap. For anything ambiguous or
architecturally significant, reply with a clarifying question instead of
guessing.

Every commit must pass both pre-commit gates: your own staged-diff self-review,
then the independent `loop-code-reviewer` subagent's verdict.

Extra scope or instructions for this pass (optional): $ARGUMENTS
