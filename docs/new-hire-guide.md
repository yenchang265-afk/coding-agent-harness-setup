# New-hire guide — agentic coding environment

This repo is a shared **plugin** for **Claude Code** and **OpenCode** so everyone
gets the same engineering loop, rules, reviewers, skills, and quality gates. It's
served from internal GitLab — nothing is downloaded from the public internet.

It packages **one bundle**, `loop`, that implements a single engineering loop:

> **brainstorming (idea → approved design) → plan → goal (build → finalize: local review → commit → open PR) → close (auto-fix CI + comment)**

## What you get

- **The loop commands** — `/brainstorming`, `/plan`, `/goal`, `/close`.
- **Always-on global rules** — security hard rules + working principles,
  delivered the native way for each agent.
- **Reviewer subagents** — `code-reviewer` (the staged-diff commit gate) and the
  autonomous `closer` (drives Azure DevOps PRs to merge).
- **Skills**: the `code-review` skill (local diff + Azure DevOps PR modes) + the
  vendored **superpowers** library (TDD, systematic debugging, planning).
- **Hooks**: deterministic format/lint/test gates; a `SessionStart` rules hook.
- **LSP** code intelligence (OpenCode) and the **codegraph** code-index MCP.

## The loop

| Stage | Command | What it does |
|-------|---------|--------------|
| brainstorming | `/brainstorming` | Gated. Turns a raw idea into an approved design. **General** path: vendored `brainstorming` skill — read-only context scan, one-question-at-a-time clarification, 2-3 approaches. **Domain** path: relentless grilling that sharpens terminology, cross-references code, and captures a `CONTEXT.md` glossary + ADRs for domain knowledge not in open-world training. No `/plan` until the user approves the design; writes a design doc. |
| plan | `/plan` | Read-only. Scans the relevant code (codegraph MCP + reads), then ordered, verifiable tasks with acceptance criteria. Never edits. |
| goal | `/goal` | Builds the plan incrementally, then **finalizes**: local `code-review` (local mode) → commit (behind the self-review + `loop-code-reviewer` gate) → opens the Azure DevOps PR. |
| close | `/close` | Drives the open PR to merge: triages review comments, fixes + pushes, auto-fixes the CI gate, replies on threads. Runs one self-contained pass; schedule it with `close-loop.sh`. |

### Brainstorming: the two paths

`/brainstorming` always starts the same — a read-only context scan, then a
**classify** step that decides which path the work needs. The split exists because
the agent's open-world training already covers some work but not yours: general
patterns it knows, your domain rules it doesn't.

**How it classifies.** Domain path when any of these hold: a `CONTEXT.md` /
`CONTEXT-MAP.md` / `docs/adr/` already exists, the idea uses specialized jargon the
agent can't define precisely, or you frame it as business-specific. Otherwise
general. When it's genuinely ambiguous, the agent asks exactly one question —
*"General build, or does this hinge on domain rules specific to your business that
I should learn and document?"* — and takes the answer.

| | **Path A — General** | **Path B — Domain** |
|---|---|---|
| When | Common frameworks/patterns the agent already knows | Knowledge not in training: your glossary, business rules, the *why* behind past decisions |
| Driver | Vendored superpowers `brainstorming` skill | Inlined grill-with-docs-style interrogation |
| How | One question at a time, surface assumptions explicitly, 2-3 approaches citing concrete repo paths | Relentless grilling: sharpen fuzzy terms to one canonical word, challenge against the glossary, cross-reference claims against code, stress-test with edge-case scenarios |
| Durable artifacts | Design doc | Design doc **plus** a `CONTEXT.md` glossary (updated inline as terms resolve) and lazy ADRs (`docs/adr/NNNN-*.md`) |

**ADRs are offered sparingly** — only when a decision is *hard to reverse* **and**
*surprising without context* **and** *the result of a real trade-off*. Miss any one
and it's skipped.

**Both paths share the same spine:** the `<HARD-GATE>` (no code, no scaffolding, no
`/plan` until you approve the design — even for "too simple to design" work), then
present the design → restate success criteria as testable conditions → write
`docs/designs/YYYY-MM-DD-<topic>-design.md` → suggest `/plan`. On the domain path
the design doc is *additional to* the `CONTEXT.md`/ADR updates, which stay the
living source of domain truth for `/plan`, `/goal`, and `/close`.

## Install — pick your agent

### Claude Code

```text
/plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup
/plugin install harness-loop@coding-agent-harness
```

The plugin auto-loads its commands/agents/skills/hooks. Rules arrive every
session via a `SessionStart` hook and on demand as the `harness-rules-loop`
skill. Re-run `/plugin update` after upstream changes.

