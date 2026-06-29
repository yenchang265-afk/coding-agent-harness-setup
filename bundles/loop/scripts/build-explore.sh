#!/usr/bin/env bash
# build-explore.sh — thin wrapper; delegates to the skill's own build script.
set -euo pipefail
exec "$(dirname "$0")/../skills/explore/scripts/build.sh" "$@"
