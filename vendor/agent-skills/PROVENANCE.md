# Provenance — agent-skills

- **Upstream:** https://github.com/addyosmani/agent-skills
- **Version:** 0.6.2
- **Commit:** d187883
- **License:** MIT — Addy Osmani (see `LICENSE`)
- **Vendored on:** 2026-06-14
- **Internal mirror:** _TODO: GitLab URL_
- **Scope:** faithful copy (24 skills + 4 agents + commands), excluding `.git/`,
  `.github/` (CI), `.gitignore`, `CONTRIBUTING.md`, the empty `.opencode/`, and
  the non-target-agent `.gemini/` config (this harness targets Claude/Codex/
  OpenCode only). Kept: `skills/`, `agents/`, `commands/` (`.toml` Codex/Gemini
  stubs), `.claude/commands/` (Claude slash commands), `.claude-plugin/`,
  `hooks/`, `references/`, `docs/`, `scripts/`, `AGENTS.md`, `CLAUDE.md`,
  `README.md`, `LICENSE`, `plugin.json`.

To refresh: re-clone upstream at the desired tag, re-copy the kept set, re-apply
the exclusions above, and update the version/commit/date.
