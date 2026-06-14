#!/usr/bin/env bash
#
# babysit-prs.sh — run the "pr-babysitter" OpenCode agent on a fixed interval,
# emulating Claude Code's /loop. Each pass is an independent, headless
# `opencode run` invocation. Babysit-only: triages review comments on PRs you
# AUTHORED, makes minimal fixes, pushes, checks CI, and replies on threads.
# Run from inside the repo you care about (babysit mode pushes code).
#
# PR review (PRs you were asked to review) has moved to the code-review bundle:
#   $OPENCODE_CONFIG/harness/scripts/review-loop.sh --project P --repo R [--pr N]
#
# Usage:
#   scripts/babysit-prs.sh                   # loop, 1h interval (default)
#   scripts/babysit-prs.sh --interval 2h     # custom interval: <n>[s|m|h], minimum 1h
#   scripts/babysit-prs.sh --once            # single pass then exit (good for cron)
#   scripts/babysit-prs.sh --model anthropic/claude-sonnet-4-6 --once
#
# Env overrides:
#   BABYSIT_MODE       babysit (default: babysit)
#   BABYSIT_INTERVAL   default interval when --interval is omitted (default: 1h, min 1h)
#   BABYSIT_AGENT      agent name to run (default: azure-devops-prs-pr-babysitter)
#   OPENCODE_BIN       path to the opencode binary (default: opencode on PATH)
#
set -euo pipefail

# Unattended loop: never let git block on an interactive credential/passphrase
# prompt — fail fast instead. Configure non-interactive auth (credential helper,
# PAT, or passphrase-less SSH / ssh-agent) so pushes succeed. See README.
export GIT_TERMINAL_PROMPT=0

MODE="${BABYSIT_MODE:-babysit}"
AGENT="${BABYSIT_AGENT:-}"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"
INTERVAL_RAW="${BABYSIT_INTERVAL:-1h}"
MODEL=""
ONCE=0

PROMPT_BABYSIT='Run a single babysitting pass NOW over my active Azure DevOps pull requests. Follow your standard workflow and guardrails: collect unresolved review comments waiting on me, decide if each needs a code change, make minimal changes + commit + push where warranted, and reply on each thread (resolving only those you actually addressed). Verify the CI gate on every active PR every pass even when there are no comments and no code changes, and treat a blocked gate like an active comment that needs attention. For anything ambiguous or architecturally significant, reply with a clarifying question instead of guessing.'

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^#\{0,1\} \{0,1\}//; $d'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)     MODE="${2:?--mode needs a value}"; shift 2 ;;
    --interval) INTERVAL_RAW="${2:?--interval needs a value}"; shift 2 ;;
    --model)    MODEL="${2:?--model needs a value}"; shift 2 ;;
    --agent)    AGENT="${2:?--agent needs a value}"; shift 2 ;;
    --once)     ONCE=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "babysit-prs: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Resolve mode → its default agent + prompt. An explicit --agent / BABYSIT_AGENT
# still wins (we only fill AGENT if it's empty). Default matches the agent id the
# generator produces for OpenCode: bundle agents are aggregated as
# "<bundle>-<file>" under .opencode/agents/, so it is "azure-devops-prs-pr-babysitter".
# If you installed the agent file manually without the bundle prefix, pass
# --agent pr-babysitter (or set BABYSIT_AGENT).
case "$MODE" in
  babysit) AGENT="${AGENT:-azure-devops-prs-pr-babysitter}"; PROMPT="$PROMPT_BABYSIT" ;;
  review)
    echo "babysit-prs: review mode moved to the code-review bundle. Use:" >&2
    echo "  \$OPENCODE_CONFIG/harness/scripts/review-loop.sh --project P --repo R [--pr N]" >&2
    exit 2 ;;
  *) echo "babysit-prs: invalid mode '$MODE' (use 'babysit')" >&2; exit 2 ;;
esac

# Convert <n>, <n>s, <n>m, <n>h to seconds. Minimum interval is 1h (3600s).
n="${INTERVAL_RAW%[smhSMH]}"
unit="${INTERVAL_RAW##*[0-9]}"
if ! [[ "$n" =~ ^[0-9]+$ ]]; then
  echo "babysit-prs: invalid interval '$INTERVAL_RAW' (use <n>[s|m|h], e.g. 1h, 90m, 7200)" >&2; exit 2
fi
case "${unit,,}" in
  ""|s) INTERVAL=$(( 10#$n )) ;;
  m)    INTERVAL=$(( 10#$n * 60 )) ;;
  h)    INTERVAL=$(( 10#$n * 3600 )) ;;
  *)    echo "babysit-prs: invalid interval '$INTERVAL_RAW' (use <n>[s|m|h])" >&2; exit 2 ;;
esac
if (( INTERVAL < 3600 )); then
  echo "babysit-prs: interval must be at least 1h (got '$INTERVAL_RAW' = ${INTERVAL}s)" >&2; exit 2
fi

if ! command -v "$OPENCODE_BIN" >/dev/null 2>&1; then
  echo "babysit-prs: cannot find opencode binary '$OPENCODE_BIN' (set OPENCODE_BIN)" >&2
  exit 127
fi

run_pass() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] babysit-prs: starting pass (mode=$MODE agent=$AGENT)"
  local args=(run --agent "$AGENT")
  [[ -n "$MODEL" ]] && args+=(--model "$MODEL")
  args+=("$PROMPT")
  if "$OPENCODE_BIN" "${args[@]}"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] babysit-prs: pass complete"
  else
    local rc=$?
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] babysit-prs: pass FAILED (exit $rc) — will retry next interval" >&2
  fi
}

trap 'echo; echo "babysit-prs: stopped."; exit 0' INT TERM

if (( ONCE == 1 )); then
  run_pass
  exit 0
fi

echo "babysit-prs: [$MODE] looping every ${INTERVAL_RAW} (${INTERVAL}s) in $(pwd). Ctrl-C to stop."
while true; do
  run_pass
  echo "babysit-prs: sleeping ${INTERVAL_RAW}..."
  sleep "$INTERVAL"
done
