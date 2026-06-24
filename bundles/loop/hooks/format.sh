#!/usr/bin/env bash
# PostToolUse / file-edited hook: format the edited file (or project) in place.
# Non-blocking by design — missing tools just warn.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$DIR/_lib.sh"

target="$(hook_target_file "${1:-}")"

case "$target" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
    soft_run npx --no-install prettier --write "$target" ;;
  *.java)
    if [ -f "./gradlew" ]; then soft_run ./gradlew spotlessApply -q
    elif [ -f "./pom.xml" ]; then soft_run ./mvnw -q spotless:apply
    fi ;;
  "")
    # no specific file: format the whole project by kind
    case "$(project_kind .)" in
      node)   soft_run npx --no-install prettier --write . ;;
      gradle) soft_run ./gradlew spotlessApply -q ;;
      maven)  soft_run ./mvnw -q spotless:apply ;;
    esac ;;
esac
exit 0
