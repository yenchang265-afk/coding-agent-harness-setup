# Vendored external materials

Third-party plugins and skills, re-hosted on internal GitLab and checked in here
so nothing is fetched from the public internet at install time.

**How to add one:** mirror the upstream repo into internal GitLab, then give it
its **own self-documenting folder** `vendor/<source>/` containing a
`PROVENANCE.md` (upstream, version, commit, license, **clone/vendor date**) and
the `skills/` and/or `agents/` it exposes. Fill in a row below. Do not dump
loose files into a shared `vendor/skills` or `vendor/agents` bucket — that
loses provenance.

| Item | Type | Internal source (GitLab) | Upstream | Version / commit | License | Vendored on | Cross-agent | Status |
|------|------|--------------------------|----------|------------------|---------|-------------|-------------|--------|
| superpowers | plugin (skills) | _TODO: mirror to internal GitLab_ | github.com/obra/superpowers | v5.1.0 / f2cbfbe | MIT (Jesse Vincent) | 2026-05-25 | ships native `.opencode/` config | **vendored** at `vendor/superpowers/` |
| ecc (everything-claude-code) | skills+agents (curated) | _TODO: mirror to internal GitLab_ | github.com/affaan-m/ecc | v2.0.0-rc.1 / 1e8c7e7 | MIT (Affaan Mustafa) | 2026-05-25 | agents/skills adapted for OpenCode | **vendored (curated subset)** at `vendor/ecc/` — see NOTICE.md |
| mattpocock-skills (incl. grill-with-docs) | plugin (skills) | _TODO: mirror to internal GitLab_ | github.com/mattpocock/skills | untagged / b8be62f | MIT (Matt Pocock) | 2026-05-25 | skills adapted as OpenCode commands | **vendored (full repo)** at `vendor/mattpocock-skills/` |
| caveman | plugin (skills+agents) | _TODO: mirror to internal GitLab_ | github.com/JuliusBrussee/caveman | untagged / 655b7d9 | MIT (Julius Brussee) | 2026-06-07 | ships `AGENTS.md` + Claude/Codex/OpenCode configs; token-compression mode | **vendored** at `vendor/caveman/` |
| wshobson/agents | agents (curated) | _TODO: mirror to internal GitLab_ | github.com/wshobson/agents | untagged / cc37bfd | MIT (Will Hobson) | 2026-06-14 | plain agent `*.md` (OpenCode/Claude compatible) | **vendored (curated subset)** at `vendor/wshobson-agents/` — see NOTICE.md |

## Notes
- **superpowers** is vendored faithfully except `tests/` and `RELEASE-NOTES.md`
  (dev-only, dropped to reduce size; `LICENSE` retained). The generator
  (`scripts/build-plugins.py`) emits `.opencode/plugins/superpowers.js`
  re-exporting `vendor/superpowers/.opencode/plugins/superpowers.js`, so the
  plugin self-registers its skills when OpenCode runs in this repo
  (see docs/new-hire-guide.md).
- **mattpocock-skills** is the repo that **grill-with-docs** lives in; the whole
  repo is vendored faithfully (only `.git/` and `.out-of-scope/` dropped). Its skills are nested by
  category (`skills/<category>/<skill>/`). It is vendored for reference and
  **not auto-wired** by the generator (only `superpowers` is). To use these
  skills, copy the wanted `SKILL.md` dirs under your agent's skills dir (e.g.
  `~/.config/opencode/skills/` or a bundle's `skills/`).
- **caveman** is vendored faithfully except `.git/`, `.github/`, `tests/`,
  `benchmarks/`, `evals/`, and `dist/` (dev-only). It is a token-compression
  communication mode plus a `cavecrew` subagent set; ships native multi-agent
  configs (`AGENTS.md`, `.codex`, `.junie`, etc.). Vendored for reference and
  **not auto-wired** by the generator — to use it, follow its `INSTALL.md` or
  copy the wanted `skills/`/`agents/` dirs into your agent's config.
- **wshobson-agents** is a **curated subset** (24 of 192 agents) of
  `wshobson/agents`, deduplicated and selected for this stack — see
  `vendor/wshobson-agents/NOTICE.md` for kept/dropped and the one `name:`
  normalization applied. Plain agent `*.md` files (OpenCode/Claude compatible);
  vendored for reference and **not auto-wired** — copy a wanted `*.md` into your
  agent's agents dir (e.g. `~/.config/opencode/agents/` or a bundle's `agents/`).
- Each vendored source keeps its own `vendor/<source>/PROVENANCE.md` recording
  version, commit, license, and the date it was cloned/vendored. This table is
  the index; `PROVENANCE.md` is the per-source record of truth.
- Record the **license** for every item — vendoring third-party code without a
  recorded license is not allowed.
