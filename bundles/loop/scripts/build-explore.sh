#!/usr/bin/env bash
# build-explore.sh — assemble skills/explore/SKILL.md from its source parts.
#
#   SKILL.md = header + mode:ado + mode:local + mode:manual + core + tools-ado-wit
#
# All source parts live alongside SKILL.md inside skills/explore/:
#   header.md, modes/ado.md, modes/manual.md, core.md, tools-ado-wit.md
#
# modes/local.md is retained as a dormant extension but not assembled —
# local doc reading is not exposed in Step 0.
#
# Step 0 in header.md directs the agent to run only the chosen mode at runtime.
# Run after editing any source part, before scripts/build-plugins.py.
set -euo pipefail
B="$(cd "$(dirname "$0")/.." && pwd)"      # bundle root
S="$B/skills/explore"                      # skill source dir
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
  cat "$S/tools-ado-wit.md"
} > "$S/SKILL.md"

echo "build-explore: skill $(wc -l < "$B/skills/explore/SKILL.md")L"
