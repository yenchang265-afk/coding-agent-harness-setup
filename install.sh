#!/usr/bin/env bash
# Bootstrap the centralized coding-agent configuration onto this machine.
#
#   ./install.sh                 configure every detected agent, all bundles
#   ./install.sh --agent=claude  only Claude Code
#   ./install.sh --bundles=core,backend-spring
#   ./install.sh --skills=tdd,grill-with-docs   only these skills (globs ok)
#   ./install.sh --subagents='*-reviewer' --commands=review-pr
#   ./install.sh --dry-run       show what would happen, change nothing
#
# Fine-grained selection: skills/subagents/commands can be narrowed via the
# flags above or a persistent manifest file (default: ./harness.selection, or
# set HARNESS_SELECTION). Flags override the manifest for that category. An
# unset category installs everything. Rules are always installed in full.
#
# Idempotent: safe to re-run after a `git pull` to pick up updates.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

DRY_RUN=0
AGENTS_ARG=""
BUNDLES_ARG=""
SKILLS_ARG="__UNSET__"
SUBAGENTS_ARG="__UNSET__"
COMMANDS_ARG="__UNSET__"

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=1 ;;
    --agent=*)        AGENTS_ARG="${arg#*=}" ;;
    --agents=*)       AGENTS_ARG="${arg#*=}" ;;
    --bundles=*)      BUNDLES_ARG="${arg#*=}" ;;
    --skills=*)       SKILLS_ARG="${arg#*=}" ;;
    --subagents=*)    SUBAGENTS_ARG="${arg#*=}" ;;
    --commands=*)     COMMANDS_ARG="${arg#*=}" ;;
    -h|--help)
      sed -n '2,17p' "$0"; exit 0 ;;
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

# --- resolve fine-grained selection (manifest, then flag overrides) ----------
# Manifest lines: "<category> <name-or-glob> [more ...]"; '#' starts a comment.
# Categories: skills | subagents | commands. Globbing is disabled while reading
# so patterns like '*-reviewer' are stored literally, not expanded against cwd.
SELECTION_FILE="${HARNESS_SELECTION:-$REPO_ROOT/harness.selection}"
if [ -f "$SELECTION_FILE" ]; then
  log "selection: $SELECTION_FILE"
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    set -f; set -- $line; set +f
    [ "$#" -eq 0 ] && continue
    cat="$1"; shift
    for v in "$@"; do
      case "$cat" in
        skills)    SEL_SKILLS+=("$v") ;;
        subagents) SEL_SUBAGENTS+=("$v") ;;
        commands)  SEL_COMMANDS+=("$v") ;;
        *) warn "selection: unknown category '$cat' (ignored)" ;;
      esac
    done
  done < "$SELECTION_FILE"
fi
# Flags override the manifest for whichever categories are given.
[ "$SKILLS_ARG"    != "__UNSET__" ] && IFS=',' read -r -a SEL_SKILLS    <<< "$SKILLS_ARG"
[ "$SUBAGENTS_ARG" != "__UNSET__" ] && IFS=',' read -r -a SEL_SUBAGENTS <<< "$SUBAGENTS_ARG"
[ "$COMMANDS_ARG"  != "__UNSET__" ] && IFS=',' read -r -a SEL_COMMANDS  <<< "$COMMANDS_ARG"
[ "${#SEL_SKILLS[@]}"    -gt 0 ] && log "skills filter: ${SEL_SKILLS[*]}"
[ "${#SEL_SUBAGENTS[@]}" -gt 0 ] && log "subagents filter: ${SEL_SUBAGENTS[*]}"
[ "${#SEL_COMMANDS[@]}"  -gt 0 ] && log "commands filter: ${SEL_COMMANDS[*]}"

# --- resolve agents ----------------------------------------------------------
detect_agents() {
  command -v claude      >/dev/null 2>&1 && echo claude
  command -v codex       >/dev/null 2>&1 && echo codex
  command -v opencode    >/dev/null 2>&1 && echo opencode
  command -v antigravity >/dev/null 2>&1 && echo antigravity
}

if [ -n "$AGENTS_ARG" ]; then
  IFS=',' read -r -a AGENTS <<< "$AGENTS_ARG"
else
  mapfile -t AGENTS < <(detect_agents)
  if [ "${#AGENTS[@]}" -eq 0 ]; then
    warn "no agent binaries detected on PATH; defaulting to all four. Use --agent= to narrow."
    AGENTS=(claude codex opencode antigravity)
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
