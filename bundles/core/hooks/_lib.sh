#!/usr/bin/env bash
# Shared helpers for the gate scripts. Stack-aware: detects project type so one
# set of hooks serves both the Next.js and the Spring Boot repos.

# Print the edited file path from a Claude/OpenCode hook payload on stdin, if any.
# Falls back to the first positional arg. Empty output => operate project-wide.
hook_target_file() {
  if [ -n "${1:-}" ]; then printf '%s' "$1"; return; fi
  if [ -t 0 ]; then return; fi
  local payload; payload="$(cat 2>/dev/null || true)"
  [ -n "$payload" ] || return
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti=d.get("tool_input") or {}
print(ti.get("file_path") or d.get("file") or "")' 2>/dev/null
  fi
}

# Echo the project kind for a given directory: "node", "gradle", "maven", or "".
project_kind() {
  local dir="${1:-.}"
  if [ -f "$dir/package.json" ]; then echo node; return; fi
  if [ -f "$dir/gradlew" ] || ls "$dir"/*.gradle* >/dev/null 2>&1; then echo gradle; return; fi
  if [ -f "$dir/pom.xml" ]; then echo maven; return; fi
  echo ""
}

# Run a command only if its binary exists; otherwise warn and succeed (hooks
# must never block work just because a tool is missing locally).
soft_run() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@"
  else
    echo "[hook] skipped: '$1' not on PATH" >&2
  fi
}
