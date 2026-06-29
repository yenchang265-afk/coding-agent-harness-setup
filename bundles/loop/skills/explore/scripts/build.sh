#!/usr/bin/env bash
# build.sh — assemble skills/explore/SKILL.md from its source parts.
#
# Source parts:
#   header.md, modes/ado.md, modes/manual.md, core.md,
#   references/tools-ado-wit.md
#
# modes/local.md is retained as a dormant extension but not assembled.
# Run after editing any source part, before scripts/build-plugins.py.
set -euo pipefail
S="$(cd "$(dirname "$0")/.." && pwd)"   # skill root
sep() { printf '\n\n---\n\n'; }

{
  cat "$S/header.md"
  sep
  cat "$S/modes/ado.md"
  sep
  cat "$S/modes/manual.md"
  sep
  cat "$S/core.md"
  sep
  cat "$S/references/tools-ado-wit.md"
} > "$S/SKILL.md"

echo "build: skill $(wc -l < "$S/SKILL.md")L"
