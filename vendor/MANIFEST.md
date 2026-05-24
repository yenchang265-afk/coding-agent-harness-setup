# Vendored external materials

Popular third-party Claude Code plugins/skills, re-hosted on internal GitLab and
checked in here so nothing is fetched from the public internet at install time.

**How to add one:** mirror the upstream repo into internal GitLab, drop its
content under `vendor/skills/<name>/` or `vendor/agents/`, and fill in a row
below. The bootstrap links `vendor/skills/*` and `vendor/agents/*` into Claude
Code automatically; high-value items are adapted into Codex/OpenCode prompts.

| Item | Type | Internal source (GitLab) | Upstream | Version / commit | License | Cross-agent | Status |
|------|------|--------------------------|----------|------------------|---------|-------------|--------|
| superpowers | plugin (skills) | _TODO: internal GitLab URL_ | _TODO: confirm upstream_ | _TODO_ | _TODO_ | adapt key skills | placeholder — awaiting internal URL |
| everything-my-claude | plugin | _TODO: internal GitLab URL_ | _TODO: confirm this is the "everything" plugin vs. an internal collection_ | _TODO_ | _TODO_ | adapt key skills | placeholder — awaiting internal URL |
| grill-with-doc | skill | _TODO: internal GitLab URL_ | _TODO: confirm upstream_ | _TODO_ | _TODO_ | adapt to prompt/rule | placeholder — awaiting internal URL + one-line description |

## Notes
- Until the internal URLs are supplied, these rows are placeholders only; no
  content is vendored yet, so the bootstrap simply finds nothing to link.
- Record the **license** for every item — vendoring third-party code without a
  recorded license is not allowed.
- "Cross-agent" notes how the item is handled for Codex/OpenCode, which have no
  skill/plugin concept (see docs/new-hire-guide.md).
