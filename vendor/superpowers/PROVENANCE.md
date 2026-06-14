# Provenance — superpowers

- **Upstream:** https://github.com/obra/superpowers
- **Version:** 5.1.0
- **Commit:** f2cbfbe
- **License:** MIT — Jesse Vincent (see `LICENSE`)
- **Vendored on:** 2026-05-25
- **Internal mirror:** _TODO: GitLab URL_
- **Scope:** faithful copy, excluding `tests/` and `RELEASE-NOTES.md`.
- **Trimmed 2026-06-14** for the plugin-native harness (targets Claude/Codex/
  OpenCode only): also dropped non-target-agent configs (`.cursor-plugin/`,
  `gemini-extension.json`, `GEMINI.md`), CI (`.github/`), and dev/vcs metadata
  (`CODE_OF_CONDUCT.md`, `.version-bump.json`, `.gitignore`, `.gitattributes`).
  The consumed `.opencode/` plugin, the `.codex-plugin/`, and `skills/`, `hooks/`,
  `docs/`, `assets/` are retained.

To refresh: re-clone upstream at the desired tag, copy in, and update the
version/commit/date above.
