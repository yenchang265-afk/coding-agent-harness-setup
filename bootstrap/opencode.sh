# OpenCode installer. Sourced by install.sh; provides install_opencode.
# rules -> ~/.config/opencode/AGENTS.md, subagents -> agent/, commands ->
# command/, and opencode.json gets the LSP block + file-edited hooks merged in.

install_opencode() {
  local base="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}/opencode"
  local b f

  # 1) rules -> AGENTS.md
  assemble_rules "$base/AGENTS.md"

  # 2) subagents -> agent/ , commands -> command/
  for b in "${SELECTED_BUNDLES[@]}"; do
    local bd="$REPO_ROOT/bundles/$b"
    if [ -d "$bd/agents" ]; then
      for f in "$bd/agents"/*.md; do
        [ -e "$f" ] || continue
        link "$f" "$base/agent/$b-$(basename "$f")"
      done
    fi
    if [ -d "$bd/commands" ]; then
      for f in "$bd/commands"/*.md; do
        [ -e "$f" ] || continue
        link "$f" "$base/command/$b-$(basename "$f")"
      done
    fi
  done

  # 3) copy shared hook scripts and merge opencode.json (lsp + experimental hooks)
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

  ok "OpenCode configured at $base"
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
