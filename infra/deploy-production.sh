#!/usr/bin/env bash

set -Eeuo pipefail

release_version="${1:-}"
release_revision="${2:-}"
ghcr_owner="${3:-}"

if [[ ! "${release_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Usage: deploy-production.sh MAJOR.MINOR.PATCH GIT_REVISION GHCR_OWNER" >&2
  exit 2
fi

if [[ ! "${release_revision}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Release revision must be a full 40-character Git SHA." >&2
  exit 2
fi

if [[ ! "${ghcr_owner}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "GHCR owner must be a lowercase GitHub account or organization name." >&2
  exit 2
fi

infra_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
production_env="${infra_dir}/production.env"
release_env="${infra_dir}/release.env"
compose_file="${infra_dir}/docker-compose.yml"

if [[ ! -s "${production_env}" ]]; then
  echo "Missing production environment file: ${production_env}" >&2
  exit 1
fi

if grep -Eq '(^|=)replace-with|example\.org' "${production_env}"; then
  echo "production.env still contains placeholder values." >&2
  exit 1
fi

if ! grep -qx 'PUBLIC_BIND_ADDRESS=0.0.0.0' "${production_env}"; then
  echo "PUBLIC_BIND_ADDRESS must be exactly 0.0.0.0 in production." >&2
  exit 1
fi

required_network_settings=(
  'API_PUBLIC_PORT=8080'
  'DASHBOARD_PUBLIC_PORT=3000'
  'GUIDELINES_PUBLIC_PORT=5000'
  'DASHBOARD_BASE_PATH=/admin'
)
for setting in "${required_network_settings[@]}"; do
  if ! grep -qxF "${setting}" "${production_env}"; then
    echo "production.env must contain ${setting}." >&2
    exit 1
  fi
done

umask 077
{
  printf 'API_IMAGE=ghcr.io/%s/mediguide-pos-api:%s\n' "${ghcr_owner}" "${release_version}"
  printf 'AI_WORKER_IMAGE=ghcr.io/%s/mediguide-pos-ai-worker:%s\n' "${ghcr_owner}" "${release_version}"
  printf 'DASHBOARD_IMAGE=ghcr.io/%s/mediguide-pos-dashboard:%s\n' "${ghcr_owner}" "${release_version}"
  printf 'GUIDELINES_IMAGE=ghcr.io/%s/mediguide-pos-guidelines:%s\n' "${ghcr_owner}" "${release_version}"
  printf 'BUILD_VERSION=%s\n' "${release_version}"
  printf 'BUILD_REVISION=%s\n' "${release_revision}"
} > "${release_env}"

compose=(
  docker compose
  --env-file "${production_env}"
  --env-file "${release_env}"
  -f "${compose_file}"
)

read_env_value() {
  local name="$1"
  sed -n "s/^${name}=//p" "${production_env}" | tail -n 1 | tr -d '\r'
}

public_api_base_url="$(read_env_value PUBLIC_API_BASE_URL)"
dashboard_public_url="$(read_env_value DASHBOARD_PUBLIC_URL)"
public_site_url="$(read_env_value PUBLIC_SITE_URL)"
public_site_url="${public_site_url:-${public_api_base_url}}"

for public_url in "${public_api_base_url}" "${dashboard_public_url}" "${public_site_url}"; do
  if [[ ! "${public_url}" =~ ^https?://[^[:space:]]+$ ]]; then
    echo "Production public route URLs must be absolute HTTP(S) URLs." >&2
    exit 1
  fi
  if [[ "${public_url}" =~ ^https?://(0\.0\.0\.0|127\.0\.0\.1|localhost)(:|/|$) ]]; then
    echo "Production public route URLs cannot use a local bind/listen address: ${public_url}" >&2
    exit 1
  fi
done

if [[ "${public_site_url}" != https://* || "${public_api_base_url}" != https://* || "${dashboard_public_url}" != https://* ]]; then
  echo "Production public route URLs must use HTTPS." >&2
  exit 1
fi

if [[ "${public_api_base_url%/}" != "${public_site_url%/}" ]]; then
  echo "PUBLIC_API_BASE_URL must equal PUBLIC_SITE_URL without an /api suffix." >&2
  exit 1
fi

if [[ "${dashboard_public_url%/}" != "${public_site_url%/}/admin/login" ]]; then
  echo "DASHBOARD_PUBLIC_URL must equal PUBLIC_SITE_URL plus /admin/login." >&2
  exit 1
fi

deployment_failure_diagnostics() {
  exit_code=$?
  trap - ERR
  set +e
  echo "Production deployment failed; collecting bounded service diagnostics." >&2
  "${compose[@]}" ps >&2
  "${compose[@]}" logs --no-color --tail 150 \
    postgres redis minio api dashboard guidelines ai-worker ai-worker-loop \
    ollama-pull-models >&2
  exit "${exit_code}"
}
trap deployment_failure_diagnostics ERR

echo "Validating MediGuide production Compose configuration."
"${compose[@]}" config --quiet

if [[ "${MEDIGUIDE_IMAGES_PRELOADED:-0}" != "1" ]]; then
  echo "Pulling immutable release images before stopping the running stack."
  pull_succeeded=false
  for attempt in {1..12}; do
    if "${compose[@]}" pull; then
      pull_succeeded=true
      break
    fi
    echo "Release image pull attempt ${attempt}/12 failed; retrying." >&2
    sleep 10
  done
  if [[ "${pull_succeeded}" != true ]]; then
    echo "Unable to pull the release images. The running stack was not modified." >&2
    exit 1
  fi
else
  echo "Using immutable release images preloaded and verified by the deployment workflow."
fi

echo "Removing existing MediGuide containers while preserving named volumes."
"${compose[@]}" down --remove-orphans --timeout 60

echo "Removing superseded MediGuide application images."
while IFS= read -r image_ref; do
  [[ -n "${image_ref}" ]] || continue
  case "${image_ref}" in
    "ghcr.io/${ghcr_owner}/mediguide-pos-api:${release_version}"|\
    "ghcr.io/${ghcr_owner}/mediguide-pos-ai-worker:${release_version}"|\
    "ghcr.io/${ghcr_owner}/mediguide-pos-dashboard:${release_version}"|\
    "ghcr.io/${ghcr_owner}/mediguide-pos-guidelines:${release_version}")
      continue
      ;;
  esac
  docker image rm "${image_ref}" || true
done < <(
  docker image ls --format '{{.Repository}}:{{.Tag}}' | \
    grep -E "^ghcr\.io/${ghcr_owner}/mediguide-pos-(api|ai-worker|dashboard|guidelines):" || true
)
docker image prune --force

echo "Applying database migrations."
"${compose[@]}" run --rm api /app/migrate up

echo "Starting the complete MediGuide stack and waiting for health checks."
"${compose[@]}" up --no-build -d --remove-orphans --wait --wait-timeout 600
"${compose[@]}" ps

verify_public_route() {
  local label="$1"
  local url="$2"
  local attempt

  for attempt in {1..12}; do
    if docker run --rm --network host curlimages/curl:8.14.1 \
      --fail --silent --show-error --location --max-time 15 "${url}" >/dev/null; then
      echo "Verified ${label}: ${url}"
      return 0
    fi
    if (( attempt < 12 )); then
      sleep 5
    fi
  done

  echo "Public route verification failed for ${label}: ${url}" >&2
  return 1
}

echo "Verifying browser-visible production routes through the configured origin."
verify_public_route "Guidelines" "${public_site_url%/}/healthz"
verify_public_route "Dashboard" "${dashboard_public_url%/}"
verify_public_route "API" "${public_api_base_url%/}/api/readyz"

asset_import_enabled="$(read_env_value GUIDELINE_ASSET_IMPORT_ENABLED)"
if [[ "${asset_import_enabled:-0}" == '1' ]]; then
  repository_dir="$(cd "${infra_dir}/.." && pwd)"
  asset_import_version_id="$(read_env_value GUIDELINE_ASSET_IMPORT_VERSION_ID)"
  asset_import_script="$(read_env_value GUIDELINE_ASSET_IMPORT_SCRIPT)"
  asset_import_manifest="$(read_env_value GUIDELINE_ASSET_IMPORT_MANIFEST)"
  asset_import_token_file="$(read_env_value GUIDELINE_ASSET_IMPORT_TOKEN_FILE)"
  asset_import_regenerate="$(read_env_value GUIDELINE_ASSET_IMPORT_REGENERATE)"
  asset_import_timeout="$(read_env_value GUIDELINE_ASSET_IMPORT_TIMEOUT_SECONDS)"

  if [[ "${asset_import_script}" != /* ]]; then
    asset_import_script="${repository_dir}/${asset_import_script}"
  fi
  if [[ "${asset_import_manifest}" != /* ]]; then
    asset_import_manifest="${repository_dir}/${asset_import_manifest}"
  fi
  if [[ -z "${asset_import_version_id}" || ! -x "${asset_import_script}" || ! -s "${asset_import_manifest}" || ! -s "${asset_import_token_file}" ]]; then
    echo "Guideline asset import is enabled but its script, draft version, manifest, or token file is unavailable." >&2
    exit 1
  fi

  asset_import_args=(
    --version-id "${asset_import_version_id}"
    --manifest "${asset_import_manifest}"
    --execute
  )
  if [[ "${asset_import_regenerate:-1}" == '1' ]]; then
    asset_import_args+=(--regenerate)
  fi
  echo "Running the opt-in governed guideline asset import."
  MEDIGUIDE_API_URL="${public_api_base_url}" \
  MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE="${asset_import_token_file}" \
  MEDIGUIDE_ASSET_IMPORT_TIMEOUT_SECONDS="${asset_import_timeout:-1800}" \
    "${asset_import_script}" "${asset_import_args[@]}"
fi

echo "MediGuide ${release_version} (${release_revision}) deployed successfully."
