#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DART_BIN="${DART_BIN:-${REPOSITORY_ROOT}/user_app/.fvm/flutter_sdk/bin/dart}"

if [[ ! -x "${DART_BIN}" ]]; then
  printf 'Missing project-pinned Dart executable: %s\n' "${DART_BIN}" >&2
  printf 'Set DART_BIN explicitly or install the pinned Flutter SDK.\n' >&2
  exit 1
fi

make -C "${REPOSITORY_ROOT}/backend" swagger
"${REPOSITORY_ROOT}/dashboard/scripts/generate-backend-types.sh"

(
  cd "${REPOSITORY_ROOT}/user_app"
  "${DART_BIN}" run tool/generate_backend_contracts.dart
  "${DART_BIN}" format lib/core/network/contracts/generated/backend_contracts.dart
)

printf 'Generated Go, TypeScript, and Dart API contracts.\n'
