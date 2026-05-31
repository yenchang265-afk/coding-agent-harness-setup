#!/usr/bin/env bash
# Shared helpers for the harness bootstrap. Sourced by install.sh and the
# per-agent modules. POSIX-bash; targets Linux and macOS (and WSL).

set -euo pipefail

# --- globals (populated by install.sh) ---------------------------------------
: "${REPO_ROOT:?REPO_ROOT must be set before sourcing common.sh}"
: "${DRY_RUN:=0}"
: "${TARGET_HOME:=$HOME}"
SELECTED_BUNDLES=()   # filled by install.sh
# Optional fine-grained selection (filled by install.sh from harness.selection +
# flags). An EMPTY set for a category means "install all of that category", so
# the default (no manifest, no flags) installs everything as before. Rules are
# never selectable — they are centralized and always installed in full.
SEL_SKILLS=()
SEL_SUBAGENTS=()
SEL_COMMANDS=()
TS="$(date +%Y%m%d-%H%M%S)"

# --- logging -----------------------------------------------------------------
_c_reset='\033[0m'; _c_blue='\033[34m'; _c_yellow='\033[33m'; _c_red='\033[31m'; _c_green='\033[32m'
log()  { printf "${_c_blue}[harness]${_c_reset} %s\n" "$*"; }
ok()   { printf "${_c_green}[harness]${_c_reset} %s\n" "$*"; }
warn() { printf "${_c_yellow}[harness] warning:${_c_reset} %s\n" "$*" >&2; }
err()  { printf "${_c_red}[harness] error:${_c_reset} %s\n" "$*" >&2; }

# run CMD, or just print it under --dry-run.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf "  would run: %s\n" "$*"
  else
    "$@"
  fi
}

# mkdir -p that respects dry-run.
ensure_dir() {
  [ -d "$1" ] && return 0
  run mkdir -p "$1"
}

