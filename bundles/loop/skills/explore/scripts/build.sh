#!/usr/bin/env bash
# build.sh — assemble skills/explore/SKILL.md from its source parts.
#
# SKILL.md contains only the shared core; mode files are loaded conditionally
# at runtime by the agent from references/:
#   references/mode-ado.md      — loaded when source == "ado"
#   references/mode-manual.md   — loaded when source == "manual"
#   references/tools-ado-wit.md — loaded by ado mode before its steps
#
# Assembly order:
#   header.md (Step 0 + routing)
#   core/dod-template.md
#   core/decompose.md
#   core/graph.md
#   core/record.md
#
# Run after editing any source part, before scripts/build-plugins.py.
set -euo pipefail
S="$(cd "$(dirname "$0")/.." && pwd)"   # skill root
sep() { printf '\n\n---\n\n'; }

{
  cat "$S/header.md"
  sep
  cat "$S/core/dod-template.md"
  sep
  cat "$S/core/decompose.md"
  sep
  cat "$S/core/graph.md"
  sep
  cat "$S/core/record.md"
} > "$S/SKILL.md"

echo "build: skill $(wc -l < "$S/SKILL.md")L"
