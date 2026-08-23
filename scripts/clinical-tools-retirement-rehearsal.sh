#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
inherited_app_env="${APP_ENV:-}"
inherited_database_url="${DATABASE_URL:-}"
if [[ "${inherited_app_env}" == "production" || "${inherited_app_env}" == "staging" ]]; then
  echo "Refusing retirement rehearsal while APP_ENV=${inherited_app_env}." >&2
  exit 1
fi
if [[ -n "${inherited_database_url}" &&
      "${inherited_database_url}" != *"@postgres:"* &&
      "${inherited_database_url}" != *"@localhost:"* &&
      "${inherited_database_url}" != *"@127.0.0.1:"* ]]; then
  echo "Refusing an inherited non-local DATABASE_URL." >&2
  exit 1
fi
unset APP_ENV DATABASE_URL COMPOSE_PROJECT_NAME

project="mediguide-clinical-tools-rehearsal-$(date -u +%Y%m%d%H%M%S)-$$"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/mediguide-clinical-tools-rehearsal.XXXXXX")"
export BUILDX_CONFIG="${temporary_root}/buildx"
mkdir -p "${BUILDX_CONFIG}"
report_dir="${REPORT_DIR:-${repo_root}/artifacts/clinical-tools-retirement-rehearsal/${project}}"
environment_file="${temporary_root}/rehearsal.env"
schema_image="${project}-schema-only:local"
api_image="${project}-api:local"

compose=(
  docker compose
  --project-name "${project}"
  --env-file "${environment_file}"
  -f "${repo_root}/infra/docker-compose.yml"
  -f "${repo_root}/infra/docker-compose.retirement-rehearsal.yml"
)

cleanup() {
  local status=$?
  "${compose[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  docker image rm "${schema_image}" "${api_image}" >/dev/null 2>&1 || true
  rm -rf "${temporary_root}"
  exit "${status}"
}
trap cleanup EXIT INT TERM

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null

mkdir -p "${report_dir}"
cp -R "${repo_root}/clinical-tools/migrations/v1/parity" "${temporary_root}/parity"

{
  echo "COMPOSE_PROJECT_NAME=${project}"
  echo "REHEARSAL_API_IMAGE=${api_image}"
  echo "APP_ENV=test"
  echo "CLINICAL_TOOLS_REHEARSAL=1"
  echo "POSTGRES_DB=mediguide_rehearsal"
  echo "POSTGRES_USER=mediguide_rehearsal"
  echo "POSTGRES_PASSWORD=rehearsal-only-password"
  echo "DATABASE_URL=postgres://mediguide_rehearsal:rehearsal-only-password@postgres:5432/mediguide_rehearsal?sslmode=disable"
  echo "MINIO_ROOT_USER=mediguide_rehearsal"
  echo "MINIO_ROOT_PASSWORD=rehearsal-only-password"
  echo "JWT_SECRET=synthetic-rehearsal-secret-not-for-deployment"
  echo "RATE_LIMIT_ENABLED=false"
  echo "CACHE_ENABLED=false"
} > "${environment_file}"
chmod 600 "${environment_file}"

echo "Starting isolated rehearsal project ${project}"
"${compose[@]}" build api
"${compose[@]}" up -d --wait postgres redis minio
"${compose[@]}" run --rm --no-deps api /app/migrate up
"${compose[@]}" run --rm --no-deps api /app/seed

author_id="$("${compose[@]}" exec -T postgres psql -U mediguide_rehearsal -d mediguide_rehearsal -Atc "SELECT id FROM users WHERE email='admin@mediguide.health.go.ug' LIMIT 1")"
if [[ ! "${author_id}" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  echo "The deterministic seed did not create the rehearsal author." >&2
  exit 1
fi

"${compose[@]}" run --rm --no-deps api \
  /app/clinicaltool-migrate --apply --require-all --actor "${author_id}"
"${compose[@]}" run --rm --no-deps \
  -v "${report_dir}:/reports" api \
  /app/clinicaltool-rehearsal \
  --json-report /reports/report.json \
  --text-report /reports/report.txt

docker build \
  --file "${repo_root}/backend/Dockerfile" \
  --target schema-only \
  --tag "${schema_image}" \
  "${repo_root}"
docker run --rm --entrypoint sh "${schema_image}" -ec \
  'if find /app -type f -name "*.html" -print | grep -q .; then echo "schema-only image contains HTML" >&2; exit 1; fi'

echo "Rehearsal reports: ${report_dir}"
echo "READY synthetic retirement rehearsal completed; no clinical approval was created"
