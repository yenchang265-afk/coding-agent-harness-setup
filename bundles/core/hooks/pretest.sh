#!/usr/bin/env bash
# Stop hook: remind/verify that tests pass for the project. Prints a hint
# rather than running a full suite automatically (suites can be slow); flip
# RUN_TESTS=1 to actually execute them.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$DIR/_lib.sh"

kind="$(project_kind .)"
if [ "${RUN_TESTS:-0}" != "1" ]; then
  case "$kind" in
    node)   echo "[hook] reminder: run 'npm test' for code you changed." >&2 ;;
    gradle) echo "[hook] reminder: run './gradlew test' for code you changed." >&2 ;;
    maven)  echo "[hook] reminder: run './mvnw test' for code you changed." >&2 ;;
  esac
  exit 0
fi

case "$kind" in
  node)   soft_run npm test ;;
  gradle) soft_run ./gradlew test ;;
  maven)  soft_run ./mvnw test ;;
esac
