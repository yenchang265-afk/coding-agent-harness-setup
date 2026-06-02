---
name: code-review
description: Review a GitHub pull request with the official Claude Code multi-agent workflow — parallel agent-rules-compliance and bug/security passes, per-issue validation, and confidence filtering — then report findings or post inline PR comments with `--comment`. Detects the active harness's rules file (CLAUDE.md / AGENTS.md / GEMINI.md). Read-only unless `--comment` is given.
---

# Code review

Provide a code review for the given pull request, mirroring Anthropic's official
`code-review` plugin workflow. The one deliberate change from the upstream
plugin: **every agent and subagent uses the same model** — there is no
haiku/sonnet/opus tiering. Spawn each step with whatever model this session is
already running; do not downgrade or upgrade per step.

Use `gh` to interact with GitHub (fetch PRs, post comments). Do not use web
fetch. The target PR is given in `$ARGUMENTS` (a PR number or URL); if none is
given, resolve the PR for the current branch with `gh pr view`.

## Agent rules file (harness-aware)

The upstream plugin assumes `CLAUDE.md`. This repo is multi-harness, and each
harness reads a different project-rules file. Determine the **rules file** to
audit against by the harness running this session:

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
of this skill, "rules file" means whichever of these applies — substitute the
concrete filename(s) wherever the steps say "rules file."

**Agent assumptions (applies to all agents and subagents):**
- All tools are functional and will work without error. Do not test tools or
  make exploratory calls. Make this clear to every subagent you launch.
- Only call a tool if it is required to complete the task. Every tool call
  should have a clear purpose.

Create a todo list before starting, then follow these steps precisely.

## Step 1 — Gate check
Launch an agent to check whether any of these are true:
- The pull request is closed.
- The pull request is a draft.
- The pull request does not need review (e.g. an automated PR, or a trivial
  change that is obviously correct).
- Claude has already commented on this PR (check `gh pr view <PR> --comments`
  for comments left by Claude).

If any condition is true, stop and do not proceed. **Note:** still review
Claude-generated PRs — only skip if Claude has already *reviewed* it.

## Step 2 — Collect rules-file paths
Launch an agent to return a list of file *paths* (not contents) for all relevant
rules files (see "Agent rules file" above for which filename(s) apply):
- The root rules file, if it exists.
- Any rules file in a directory containing files modified by the PR.

## Step 3 — Summarize the PR
Launch an agent to view the pull request (`gh pr view`, `gh pr diff`) and return
a concise summary of the changes. Capture the PR title and description — every
later subagent receives these for author-intent context.

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
to validate it. Give each the PR title, description, and the issue description.
The subagent's job is to confirm, with high confidence, that the stated issue is
truly an issue — e.g. for "variable is not defined," verify that's actually true
in the code; for a rules-file violation, verify the cited rule is scoped to that
file and is actually violated.

## Step 6 — Filter
Drop any issue that was not validated in Step 5. What remains is the
high-signal review.

## Step 7 — Report
Output a summary of findings to the terminal:
- If issues were found, list each with a brief description.
- If none were found, state: `No issues found. Checked for bugs and rules-file
  compliance.`

If `--comment` was **not** provided, stop here — post no GitHub comments.

If `--comment` **was** provided and **no** issues were found, post a summary
comment with `gh pr comment` (format below) and stop.

If `--comment` **was** provided and issues **were** found, continue to Step 8.

## Step 8 — Stage comments
Build the list of comments you plan to leave. This is only for you to confirm
you are comfortable with them — do not post this list anywhere.

## Step 9 — Post inline comments
Post inline comments for each issue using
`mcp__github_inline_comment__create_inline_comment` with `confirmed: true`. For
each comment:
- Provide a brief description of the issue.
- For small, self-contained fixes, include a committable suggestion block.
- For larger fixes (6+ lines, structural changes, or changes spanning multiple
  locations), describe the issue and the suggested fix **without** a suggestion
  block.
- Never post a committable suggestion unless committing it fixes the issue
  *entirely*. If follow-up steps are required, do not leave a committable
  suggestion.

**Only post ONE comment per unique issue. Do not post duplicates.**

## False positives — do NOT flag (apply in Steps 4 and 5)
- Pre-existing issues the diff didn't introduce.
- Something that looks like a bug but is actually correct.
- Pedantic nitpicks a senior engineer would not flag.
- Issues a linter will catch (do not run the linter to verify).
- General code-quality concerns (e.g. lack of test coverage, generic security
  hardening) unless explicitly required by a rules file.
- Issues mentioned in the rules file but explicitly silenced in the code (e.g.
  via a lint-ignore comment).

## Notes
- Use the `gh` CLI for all GitHub interaction. Do not use web fetch.
- You must cite and link each issue in inline comments (e.g. if referring to a
  rules-file rule, link to it).
- If no issues are found and `--comment` is provided, post this comment:

  ---

  ## Code review

  No issues found. Checked for bugs and rules-file compliance.

  ---

- When linking to code in inline comments, follow this format precisely or the
  Markdown preview won't render correctly:
  `https://github.com/anthropics/claude-code/blob/c21d3c10bc8e898b7ac1a2d745bdc9bc4e423afe/package.json#L10-L15`
  - Requires the **full** git SHA — a literal SHA, not a `$(git rev-parse HEAD)`
    substitution (the comment is rendered as raw Markdown).
  - The repo name must match the repo you're reviewing.
  - A `#` sign after the file name.
  - Line range format is `L[start]-L[end]`.
  - Provide at least one line of context before and after, centered on the line
    you're commenting on (e.g. for lines 5-6, link to `L4-7`).
