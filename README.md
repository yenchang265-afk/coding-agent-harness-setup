# coding-agent-harness

A shared **plugin** for two coding agents — **Claude Code** and **OpenCode** —
that gives every developer the same engineering loop, global rules, review
skill, commit gate, and deterministic format/lint/test hooks. Authored once as a
single **bundle**; packaged natively for each agent.

It implements one loop:

> **brainstorming (idea → approved design) → plan → goal (build → finalize: local review → commit → open PR) → close (auto-fix CI + comment)**

> Replace `<internal-gitlab-url>` and `YOUR_ADO_ORG` placeholders with your real
> values before sharing with the team.

## The loop

Everything lives in one bundle, `bundles/loop/`. The four commands are the loop:

| Stage | Command | What it does | Side effects |
|-------|---------|--------------|--------------|
| brainstorming | `/brainstorming` | Turns a raw idea into an approved design. Branches: a **general** path (vendored `brainstorming` skill — read-only context scan, one-question-at-a-time clarification, 2-3 approaches) and a **domain** path (relentless grilling that sharpens terminology, cross-references code, and captures a `CONTEXT.md` glossary + ADRs for domain knowledge not in open-world training). Gated — no `/plan` until the user approves the design. | design doc; on domain path also `CONTEXT.md` + ADRs |
| plan | `/plan` | Read-only scan of the relevant code (codegraph MCP + reads), then ordered, verifiable tasks with acceptance criteria. | none |
| goal | `/goal` | Builds the plan incrementally, then **finalizes**: local `code-review` (local mode) → commit (behind the self-review + `loop-code-reviewer` gate) → opens the Azure DevOps PR (`repo_create_pull_request`). | branch, commit, push, PR |
| close | `/close` | Drives the open PR to merge: triages review comments, fixes + pushes, auto-fixes the CI gate (bounded), replies on threads. One self-contained pass per run. | commits, pushes, PR comments |

Supporting pieces in the bundle:

- **`rules/00-global.md`** — always-on global engineering rules (security hard
  rules + working principles).
- **`skills/code-review`** — the review brain: **local** mode (unpushed diff,
  terminal output) and **azure** mode (Azure DevOps PR, file/line-anchored
  comments). `/goal` finalize uses local mode.
- **`agents/code-reviewer`** — the staged-diff commit gate (returns
  `VERDICT: APPROVE | REQUEST_CHANGES`); used by `/goal` and `/close`.
- **`agents/closer`** — the autonomous PR closer behind `/close`.
- **`hooks/`** — format on edit, lint/test reminders on stop, a deterministic
  `pre-commit` lint gate, and a `SessionStart` rules hook.

## Install

### Claude Code

The repo is a Claude Code **plugin marketplace** (`.claude-plugin/marketplace.json`).

```text
/plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
/plugin install harness-loop@coding-agent-harness
```

The plugin auto-loads its `commands/`, `agents/`, `skills/`, and `hooks/`. Rules
are injected every session by a `SessionStart` hook and are also available on
demand as the `harness-rules-loop` skill.

### OpenCode

OpenCode is **project-scoped** — no install step. Running `opencode` inside this
repo auto-loads:

- `opencode.json` — LSP (TypeScript, Java), a file-edited format hook, the
  `codegraph` code-index MCP, the (disabled) Azure DevOps MCP, and `instructions`
  pointing at `bundles/loop/AGENTS.md`.
- `.opencode/agents/`, `.opencode/commands/`, `.opencode/skills/` — the bundle's
  agents/commands/skills, aggregated (e.g. `loop-closer`, `loop-goal`).
- `.opencode/plugins/superpowers.js` — the vendored Superpowers plugin.

To use it from **another** repo, add this repo's config to your global
`~/.config/opencode/`: point `instructions` at `bundles/loop/AGENTS.md` and copy
or symlink the `.opencode/{agents,commands,skills}` dirs.

## How it's built (maintainers)

**The bundle is the source of truth.** All agent-specific packaging is
**generated** from it by `scripts/build-plugins.py` — never hand-edit a generated
file. Edit the bundle sources, then re-run:

```bash
python3 scripts/build-plugins.py          # regenerate all packaging
python3 scripts/build-plugins.py --check   # CI gate: fail if anything is stale
```

Generated: `.claude-plugin/marketplace.json`, `bundles/loop/.claude-plugin/plugin.json`,
the bundle's `AGENTS.md` + `harness-rules-loop` skill + `SessionStart` rules hook,
the root `AGENTS.md` + `opencode.json`, and the aggregated `.opencode/` tree.

The `code-review` skill is assembled from `bundles/loop/_parts/` by
`bundles/loop/scripts/build-review.sh` — run that **before** `build-plugins.py`
if you change those parts.

## Local code review (before you push)

Review at the **push / PR boundary**, not on every commit.

- **`/goal` finalize** runs the `code-review` skill in local mode over your
  unpushed diff, correctness-focused with a signal-over-noise bar, before it
  commits.
- **pre-commit gate** — `bundles/loop/hooks/pre-commit` is a **deterministic**
  lint-only gate (no AI, no tokens). Point your global `core.hooksPath` at the
  installed hook to keep trivial issues out of history; bypass one commit with
  `git commit --no-verify`.

Deliberately **no pre-push AI hook** — a blocking AI review on every push is slow
and burns tokens. The AI review is the finalize step; the commit-time gate is
deterministic.

## Determinism gates for degraded models

The Azure DevOps stages run under OpenCode and add gates so a weak/confused model
can't leave noise or push bad code:

- **Two pre-commit gates** — every AI-generated commit (`/goal` finalize and
  `/close` auto-fix) passes a staged-diff self-review **and** the independent
  `loop-code-reviewer` subagent's `VERDICT:` before it's allowed to commit.
- **Re-read post-gate (azure review)** — after drafting a PR comment the agent
  re-reads the actual file/line from the MCP to confirm the anchor; wrong-line
  anchors are dropped, not posted.
- **Bounded CI auto-fix** — `/close` fixes failing CI within a capped number of
  cycles, then flags for a human rather than looping forever.

The Azure DevOps MCP is registered **disabled** in `opencode.json`; enable it and
set your org (replace `YOUR_ADO_ORG`) to use `/goal`'s PR creation and `/close`.
See `docs/new-hire-guide.md` for the `close-loop.sh` runner.

## Scope

In scope: the brainstorming → plan → goal → close loop, global rules, the review
skill + commit gate + PR closer, hooks, OpenCode LSP, the codegraph code-index
MCP, vendored external materials (`vendor/`), and native plugin packaging for
Claude Code and OpenCode.

Out of scope: model connectivity/credentials and package-registry config
(handled by existing infrastructure).
