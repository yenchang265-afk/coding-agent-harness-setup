# Mode: azure (source = ado-hybrid, sink = ado-threads)

Self-contained, idempotent pass over the ADO PRs you were handed. You were given
an ALREADY-FILTERED PR list (status/draft/vote/iteration gating ran in the
runner) plus, per PR: the latest `iterationId`, the `lastReviewedIteration` (from
your marker), and an optional local checkout path pinned to the iteration's
source commit. Use the ADO tools section for every MCP call.

## Build the hunk-table (source = ado-hybrid)
1. **Line numbers (authoritative): MCP.** Call `repo_get_pull_request_changes` at
   the latest iteration (or the N→M delta if `lastReviewedIteration` < latest).
   Take each changed line's **new-side line number** directly from the MCP diff —
   never count hunk offsets yourself. Build entries
   `{ hunk_id, file, line, source_text }`.
2. **Context reads (cheap): local checkout, if provided.** To read around a hunk
   to judge a finding, `Read` the pinned local checkout instead of fetching the
   file through MCP. No checkout → fall back to MCP reads.
3. No diff/changes tool exposed → STOP and report you cannot fetch diffs. Never
   "review" from the title/description.

Hand the hunk-table to the shared core.

## Write findings (sink = ado-threads) — POST-GATE IS MANDATORY
For each finding the core returns (by `hunk_id`):
1. Look up `{ file, line, source_text }` from the hunk-table by `hunk_id`.
2. **Re-read line `line`** (local checkout if provided, else the MCP diff) and
   assert it equals `source_text`. **If it does not match, DROP the finding, log
   "anchor mismatch hunk_id=<id>", and do NOT post.** Off-by-one or a moved line
   means you have not confirmed the location.
3. Only on a match, post with `repo_create_pull_request_thread`, passing
   `filePath` + `rightFileStartLine`=`rightFileEndLine`=`line`. Before opening,
   check existing threads (from anyone) at that file/line — skip duplicates.
4. **Cap: at most ~8 new threads per PR per pass.** Roll the rest into the summary.

The model selects `hunk_id`; this gate supplies and verifies the line. A wrong
line cannot be posted.

## Summary + iteration marker
Post ONE summary thread (omit file/line on purpose → PR-level). Lead with the
core's tally or "No blocking issues", then grouped minor items, then EXACTLY:
`Automated review — iteration <M>.` (M = the iteration you reviewed). This marker
is your only memory between passes — keep it exact.

## Follow up on your threads
Find unresolved threads YOU authored whose latest comment is the author's reply.
If addressed (fixed later or answered convincingly), acknowledge briefly and
resolve (`repo_update_pull_request_thread`, status fixed/closed). If a real
concern remains, reply ONCE. Never resolve just to clear the board.

## Side-effects allowed: COMMENT-ONLY.
Leave/reply/resolve threads via MCP. NEVER edit code, push, vote, or add
reviewers (see off-limits). Read-only git is allowed only to read the pinned
checkout (diff/show/read) — never write/push/checkout-new.
