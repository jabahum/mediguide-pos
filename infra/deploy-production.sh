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

if ! grep -qx 'PUBLIC_BIND_ADDRESS=127.0.0.1' "${production_env}"; then
  echo "PUBLIC_BIND_ADDRESS must be exactly 127.0.0.1 in production." >&2
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

echo "Validating MediGuide production Compose configuration."
"${compose[@]}" config --quiet

declare -A old_first_party_images=()
while IFS= read -r container_id; do
  [[ -n "${container_id}" ]] || continue
  image_ref="$(docker inspect --format '{{.Config.Image}}' "${container_id}")"
  case "${image_ref}" in
    ghcr.io/*/mediguide-pos-api:*|\
    ghcr.io/*/mediguide-pos-ai-worker:*|\
    ghcr.io/*/mediguide-pos-dashboard:*|\
    ghcr.io/*/mediguide-pos-guidelines:*|\
    mediguide-api:*|\
    mediguide-ai-worker:*|\
    mediguide-dashboard:*|\
    mediguide-guidelines:*)
      old_first_party_images["${image_ref}"]=1
      ;;
  esac
done < <(docker ps -aq --filter 'label=com.docker.compose.project=mediguide')

echo "Removing existing MediGuide containers while preserving named volumes."
"${compose[@]}" down --remove-orphans --timeout 60

if (( ${#old_first_party_images[@]} > 0 )); then
  echo "Removing previous MediGuide first-party images."
  for image_ref in "${!old_first_party_images[@]}"; do
    if ! docker image rm "${image_ref}"; then
      echo "Warning: ${image_ref} is still used elsewhere and was not removed." >&2
    fi
  done
fi

echo "Pulling immutable release images."
"${compose[@]}" pull

echo "Applying database migrations."
"${compose[@]}" run --rm api /app/migrate up

echo "Starting the complete MediGuide stack and waiting for health checks."
"${compose[@]}" up --no-build -d --remove-orphans --wait --wait-timeout 600
"${compose[@]}" ps

echo "MediGuide ${release_version} (${release_revision}) deployed successfully."
