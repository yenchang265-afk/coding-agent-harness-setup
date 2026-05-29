# ecc (everything-claude-code) — vendored subset

This is a **curated subset** of [everything-claude-code](https://github.com/affaan-m/ecc),
not the full repository.

- **Upstream:** github.com/affaan-m/ecc
- **Version:** 2.0.0-rc.1 (commit 1e8c7e7)
- **License:** MIT — Copyright (c) 2026 Affaan Mustafa (see `LICENSE`)

## What was kept
Skills and agents relevant to our stack (Next.js, Spring Boot, Java, MariaDB,
ClickHouse) plus cross-cutting engineering workflows (TDD, code review,
debugging, planning, security, git/GitHub). The upstream repo ships ~232 skills
and ~60 agents covering many unrelated domains; those were intentionally
excluded to keep the harness focused.

## What was dropped
Everything else: `assets/`, `docs/`, `tests/`, `src/`, dashboards, ecc-specific
commands/hooks/machinery, and the ~200 off-stack skills.

## Caveats
- A few vendored skills may reference sibling ecc skills that were not included;
  those cross-references will simply not resolve. Report any that matter and we
  can vendor the dependency.
- Consumed by Claude Code only (skills + subagents) via the bootstrap. To add
  more, copy the dirs from upstream into `skills/` or `agents/` here.
