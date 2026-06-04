---
name: code-review
description: Multi-agent code review — parallel rules-compliance and bug/security passes, per-issue validation, and high-signal filtering. Detects the active harness's rules file (CLAUDE.md / AGENTS.md / GEMINI.md). Read-only — reports findings, never edits, commits, or pushes.
---

# Code review

Review the diff with a multi-agent workflow: parallel reviewers → per-issue
validation → high-signal filtering. Every agent and subagent runs on whatever
model this session is using.

This is a review only — **never edit files, commit, or push.** Leave fixes to
the user.

## Agent rules file (harness-aware)

Each harness reads a different project-rules file. Determine the **rules file**
to audit against by the harness running this session:

| Harness | Rules file |
| --- | --- |
| Claude Code | `CLAUDE.md` |
| Codex CLI | `AGENTS.md` |
| OpenCode | `AGENTS.md` |
| Antigravity / Gemini CLI | `GEMINI.md` |

Prefer the file for the active harness. If you can't tell which harness is
running, treat **any** of `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` present in
the repo as a rules file (these tools assemble the same shared rules into
different filenames here, so their content is equivalent). Throughout the rest
of this skill, "rules file" means whichever of these applies.

**Agent assumptions (applies to all agents and subagents):**
- All tools are functional and will work without error. Do not test tools or
  make exploratory calls. Make this clear to every subagent you launch.
- Only call a tool if it is required to complete the task. Every tool call
  should have a clear purpose.

Create a todo list before starting, then follow these steps precisely.

## Step 1 — Gather the diff
Establish the review scope — review only what these show:
- Scope overview: `git status --short` and
  `git diff --stat @{upstream}...HEAD 2>/dev/null || git diff --stat HEAD`
- Committed but unpushed: `git diff @{upstream}...HEAD 2>/dev/null || git diff origin/HEAD...HEAD`
- Uncommitted work: `git diff HEAD`

If `$ARGUMENTS` names a path or commit range, review that instead. If there is
nothing to review, say so and stop.

## Step 2 — Collect rules-file paths
Launch an agent to return a list of file *paths* (not contents) for all relevant
rules files (see "Agent rules file" above for which filename(s) apply):
- The root rules file, if it exists.
- Any rules file in a directory containing files touched by the diff.

## Step 3 — Summarize the change
Launch an agent to summarize the diff concisely — the apparent intent of the
change. Derive intent from the commit messages (`git log @{upstream}..HEAD` /
`git log origin/HEAD..HEAD`) and the diff itself. Every later subagent receives
this summary for author-intent context.

## Step 4 — Four parallel reviewers
Launch 4 agents **in parallel**. Each returns a list of issues; each issue has a
description and the reason it was flagged (e.g. `"rules-file adherence"`,
`"bug"`). All four run on the same model.

- **Agents 1 + 2 — rules-file compliance.** Audit the changes for compliance
  with the rules file in parallel. When evaluating a file, only consider rules
  files that share its path or live in a parent directory.
- **Agent 3 — bug scan.** Scan for obvious bugs. Focus only on the diff itself
  without reading extra context. Flag only significant bugs; ignore nitpicks and
  likely false positives. Do not flag anything you cannot validate without
  context outside the diff.
- **Agent 4 — logic/security.** Look for problems in the introduced code —
  security issues, incorrect logic, etc. Only consider issues that fall within
  the changed code.

**CRITICAL: we only want HIGH-SIGNAL issues.** Flag an issue only when:
- The code will fail to compile or parse (syntax errors, type errors, missing
  imports, unresolved references), **or**
- The code will definitely produce wrong results regardless of inputs (clear
  logic errors), **or**
- It is a clear, unambiguous rules-file violation where you can quote the exact
  rule being broken.

Do **NOT** flag:
- Code style or quality concerns.
- Potential issues that depend on specific inputs or state.
- Subjective suggestions or improvements.

If you are not certain an issue is real, do not flag it. False positives erode
trust and waste reviewer time.

## Step 5 — Validate each issue
For every issue found by agents 3 and 4, launch parallel subagents (same model)
to validate it. Give each the change summary and the issue description. The
subagent's job is to confirm, with high confidence, that the stated issue is
truly an issue — e.g. for "variable is not defined," verify that's actually true
in the code; for a rules-file violation, verify the cited rule is scoped to that
file and is actually violated.

## Step 6 — Filter
Drop any issue that was not validated in Step 5. What remains is the
high-signal review.

## Step 7 — Report
Output the review to the terminal. **Do not edit, commit, or push.**
- Lead with a one-line tally of validated findings (e.g.
  `2 important, 1 functional`), or `No blocking issues` when clean.
- For each finding, give a brief description, the concrete `file:line`, why it
  matters, and a suggested fix.
- If none were found, state: `No issues found. Checked for bugs and rules-file
  compliance.`

## False positives — do NOT flag (apply in Steps 4 and 5)
- Pre-existing issues the diff didn't introduce (unless severe — security /
  data-loss).
- Something that looks like a bug but is actually correct.
- Pedantic nitpicks a senior engineer would not flag.
- Issues a linter / formatter / type checker / CI already catches (do not run
  the linter to verify).
- General code-quality concerns (e.g. lack of test coverage, generic security
  hardening) unless explicitly required by a rules file.
- Issues mentioned in the rules file but explicitly silenced in the code (e.g.
  via a lint-ignore comment).
