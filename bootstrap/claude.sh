# Claude Code installer. Sourced by install.sh; provides install_claude.
# Installs bundle skills/agents/commands/hooks directly (works offline) and
# assembles bundle rules into ~/.claude/CLAUDE.md. The internal marketplace
# (.claude-plugin/marketplace.json) is the alternative native path; see the
# instructions printed at the end.

install_claude() {
  local base="$TARGET_HOME/.claude"
  local b name dst

  # 1) rules -> CLAUDE.md
  assemble_rules "$base/CLAUDE.md"

  # 2) subagents, skills, commands from each selected bundle (+ vendor)
  local src pj rel d f adir
  for b in "${SELECTED_BUNDLES[@]}"; do
    local bd="$REPO_ROOT/bundles/$b"

    if [ -d "$bd/agents" ]; then
      for f in "$bd/agents"/*.md; do
        [ -e "$f" ] || continue
        link "$f" "$base/agents/$b-$(basename "$f")"
      done
    fi
    if [ -d "$bd/commands" ]; then
      for f in "$bd/commands"/*.md; do
        [ -e "$f" ] || continue
        link "$f" "$base/commands/$b-$(basename "$f")"
      done
    fi
  done

  # bundle + vendored SKILL.md skills (shared helper; Claude consumes them natively)
  link_all_skills "$base/skills"

  # vendored subagents
  for adir in "$REPO_ROOT/vendor"/*/agents; do
    [ -d "$adir" ] || continue
    for f in "$adir"/*.md; do
      [ -e "$f" ] || continue
      link "$f" "$base/agents/vendor-$(basename "$f")"
    done
  done

  # 3) hooks: copy the shared gate scripts and merge hook config into settings.json
  local hooks_src="$REPO_ROOT/bundles/core/hooks"
  if [ -d "$hooks_src" ]; then
    ensure_dir "$base/harness/hooks"
    for f in "$hooks_src"/*.sh; do
      [ -e "$f" ] || continue
      copy "$f" "$base/harness/hooks/$(basename "$f")"
      run chmod +x "$base/harness/hooks/$(basename "$f")" 2>/dev/null || true
    done
    _claude_merge_settings "$base/settings.json" "$base/harness/hooks"
  fi

  ok "Claude Code configured at $base"
  cat <<EOF

  Native marketplace alternative (instead of this copy install):
    claude plugin marketplace add <your-internal-gitlab-url>/coding-agent-harness-setup
    claude plugin install core backend-spring frontend-nextjs data-platform
EOF
}

# Merge our PostToolUse/Stop hooks into settings.json using python3 if present;
# otherwise write a snippet the user can merge by hand (never clobber).
_claude_merge_settings() {
  local settings="$1" hooksdir="$2"
  local snippet
  snippet=$(cat <<JSON
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit",
        "hooks": [ { "type": "command", "command": "$hooksdir/format.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "$hooksdir/pretest.sh" } ] }
    ]
  }
}
JSON
)
  if [ "$DRY_RUN" = "1" ]; then
    printf "  would merge hooks into %s\n" "$settings"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    ensure_dir "$(dirname "$settings")"
    SETTINGS="$settings" SNIPPET="$snippet" python3 - <<'PY'
import json, os, sys
path = os.environ["SETTINGS"]
add = json.loads(os.environ["SNIPPET"])
try:
    with open(path) as fh: cfg = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}
hooks = cfg.setdefault("hooks", {})
for event, entries in add["hooks"].items():
    existing = hooks.setdefault(event, [])
    # de-dupe by command string so re-runs are idempotent
    have = {json.dumps(e, sort_keys=True) for e in existing}
    for e in entries:
        if json.dumps(e, sort_keys=True) not in have:
            existing.append(e)
with open(path, "w") as fh:
    json.dump(cfg, fh, indent=2); fh.write("\n")
print(f"  merged hooks into {path}")
PY
  else
    local out="$settings.harness-snippet.json"
    printf '%s\n' "$snippet" > "$out"
    warn "python3 not found; wrote hook snippet to $out — merge it into $settings manually"
  fi
}
