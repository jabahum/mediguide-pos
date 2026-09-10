#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
  cat <<'EOF'
Upload governed guideline images, rewrite the target draft with environment-local
asset references, validate it, and optionally regenerate structured content.

Required environment:
  MEDIGUIDE_API_URL                    API origin (no /api suffix)
  MEDIGUIDE_ASSET_IMPORT_TOKEN         short-lived token with asset, Markdown,
                                       validation and regeneration permissions
    or
  MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE    readable file containing that token

Usage:
  import-guideline-assets.sh --version-id UUID --manifest FILE [--execute] [--regenerate]

The default is a read-only preflight. --execute uploads and saves the draft.
--regenerate also queues regeneration and waits for completion. This command
never reviews blocks/assets, accepts regeneration, or publishes a guideline.
EOF
}

version_id=''
manifest_path=''
execute=false
regenerate=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version-id) version_id="${2:-}"; shift 2 ;;
    --manifest) manifest_path="${2:-}"; shift 2 ;;
    --execute) execute=true; shift ;;
    --regenerate) regenerate=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! "$version_id" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ || -z "$manifest_path" ]]; then
  usage >&2
  exit 2
fi
if [[ ! -f "$manifest_path" ]]; then
  printf 'Asset manifest does not exist: %s\n' "$manifest_path" >&2
  exit 2
fi
for command_name in curl jq mktemp; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s is required.\n' "$command_name" >&2
    exit 2
  fi
done

if [[ -n "${MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE:-}" ]]; then
  if [[ ! -s "$MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE" ]]; then
    printf 'Token file is missing or empty: %s\n' "$MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE" >&2
    exit 2
  fi
  import_token="$(tr -d '\r\n' < "$MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE")"
else
  import_token="${MEDIGUIDE_ASSET_IMPORT_TOKEN:-}"
fi
if [[ -z "${MEDIGUIDE_API_URL:-}" || -z "$import_token" ]]; then
  printf 'MEDIGUIDE_API_URL and an asset import token are required.\n' >&2
  exit 2
fi

schema_version="$(jq -r '.schema_version // empty' "$manifest_path")"
asset_count="$(jq -r 'if (.assets | type) == "array" then (.assets | length) else -1 end' "$manifest_path")"
if [[ "$schema_version" != '1' || "$asset_count" -lt 1 ]]; then
  printf 'Manifest must use schema_version 1 and contain at least one asset.\n' >&2
  exit 2
fi
missing_source_count="$(jq -r 'if (.missing_sources | type) == "array" then (.missing_sources | length) else 0 end' "$manifest_path")"
if (( missing_source_count > 0 )); then
  printf 'Warning: manifest records %d authoritative source file(s) that remain unavailable and will not be substituted.\n' \
    "$missing_source_count" >&2
fi

manifest_dir="$(cd "$(dirname "$manifest_path")" && pwd)"
api_url="${MEDIGUIDE_API_URL%/}"
authorization="Authorization: Bearer ${import_token}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/mediguide-asset-import.XXXXXX")"
cleanup() { rm -rf "$work_dir"; }
trap cleanup EXIT

draft_response="$work_dir/draft.json"
assets_response="$work_dir/assets.json"
curl --fail-with-body --silent --show-error -H "$authorization" \
  "$api_url/api/v2/guideline-versions/$version_id/markdown-draft" -o "$draft_response"
curl --fail-with-body --silent --show-error -H "$authorization" \
  "$api_url/api/v2/guideline-versions/$version_id/assets" -o "$assets_response"

draft_status="$(jq -r '(.data // .).revision.publication_state // empty' "$draft_response")"
if [[ "$draft_status" == 'published' || "$draft_status" == 'superseded' ]]; then
  printf 'Refusing to modify immutable %s revision; create a new draft version.\n' "$draft_status" >&2
  exit 1
fi

