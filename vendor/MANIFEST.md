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

## Notes
- **superpowers** is vendored faithfully except `tests/` and `RELEASE-NOTES.md`
  (dev-only, dropped to reduce size; `LICENSE` retained). The bootstrap
  symlinks `vendor/superpowers/.opencode/plugins/superpowers.js` into
  `~/.config/opencode/plugin/` so the plugin self-registers its skills
  (see docs/new-hire-guide.md).
- **mattpocock-skills** is the repo that **grill-with-docs** lives in; the whole
  repo is vendored faithfully (only `.git/` dropped). Its skills are nested by
  category (`skills/<category>/<skill>/`) and the in-scope set is declared in its
  `plugin.json`. The bootstrap honors that explicit list (so only the 14 in-scope
  skills are linked, not the deprecated/personal ones); for sources without such a
  list it auto-discovers every dir containing a `SKILL.md`.
- Each vendored source keeps its own `vendor/<source>/PROVENANCE.md` recording
  version, commit, license, and the date it was cloned/vendored. This table is
  the index; `PROVENANCE.md` is the per-source record of truth.
- Record the **license** for every item — vendoring third-party code without a
  recorded license is not allowed.
