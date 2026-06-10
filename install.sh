#!/usr/bin/env bash
# Bootstrap the centralized coding-agent configuration onto this machine.
#
#   ./install.sh                 configure OpenCode, all bundles
#   ./install.sh --profile=frontend   FE side: core + frontend-nextjs
#   ./install.sh --profile=backend    BE side: core + backend-spring + data-platform
#   ./install.sh --bundles=core,backend-spring   explicit bundle list
#   ./install.sh --skills=tdd,grill-with-docs   only these skills (globs ok)
#   ./install.sh --subagents='*-reviewer' --commands=review-pr
#   ./install.sh --no-codegraph  skip wiring the codegraph code-index MCP server
#   ./install.sh --git-hooks     also enable the deterministic git pre-commit gate (global, opt-in)
#   ./install.sh --dry-run       show what would happen, change nothing
#
# Profiles (see profiles.conf) pick a bundle set for your side of the stack:
# frontend | backend | fullstack. --bundles overrides --profile. The selection
# (profile + skills/subagents/commands) can also live in a persistent manifest
# file (default: ./harness.selection, or set HARNESS_SELECTION); flags override
# the manifest. An unset skills/subagents/commands category installs everything.
# Rules are always installed in full.
#
# Idempotent: safe to re-run after a `git pull` to pick up updates.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

DRY_RUN=0
AGENTS_ARG=""
BUNDLES_ARG=""
PROFILE_ARG="__UNSET__"
SKILLS_ARG="__UNSET__"
SUBAGENTS_ARG="__UNSET__"
COMMANDS_ARG="__UNSET__"
CODEGRAPH=1
GIT_HOOKS=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=1 ;;
    --agent=*)        AGENTS_ARG="${arg#*=}" ;;
    --agents=*)       AGENTS_ARG="${arg#*=}" ;;
    --profile=*)      PROFILE_ARG="${arg#*=}" ;;
    --bundles=*)      BUNDLES_ARG="${arg#*=}" ;;
    --skills=*)       SKILLS_ARG="${arg#*=}" ;;
    --subagents=*)    SUBAGENTS_ARG="${arg#*=}" ;;
    --commands=*)     COMMANDS_ARG="${arg#*=}" ;;
    --no-codegraph)   CODEGRAPH=0 ;;
    --git-hooks)      GIT_HOOKS=1 ;;
    -h|--help)
      sed -n '2,23p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
export DRY_RUN CODEGRAPH

# shellcheck source=bootstrap/common.sh
source "$REPO_ROOT/bootstrap/common.sh"

# --- parse selection manifest (profile + skills/subagents/commands) ----------
# Lines: "<category> <name-or-glob> [more ...]"; '#' starts a comment. Categories:
# profile | skills | subagents | commands. Globbing is disabled while reading so
# patterns like '*-reviewer' are stored literally, not expanded against cwd.
MANIFEST_PROFILE=""
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
        profile)   MANIFEST_PROFILE="$v" ;;
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

# --- resolve bundles (explicit --bundles > profile > all) --------------------
all_bundles() {
  local d
  for d in "$REPO_ROOT"/bundles/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
}

# Look up a profile name in profiles.conf -> SELECTED_BUNDLES.
resolve_profile() {
  local want="$1" pf="$REPO_ROOT/profiles.conf" found=0 name
  [ -f "$pf" ] || { err "profiles.conf not found; cannot resolve --profile=$want"; exit 2; }
  SELECTED_BUNDLES=()
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    set -f; set -- $line; set +f
    [ "$#" -eq 0 ] && continue
    name="$1"; shift
    if [ "$name" = "$want" ]; then SELECTED_BUNDLES=("$@"); found=1; break; fi
  done < "$pf"
  if [ "$found" -ne 1 ]; then
    err "unknown profile '$want'. Available: $(awk '!/^[[:space:]]*#/ && NF {print $1}' "$pf" | tr '\n' ' ')"
    exit 2
  fi
}

# Profile from flag (wins) or manifest.
PROFILE=""
[ "$PROFILE_ARG" != "__UNSET__" ] && PROFILE="$PROFILE_ARG"
[ -z "$PROFILE" ] && PROFILE="$MANIFEST_PROFILE"

if [ -n "$BUNDLES_ARG" ]; then
  IFS=',' read -r -a SELECTED_BUNDLES <<< "$BUNDLES_ARG"
  [ -n "$PROFILE" ] && warn "--bundles given; ignoring profile '$PROFILE'"
elif [ -n "$PROFILE" ]; then
  resolve_profile "$PROFILE"
  log "profile: $PROFILE"
else
  mapfile -t SELECTED_BUNDLES < <(all_bundles)
fi
export SELECTED_BUNDLES
log "bundles: ${SELECTED_BUNDLES[*]}"
[ "${#SEL_SKILLS[@]}"    -gt 0 ] && log "skills filter: ${SEL_SKILLS[*]}"
[ "${#SEL_SUBAGENTS[@]}" -gt 0 ] && log "subagents filter: ${SEL_SUBAGENTS[*]}"
[ "${#SEL_COMMANDS[@]}"  -gt 0 ] && log "commands filter: ${SEL_COMMANDS[*]}"

# --- resolve agent (OpenCode only) -------------------------------------------
# This harness targets OpenCode exclusively. --agent is accepted for back-compat
# but only 'opencode' is valid.
if [ -n "$AGENTS_ARG" ] && [ "$AGENTS_ARG" != "opencode" ]; then
  err "this harness is OpenCode-only; --agent='$AGENTS_ARG' is not supported (use --agent=opencode or omit)"
  exit 2
fi
AGENTS=(opencode)
log "agents: ${AGENTS[*]}"
[ "$DRY_RUN" = "1" ] && warn "dry-run: no files will be changed"

# codegraph code-index MCP server is wired into every agent below (unless
# --no-codegraph); warn once if the binary isn't installed yet.
[ "$CODEGRAPH" = "1" ] && codegraph_check

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

# Opt-in deterministic git pre-commit gate (adapter-independent, so it runs once
# here rather than in a per-agent module).
[ "$GIT_HOOKS" = "1" ] && install_git_hooks

ok "done. Re-run after 'git pull' to update."
