# NOTICE — wshobson/agents curated subset

Upstream `wshobson/agents` ships **192 agents** across ~70 single-purpose
plugins (many agents are duplicated across plugins). This harness targets a
specific stack — **Next.js 16 · Spring Boot 3.5 · Oracle/MariaDB · ClickHouse ·
MinIO** — driven by a degraded model whose value comes mostly from review,
testing, debugging, and architecture guardrails. Vendoring all 192 agents
(13 MB, mostly off-stack) would add noise, so this is a **curated subset**.

Like the rest of `vendor/`, this is checked in for **reference**; the bootstrap
does **not** auto-link these agents. To use one, copy its `*.md` into
`~/.config/opencode/agent/` (OpenCode) or `~/.claude/agents/` (Claude Code).

## Kept (24 agents)

Deduplicated to one copy per agent (upstream repeats the same agent across
plugins). Selected by relevance to the stack and the harness's review/quality
theme.

**Review / quality / security (core harness theme)**
- `code-reviewer` · `architect-review` · `security-auditor`
- `backend-security-coder` · `frontend-security-coder`

**Test / debug**
- `debugger` · `error-detective` · `test-automator` · `tdd-orchestrator`

**Performance / observability / ops**
- `performance-engineer` · `observability-engineer` · `deployment-engineer`

**Stack languages**
- `typescript-pro` · `javascript-pro` (Next.js front end)
- `java-pro` (Spring Boot) · `sql-pro` (Oracle/MariaDB/ClickHouse)

**Architecture / data / docs**
- `backend-architect` · `frontend-developer` · `legacy-modernizer`
- `database-architect` · `database-optimizer` · `database-admin`
- `api-documenter` · `docs-architect`

## Dropped (the rest)

Off-stack or out-of-scope domains: blockchain/web3, quantitative trading,
SEO, ARM/microcontrollers, game development, ML/MLOps/AI-image, reverse
engineering, marketing/sales/HR/legal, and language-pro agents for languages
not in this stack (Python, Go, Rust, C/C++, C#, Scala, Elixir, Haskell, Julia,
PHP, Ruby, .NET, Flutter/iOS/mobile). Also dropped: upstream packaging
(`plugins/`, `.claude-plugin/`, `tools/`, `Makefile`, multi-agent CLI configs).

## Normalization applied

Upstream's build emits the same agent under each plugin with a
plugin-prefixed `name:` (e.g. `comprehensive-review-security-auditor`). Because
this subset keeps one copy per agent, each file's `name:` frontmatter was
normalized to its filename (e.g. `security-auditor`) so agent ids are clean and
consistent. No other content was changed. Re-apply this when refreshing.
