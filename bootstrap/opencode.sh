# OpenCode installer. Sourced by install.sh; provides install_opencode.
# rules -> ~/.config/opencode/AGENTS.md, subagents -> agent/, commands ->
# command/, skills -> skills/ (OpenCode natively discovers SKILL.md since
# v1.0.190), the vendored superpowers plugin -> plugin/, and opencode.json gets
# the LSP block + file-edited hooks merged in.

install_opencode() {
  local base="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}/opencode"
  local b f

  # 1) rules -> AGENTS.md
  assemble_rules "$base/AGENTS.md"

  # 2) subagents -> agent/ , commands -> command/
  for b in "${SELECTED_BUNDLES[@]}"; do
    local bd="$REPO_ROOT/bundles/$b"
    bundle_for_adapter "$b" opencode || continue
    if [ -d "$bd/agents" ]; then
      for f in "$bd/agents"/*.md; do
        [ -e "$f" ] || continue
        selected subagents "$(basename "$f" .md)" || continue
        link "$f" "$base/agent/$b-$(basename "$f")"
      done
    fi
    if [ -d "$bd/commands" ]; then
      for f in "$bd/commands"/*.md; do
        [ -e "$f" ] || continue
        selected commands "$(basename "$f" .md)" || continue
        link "$f" "$base/command/$b-$(basename "$f")"
      done
    fi
    # bundle-provided helper scripts (e.g. the PR loop runner) -> harness/scripts
    if [ -d "$bd/scripts" ]; then
      ensure_dir "$base/harness/scripts"
      for f in "$bd/scripts"/*.sh; do
        [ -e "$f" ] || continue
        copy "$f" "$base/harness/scripts/$(basename "$f")"
        run chmod +x "$base/harness/scripts/$(basename "$f")" 2>/dev/null || true
      done
    fi
  done

  # 3) bundle + vendored SKILL.md skills -> skills/ (OpenCode discovers these
  # natively via its built-in skill tool; same shared helper Claude/Antigravity use)
  link_all_skills "$base/skills"

  # 4) vendored superpowers plugin -> plugin/ (opencode auto-loads *.js there).
  # The plugin self-registers the vendored skills dir relative to its own path,
  # so this is the offline equivalent of INSTALL.md's git-backed plugin spec.
  local sp_plugin="$REPO_ROOT/vendor/superpowers/.opencode/plugins/superpowers.js"
  if [ -f "$sp_plugin" ]; then
    link "$sp_plugin" "$base/plugin/superpowers.js"
  fi

  # 5) warn about missing LSP servers for the bundles actually selected
  _opencode_check_lsp

  # 6) copy shared hook scripts and merge opencode.json (lsp + experimental hooks)
  local hooks_src="$REPO_ROOT/bundles/core/hooks"
  ensure_dir "$base/harness/hooks"
  if [ -d "$hooks_src" ]; then
    for f in "$hooks_src"/*.sh; do
      [ -e "$f" ] || continue
      copy "$f" "$base/harness/hooks/$(basename "$f")"
      run chmod +x "$base/harness/hooks/$(basename "$f")" 2>/dev/null || true
    done
  fi
  _opencode_merge_config "$base/opencode.json" "$base/harness/hooks"

  # 7) codegraph code-index MCP server (opencode uses a "local" stdio server)
  [ "${CODEGRAPH:-1}" = "1" ] && merge_mcp_json "$base/opencode.json" mcp codegraph \
    '{"type":"local","command":["codegraph","serve","--mcp"],"enabled":true}'

  # 8) azure-devops-prs bundle: register the Azure DevOps MCP server, DISABLED by
  # default. It needs your org + auth, so the user enables it and sets the org
  # (replace YOUR_ADO_ORG) — see the README. The babysitter/reviewer agents are
  # inert until it's enabled.
  if bundle_selected azure-devops-prs; then
    merge_mcp_json "$base/opencode.json" mcp azure-devops \
      '{"type":"local","command":["npx","-y","@azure-devops/mcp","YOUR_ADO_ORG"],"environment":{},"enabled":false}'
    log "azure-devops-prs: PR loop runner -> $base/harness/scripts/babysit-prs.sh; enable the azure-devops MCP in $base/opencode.json to use it"
  fi

  ok "OpenCode configured at $base"
}

# Warn when an LSP server for a selected bundle isn't on PATH (intellisense is
# optional, so this is advisory only — not a hard failure).
_opencode_check_lsp() {
  local b
  for b in "${SELECTED_BUNDLES[@]}"; do
    case "$b" in
      frontend-nextjs)
        command -v typescript-language-server >/dev/null 2>&1 || \
          warn "LSP: 'typescript-language-server' not on PATH — TS/JS intellisense in OpenCode will be inactive (npm i -g typescript-language-server typescript)" ;;
      backend-spring)
        command -v jdtls >/dev/null 2>&1 || \
          warn "LSP: 'jdtls' not on PATH — Java intellisense in OpenCode will be inactive (install Eclipse JDT language server)" ;;
    esac
  done
}

# Merge LSP servers + a file-edited format hook into opencode.json (python3),
# else drop a reference config alongside it.
_opencode_merge_config() {
  local cfg="$1" hooksdir="$2"
  local tmpl="$REPO_ROOT/adapters/opencode/opencode.json"
  if [ "$DRY_RUN" = "1" ]; then printf "  would merge LSP+hooks into %s\n" "$cfg"; return 0; fi
  if command -v python3 >/dev/null 2>&1 && [ -f "$tmpl" ]; then
    ensure_dir "$(dirname "$cfg")"
    CFG="$cfg" TMPL="$tmpl" HOOKS="$hooksdir" python3 - <<'PY'
import json, os
cfg_path, tmpl_path, hooks = os.environ["CFG"], os.environ["TMPL"], os.environ["HOOKS"]
with open(tmpl_path) as fh:
    tmpl = json.load(fh)
# inject the resolved hooks dir into the format command
fmt = f"{hooks}/format.sh"
try:
    exp = tmpl["experimental"]["hook"]["file_edited"]["*"]
    for h in exp:
        if h.get("command") and h["command"] and h["command"][0] == "__FORMAT__":
            h["command"][0] = fmt
except (KeyError, TypeError, IndexError):
    pass
try:
    with open(cfg_path) as fh: cfg = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}
def deep_merge(a, b):
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(a.get(k), dict):
            deep_merge(a[k], v)
        else:
            a[k] = v
deep_merge(cfg, tmpl)
with open(cfg_path, "w") as fh:
    json.dump(cfg, fh, indent=2); fh.write("\n")
print(f"  merged LSP+hooks into {cfg_path}")
PY
  else
    warn "python3 or adapter template missing; copy adapters/opencode/opencode.json into $cfg manually"
  fi
}
