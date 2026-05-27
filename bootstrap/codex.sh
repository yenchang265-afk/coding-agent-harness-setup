# Codex CLI installer. Sourced by install.sh; provides install_codex.
# Codex has no skill/plugin/subagent concept, so: rules -> ~/.codex/AGENTS.md,
# commands & adapted subagents -> ~/.codex/prompts/, and a managed config block
# is appended to ~/.codex/config.toml. Hook intent is encoded as rules.

install_codex() {
  local base="$TARGET_HOME/.codex"
  local b f

  # 1) rules -> global AGENTS.md, plus a quality-gates note (hooks can't enforce)
  assemble_rules "$base/AGENTS.md"
  _codex_append_gates "$base/AGENTS.md"

  # 2) commands -> prompts
  for b in "${SELECTED_BUNDLES[@]}"; do
    local bd="$REPO_ROOT/bundles/$b"
    if [ -d "$bd/commands" ]; then
      for f in "$bd/commands"/*.md; do
        [ -e "$f" ] || continue
        selected commands "$(basename "$f" .md)" || continue
        link "$f" "$base/prompts/$b-$(basename "$f")"
      done
    fi
    # 3) subagents adapted to prompts ("/<name>" invokes the reviewer persona)
    if [ -d "$bd/agents" ]; then
      for f in "$bd/agents"/*.md; do
        [ -e "$f" ] || continue
        selected subagents "$(basename "$f" .md)" || continue
        _codex_agent_to_prompt "$f" "$base/prompts/$b-$(basename "$f")"
      done
    fi
  done

  # 4) merge adapter config.toml block
  _codex_merge_config "$base/config.toml"

  # 5) codegraph code-index MCP server (unless opted out)
  _codex_add_codegraph "$base/config.toml"

  ok "Codex CLI configured at $base"
}

# Append the codegraph MCP server table to config.toml (idempotent). Codex uses
# TOML, so this is a guarded append rather than the shared JSON merger.
_codex_add_codegraph() {
  local cfg="$1"
  [ "${CODEGRAPH:-1}" = "1" ] || return 0
  if [ "$DRY_RUN" = "1" ]; then printf "  would add codegraph MCP server to %s\n" "$cfg"; return 0; fi
  if [ -f "$cfg" ] && grep -qF '[mcp_servers.codegraph]' "$cfg"; then return 0; fi
  ensure_dir "$(dirname "$cfg")"
  cat >> "$cfg" <<'TOML'

[mcp_servers.codegraph]
command = "codegraph"
args = ["serve", "--mcp"]
TOML
  ok "added codegraph MCP server to $cfg"
}

# Convert a Claude-style subagent .md into a Codex prompt that adopts the persona.
_codex_agent_to_prompt() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" = "1" ]; then
    printf "  would adapt subagent -> prompt %s\n" "$dst"; return 0
  fi
  ensure_dir "$(dirname "$dst")"
  {
    echo "# Adapted from a Claude subagent. Invoke as a Codex prompt."
    echo "Adopt the following role for this task, then review the current changes:"
    echo
    cat "$src"
  } > "$dst"
}

_codex_append_gates() {
  local agents="$1"
  [ "$DRY_RUN" = "1" ] && { printf "  would append quality-gates note to %s\n" "$agents"; return 0; }
  cat >> "$agents" <<'MD'

## Quality gates (Codex has no enforcing hooks — follow these manually)
- Before finishing a task, run the project formatter and linter:
  - JS/TS (package.json): `npm run lint && npm run format` (or prettier/eslint).
  - Java (gradlew): `./gradlew spotlessApply check`; Maven: `./mvnw spotless:apply verify`.
- Run the relevant tests for code you touched before reporting done.
MD
}

_codex_merge_config() {
  local cfg="$1"
  local block="$REPO_ROOT/adapters/codex/config.toml"
  [ -f "$block" ] || { warn "no adapters/codex/config.toml; skipping config merge"; return 0; }
  if [ "$DRY_RUN" = "1" ]; then printf "  would merge %s into %s\n" "$block" "$cfg"; return 0; fi
  ensure_dir "$(dirname "$cfg")"
  local marker="# >>> harness-managed >>>"
  if [ -f "$cfg" ] && grep -qF "$marker" "$cfg"; then
    log "config.toml already has harness block; leaving as-is"
    return 0
  fi
  {
    [ -f "$cfg" ] && cat "$cfg" && echo
    echo "$marker"
    cat "$block"
    echo "# <<< harness-managed <<<"
  } > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  ok "merged harness block into $cfg"
}
