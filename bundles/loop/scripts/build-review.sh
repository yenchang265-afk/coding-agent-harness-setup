#!/usr/bin/env bash
# build-review.sh — assemble the code-review skill from _parts.
#   skill = skill.header + core + local + azure + tools   (both modes)
# The loop's `/goal` finalize uses the LOCAL mode of this skill; the AZURE mode
# is available when reviewing an Azure DevOps PR by project + repo.
# Run after editing any _parts file, before scripts/build-plugins.py.
set -euo pipefail
B="$(cd "$(dirname "$0")/.." && pwd)"      # bundle root
P="$B/_parts"
sep() { printf '\n\n---\n\n'; }

mkdir -p "$B/skills/code-review"

{ cat "$P/skill.header.md"; sep; cat "$P/review-core.md"; sep; \
  cat "$P/modes/local.md"; sep; cat "$P/modes/azure.md"; sep; cat "$P/tools-ado.md"; } \
  > "$B/skills/code-review/SKILL.md"

echo "build-review: skill $(wc -l < "$B/skills/code-review/SKILL.md")L"
