#!/usr/bin/env bash
# Lint the project. Exits non-zero on lint failure so it can gate CI or a
# pre-commit invocation; as a Stop hook it surfaces problems without blocking.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$DIR/_lib.sh"

case "$(project_kind .)" in
  node)   soft_run npm run --silent lint ;;
  gradle) soft_run ./gradlew -q checkstyleMain spotlessCheck ;;
  maven)  soft_run ./mvnw -q checkstyle:check spotless:check ;;
  *)      echo "[hook] lint: unknown project kind, nothing to do" >&2 ;;
esac
