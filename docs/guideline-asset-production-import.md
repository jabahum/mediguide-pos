# Production guideline asset import

Use `scripts/import-guideline-assets.sh` to promote repository-owned guideline
images into an editable version in a target environment. The importer always
uses the authenticated guideline asset and Markdown APIs. It never writes
directly to MinIO or PostgreSQL.

## Safety contract

- The target must be an editable draft version. Published and superseded
  revisions are rejected.
- Asset IDs are created in the target environment. Never copy
  `guideline-asset://` UUIDs from development into production.
- Existing target assets are reused only when their SHA-256 checksum and
  original filename both match.
- Markdown is saved with its current ETag. A concurrent editor causes a safe
  conflict instead of being overwritten.
- Validation must have zero errors before optional regeneration starts.
- The importer never reviews assets or blocks, accepts a regeneration review,
  or publishes a guideline. Those remain explicit human decisions.

The command needs Bash, `curl`, `jq`, `mktemp`, `base64`, and either
`sha256sum` or `shasum`.

## Manual preflight and execution

Create a short-lived token with guideline asset management, Markdown editing,
Markdown validation, and structure-regeneration permissions. Store it in a
mode-`0600` file outside the repository.

Run a read-only preflight first:

```bash
MEDIGUIDE_API_URL=https://mediguide.health.go.ug \
MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE=/run/secrets/mediguide-guideline-asset-import.token \
./scripts/import-guideline-assets.sh \
  --version-id TARGET_DRAFT_VERSION_UUID \
  --manifest scripts/manifests/ucg-2023-assets.json
```

Then import and regenerate:

```bash
MEDIGUIDE_API_URL=https://mediguide.health.go.ug \
MEDIGUIDE_ASSET_IMPORT_TOKEN_FILE=/run/secrets/mediguide-guideline-asset-import.token \
./scripts/import-guideline-assets.sh \
  --version-id TARGET_DRAFT_VERSION_UUID \
  --manifest scripts/manifests/ucg-2023-assets.json \
  --execute --regenerate
```

The command is restart-safe. If every file is already uploaded and referenced,
it performs no Markdown save. It also skips regeneration when the unchanged
revision is already queued, processing, awaiting review, or approved.

## Opt-in production startup hook

Set these values in `infra/production.env` only for the deployment that should
perform the import:

```dotenv
GUIDELINE_ASSET_IMPORT_ENABLED=1
GUIDELINE_ASSET_IMPORT_VERSION_ID=TARGET_DRAFT_VERSION_UUID
GUIDELINE_ASSET_IMPORT_SCRIPT=asset-import/scripts/import-guideline-assets.sh
GUIDELINE_ASSET_IMPORT_MANIFEST=asset-import/scripts/manifests/ucg-2023-assets.json
GUIDELINE_ASSET_IMPORT_TOKEN_FILE=/run/secrets/mediguide-guideline-asset-import.token
GUIDELINE_ASSET_IMPORT_REGENERATE=1
GUIDELINE_ASSET_IMPORT_TIMEOUT_SECONDS=1800
```

`infra/deploy-production.sh` runs the importer only after the API, dashboard,
and public site are healthy. Set `GUIDELINE_ASSET_IMPORT_ENABLED=0` again after
the successful one-time import and remove the expired token file.

An import failure makes the deployment command fail visibly, but it does not
approve or publish partially imported content. Rerun the same manifest after
correcting the problem.

## UCG manifest status

`scripts/manifests/ucg-2023-assets.json` contains the 51 authoritative UCG
images currently present in the repository. The manifest records, but does not
substitute, the missing image:

```text
images/chapter-17-weight-for-height-girls-2-to-5-years.png
```

Obtain that file from the authoritative publication, add it to the appropriate
UCG source directory and manifest, and rerun the importer. Do not fabricate a
clinical growth chart.

After regeneration, an authorized reviewer must inspect the figures and every
other pending high-risk block, accept the exact regeneration job, validate the
publication, and explicitly publish the new version.
