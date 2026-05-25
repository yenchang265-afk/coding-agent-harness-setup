# New-hire guide — agentic coding environment

This repo centralizes the configuration for our AI coding agents so everyone
gets the same rules, reviewers, skills, and quality gates. Everything is served
from internal GitLab — nothing is downloaded from the public internet.

## What you get

- **Global rules** for our stack (Next.js 16, Spring Boot 3.5, Oracle/MariaDB, ClickHouse, MinIO), loaded into each agent.
- **Reviewer subagents**: `nextjs-reviewer`, `spring-reviewer`, `sql-reviewer`.
- **Skills** like `pre-pr-review`, plus the vendored **superpowers** skill library (TDD, systematic debugging, planning, code-review workflows).
- **Hooks** that auto-format on edit and remind you to test (where the agent supports hooks).
- **LSP** code intelligence for OpenCode.

## Supported agents

| | Rules | Subagents | Skills | Hooks | LSP |
|---|---|---|---|---|---|
| **Claude Code** | CLAUDE.md | native | native | native | editor only |
| **Codex CLI** | AGENTS.md | as prompts | as prompts | rules only (no enforcement) | editor only |
| **OpenCode** | AGENTS.md | native | as commands | file-edited hook | native |
| **Antigravity CLI** | GEMINI.md | — | native (SKILL.md) | — | editor only |

The plugin/skill concepts are richest in Claude Code; the others get the same
*content*, adapted to what each supports. Antigravity is Gemini-CLI-based and
shares `~/.gemini/GEMINI.md` with Gemini CLI, so our rules apply to both; it
consumes our skills natively in the `SKILL.md` format.

## Install

1. Clone from internal GitLab:
   ```
   git clone <internal-gitlab-url>/coding-agent-harness-setup.git
   cd coding-agent-harness-setup
   ```
2. Run the bootstrap:
   - **Linux / macOS / WSL:** `./install.sh`
   - **Windows (native):** `pwsh ./install.ps1`
   Options: `--agent=claude,codex,opencode,antigravity` (or `-Agent`), `--bundles=...`, `--dry-run` (or `-DryRun`).
3. Re-run after `git pull` to pick up updates — it's idempotent and backs up anything it replaces.

The bootstrap configures only the agents it finds on your `PATH` (override with `--agent`).

### Claude Code via the internal marketplace (alternative)

Instead of the copy-install, you can use the native plugin flow:
```
claude plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
claude plugin install core frontend-nextjs backend-spring data-platform
```

## Editor LSP (for humans, not the agents)

Install language servers from our internal mirror so your editor gives
intellisense (the agents don't rely on these, except OpenCode):
- TypeScript/Next.js: `typescript-language-server`
- Java/Spring: `jdtls` (Eclipse JDT Language Server)

## Out of scope here

- **Model connectivity / credentials** — handled by our existing setup; not managed by this repo.
- **Package registry config** — dependencies already resolve from internal Nexus/GitLab.

## Layout

```
bundles/        domain bundles (core, frontend-nextjs, backend-spring, data-platform)
  <bundle>/rules,agents,skills,commands,  core also has hooks/
vendor/         vendored external plugins/skills + MANIFEST.md (provenance + license)
adapters/       codex/config.toml, opencode/opencode.json (LSP)
bootstrap/      per-agent install logic
.claude-plugin/ marketplace.json (Claude Code internal marketplace)
install.sh / install.ps1
```

## Maintainers

- Add or edit a rule: change the relevant `bundles/<bundle>/rules/*.md`; it flows to all agents on next install.
- Add a reviewer: drop a `agents/<name>.md` into a bundle.
- Vendor an external skill/plugin: mirror it to GitLab, add it under `vendor/`, and record source+version+license in `vendor/MANIFEST.md`.

### Vendored: superpowers

[superpowers](https://github.com/obra/superpowers) (MIT) is vendored at
`vendor/superpowers/`. Its skills are installed into Claude Code by the
bootstrap (and via the internal marketplace). For **Codex** and **OpenCode**,
superpowers ships its own native configs (`vendor/superpowers/.codex-plugin/`,
`vendor/superpowers/.opencode/`) — point those agents at the vendored copy to
enable it, rather than re-adapting the skills by hand.
- Bump a bundle: update its `.claude-plugin/plugin.json` version and `marketplace.json`.
