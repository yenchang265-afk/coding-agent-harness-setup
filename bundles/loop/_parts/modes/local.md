# Mode: local (source = local git, sink = terminal)

On-demand review of the unpushed local diff before pushing. Read-only.

## Build the hunk-table (source)
Run, and review ONLY what they show:
- Scope:            `git status --short`
- Unpushed commits: `git diff @{upstream}...HEAD 2>/dev/null || git diff origin/HEAD...HEAD`
- Uncommitted:      `git diff HEAD`
If the request names a path or commit range, diff that instead.

For each changed line on the new side, build one hunk-table entry
`{ hunk_id, file, line, source_text }` — `line` is the new-side line number the
unified diff already reports; `source_text` is that exact line. Read context
around a hunk when you need it to judge a finding.

Hand the hunk-table to the shared core and run its review.

## Write findings (sink = terminal)
Lead with the core's one-line tally, or **"No blocking issues"** when clean.
Then list each Important/Functional finding as `file:line — why — fix`, using the
line the finding's `hunk_id` maps to in the table. Roll nits into one grouped
note with a count.

## Side-effects allowed: NONE.
Do not edit files, commit, or push. Review only.
