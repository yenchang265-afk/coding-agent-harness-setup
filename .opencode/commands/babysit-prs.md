---
description: Run one babysitting pass over my active Azure DevOps PRs (triage comments, fix + push if needed, check CI, reply).
agent: pr-babysitter
subtask: false
---
Run a single babysitting pass NOW over my active Azure DevOps pull requests.

Follow your standard workflow and guardrails: collect unresolved review
comments that are waiting on me, decide whether each needs a code change, make
minimal changes + commit + push where warranted, check the CI gate after
pushing, and reply on each thread (resolving only those you actually
addressed). For anything ambiguous or architecturally significant, reply with a
clarifying question instead of guessing.

Extra scope or instructions for this pass (optional): $ARGUMENTS
