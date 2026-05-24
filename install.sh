#!/usr/bin/env bash
# Bootstrap the centralized coding-agent configuration onto this machine.
#
#   ./install.sh                 configure every detected agent, all bundles
#   ./install.sh --agent=claude  only Claude Code
#   ./install.sh --bundles=core,backend-spring
#   ./install.sh --dry-run       show what would happen, change nothing
#
# Idempotent: safe to re-run after a `git pull` to pick up updates.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

DRY_RUN=0
AGENTS_ARG=""
BUNDLES_ARG=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=1 ;;
    --agent=*)        AGENTS_ARG="${arg#*=}" ;;
    --agents=*)       AGENTS_ARG="${arg#*=}" ;;
    --bundles=*)      BUNDLES_ARG="${arg#*=}" ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
export DRY_RUN

# shellcheck source=bootstrap/common.sh
source "$REPO_ROOT/bootstrap/common.sh"

# --- resolve bundles ---------------------------------------------------------
all_bundles() {
  local d
  for d in "$REPO_ROOT"/bundles/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
}

if [ -n "$BUNDLES_ARG" ]; then
  IFS=',' read -r -a SELECTED_BUNDLES <<< "$BUNDLES_ARG"
else
  mapfile -t SELECTED_BUNDLES < <(all_bundles)
fi
export SELECTED_BUNDLES
log "bundles: ${SELECTED_BUNDLES[*]}"

# --- resolve agents ----------------------------------------------------------
detect_agents() {
  command -v claude   >/dev/null 2>&1 && echo claude
  command -v codex    >/dev/null 2>&1 && echo codex
  command -v opencode >/dev/null 2>&1 && echo opencode
}

if [ -n "$AGENTS_ARG" ]; then
  IFS=',' read -r -a AGENTS <<< "$AGENTS_ARG"
else
  mapfile -t AGENTS < <(detect_agents)
  if [ "${#AGENTS[@]}" -eq 0 ]; then
    warn "no agent binaries detected on PATH; defaulting to all three. Use --agent= to narrow."
    AGENTS=(claude codex opencode)
  fi
fi
log "agents: ${AGENTS[*]}"
[ "$DRY_RUN" = "1" ] && warn "dry-run: no files will be changed"

# --- run per-agent modules ---------------------------------------------------
for a in "${AGENTS[@]}"; do
  mod="$REPO_ROOT/bootstrap/$a.sh"
  if [ ! -f "$mod" ]; then
    err "no bootstrap module for agent '$a' ($mod); skipping"
    continue
  fi
  log "configuring $a ..."
  # shellcheck disable=SC1090
  source "$mod"
  "install_$a"
done

ok "done. Re-run after 'git pull' to update."
