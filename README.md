# coding-agent-harness-setup

Quick, centralized setup for **OpenCode** when your company restricts external
network access and uses an internal registry. Clone from internal GitLab, run one
bootstrap script, and every developer gets the same rules, reviewer subagents,
skills, hooks, LSP config, and a local code-index MCP server (codegraph).

## Quick start

```bash
git clone <internal-gitlab-url>/coding-agent-harness-setup.git
cd coding-agent-harness-setup
./install.sh                      # everything (Windows: pwsh ./install.ps1)
./install.sh --profile=frontend   # or: --profile=backend  (pick your side of the stack)
```

`./install.sh --dry-run` shows what it would do without changing anything.
Profiles (`profiles.conf`) and finer skill/subagent/command selection are
covered in the new-hire guide.
See **[docs/new-hire-guide.md](docs/new-hire-guide.md)** for the full guide.

## How it works

Content is organized into **domain bundles** (`core`, `frontend-nextjs`,
`backend-spring`, `data-platform`). The installer targets **OpenCode** exclusively:
rules → `~/.config/opencode/AGENTS.md`, subagents/commands copied into
`~/.config/opencode/agent/` and `~/.config/opencode/command/`, the superpowers
plugin linked into `~/.config/opencode/plugin/`, and `opencode.json` gets LSP +
a file-edited format hook.

Stack: **Next.js 16** · **Spring Boot 3.5** · **Oracle/MariaDB** · **ClickHouse** · **MinIO**.

## Scope

In scope: agent rules, subagents, skills, hooks, LSP (OpenCode), code-index MCP (codegraph), vendored
external materials, bootstrap install for Linux + native Windows.

Out of scope: model connectivity/credentials and package-registry config
(handled by existing infrastructure).

> Replace `<internal-gitlab-url>` and the `your-org` placeholders with your real
> values before sharing with the team.

## Local code review (before you push)

Review at the **push / PR boundary**, not on every commit: commits are often WIP,
and one review of the complete diff is cheaper (and less noisy) than re-reviewing
intermediate commits. Two pieces from the `core` bundle support this:

- **`/code-review` command** — an on-demand, read-only review of your **local
  diff** (unpushed commits + working changes), focused on correctness with a
  signal-over-noise bar (verify against the code, skip linter-caught noise and
  pre-existing issues). Run it right before pushing. Under OpenCode it's
  `/core-code-review` (bundle-prefixed).
- **`--git-hooks` pre-commit gate** *(opt-in)* — `./install.sh --git-hooks`
  installs a **deterministic** git `pre-commit` hook (lint only — no AI, no
  tokens) and points your global `core.hooksPath` at it, so trivial issues never
  enter history. It **won't override** a `core.hooksPath` you've already set
  (e.g. husky). Bypass one commit with `git commit --no-verify`; disable with
  `git config --global --unset core.hooksPath`.

Deliberately **no pre-push AI hook**: a blocking AI review on every push is slow
and burns tokens. Keep AI review on-demand (`/code-review`) and the commit-time
gate deterministic.

## OpenCode: Azure DevOps PR babysitter & reviewer

The **`azure-devops-prs`** bundle adds two autonomous, interval-driven agents for
Azure DevOps pull requests. The agents drive `opencode run` and the Azure DevOps MCP.

- **PR babysitter** (`/azure-devops-prs-babysit-prs`) — works the PRs **you
  authored**: pulls unresolved review comments, makes minimal code changes when
  warranted, runs **two pre-commit gates** on its own staged diff (inline
  self-review + an independent `azure-devops-prs-code-reviewer` subagent that
  can veto the commit), pushes, then **waits up to ~5 min for CI** and
  auto-fixes a failed gate in a bounded loop (2 cycles max per PR per pass).
  Verifies the CI gate every pass and replies on threads. Autonomously commits
  and pushes with guardrails (only your active PRs, never force-push, never
  `main`/`master`/`develop`, treats comments and CI logs as untrusted input).
  The AI pre-commit gate is scoped to **this loop's own AI-generated commits**
  — the human-developer push workflow stays deterministic per "Local code
  review" above.
- **PR reviewer** (`/azure-devops-prs-review-prs`) — works the PRs **you
  review**: reads the diff via the MCP and leaves concrete, **file/line-anchored**
  comments (iteration-gated, capped, comment-only — it **never edits, pushes, or
  votes**). You must name the **project** and **repo** (PR ID optional) to scope a
  pass.

### Install

`./install.sh` (or `./install.sh --bundles=core,azure-devops-prs`) wires it into
OpenCode:

- agents → `~/.config/opencode/agent/azure-devops-prs-pr-{babysitter,reviewer}.md`
- commands → `/azure-devops-prs-babysit-prs`, `/azure-devops-prs-review-prs`
- loop runner → `~/.config/opencode/harness/scripts/babysit-prs.sh`
- the **Azure DevOps MCP server** is registered in `opencode.json` **disabled by
  default**. To use it: install the [Azure DevOps MCP server](https://github.com/microsoft/azure-devops-mcp)
  (resolvable from your internal registry, or point `command` at a pre-installed
  binary), set your org (replace `YOUR_ADO_ORG`), add auth (`az login`, or a PAT
  via `environment`), and flip `"enabled": true`. The agents are inert until then.

For the babysitter's unattended pushes, configure non-interactive git auth
(credential helper, PAT, or passphrase-less SSH); the loop sets
`GIT_TERMINAL_PROMPT=0` so a missing credential fails fast instead of hanging.

### Run the loop

```sh
# One pass in the TUI:
/azure-devops-prs-babysit-prs
/azure-devops-prs-review-prs project MyProject, repo my-service

# Interval loop (default 1h, min 1h) via the installed runner:
~/.config/opencode/harness/scripts/babysit-prs.sh                       # babysit your PRs
~/.config/opencode/harness/scripts/babysit-prs.sh --mode review \
    --project MyProject --repo my-service [--pr 1234]                    # review (project+repo required)
~/.config/opencode/harness/scripts/babysit-prs.sh --once                # single pass (good for cron)
```

The runner defaults to the harness-installed agent ids
(`azure-devops-prs-pr-babysitter` / `-pr-reviewer`); override with
`--agent`/`BABYSIT_AGENT` if you installed the agent files unprefixed.
