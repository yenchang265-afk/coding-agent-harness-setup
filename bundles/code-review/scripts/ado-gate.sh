#!/usr/bin/env bash
# ado-gate.sh — deterministic PR qualification. The degraded model must NEVER
# judge merge status; these are enum/integer fields, filtered here in code.
# Reads a JSON array of PRs on stdin, writes the qualifying subset as JSON.
#
# Qualifies iff ALL hold:
#   status == "active"                         (not draft/abandoned/completed)
#   isDraft == false
#   createdBy.uniqueName != me                 (my own PRs are the babysitter's job)
#   my reviewer vote == 0                      (not already approved/rejected)
#   latestIteration > lastReviewedIteration    (something new to review)
qualify_prs() {
  local me="$1"
  jq --arg me "$me" '
    map(select(
      .status == "active"
      and (.isDraft == false)
      and (.createdBy.uniqueName != $me)
      and (([.reviewers[]? | select(.uniqueName == $me) | .vote] | (first // 0)) == 0)
      and ((.latestIteration // 0) > (.lastReviewedIteration // 0))
    ))
  '
}