# Back up an existing path before we overwrite it, unless it already points
# into this repo (i.e. a previous run of ours). Never deletes user data.
backup_path() {
  local p="$1"
  [ -e "$p" ] || [ -L "$p" ] || return 0
  if [ -L "$p" ]; then
    local tgt; tgt="$(readlink "$p" || true)"
    case "$tgt" in
      "$REPO_ROOT"/*) return 0 ;;  # our own symlink, leave it
    esac
  fi
  warn "backing up existing $p -> $p.bak.$TS"
  run mv "$p" "$p.bak.$TS"
}

# Symlink src->dst on POSIX; backs up any foreign file first, then force-creates
# (ln -sfn) so re-running over our own symlink is a clean no-op-ish replace.
link() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  backup_path "$dst"
  run ln -sfn "$src" "$dst"
}

# Overwrite-copy into a directory we fully own (hook scripts, generated prompts).
# No backup: re-running just refreshes our own files, so .bak churn is avoided.
copy() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  run cp -Rf "$src" "$dst"
}

# Match NAME against a list of glob patterns; an empty list matches everything.
_sel_match() {
  local name="$1"; shift
  [ "$#" -eq 0 ] && return 0
  local pat
  for pat in "$@"; do
    # shellcheck disable=SC2254
    case "$name" in $pat) return 0 ;; esac
  done
  return 1
}

# selected <category> <name> -> 0 if NAME should be installed for that category.
# Categories: skills | subagents | commands. NAME is the bare item name (skill
# dir name, or the agent/command file name without .md).
selected() {
  local cat="$1" name="$2"
  case "$cat" in
    skills)    _sel_match "$name" ${SEL_SKILLS[@]+"${SEL_SKILLS[@]}"} ;;
    subagents) _sel_match "$name" ${SEL_SUBAGENTS[@]+"${SEL_SUBAGENTS[@]}"} ;;
    commands)  _sel_match "$name" ${SEL_COMMANDS[@]+"${SEL_COMMANDS[@]}"} ;;
    *) return 0 ;;
  esac
}

# Is a bundle in the selected set?
bundle_selected() {
  local b
  for b in "${SELECTED_BUNDLES[@]}"; do
    [ "$b" = "$1" ] && return 0
  done
  return 1
}

# Should bundle <1> be installed for adapter <2>? A bundle may restrict itself to
# specific adapters with an optional "adapters" file (one agent name per line,
# '#' comments allowed). No file = applies to every adapter. Lets OpenCode-only
# bundles (e.g. azure-devops-prs) be skipped by Claude/Codex/Antigravity.
bundle_for_adapter() {
  local b="$1" adapter="$2" f="$REPO_ROOT/bundles/$1/adapters" line tok
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    for tok in $line; do
      [ "$tok" = "$adapter" ] && return 0
    done
  done < "$f"
  return 1
}

# Install the deterministic git pre-commit gate (opt-in via --git-hooks). Copies
# the core hook scripts to a harness-owned dir and points git's global
# core.hooksPath at it — but never clobbers a core.hooksPath you've already set
# (e.g. husky), so it can't silently break another tool. Adapter-independent, so
# install.sh calls it directly, not a per-agent module.
install_git_hooks() {
  local dir="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}/harness/git-hooks"
  local src="$REPO_ROOT/bundles/core/hooks" f
  ensure_dir "$dir"
  # the gate scripts the hook depends on, plus the hook itself
  for f in _lib.sh lint.sh format.sh pre-commit; do
    [ -f "$src/$f" ] && copy "$src/$f" "$dir/$f"
  done
  run chmod +x "$dir/pre-commit" 2>/dev/null || true

  if [ "$DRY_RUN" = "1" ]; then
    printf "  would set git core.hooksPath -> %s (unless already set)\n" "$dir"; return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    warn "git not on PATH; copied hooks to $dir but couldn't set core.hooksPath. Set it manually."
    return 0
  fi
  local current; current="$(git config --global --get core.hooksPath 2>/dev/null || true)"
  if [ -n "$current" ] && [ "$current" != "$dir" ]; then
    warn "git core.hooksPath already set to '$current' — not overriding. To use the harness hook, point it at $dir (or chain them)."
    return 0
  fi
  git config --global core.hooksPath "$dir"
  ok "git pre-commit gate enabled globally (core.hooksPath=$dir). Applies to all repos; bypass once with 'git commit --no-verify', disable with 'git config --global --unset core.hooksPath'."
}

# Link all SKILL.md skills (from selected bundles + every vendored source) into
# a destination skills directory. Used by agents that natively support the
# SKILL.md format (Claude, Antigravity). Vendored layouts differ: if a source's
# plugin.json declares an explicit "./skills/..." list (e.g. category-nested
# repos), honor exactly that; otherwise auto-discover every dir with a SKILL.md.
link_all_skills() {
  local dest="$1" b s src pj rel d f sn
  for b in "${SELECTED_BUNDLES[@]}"; do
    [ -d "$REPO_ROOT/bundles/$b/skills" ] || continue
    for s in "$REPO_ROOT/bundles/$b/skills"/*/; do
      [ -d "$s" ] || continue
      sn="$(basename "$s")"
      selected skills "$sn" || continue
      link "${s%/}" "$dest/$sn"
    done
  done
  for src in "$REPO_ROOT/vendor"/*/; do
    [ -d "${src}skills" ] || continue
    pj="${src}.claude-plugin/plugin.json"
    if [ -f "$pj" ] && grep -q '"\./skills/' "$pj"; then
      while IFS= read -r rel; do
        d="${src}${rel#./}"
        [ -d "$d" ] || continue
        sn="$(basename "$d")"
        selected skills "$sn" || continue
        link "${d%/}" "$dest/$sn"
      done <<EOF
$(grep -oE '"\./skills/[^"]+"' "$pj" | tr -d '"')
EOF
    else
      find "${src}skills" -type f -name 'SKILL.md' | while IFS= read -r f; do
        d="$(dirname "$f")"
        sn="$(basename "$d")"
        selected skills "$sn" || continue
        link "$d" "$dest/$sn"
      done
    fi
  done
}

# Warn (once) if the codegraph code-index binary isn't on PATH. The harness
# wires the MCP server into each agent's config, but the server can't start
# without the binary. We never auto-download it (respects the network policy).
_CODEGRAPH_WARNED=0
codegraph_check() {
  [ "$_CODEGRAPH_WARNED" = "1" ] && return 0
  _CODEGRAPH_WARNED=1
  command -v codegraph >/dev/null 2>&1 && return 0
  warn "codegraph not on PATH — the code-index MCP server is configured but won't start until you install it: 'curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh' (or 'npx @colbymchenry/codegraph'), then run 'codegraph init -i' inside each repo. https://github.com/colbymchenry/codegraph"
}

# Merge a single MCP server entry into a JSON config file under <topkey>.
#   merge_mcp_json <file> <topkey> <server-name> <json-value>
# Idempotent: the entry is (re)written each run. Needs python3; otherwise warns.
merge_mcp_json() {
  local file="$1" topkey="$2" name="$3" val="$4"
  if [ "$DRY_RUN" = "1" ]; then
    printf "  would add MCP server '%s' to %s (%s)\n" "$name" "$file" "$topkey"; return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not found; add MCP server '$name' to $file under \"$topkey\" manually"
    return 0
  fi
  ensure_dir "$(dirname "$file")"
  MCP_FILE="$file" MCP_TOP="$topkey" MCP_NAME="$name" MCP_VAL="$val" python3 - <<'PY'
import json, os
f, top, name, val = (os.environ[k] for k in ("MCP_FILE", "MCP_TOP", "MCP_NAME", "MCP_VAL"))
val = json.loads(val)
try:
    with open(f) as fh: cfg = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}
if not isinstance(cfg, dict): cfg = {}
section = cfg.get(top)
if not isinstance(section, dict): section = {}; cfg[top] = section
section[name] = val
with open(f, "w") as fh:
    json.dump(cfg, fh, indent=2); fh.write("\n")
print(f"  added MCP server '{name}' to {f}")
PY
}

# Concatenate the rules/*.md of every selected bundle into a single managed
# block written to $1. Re-runnable: the whole file is regenerated each time.
assemble_rules() {
  local out="$1" b f
  ensure_dir "$(dirname "$out")"
  local tmp; tmp="$(mktemp)"
  {
    echo "<!-- BEGIN harness-managed rules. Generated by install.sh; edits here are overwritten. -->"
    echo "# Engineering rules (centralized)"
    echo
    for b in "${SELECTED_BUNDLES[@]}"; do
      [ -d "$REPO_ROOT/bundles/$b/rules" ] || continue
      for f in "$REPO_ROOT/bundles/$b/rules"/*.md; do
        [ -e "$f" ] || continue
        echo "<!-- source: bundles/$b/$(basename "$f") -->"
        cat "$f"
        echo
      done
    done
    echo "<!-- END harness-managed rules. -->"
  } > "$tmp"

  if [ "$DRY_RUN" = "1" ]; then
    printf "  would write assembled rules -> %s (%s lines)\n" "$out" "$(wc -l < "$tmp")"
    rm -f "$tmp"
  else
    # Only back up a pre-existing file we don't already manage, so re-runs
    # don't spawn a .bak every time.
    if ! grep -q "BEGIN harness-managed rules" "$out" 2>/dev/null; then
      backup_path "$out"
    fi
    mv "$tmp" "$out"
    ok "wrote $out"
  fi
}
