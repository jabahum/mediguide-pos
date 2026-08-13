#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_tag="${1:-}"
mode="${2:-}"

if [[ -z "${release_tag}" ]]; then
  echo "Usage: bash scripts/check-release-readiness.sh vMAJOR.MINOR.PATCH [--metadata-only]" >&2
  exit 2
fi

if [[ ! "${release_tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid release tag '${release_tag}'. Expected vMAJOR.MINOR.PATCH." >&2
  exit 1
fi

mobile_version_line="$(grep -E '^version:[[:space:]]+' "${repository_root}/user_app/pubspec.yaml")"
mobile_version="${mobile_version_line#version: }"
mobile_semver="${mobile_version%%+*}"
expected_tag="v${mobile_semver}"

if [[ "${release_tag}" != "${expected_tag}" ]]; then
  echo "Release tag ${release_tag} does not match user_app version ${mobile_version}." >&2
  echo "Expected ${expected_tag}; bump user_app/pubspec.yaml first." >&2
  exit 1
fi

echo "Release metadata is consistent: ${release_tag} / mobile ${mobile_version}."

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
docker compose \
  --env-file infra/production.env.example \
  -f infra/docker-compose.yml \
  config --quiet

echo "Release preflight passed for ${release_tag}."
echo "The tag will publish GHCR image version ${release_tag#v}."
