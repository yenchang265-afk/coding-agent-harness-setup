# New-hire guide — agentic coding environment

This repo is a shared **plugin** for **Claude Code**, **Codex**, and **OpenCode**
so everyone gets the same rules, reviewers, skills, and quality gates. It's served
from internal GitLab — nothing is downloaded from the public internet.

## What you get

- **Per-stack rules** (Next.js 16, Spring Boot 3.5, Oracle/MariaDB, ClickHouse,
  MinIO) — always-on, delivered the native way for each agent.
- **Reviewer subagents**: `nextjs-reviewer`, `spring-reviewer`, `sql-reviewer`
  (plus the OpenCode-only `code-review` / `azure-devops-prs` agents).
- **Skills**: bundle skills (pre-PR review, code-review) + the vendored
  **superpowers** library (TDD, systematic debugging, planning).
- **Hooks**: deterministic format/lint/test gates; a `SessionStart` rules hook.
- **LSP** code intelligence (OpenCode) and the **codegraph** code-index MCP.

## Install — pick your agent

Content is organized into **bundles**. Install only the bundles for your side of
the stack; everyone takes `core`.

### Claude Code

```text
/plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
/plugin install harness-core@coding-agent-harness
# frontend devs:
/plugin install harness-frontend-nextjs@coding-agent-harness
# backend devs:
/plugin install harness-backend-spring@coding-agent-harness
/plugin install harness-data-platform@coding-agent-harness
```

Plugins auto-load their commands/agents/skills/hooks. Rules arrive every session
via a `SessionStart` hook and on demand as `harness-rules-*` skills. Re-run
`/plugin update` after upstream changes.

### Codex

```text
codex plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
codex plugin install harness-core
codex plugin install harness-frontend-nextjs   # or harness-backend-spring, harness-data-platform
```

Codex loads each bundle's `skills/` (incl. the `harness-rules-*` rule skills) and
hooks. Running Codex **inside this repo** also picks up the per-bundle `AGENTS.md`
as always-on instructions.

### OpenCode

OpenCode is **project-scoped** — clone the repo and run `opencode` inside it. It
auto-loads `opencode.json` (LSP + format hook + codegraph MCP + `instructions`)
and the aggregated `.opencode/{agents,commands,skills}` + `.opencode/plugins/`.

To use OpenCode from another repo, add this repo's config to your global
`~/.config/opencode/`: set `instructions` to `bundles/*/AGENTS.md` and copy or
symlink the `.opencode/{agents,commands,skills}` dirs. The OpenCode-only
`code-review` and `azure-devops-prs` bundles ship here too.

## Code indexing (codegraph MCP)

[codegraph](https://github.com/colbymchenry/codegraph) is wired into OpenCode as a
local **MCP server** (`codegraph serve --mcp`) in `opencode.json`. It gives the
agent a queryable code knowledge graph (symbols + call/edge relations across 30+
languages) so it makes fewer, more accurate tool calls. MIT, **100% local**
(SQLite). For Claude Code, add the same MCP via your client config.

You still need the `codegraph` binary on `PATH` (not downloaded here — network
policy):

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
# Windows: irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
codegraph init -i      # once per repo; a file-watcher then keeps the index fresh
```

## Editor LSP (for humans)

Install language servers from our internal mirror for editor intellisense:
- TypeScript/Next.js: `typescript-language-server` (`npm i -g typescript-language-server typescript`)
- Java/Spring: `jdtls` (Eclipse JDT Language Server)

OpenCode uses these too (configured in `opencode.json`); the other agents don't.

## The review/babysit loops (OpenCode bundles)

The `code-review` and `azure-devops-prs` bundles drive `opencode run` + the Azure
DevOps MCP. The MCP is registered **disabled** in `opencode.json`; set your org
(replace `YOUR_ADO_ORG`), add auth, and flip `"enabled": true` to use them.

```sh
# Review open PRs (single pass good for cron):
bundles/code-review/scripts/review-loop.sh --project MyProject --repo my-service --once
# Babysit your own PRs:
bundles/azure-devops-prs/scripts/babysit-prs.sh --once
```

## Out of scope here

- **Model connectivity / credentials** — handled by existing setup.
- **Package registry config** — dependencies resolve from internal Nexus/GitLab.

## Layout

```
bundles/        domain bundles — the source of truth
  <bundle>/rules,agents,commands,skills,hooks + generated AGENTS.md & manifests
.claude-plugin/ marketplace.json (Claude Code)            [generated]
.agents/        plugins/marketplace.json (Codex)          [generated]
opencode.json   OpenCode config (lsp+mcp+instructions)    [generated]
.opencode/      aggregated agents/commands/skills/plugins [generated]
AGENTS.md       assembled global rules                    [generated]
scripts/        build-plugins.py (the generator)
vendor/         vendored external plugins/skills + MANIFEST.md (provenance + license)
docs/
```

## Maintainers

**Bundles are the source of truth; everything else is generated.** Never
hand-edit a generated file (they carry a "GENERATED" marker).

- **Edit a rule:** change `bundles/<bundle>/rules/*.md`, then run
  `python3 scripts/build-plugins.py`. It regenerates AGENTS.md, the rule skill,
  and the rules hook for every agent.
- **Add a reviewer:** drop `bundles/<bundle>/agents/<name>.md` in, re-run the
  generator.
- **Add a command/skill:** add it under the bundle, re-run the generator.
- **New bundle:** create `bundles/<name>/`, add a `BUNDLE_META` entry in
  `scripts/build-plugins.py` (and an `adapters` file if it's agent-restricted),
  re-run.
- **CI gate:** `python3 scripts/build-plugins.py --check` fails if any generated
  artifact is stale — run it in CI so generated files never drift from sources.

### Vendored: superpowers

[superpowers](https://github.com/obra/superpowers) (MIT) is vendored at
`vendor/superpowers/`. The generator emits `.opencode/plugins/superpowers.js`
re-exporting the vendored OpenCode plugin, so it auto-loads when you run OpenCode
in this repo. See `vendor/MANIFEST.md` for all vendored sources + licenses.
