#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
development_env="${repo_root}/infra/development.env"
staging_env="${repo_root}/infra/staging.env.example"
production_env="${repo_root}/infra/production.env.example"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

extract_keys() {
  local source_file="$1"
  local destination_file="$2"

  awk -F= '
    /^[A-Za-z_][A-Za-z0-9_]*=/ { print $1 }
  ' "${source_file}" | sort > "${destination_file}"
}

validate_file() {
  local source_file="$1"
  local duplicate_keys
  local firebase_value

  duplicate_keys="$({
    awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/ { print $1 }' "${source_file}" |
      sort |
      uniq -d
  } || true)"
  if [[ -n "${duplicate_keys}" ]]; then
    echo "${source_file} contains duplicate environment keys:" >&2
    echo "${duplicate_keys}" >&2
    return 1
  fi

  firebase_value="$(awk -F= '$1 == "FIREBASE_SERVICE_ACCOUNT_BASE64" { sub(/^[^=]*=/, ""); print; exit }' "${source_file}")"
  if [[ "${firebase_value}" == *.json || "${firebase_value}" == *.base64 ]]; then
    echo "${source_file}: FIREBASE_SERVICE_ACCOUNT_BASE64 must contain encoded data, not a filename." >&2
    return 1
  fi
}

for source_file in "${development_env}" "${staging_env}" "${production_env}"; do
  validate_file "${source_file}"
done

extract_keys "${development_env}" "${tmp_dir}/development.keys"
extract_keys "${staging_env}" "${tmp_dir}/staging.keys"
extract_keys "${production_env}" "${tmp_dir}/production.keys"

for environment_name in staging production; do
  if ! diff -u "${tmp_dir}/development.keys" "${tmp_dir}/${environment_name}.keys"; then
    echo "Infrastructure environment schema mismatch: development vs ${environment_name}." >&2
    exit 1
  fi
done

# When ignored deployment files exist locally, validate their keys as well
# without reading or printing secret values.
for environment_name in staging production; do
  local_env="${repo_root}/infra/${environment_name}.env"
  if [[ -f "${local_env}" ]]; then
    validate_file "${local_env}"
    extract_keys "${local_env}" "${tmp_dir}/${environment_name}.local.keys"
    if ! diff -u "${tmp_dir}/development.keys" "${tmp_dir}/${environment_name}.local.keys"; then
      echo "Local ${environment_name}.env does not match the canonical environment schema." >&2
      exit 1
    fi
  fi
done

rg -o '\$\{[A-Za-z_][A-Za-z0-9_]*' \
  "${repo_root}/infra/docker-compose.yml" \
  "${repo_root}/infra/docker-compose.dev.yml" |
  sed 's/.*${//' |
  sort -u > "${tmp_dir}/compose.keys"

if missing_keys="$(comm -23 "${tmp_dir}/compose.keys" "${tmp_dir}/development.keys")" &&
  [[ -n "${missing_keys}" ]]; then
  echo "Compose references variables absent from the infrastructure environment schema:" >&2
  echo "${missing_keys}" >&2
  exit 1
fi

echo "Infrastructure environment schemas are aligned."
