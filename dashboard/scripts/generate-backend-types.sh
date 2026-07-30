#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_SWAGGER="${SCRIPT_DIR}/../../backend/docs/swagger.json"
OUTPUT_DIR="${SCRIPT_DIR}/../types/generated"
OUTPUT_FILE="${OUTPUT_DIR}/backend-openapi.ts"

if [[ ! -f "${BACKEND_SWAGGER}" ]]; then
  printf 'Missing backend OpenAPI document: %s\n' "${BACKEND_SWAGGER}" >&2
  printf 'Generate it first with: make -C backend swagger\n' >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

cd "${SCRIPT_DIR}/.."
bunx --bun swagger-typescript-api generate \
  --path "${BACKEND_SWAGGER}" \
  --output "${OUTPUT_DIR}" \
  --name "$(basename "${OUTPUT_FILE}")" \
  --no-client \
  --add-readonly \
  --enum-style union \
  --extract-enums \
  --sort-types \
  --silent

printf 'Generated dashboard contracts: %s\n' "${OUTPUT_FILE}"
