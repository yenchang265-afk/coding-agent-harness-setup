# New-hire guide — agentic coding environment

This repo centralizes the **OpenCode** configuration for our team so everyone
gets the same rules, reviewers, skills, and quality gates. Everything is served
from internal GitLab — nothing is downloaded from the public internet.

## What you get

- **Global rules** for our stack (Next.js 16, Spring Boot 3.5, Oracle/MariaDB, ClickHouse, MinIO), loaded into OpenCode via `~/.config/opencode/AGENTS.md`.
- **Reviewer subagents**: `nextjs-reviewer`, `spring-reviewer`, `sql-reviewer`.
- **Skills** via the vendored **superpowers** plugin (TDD, systematic debugging, planning, code-review workflows).
- **Hooks** that auto-format on edit (file-edited hook in `opencode.json`).
- **LSP** code intelligence (native in OpenCode).
- **Code index** via the codegraph MCP server, wired into OpenCode (local, offline).

## Install

1. Clone from internal GitLab:
   ```
   git clone <internal-gitlab-url>/coding-agent-harness-setup.git
   cd coding-agent-harness-setup
   ```
2. Run the bootstrap:
   - **Linux / macOS / WSL:** `./install.sh`
   - **Windows (native):** `pwsh ./install.ps1`
   Options: `--bundles=...`, `--dry-run` (or `-DryRun`).
3. Re-run after `git pull` to pick up updates — it's idempotent and backs up anything it replaces.

### Pick your side of the stack (profiles)

A **profile** installs the bundle set for your role:

- `./install.sh --profile=frontend` → `core` + `frontend-nextjs`
- `./install.sh --profile=backend` → `core` + `backend-spring` + `data-platform`
- `./install.sh --profile=fullstack` (default if you specify nothing) → everything

Profiles are defined in `profiles.conf`. `--bundles=...` overrides a profile;
`core` (global rules + hooks) stays in every profile.

### Choosing what to install (skills / subagents / commands)

By default you get everything. To narrow it down (Linux/macOS/WSL via
`install.sh`):

- **One-off flags:** `./install.sh --profile=backend --skills=tdd,grill-with-docs --subagents='*-reviewer' --commands=review-pr` (globs allowed).
- **Persistent manifest:** copy `harness.selection.example` to `harness.selection` (git-ignored) and list your picks — including a `profile <name>` line. It's read on every run, so it survives `git pull`. Flags override the manifest per-category for a single run.

A skills/subagents/commands category with no selection installs everything in
it. Note that **profiles scope bundle content** (rules, reviewers, bundle
skills); the **vendored skill library** (superpowers, ecc, mattpocock-skills) is
shared and installs for everyone regardless of profile — narrow it with
`--skills` if you don't want all of it.

**Rules are not selectable** — the centralized rule set (incl. the security
baseline) is always installed in full, by design. Native Windows `install.ps1`
supports profiles (`-ProfileName backend`) and the `profile` manifest line, but
not yet per-skill/subagent/command filtering — it installs all of those.

### OpenCode quick setup

If OpenCode is your agent, the one-liner is:
```bash
./install.sh --agent=opencode --profile=backend   # or frontend / fullstack
```
This writes `~/.config/opencode/`: rules → `AGENTS.md`, bundle subagents →
`agent/`, bundle commands → `command/`, the superpowers plugin → `plugin/`, and
merges LSP + a format hook into `opencode.json` (your existing config is
preserved, not overwritten).

For full intellisense, put the LSP server for your stack on `PATH` — the
installer warns if it's missing for a selected bundle:
- frontend → `typescript-language-server` (`npm i -g typescript-language-server typescript`)
- backend → `jdtls` (Eclipse JDT Language Server)

Skills come from the vendored superpowers plugin, which auto-loads on the next
OpenCode start. Verify with:
`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`, or ask it
"tell me about your superpowers".

On Windows: `.\install.ps1 -Agent opencode -ProfileName backend`. The plugin is
linked via a symlink, which needs **Developer Mode** (or an elevated shell)
enabled — otherwise the installer warns and you can fall back to the git-backed
plugin spec in `vendor/superpowers/.opencode/INSTALL.md`. The `opencode.json`
merge is manual on Windows (you get `opencode.harness.json` to merge in).

## Code indexing (codegraph MCP — for the agents)

The bootstrap wires [codegraph](https://github.com/colbymchenry/codegraph) into
OpenCode as a local **MCP server** (`codegraph serve --mcp`).
It gives the agent a queryable code knowledge graph — symbols, call/edge
relationships across 30+ languages — so it makes fewer, more accurate tool calls
when exploring an unfamiliar codebase. It's MIT and **100% local** (SQLite, no
data leaves your machine), which is why we chose it over hosted options.

The bootstrap adds the server to `opencode.json`. Existing config is preserved.

You still need the `codegraph` binary on `PATH` — the installer **does not**
download it (network policy), it just warns if it's missing:
```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
# Windows: irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
# then, once per repo:
codegraph init -i
```
After `init -i`, a file-watcher keeps the index fresh on edits.

Don't want it? Skip the wiring entirely with `./install.sh --no-codegraph`
(Windows: `.\install.ps1 -NoCodegraph`).

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
adapters/       opencode/opencode.json (LSP + MCP config)
bootstrap/      install logic
install.sh / install.ps1
```

## Maintainers

- Add or edit a rule: change the relevant `bundles/<bundle>/rules/*.md`; it flows to all agents on next install.
- Add a reviewer: drop a `agents/<name>.md` into a bundle.
- Vendor an external skill/plugin: mirror it to GitLab, add it under `vendor/`, and record source+version+license in `vendor/MANIFEST.md`.

### Vendored: superpowers

[superpowers](https://github.com/obra/superpowers) (MIT) is vendored at
`vendor/superpowers/`. The bootstrap symlinks the vendored plugin
(`vendor/superpowers/.opencode/plugins/superpowers.js`) into
`~/.config/opencode/plugin/`; the plugin self-registers the vendored skills
dir, so no manual step is needed.
