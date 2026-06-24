---
description: "/goal — build the planned change incrementally, then finalize it: local code review → commit → open the Azure DevOps PR. The build stage of the loop."
---
Drive the goal below to a **finished, reviewed, PR'd** state. This is the build
stage of the brainstorming → plan → goal → close loop: implement against the `/plan`
(ask for one if none exists), then **finalize**. Define the success criteria
first, then loop until they are verified.

Goal: $ARGUMENTS

## A. Build (incremental)
Work the plan one task at a time — implement, verify, move on. Don't write the
whole change at once.
- Make the **minimal, surgical** change for the current task; touch only what it
  needs. Follow the global rules and the surrounding code's conventions.
- After each task, run the gate for the project kind (the format hook runs on
  edit; you run lint + the tests covering what you touched). Leave it green
  before starting the next task — never skip or hardcode around a test.
- Checkpoint after each task: what's done, how it was verified, what remains.

## B. Finalize — only once the build is complete and green
1. **Local code review.** Review the full local diff (unpushed commits +
   working changes) using the **`code-review` skill in local mode**. Fix every
   Important and Functional finding, then re-review until clean. Read-only step —
   it reports; you fix.
2. **Commit.** Stage the change and pass **both pre-commit gates**:
   - your own staged-diff self-review (addresses the goal, on-scope, no debug
     code / secrets, gates pass), then
   - the independent **`loop-code-reviewer`** subagent's verdict on the staged
     diff (OpenCode: `opencode run --agent loop-code-reviewer "Review the
     currently staged diff in $(pwd) and return your structured verdict."`;
     Claude: the Task tool with the `code-reviewer` agent).
     `VERDICT: APPROVE` → commit. `VERDICT: REQUEST_CHANGES` → apply small,
     on-scope corrections and re-run both gates (cap 2 cycles); if still not
     approvable, stop and report — don't widen scope to silence it.
   Commit on a feature branch (never `main`/`master`/`develop`) with a message
   explaining the **why**, not the what. Then `git push -u origin <branch>`.
3. **Open the PR (Azure DevOps MCP).** Create the pull request with
   `repo_create_pull_request`, passing `repositoryId`, `sourceRefName`
   (`refs/heads/<your-branch>`), `targetRefName` (`refs/heads/<base>`), and a
   `title` summarizing the change; put the why + a test plan in the description.
   Keep the PR focused — unrelated cleanups go in their own PR.

## Output
Report: what was built (per task, with how it was verified), the local-review +
gate outcomes, the commit(s), and the **PR id / URL**. Then suggest `/close` as
the next stage to drive the PR to merge (resolve comments + keep CI green).
