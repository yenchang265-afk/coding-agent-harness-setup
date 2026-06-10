#!/usr/bin/env bash
# build-review.sh — assemble the two self-contained artifacts from _parts.
#   skill  = skill.header + core + local + azure + tools   (interactive, both modes)
#   agent  = agent.header + core + azure + tools           (scheduler, azure only)
# Run after editing any _parts file.
set -euo pipefail
B="$(cd "$(dirname "$0")/.." && pwd)"      # bundle root
P="$B/_parts"
sep() { printf '\n\n---\n\n'; }

mkdir -p "$B/skills/code-review" "$B/agents"

{ cat "$P/skill.header.md"; sep; cat "$P/review-core.md"; sep; \
  cat "$P/modes/local.md"; sep; cat "$P/modes/azure.md"; sep; cat "$P/tools-ado.md"; } \
  > "$B/skills/code-review/SKILL.md"

{ cat "$P/agent.header.md"; sep; cat "$P/review-core.md"; sep; \
  cat "$P/modes/azure.md"; sep; cat "$P/tools-ado.md"; } \
  > "$B/agents/pr-reviewer.md"

echo "build-review: skill $(wc -l < "$B/skills/code-review/SKILL.md")L, agent $(wc -l < "$B/agents/pr-reviewer.md")L"
