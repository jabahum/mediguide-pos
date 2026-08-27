#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_tag="${1:-}"
mode="${2:-}"

if [[ -z "${release_tag}" ]]; then
  echo "Usage: bash scripts/check-release-readiness.sh vMAJOR.MINOR.PATCH [--metadata-only]" >&2
  exit 2
fi

if [[ ! "${release_tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid release tag '${release_tag}'. Expected vMAJOR.MINOR.PATCH." >&2
  exit 1
fi

mobile_version_line="$(grep -E '^version:[[:space:]]+' "${repository_root}/user_app/pubspec.yaml")"
mobile_version="${mobile_version_line#version: }"
mobile_semver="${mobile_version%%+*}"
mobile_build_number="${mobile_version##*+}"
platform_version="$(tr -d '[:space:]' < "${repository_root}/VERSION")"
expected_tag="v${platform_version}"

if [[ "${release_tag}" != "${expected_tag}" ]]; then
  echo "Release tag ${release_tag} does not match VERSION (${platform_version})." >&2
  echo "Expected ${expected_tag}; run make release-prepare RELEASE_TAG=${release_tag}." >&2
  exit 1
fi

if [[ "${mobile_semver}" != "${platform_version}" ]]; then
  echo "user_app version ${mobile_version} does not match VERSION (${platform_version})." >&2
  exit 1
fi

if [[ "${mobile_build_number}" == "${mobile_version}" || ! "${mobile_build_number}" =~ ^[1-9][0-9]*$ ]]; then
  echo "user_app version ${mobile_version} has an invalid Flutter build number." >&2
  exit 1
fi

json_version() {
  sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

assert_version() {
  local component="$1"
  local actual="$2"
  if [[ "${actual}" != "${platform_version}" ]]; then
    echo "${component} version ${actual:-<missing>} does not match VERSION (${platform_version})." >&2
    echo "Run make release-prepare RELEASE_TAG=${release_tag}." >&2
    exit 1
  fi
}

assert_version "dashboard" "$(json_version "${repository_root}/dashboard/package.json")"
assert_version "guidelines-platform" "$(json_version "${repository_root}/guidelines-platform/package.json")"
assert_version "guidelines-platform lockfile" "$(json_version "${repository_root}/guidelines-platform/package-lock.json")"
assert_version "ai-worker" "$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "${repository_root}/ai-worker/pyproject.toml" | head -n 1)"
assert_version "ai-worker lockfile" "$(awk '/^name = "mediguide-ai-worker"$/ { getline; gsub(/^version = "|"$/, ""); print; exit }' "${repository_root}/ai-worker/uv.lock")"
assert_version "backend Swagger source" "$(sed -n 's|^// @version[[:space:]]*||p' "${repository_root}/backend/cmd/api/main.go" | head -n 1)"
assert_version "backend generated Swagger JSON" "$(json_version "${repository_root}/backend/docs/swagger.json")"
assert_version "backend generated Swagger YAML" "$(sed -n 's/^  version:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}.*/\1/p' "${repository_root}/backend/docs/swagger.yaml" | head -n 1)"

tracked_generated_dart_files="$(git -C "${repository_root}" ls-files '*.g.dart' '*.freezed.dart')"
if [[ -n "${tracked_generated_dart_files}" ]]; then
  echo "Generated *.g.dart and *.freezed.dart files must not be committed:" >&2
  printf '%s\n' "${tracked_generated_dart_files}" >&2
  exit 1
fi

echo "Release metadata is consistent: ${release_tag} / mobile ${mobile_version} / all services ${platform_version}."

if [[ "${mode}" == "--metadata-only" ]]; then
  exit 0
fi

cd "${repository_root}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "The worktree is not clean. Commit or intentionally stash release changes first." >&2
  exit 1
fi

tag_commit="$(git rev-parse -q --verify "refs/tags/${release_tag}^{commit}" 2>/dev/null || true)"
if [[ -n "${tag_commit}" && "${tag_commit}" != "$(git rev-parse HEAD)" ]]; then
  echo "Existing tag ${release_tag} points to ${tag_commit}, not HEAD." >&2
  exit 1
fi

contained_in_main=false
for main_ref in refs/remotes/upstream/main refs/remotes/origin/main refs/heads/main; do
  if git show-ref --verify --quiet "${main_ref}" && git merge-base --is-ancestor HEAD "${main_ref}"; then
    contained_in_main=true
    break
  fi
done
if [[ "${contained_in_main}" != true ]]; then
  echo "HEAD is not contained in a known main branch. Fetch and merge the release commit first." >&2
  exit 1
fi

docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  config --quiet
bash scripts/check-infra-env-parity.sh
docker compose \
  --env-file infra/staging.env.example \
  -f infra/docker-compose.yml \
  config --quiet
docker compose \
  --env-file infra/production.env.example \
  -f infra/docker-compose.yml \
  config --quiet

echo "Release preflight passed for ${release_tag}."
echo "The tag will publish GHCR image version ${release_tag#v}."
