# coding-agent-harness-setup

Quick, centralized setup for AI coding agents (Claude Code, Codex CLI, OpenCode,
Antigravity CLI) when your company restricts external network access and uses an internal
registry. Clone from internal GitLab, run one bootstrap script, and every
developer gets the same rules, reviewer subagents, skills, hooks, LSP config, and
a local code-index MCP server (codegraph).

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
`backend-spring`, `data-platform`). One bundle is consumed several ways:

- **Claude Code** — installed as plugins (skills, subagents, commands, hooks); rules → `CLAUDE.md`. An internal marketplace (`.claude-plugin/marketplace.json`) is also provided.
- **OpenCode** — rules → `AGENTS.md`, subagents/commands copied, `opencode.json` gets LSP + a file-edited format hook.
- **Codex CLI** — rules → `AGENTS.md`, subagents/commands → prompts; hook intent encoded as rules (Codex has no enforcing hooks).
- **Antigravity CLI** — Gemini-CLI-based; rules → `~/.gemini/GEMINI.md` (shared with Gemini CLI), skills linked natively in `SKILL.md` format.

Stack: **Next.js 16** · **Spring Boot 3.5** · **Oracle/MariaDB** · **ClickHouse** · **MinIO**.

## Scope

In scope: agent rules, subagents, skills, hooks, LSP (OpenCode), code-index MCP (codegraph), vendored
external materials, bootstrap install for Linux + native Windows.

Out of scope: model connectivity/credentials and package-registry config
(handled by existing infrastructure).

> Replace `<internal-gitlab-url>` and the `your-org` placeholders with your real
> values before sharing with the team.