### OpenCode

OpenCode is **project-scoped** — clone the repo and run `opencode` inside it. It
auto-loads `opencode.json` (LSP + format hook + codegraph MCP + the Azure DevOps
MCP + `instructions`) and the aggregated `.opencode/{agents,commands,skills}` +
`.opencode/plugins/`.

To use OpenCode from another repo, add this repo's config to your global
`~/.config/opencode/`: set `instructions` to `bundles/loop/AGENTS.md` and copy or
symlink the `.opencode/{agents,commands,skills}` dirs.

## Code indexing (codegraph MCP)

[codegraph](https://github.com/colbymchenry/codegraph) is wired into OpenCode as a
local **MCP server** (`codegraph serve --mcp`) in `opencode.json`. It gives the
agent a queryable code knowledge graph (symbols + call/edge relations across 30+
languages) so it makes fewer, more accurate tool calls — `/plan`'s scan leans on it.
MIT, **100% local** (SQLite). For Claude Code, add the same MCP via your client
config.

You still need the `codegraph` binary on `PATH` (not downloaded here — network
policy):

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
# Windows: irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
codegraph init -i      # once per repo; a file-watcher then keeps the index fresh
```

## Editor LSP (for humans)

Install language servers from our internal mirror for editor intellisense:
- TypeScript: `typescript-language-server` (`npm i -g typescript-language-server typescript`)
- Java: `jdtls` (Eclipse JDT Language Server)

OpenCode uses these too (configured in `opencode.json`); Claude Code doesn't.

## The close loop (Azure DevOps)

`/goal` opens the PR; `/close` drives it to merge. Both use the **Azure DevOps
MCP**, registered **disabled** in `opencode.json` — set your org (replace
`YOUR_ADO_ORG`), add auth, and flip `"enabled": true` to use them.

`/close` runs one self-contained pass. To run it headlessly on an interval
(emulating `/loop`):

```sh
# Single pass (good for cron):
bundles/loop/scripts/close-loop.sh --once
# Loop hourly:
bundles/loop/scripts/close-loop.sh --interval 1h
```

Every commit the closer makes passes two gates: its own staged-diff self-review,
then the independent `loop-code-reviewer` subagent's verdict. CI failures are
auto-fixed within a bounded fix-cycle cap, otherwise flagged for a human.

## Out of scope here

- **Model connectivity / credentials** — handled by existing setup.
- **Package registry config** — dependencies resolve from internal Nexus/GitLab.

## Layout

```
bundles/loop/   the one bundle — source of truth
  commands/     brainstorming, plan, goal, close
  agents/       code-reviewer (commit gate), closer (PR closer)
  skills/       code-review (+ generated harness-rules-loop)
  rules/        00-global.md (global engineering rules)
  hooks/        format/lint/pretest/pre-commit (+ generated hooks.json, inject-rules.sh)
  scripts/      build-review.sh, close-loop.sh
  _parts/       review-brain parts assembled by build-review.sh
  AGENTS.md, .claude-plugin/plugin.json                  [generated]
.claude-plugin/ marketplace.json (Claude Code)           [generated]
opencode.json   OpenCode config (lsp+mcp+instructions)   [generated]
.opencode/      aggregated agents/commands/skills/plugins [generated]
AGENTS.md       assembled global rules                    [generated]
scripts/        build-plugins.py (the generator)
vendor/         vendored superpowers plugin + MANIFEST.md (provenance + license)
docs/
```

## Maintainers

**The bundle is the source of truth; everything else is generated.** Never
hand-edit a generated file (they carry a "GENERATED" marker).

- **Edit a rule:** change `bundles/loop/rules/*.md`, then run
  `python3 scripts/build-plugins.py`. It regenerates AGENTS.md, the rule skill,
  and the rules hook for both agents.
- **Edit the review brain:** change `bundles/loop/_parts/*`, run
  `bundles/loop/scripts/build-review.sh`, then `build-plugins.py`.
- **Add a command/agent/skill:** add it under `bundles/loop/`, re-run the
  generator.
- **CI gate:** `python3 scripts/build-plugins.py --check` fails if any generated
  artifact is stale — run it in CI so generated files never drift from sources.

### Vendored: superpowers

[superpowers](https://github.com/obra/superpowers) (MIT) is vendored at
`vendor/superpowers/` and is the **only** vendored dependency. The generator emits
`.opencode/plugins/superpowers.js` re-exporting the vendored OpenCode plugin, so it
auto-loads when you run OpenCode in this repo. It drives the `/brainstorming`
general path; the domain path's grill-with-docs technique is inlined directly in
the command, so no other library is vendored. See `vendor/MANIFEST.md` for
provenance + license.