printf 'Preflight: version=%s assets=%s manifest=%s\n' "$version_id" "$asset_count" "$manifest_path"
missing_files=0
while IFS= read -r encoded_asset; do
  asset="$(printf '%s' "$encoded_asset" | base64 --decode)"
  relative_file="$(jq -r '.file // empty' <<<"$asset")"
  markdown_path="$(jq -r '.markdown_path // empty' <<<"$asset")"
  if [[ -z "$relative_file" || -z "$markdown_path" || "$relative_file" == /* ]]; then
    printf 'Each asset requires a relative file and markdown_path.\n' >&2
    exit 1
  fi
  source_file="$manifest_dir/$relative_file"
  if [[ ! -s "$source_file" ]]; then
    printf 'Missing asset source: %s\n' "$source_file" >&2
    missing_files=$((missing_files + 1))
  fi
done < <(jq -r '.assets[] | @base64' "$manifest_path")
if (( missing_files > 0 )); then
  printf 'Preflight failed: %d asset source file(s) are missing.\n' "$missing_files" >&2
  exit 1
fi
if [[ "$execute" != true ]]; then
  printf 'Dry run complete. Re-run with --execute after checking the target and manifest.\n'
  exit 0
fi

jq -r '(.data // .).content' "$draft_response" > "$work_dir/current.md"
cp "$work_dir/current.md" "$work_dir/updated.md"
: > "$work_dir/replacements.jsonl"
uploaded=0
reused=0

checksum_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf 'sha256sum or shasum is required.\n' >&2
    return 2
  fi
}

while IFS= read -r encoded_asset; do
  asset="$(printf '%s' "$encoded_asset" | base64 --decode)"
  relative_file="$(jq -r '.file' <<<"$asset")"
  markdown_path="$(jq -r '.markdown_path' <<<"$asset")"
  source_file="$manifest_dir/$relative_file"
  # The manifest's Markdown filename is the stable cross-environment identity.
  # Source files may retain extraction-specific names (for example, a leading
  # figure number), while uploaded assets use the curated Markdown filename.
  filename="$(basename "$markdown_path")"
  checksum="$(checksum_file "$source_file")"
  reference="$(jq -r --arg checksum "$checksum" --arg filename "$filename" \
    '[(.data // .).items[] | select(.checksum == $checksum and .original_filename == $filename)][0].reference // empty' \
    "$assets_response")"

  if [[ -n "$reference" ]]; then
    reused=$((reused + 1))
  else
    upload_response="$work_dir/upload-$uploaded.json"
    curl --fail-with-body --silent --show-error -X POST -H "$authorization" \
      -F "file=@$source_file;filename=$filename" \
      -F "alternative_text=$(jq -r '.alternative_text // empty' <<<"$asset")" \
      -F "caption=$(jq -r '.caption // empty' <<<"$asset")" \
      -F "source=$(jq -r '.source // empty' <<<"$asset")" \
      -F "attribution=$(jq -r '.attribution // empty' <<<"$asset")" \
      -F "license=$(jq -r '.license // empty' <<<"$asset")" \
      -F "clinically_sensitive=$(jq -r '.clinically_sensitive // true' <<<"$asset")" \
      "$api_url/api/v2/guideline-versions/$version_id/assets" -o "$upload_response"
    reference="$(jq -r '(.data // .).reference // empty' "$upload_response")"
    if [[ -z "$reference" ]]; then
      printf 'Upload did not return an asset reference for %s.\n' "$filename" >&2
      exit 1
    fi
    uploaded=$((uploaded + 1))
  fi

  if ! grep -Fq "$markdown_path" "$work_dir/updated.md" && \
     ! grep -Fq "$reference" "$work_dir/updated.md"; then
    printf 'Draft contains neither %s nor its environment asset reference.\n' "$markdown_path" >&2
    exit 1
  fi
  jq -cn --arg from "$markdown_path" --arg to "$reference" '{from:$from,to:$to}' \
    >> "$work_dir/replacements.jsonl"
done < <(jq -r '.assets[] | @base64' "$manifest_path")

jq -s '.' "$work_dir/replacements.jsonl" > "$work_dir/replacements.json"
jq -Rnj --rawfile content "$work_dir/updated.md" --slurpfile replacements "$work_dir/replacements.json" \
  '$content | reduce $replacements[0][] as $replacement (. ; split($replacement.from) | join($replacement.to))' \
  > "$work_dir/rewritten.md"
mv "$work_dir/rewritten.md" "$work_dir/updated.md"

if cmp -s "$work_dir/current.md" "$work_dir/updated.md"; then
  revision_id="$(jq -r '(.data // .).revision.id' "$draft_response")"
  structured_status="$(jq -r '(.data // .).revision.structured_content_status // empty' "$draft_response")"
  markdown_changed=false
  printf 'All assets were already uploaded and referenced; no Markdown save was needed.\n'
else
  etag="$(jq -r '(.data // .).etag' "$draft_response")"
  jq -n --rawfile content "$work_dir/updated.md" --arg expected_revision "$etag" \
    '{content:$content,expected_revision:$expected_revision,checkpoint_name:"Production guideline asset import",change_summary:"Imported governed guideline images and replaced source paths with environment-local asset references.",source_type:"manual_edit"}' \
    > "$work_dir/save.json"
  curl --fail-with-body --silent --show-error -X PUT -H "$authorization" \
    -H 'Content-Type: application/json' --data-binary "@$work_dir/save.json" \
    "$api_url/api/v2/guideline-versions/$version_id/markdown-draft" -o "$work_dir/saved.json"
  revision_id="$(jq -r '(.data // .).revision.id // empty' "$work_dir/saved.json")"
  if [[ -z "$revision_id" ]]; then
    printf 'Markdown save did not return a revision ID.\n' >&2
    exit 1
  fi
  structured_status='outdated'
  markdown_changed=true
fi

validation_response="$work_dir/validation.json"
curl --fail-with-body --silent --show-error -H "$authorization" \
  "$api_url/api/v2/guideline-versions/$version_id/markdown-revisions/$revision_id/validation" \
  -o "$validation_response"
validation_valid="$(jq -r '(.data // .).valid' "$validation_response")"
validation_errors="$(jq -r '(.data // .).errors' "$validation_response")"
validation_warnings="$(jq -r '(.data // .).warnings' "$validation_response")"
printf 'Imported assets: uploaded=%d reused=%d revision=%s validation_errors=%s validation_warnings=%s\n' \
  "$uploaded" "$reused" "$revision_id" "$validation_errors" "$validation_warnings"
if [[ "$validation_valid" != true ]]; then
  jq -r '(.data // .).issues[] | select(.severity == "error") | "[\(.code)] line \(.line): \(.message)"' \
    "$validation_response" >&2
  exit 1
fi

if [[ "$regenerate" != true ]]; then
  printf 'Import complete. Regeneration was not requested.\n'
  exit 0
fi

if [[ "$markdown_changed" != true ]]; then
  case "$structured_status" in
    review_required|approved|queued|processing)
      printf 'Structured content is already %s for this unchanged revision; regeneration was skipped.\n' "$structured_status"
      exit 0
      ;;
  esac
fi

jq -cn --arg revision_id "$revision_id" --arg key "asset-import-$revision_id" \
  '{revision_id:$revision_id,idempotency_key:$key}' > "$work_dir/regenerate.json"
curl --fail-with-body --silent --show-error -X POST -H "$authorization" \
  -H 'Content-Type: application/json' --data-binary "@$work_dir/regenerate.json" \
  "$api_url/api/v2/guideline-versions/$version_id/regenerate" -o "$work_dir/job-created.json"
job_id="$(jq -r '(.data // .).job.id // empty' "$work_dir/job-created.json")"
if [[ -z "$job_id" ]]; then
  printf 'Regeneration did not return a job ID.\n' >&2
  exit 1
fi

deadline=$((SECONDS + ${MEDIGUIDE_ASSET_IMPORT_TIMEOUT_SECONDS:-1800}))
job_state='queued'
while (( SECONDS < deadline )); do
  curl --fail-with-body --silent --show-error -H "$authorization" \
    "$api_url/api/v2/guideline-versions/$version_id/regeneration-jobs/$job_id" \
    -o "$work_dir/job.json"
  job_state="$(jq -r '(.data // .).job.status' "$work_dir/job.json")"
  job_progress="$(jq -r '(.data // .).job.progress_percent' "$work_dir/job.json")"
  printf 'Regeneration: %s (%s%%)\n' "$job_state" "$job_progress"
  case "$job_state" in
    completed) break ;;
    failed|canceled|superseded)
      printf 'Regeneration stopped with status %s. Nothing was reviewed or published.\n' "$job_state" >&2
      exit 1
      ;;
  esac
  sleep 5
done
if [[ "$job_state" != 'completed' ]]; then
  printf 'Timed out waiting for regeneration. The saved draft remains unpublished.\n' >&2
  exit 1
fi

printf 'Asset import and regeneration completed. STOP: authorized humans must review figures and other high-risk blocks, accept this job, and publish explicitly.\n'
