# coding-agent-harness

A shared **plugin** for three coding agents — **Claude Code**, **Codex**, and
**OpenCode** — that gives every developer the same per-stack rules, reviewer
subagents, skills, and deterministic review/format hooks. Authored once as
**domain bundles**; packaged natively for each agent.

Stack: **Next.js 16** · **Spring Boot 3.5** · **Oracle/MariaDB** · **ClickHouse** · **MinIO**.

> Replace `<internal-gitlab-url>` and `your-org` placeholders with your real
> values before sharing with the team.

## What's in it

Content lives in **bundles** (`bundles/<bundle>/`). Each bundle carries some mix
of `rules/`, `agents/`, `commands/`, `skills/`, and `hooks/`:

| Bundle | Agents (Claude/Codex/OpenCode) | What it adds |
|--------|:---:|--------------|
| `core` | all | Global coding rules (always-on), `/code-review` command, deterministic pre-commit + format/lint/test hooks, pre-PR review skill |
| `frontend-nextjs` | all | Next.js 16 rules, Next.js reviewer agent, route scaffolder command |
| `backend-spring` | all | Spring Boot 3.5 rules, Spring reviewer agent |
| `data-platform` | all | Oracle/MariaDB + ClickHouse/MinIO rules, SQL reviewer agent |
| `code-review` | OpenCode only | Unified review brain: local-diff + Azure DevOps PR review skill, scheduled PR-reviewer agent |
| `azure-devops-prs` | OpenCode only | Autonomous Azure DevOps PR babysitter agent + command |

The last two are **OpenCode-only** (their agents drive `opencode run` + the Azure
DevOps MCP); that restriction is declared in each bundle's `adapters` file and
honored by the build (no Claude/Codex manifest is emitted for them).

## Install

### Claude Code

The repo is a Claude Code **plugin marketplace** (`.claude-plugin/marketplace.json`)
listing one plugin per bundle.

```text
/plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
/plugin install harness-core@coding-agent-harness
/plugin install harness-frontend-nextjs@coding-agent-harness   # your side of the stack
/plugin install harness-backend-spring@coding-agent-harness
/plugin install harness-data-platform@coding-agent-harness
```

Each plugin auto-loads its `commands/`, `agents/`, `skills/`, and `hooks/`.
Rules are injected every session by a `SessionStart` hook (always-on) and are
also available on demand as `harness-rules-*` skills.

### Codex

The repo is also a Codex **plugin marketplace** (`.agents/plugins/marketplace.json`):

```text
codex plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
codex plugin install harness-core
```

Codex loads each bundle's `skills/` (including the `harness-rules-*` rule skills)
and `hooks/`. When you run Codex **inside this repo**, the per-bundle `AGENTS.md`
files are picked up directly as always-on instructions.

### OpenCode

OpenCode is **project-scoped** — no install step. Running `opencode` inside this
repo auto-loads:

- `opencode.json` — LSP (TypeScript, Java), a file-edited format hook, the
  `codegraph` code-index MCP, the (disabled) Azure DevOps MCP, and `instructions`
  pointing at every bundle's `AGENTS.md`.
- `.opencode/agents/`, `.opencode/commands/`, `.opencode/skills/` — all bundle
  agents/commands/skills, aggregated.
- `.opencode/plugins/superpowers.js` — the vendored Superpowers plugin.

To use it from **another** repo, add this repo's config to your global
`~/.config/opencode/`: point `instructions` at `bundles/*/AGENTS.md` and copy or
symlink the `.opencode/{agents,commands,skills}` dirs.

## How it's built (maintainers)

**The bundles are the source of truth.** All agent-specific packaging is
**generated** from them by `scripts/build-plugins.py` — never hand-edit a
generated file. Edit the bundle sources, then re-run:

```bash
python3 scripts/build-plugins.py          # regenerate all packaging
python3 scripts/build-plugins.py --check   # CI gate: fail if anything is stale
```

Generated: the two `marketplace.json` files, per-bundle `.claude-plugin/plugin.json`
and `.codex-plugin/plugin.json`, each bundle's `AGENTS.md` + `harness-rules-*`
skill + `SessionStart` rules hook, the root `AGENTS.md` + `opencode.json`, and the
aggregated `.opencode/` tree.

The `code-review` bundle additionally generates `SKILL.md` + `agents/pr-reviewer.md`
from parts via `bundles/code-review/scripts/build-review.sh` (run that before
`build-plugins.py` if you change those parts).

## Local code review (before you push)

Review at the **push / PR boundary**, not on every commit.

- **`/code-review`** (`core`) — on-demand, read-only review of your **local diff**
  (unpushed commits + working changes), correctness-focused with a
  signal-over-noise bar. Run it right before pushing.
- **pre-commit gate** — `bundles/core/hooks/pre-commit` is a **deterministic**
  lint-only gate (no AI, no tokens). Point your global `core.hooksPath` at the
  installed hook to keep trivial issues out of history; bypass one commit with
  `git commit --no-verify`.

Deliberately **no pre-push AI hook** — a blocking AI review on every push is slow
and burns tokens. Keep AI review on-demand and the commit-time gate deterministic.

## Determinism gates for degraded models

The `code-review` and `azure-devops-prs` bundles run under OpenCode and add gates
so a weak/confused model can't leave noise:

- **`ado-gate.sh` pre-filter** — drops PRs that are merged/abandoned/draft or
  already reviewed at the current iteration *before* any LLM call (via the
  `PR_LIST_JSON` + `ADO_ME` env vars).
- **Re-read post-gate** — after drafting a comment the agent re-reads the actual
  file/line from the MCP to confirm the anchor; wrong-line anchors are dropped,
  not posted.

The Azure DevOps MCP is registered **disabled** in `opencode.json`; enable it and
set your org (replace `YOUR_ADO_ORG`) to use these bundles. See
`docs/new-hire-guide.md` for the review/babysit loop runners.

## Scope

In scope: per-stack rules, reviewer subagents, skills, hooks, OpenCode LSP, the
codegraph code-index MCP, vendored external materials (`vendor/`), and native
plugin packaging for Claude Code, Codex, and OpenCode.

Out of scope: model connectivity/credentials and package-registry config
(handled by existing infrastructure).
