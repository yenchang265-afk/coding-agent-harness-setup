# Vendored external materials

Popular third-party Claude Code plugins/skills, re-hosted on internal GitLab and
checked in here so nothing is fetched from the public internet at install time.

**How to add one:** mirror the upstream repo into internal GitLab, drop its
content under `vendor/skills/<name>/` or `vendor/agents/`, and fill in a row
below. The bootstrap links `vendor/skills/*` and `vendor/agents/*` into Claude
Code automatically; high-value items are adapted into Codex/OpenCode prompts.

| Item | Type | Internal source (GitLab) | Upstream | Version / commit | License | Cross-agent | Status |
|------|------|--------------------------|----------|------------------|---------|-------------|--------|
| superpowers | plugin (skills) | _TODO: mirror to internal GitLab_ | github.com/obra/superpowers | v5.1.0 / f2cbfbe | MIT (Jesse Vincent) | ships native `.codex-plugin/` + `.opencode/` configs | **vendored** at `vendor/superpowers/` |
| ecc (everything-claude-code) | skills+agents (curated) | _TODO: mirror to internal GitLab_ | github.com/affaan-m/ecc | v2.0.0-rc.1 / 1e8c7e7 | MIT (Affaan Mustafa) | Claude-only (skills+subagents) | **vendored (curated subset)** at `vendor/ecc/` — see NOTICE.md |
| grill-with-doc | skill | _TODO: internal GitLab URL_ | _TODO: confirm upstream_ | _TODO_ | _TODO_ | adapt to prompt/rule | placeholder — awaiting internal URL + one-line description |

## Notes
- **superpowers** is vendored faithfully except `tests/` and `RELEASE-NOTES.md`
  (dev-only, dropped to reduce size; `LICENSE` retained). It is registered in
  `.claude-plugin/marketplace.json`; its 14 skills are also symlinked into
  Claude Code by the bootstrap copy-install. It ships its own `.codex-plugin/`
  and `.opencode/` configs, so Codex/OpenCode users can enable it natively from
  `vendor/superpowers/` (see docs/new-hire-guide.md) rather than re-adapting.
- The remaining rows are placeholders only; no content is vendored for them yet,
  so the bootstrap simply finds nothing to link.
- Record the **license** for every item — vendoring third-party code without a
  recorded license is not allowed.
- "Cross-agent" notes how the item is handled for Codex/OpenCode, which have no
  skill/plugin concept (see docs/new-hire-guide.md).
