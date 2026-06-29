#!/usr/bin/env bash
# build-explore.sh — assemble the explore skill from _parts.
#
#   skill = header + mode:ado + mode:local + mode:manual + core + tools-ado-wit
#
# The ado and local mode sections are always included so the skill is
# self-contained; Step 0 in the header directs the agent to run only the
# selected mode at runtime.
#
# Run after editing any _parts/explore file, before scripts/build-plugins.py.
set -euo pipefail
B="$(cd "$(dirname "$0")/.." && pwd)"      # bundle root
P="$B/_parts/explore"
sep() { printf '\n\n---\n\n'; }

mkdir -p "$B/skills/explore"

{
  cat "$P/skill.header.md"
  sep
  cat "$P/modes/ado.md"
  sep
  cat "$P/modes/local.md"
  sep
  cat "$P/modes/manual.md"
  sep
  cat "$P/core.md"
  sep
  cat "$P/tools-ado-wit.md"
} > "$B/skills/explore/SKILL.md"

echo "build-explore: skill $(wc -l < "$B/skills/explore/SKILL.md")L"
