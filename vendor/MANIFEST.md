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

## Notes
- **superpowers** is vendored faithfully except `tests/` and `RELEASE-NOTES.md`
  (dev-only, dropped to reduce size; `LICENSE` retained). The generator
  (`scripts/build-plugins.py`) emits `.opencode/plugins/superpowers.js`
  re-exporting `vendor/superpowers/.opencode/plugins/superpowers.js`, so the
  plugin self-registers its skills when OpenCode runs in this repo
  (see docs/new-hire-guide.md).
- **superpowers is the only vendored dependency.** The loop bundle was stripped to
  loop-engineering only; the previously-vendored reference libraries (`ecc`,
  `mattpocock-skills`, `caveman`, `agent-skills`) were removed. The
  **grill-with-docs** technique that drove the `/brainstorming` domain path is now
  **inlined** directly in `bundles/loop/commands/brainstorming.md`, so no vendored
  copy is needed.
- Each vendored source keeps its own `vendor/<source>/PROVENANCE.md` recording
  version, commit, license, and the date it was cloned/vendored. This table is
  the index; `PROVENANCE.md` is the per-source record of truth.
- Record the **license** for every item — vendoring third-party code without a
  recorded license is not allowed.
