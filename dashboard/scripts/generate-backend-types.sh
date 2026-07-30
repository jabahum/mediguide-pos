#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_SWAGGER="${SCRIPT_DIR}/../../backend/docs/swagger.json"

if [[ ! -f "${BACKEND_SWAGGER}" ]]; then
  printf 'Missing backend OpenAPI document: %s\n' "${BACKEND_SWAGGER}" >&2
  printf 'Generate it first with: make -C backend swagger\n' >&2
  exit 1
fi

printf '%s\n' \
  "The Go OpenAPI document is the source of truth for new backend contracts:" \
  "  ${BACKEND_SWAGGER}" \
  "" \
  "Automatic client generation is intentionally deferred until the legacy" \
  "/api/v1/collections compatibility endpoints are replaced by typed domain APIs." \
  "See docs/pocketbase-removal.md for the migration plan."
