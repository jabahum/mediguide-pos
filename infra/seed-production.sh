#!/usr/bin/env bash

set -Eeuo pipefail

scope="${1:-}"
reset_password="${2:-false}"

if [[ "${scope}" != "admin" && "${scope}" != "facilities" ]]; then
  echo "Usage: CONFIRM_PRODUCTION_SEED=SEED_PRODUCTION $0 admin|facilities [true|false]" >&2
  exit 2
fi
if [[ "${reset_password}" != "true" && "${reset_password}" != "false" ]]; then
  echo "The reset-password argument must be true or false." >&2
  exit 2
fi
if [[ "${scope}" != "admin" && "${reset_password}" == "true" ]]; then
  echo "Password reset is valid only for the admin scope." >&2
  exit 2
fi
if [[ "${CONFIRM_PRODUCTION_SEED:-}" != "SEED_PRODUCTION" ]]; then
  echo "Set CONFIRM_PRODUCTION_SEED=SEED_PRODUCTION to confirm this production mutation." >&2
  exit 2
fi

infra_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
production_env="${infra_dir}/production.env"
release_env="${infra_dir}/release.env"
compose_file="${infra_dir}/docker-compose.yml"

for required_file in "${production_env}" "${release_env}" "${compose_file}"; do
  if [[ ! -s "${required_file}" ]]; then
    echo "Missing required production deployment file: ${required_file}" >&2
    exit 1
  fi
done
if ! grep -qx 'APP_ENV=production' "${production_env}"; then
  echo "Refusing to seed because APP_ENV=production is not configured." >&2
  exit 1
fi
if [[ "${scope}" == "admin" ]]; then
  for variable in DEFAULT_ADMIN_EMAIL DEFAULT_ADMIN_PASSWORD; do
    if ! grep -Eq "^${variable}=.+" "${production_env}"; then
      echo "${variable} must be configured in production.env." >&2
      exit 1
    fi
  done
fi

compose=(
  docker compose
  --env-file "${production_env}"
  --env-file "${release_env}"
  -f "${compose_file}"
)

"${compose[@]}" config --quiet
if ! "${compose[@]}" ps --status running --services | grep -qx 'postgres'; then
  echo "The production PostgreSQL service is not running." >&2
  exit 1
fi

backup_dir="${infra_dir}/backups"
backup_path="${backup_dir}/pre-seed-${scope}-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"
umask 077
mkdir -p "${backup_dir}"

echo "Creating pre-seed PostgreSQL backup: ${backup_path}"
"${compose[@]}" exec -T postgres sh -eu -c \
  'pg_dump --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --no-owner --no-privileges' \
  | gzip > "${backup_path}"
test -s "${backup_path}"

seed_args=(run --rm -e "SEED_SCOPE=${scope}")
if [[ "${reset_password}" == "true" ]]; then
  seed_args+=(-e SEED_ADMIN_RESET_PASSWORD=true)
fi
seed_args+=(api /app/seed)

echo "Running idempotent production ${scope} seed."
"${compose[@]}" "${seed_args[@]}"
echo "Production ${scope} seed completed. Backup retained at ${backup_path}."
