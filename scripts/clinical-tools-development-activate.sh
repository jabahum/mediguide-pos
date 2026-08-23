#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/mediguide-clinical-tools-development.XXXXXX")"
export BUILDX_CONFIG="${temporary_root}/buildx"
mkdir -p "${BUILDX_CONFIG}"
trap 'rm -rf "${temporary_root}"' EXIT INT TERM

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null

compose=(
  docker compose
  --env-file "${repo_root}/infra/development.env"
  -f "${repo_root}/infra/docker-compose.yml"
  -f "${repo_root}/infra/docker-compose.dev.yml"
)

"${compose[@]}" build api
"${compose[@]}" up -d --wait postgres redis minio
"${compose[@]}" run --rm --no-deps api /app/migrate up
"${compose[@]}" run --rm --no-deps api /app/seed
"${compose[@]}" run --rm --no-deps \
  -e CLINICAL_TOOLS_DEVELOPMENT_ACTIVATION=1 \
  api /app/clinicaltool-development-activate
