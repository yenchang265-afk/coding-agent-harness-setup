#!/usr/bin/env bash
# ado-gate.test.sh — qualify_prs filters on structured fields only.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/ado-gate.sh"

ME="me@org"
INPUT='[
  {"pullRequestId":1,"status":"active","isDraft":false,"createdBy":{"uniqueName":"other@org"},"reviewers":[{"uniqueName":"me@org","vote":0}],"latestIteration":3,"lastReviewedIteration":1},
  {"pullRequestId":2,"status":"active","isDraft":true ,"createdBy":{"uniqueName":"other@org"},"reviewers":[{"uniqueName":"me@org","vote":0}],"latestIteration":1,"lastReviewedIteration":0},
  {"pullRequestId":3,"status":"completed","isDraft":false,"createdBy":{"uniqueName":"other@org"},"reviewers":[{"uniqueName":"me@org","vote":0}],"latestIteration":2,"lastReviewedIteration":0},
  {"pullRequestId":4,"status":"active","isDraft":false,"createdBy":{"uniqueName":"me@org"},"reviewers":[{"uniqueName":"me@org","vote":0}],"latestIteration":2,"lastReviewedIteration":0},
  {"pullRequestId":5,"status":"active","isDraft":false,"createdBy":{"uniqueName":"other@org"},"reviewers":[{"uniqueName":"me@org","vote":10}],"latestIteration":2,"lastReviewedIteration":2},
  {"pullRequestId":6,"status":"active","isDraft":false,"createdBy":{"uniqueName":"other@org"},"reviewers":[{"uniqueName":"me@org","vote":0}],"latestIteration":2,"lastReviewedIteration":2}
]'
got="$(printf '%s' "$INPUT" | qualify_prs "$ME" | jq -c '[.[].pullRequestId]')"
# Keep only #1. Drop 2(draft) 3(completed) 4(mine) 5(approved) 6(nothing new).
[ "$got" = '[1]' ] || { echo "FAIL: expected [1], got $got" >&2; exit 1; }
echo "PASS"
