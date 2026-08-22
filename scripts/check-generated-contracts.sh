#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DART_BIN="${DART_BIN:-${REPOSITORY_ROOT}/user_app/.fvm/flutter_sdk/bin/dart}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mediguide-contracts.XXXXXX")"
trap 'rm -rf "${TEMP_DIR}"' EXIT

if [[ ! -x "${DART_BIN}" ]]; then
  printf 'Missing project-pinned Dart executable: %s\n' "${DART_BIN}" >&2
  printf 'Set DART_BIN explicitly or install the pinned Flutter SDK.\n' >&2
  exit 1
fi

mkdir -p "${TEMP_DIR}/docs" "${TEMP_DIR}/dashboard" "${TEMP_DIR}/mobile"

(
  cd "${REPOSITORY_ROOT}/backend"
  go run github.com/swaggo/swag/cmd/swag@v1.16.6 init \
    -g main.go \
    -d cmd/api,internal/handlers,internal/httpx,internal/models,internal/services,internal/clinicaltools \
    -o "${TEMP_DIR}/docs" \
    --outputTypes go,json,yaml \
    --generatedTime=false \
    --parseInternal
)

"${REPOSITORY_ROOT}/dashboard/scripts/generate-backend-types.sh" \
  "${TEMP_DIR}/docs/swagger.json" \
  "${TEMP_DIR}/dashboard/backend-openapi.ts"

(
  cd "${REPOSITORY_ROOT}/user_app"
  "${DART_BIN}" run tool/generate_backend_contracts.dart \
    "${TEMP_DIR}/docs/swagger.json" \
    "${TEMP_DIR}/mobile/backend_contracts.dart"
  "${DART_BIN}" format "${TEMP_DIR}/mobile/backend_contracts.dart"
)

drift=0
compare_generated() {
  local generated="$1"
  local committed="$2"
  if ! cmp -s "${generated}" "${committed}"; then
    printf 'Generated contract drift: %s\n' "${committed#"${REPOSITORY_ROOT}/"}" >&2
    diff -u "${committed}" "${generated}" || true
    drift=1
  fi
}

compare_generated "${TEMP_DIR}/docs/docs.go" "${REPOSITORY_ROOT}/backend/docs/docs.go"
compare_generated "${TEMP_DIR}/docs/swagger.json" "${REPOSITORY_ROOT}/backend/docs/swagger.json"
compare_generated "${TEMP_DIR}/docs/swagger.yaml" "${REPOSITORY_ROOT}/backend/docs/swagger.yaml"
compare_generated "${TEMP_DIR}/dashboard/backend-openapi.ts" "${REPOSITORY_ROOT}/dashboard/types/generated/backend-openapi.ts"
compare_generated "${TEMP_DIR}/mobile/backend_contracts.dart" "${REPOSITORY_ROOT}/user_app/lib/core/network/contracts/generated/backend_contracts.dart"

if (( drift != 0 )); then
  printf 'Run make contracts and commit the generated output.\n' >&2
  exit 1
fi

printf 'Generated Go, TypeScript, and Dart contracts are reproducible and current.\n'
