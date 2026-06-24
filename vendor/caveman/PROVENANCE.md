# Provenance — caveman

- **Upstream:** https://github.com/JuliusBrussee/caveman
- **Version:** untagged
- **Commit:** 655b7d9
- **License:** MIT — Julius Brussee (see `LICENSE`)
- **Vendored on:** 2026-06-07
- **Internal mirror:** _TODO: GitLab URL_
- **Scope:** faithful copy, excluding `.git/`, `.github/`, `tests/`,
  `benchmarks/`, `evals/`, and `dist/` (dev-only, dropped to reduce size;
  `LICENSE` retained).
- **Trimmed 2026-06-14** for the plugin-native harness (targets Claude/Codex/
  OpenCode only): also dropped non-target-agent configs (`.junie/`, `.kiro/`,
  `.roo/`, the stale `.agents/` mirror, `gemini-extension.json`, `GEMINI.md`),
  the upstream installers (`install.sh`, `install.ps1`), and dev/vcs metadata
  (`CONTRIBUTING.md`, `skills-lock.json`, `.gitignore`, `.gitattributes`). The
  Claude (`.claude-plugin/`), Codex (`.codex/`), and OpenCode configs plus the
  functional `src/`, `bin/`, `skills/`, `agents/`, `commands/` are retained.

To refresh: re-clone upstream at the desired commit, copy in, and update the
version/commit/date above.
