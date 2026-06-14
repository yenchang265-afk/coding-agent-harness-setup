---
description: Review the local diff (unpushed commits + working changes) for correctness before you push. Read-only — reports findings, never edits or pushes.
---
Do a focused **code review of my local diff** — the work that isn't on the remote
yet — so I can fix problems before they reach the PR (and the automated reviewer).

## Gather the diff (don't review the whole repo)
Run these and review only what they show:
- Scope: `git status --short` and `git diff --stat @{upstream}...HEAD 2>/dev/null || git diff --stat HEAD`
- Unpushed commits: `git diff @{upstream}...HEAD 2>/dev/null || git diff origin/HEAD...HEAD`
- Uncommitted work: `git diff HEAD`

If `$ARGUMENTS` names a path or commit range, review that instead.

## Review philosophy — signal over noise
Only raise a finding you can stand behind: one you've **verified against the
actual code** (trace the path, cite a concrete `file:line`), with a real reason
it's wrong — not a guess inferred from a name or a vague "looks risky". If you
wouldn't bet it's a real problem, don't raise it. Classify what survives:
- **Important** — correctness / logic bug, security hole, data-loss / race → fix before pushing.
- **Functional** — API / contract concern, missing error handling, broken edge case.
- **Nit** — style / naming / typo. Group these; mention as a count, don't enumerate every one.

**Do NOT report** (noise): anything the linter / formatter / type checker / CI
already catches; pedantic nitpicks; code that looks buggy but isn't once you
trace it; lines carrying a lint-ignore / suppression comment; pre-existing issues
this diff didn't introduce (unless severe — security / data-loss).

## Output
Lead with a one-line tally (e.g. `2 important, 1 functional, 3 nits`), or **"No
blocking issues"** when clean. Then list each Important/Functional finding with
its `file:line`, why it matters, and a concrete fix. Roll nits into a single
grouped note. This is a review only — **do not edit files, commit, or push**;
leave that to me.
