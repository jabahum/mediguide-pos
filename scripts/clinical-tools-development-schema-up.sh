#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/mediguide-schema-tools-development.XXXXXX")"
export BUILDX_CONFIG="${temporary_root}/buildx"
mkdir -p "${BUILDX_CONFIG}"
trap 'rm -rf "${temporary_root}"' EXIT INT TERM

compose=(
  docker compose
  --env-file "${repo_root}/infra/development.env"
  -f "${repo_root}/infra/docker-compose.yml"
  -f "${repo_root}/infra/docker-compose.dev.yml"
  -f "${repo_root}/infra/docker-compose.schema-tools.dev.yml"
)

"${compose[@]}" up -d --build --wait api
"${compose[@]}" exec -T api sh -ec \
  'if find /app -type f -name "*.html" -print | grep -q .; then echo "schema-only development API contains HTML" >&2; exit 1; fi'

echo "READY schema-only development API is healthy and contains no executable HTML"
