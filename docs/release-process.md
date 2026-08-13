# MediGuide platform release process

This runbook releases the backend, AI worker, dashboard, public guidelines
site, and Flutter clients from one immutable Git tag. It does not restart or
modify production by itself.

## Release model

Use one SemVer tag in the form `vMAJOR.MINOR.PATCH`. The tag must match the
SemVer part of `user_app/pubspec.yaml`; the Flutter build number remains after
the `+` and must increase for every store upload.

For example, the current mobile version `2.0.15+42` is released with Git tag
`v2.0.15`. That tag produces these immutable container tags:

- `ghcr.io/<owner>/mediguide-pos-api:2.0.15`
- `ghcr.io/<owner>/mediguide-pos-ai-worker:2.0.15`
- `ghcr.io/<owner>/mediguide-pos-dashboard:2.0.15`
- `ghcr.io/<owner>/mediguide-pos-guidelines:2.0.15`

The AI HTTP service and background loop intentionally use the same AI-worker
image. PostgreSQL, Redis, MinIO, Ollama, and the Ollama model-pull helper are
third-party infrastructure images and are not republished to GHCR.

The private dashboard and AI-worker package versions are not release inputs.
Do not run the standalone `guidelines-platform` `npm version` scripts for a
monorepo release; the repository tag is the platform source of truth.

## One-time GitHub setup

Repository Actions must have permission to write packages and releases. The
container workflow uses its scoped `GITHUB_TOKEN` for GHCR. Set these repository
variables to real public endpoints before tagging:

```bash
gh variable set PUBLIC_API_BASE_URL --body 'https://api.example.org'
gh variable set MOBILE_API_BASE_URL --body 'https://api.example.org'
```

Create a long-lived Android upload key once, store it outside the repository,
and back it up securely. Losing this key can prevent future application updates.

```bash
keytool -genkeypair -v \
  -keystore mediguide-upload.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias mediguide-upload

openssl base64 -A -in mediguide-upload.jks | \
  gh secret set ANDROID_UPLOAD_KEYSTORE_BASE64
printf '%s' '<store-password>' | gh secret set ANDROID_UPLOAD_STORE_PASSWORD
printf '%s' 'mediguide-upload' | gh secret set ANDROID_UPLOAD_KEY_ALIAS
printf '%s' '<key-password>' | gh secret set ANDROID_UPLOAD_KEY_PASSWORD
```

Never commit the keystore or `android/key.properties`; both are ignored. Tag
builds fail closed when any Android signing secret is absent. Manual dispatches
may still create a debug-signed internal build.

Apple artifacts are currently compile-verified but unsigned. A distributable
iOS IPA still requires an Apple Distribution certificate, provisioning profile,
App Store Connect API credentials, an export-options file, and a dedicated
signed/notarized workflow. Do not submit the unsigned ZIP to the App Store or
describe it as an installable iOS release.

## Prepare the release

1. Choose the version and bump `user_app/pubspec.yaml`. Increment both the
   SemVer and build number as appropriate. For the current candidate, keep
   `version: 2.0.15+42` and use `v2.0.15`.
2. Update user-facing release notes and any migration or operational notes.
3. Merge the release commit into the canonical `main` branch.
4. Fetch `main` and all existing tags from the canonical remote. This checkout
   currently calls that remote `upstream`; confirm with `git remote -v`.

```bash
git fetch upstream main --tags --prune
git switch main
git pull --ff-only upstream main
git status --short
make release-check RELEASE_TAG=v2.0.15
```

The final status command must be empty. The release check validates the mobile
version, clean Git state, reachability from a known `main`, existing-tag safety,
and development and production Compose rendering.

Run the complete gates locally when the required SDKs are available:

```bash
make contracts-check

(cd backend && go test ./... && go vet ./... && go build ./...)
(cd ai-worker && python3 -m pytest)

(cd dashboard && \
  bun install --frozen-lockfile && \
  bun audit --production && \
  bun run lint && bun run typecheck && bun run test && bun run build)

(cd guidelines-platform && \
  npm ci && npm audit --omit=dev && \
  npm run lint && npm run test && npm run build)

(cd user_app && \
  fvm flutter pub get && \
  fvm dart run build_runner build --delete-conflicting-outputs && \
  fvm dart format --output=none --set-exit-if-changed lib test && \
  fvm flutter analyze && \
  fvm flutter test && \
  fvm flutter build appbundle --release \
    --dart-define=MEDIGUIDE_API_BASE_URL=https://api.example.org)

docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  config --quiet
docker compose \
  --env-file infra/production.env.example \
  -f infra/docker-compose.yml \
  config --quiet
```

Use Node 22 for the guidelines build and the pinned Flutter 3.44.8 from
`user_app/.fvmrc`. Warnings should be reviewed and recorded, but any error,
failed test, generated-file drift, or failed build blocks the tag.

## Create and push the release tag

Create the tag only from the verified `main` commit. A signed tag is preferred;
use an annotated tag only when signing is not configured.

```bash
git tag -s v2.0.15 -m 'MediGuide v2.0.15'
# Fallback: git tag -a v2.0.15 -m 'MediGuide v2.0.15'
git show --no-patch --decorate v2.0.15
git push upstream refs/tags/v2.0.15
```

Never move, delete, or reuse a published release tag. Fix a bad release with a
new patch version and a higher Flutter build number.

The tag starts two workflows:

- `Build and publish container images` tests the platform and publishes four
  GHCR packages with `2.0.15`, `2.0`, `2`, and `sha-*` tags, provenance, and an
  SBOM.
- `Test and build mobile release` verifies generated code, analyzes and tests
  Flutter, builds signed Android APK/AAB, Flutter web, unsigned iOS, and macOS,
  then creates a GitHub Release with a manifest and SHA-256 checksums.

Monitor both workflows and do not deploy while either is incomplete:

```bash
release_sha="$(git rev-list -n 1 v2.0.15)"
gh run list --commit "${release_sha}" --limit 10
gh run watch <run-id> --exit-status
gh release view v2.0.15
```

Confirm all four immutable images exist. GHCR SemVer tags omit the leading `v`:

```bash
owner='<lowercase-github-owner>'
for image in api ai-worker dashboard guidelines; do
  docker buildx imagetools inspect \
    "ghcr.io/${owner}/mediguide-pos-${image}:2.0.15"
done
```

Download the release, then verify its checksums before distribution:

```bash
mkdir -p /tmp/mediguide-v2.0.15
gh release download v2.0.15 --dir /tmp/mediguide-v2.0.15
(cd /tmp/mediguide-v2.0.15 && sha256sum --check SHA256SUMS)
```

On macOS, use `shasum -a 256 -c SHA256SUMS` if GNU `sha256sum` is unavailable.

## Deploy immutable images

Prepare `infra/production.env` outside Git. Replace every placeholder and pin
the four first-party images to the exact released version, never `latest`:

```dotenv
API_IMAGE=ghcr.io/<owner>/mediguide-pos-api:2.0.15
AI_WORKER_IMAGE=ghcr.io/<owner>/mediguide-pos-ai-worker:2.0.15
DASHBOARD_IMAGE=ghcr.io/<owner>/mediguide-pos-dashboard:2.0.15
GUIDELINES_IMAGE=ghcr.io/<owner>/mediguide-pos-guidelines:2.0.15
BUILD_VERSION=v2.0.15
BUILD_REVISION=<full-tagged-git-sha>
```

Also verify database, JWT, SMTP, object-storage, CORS, public URL, Redis, model,
and trusted-proxy values. Log in to GHCR with a read-packages token if packages
are private:

```bash
printf '%s' "${GHCR_TOKEN}" | docker login ghcr.io \
  --username '<github-user>' --password-stdin
```

Before changing a running environment, announce the maintenance window, take
tested PostgreSQL and MinIO backups, and record the current image digests. Then:

```bash
compose='docker compose --env-file infra/production.env -f infra/docker-compose.yml'

$compose config --quiet
$compose pull api ai-worker dashboard guidelines
$compose run --rm api /app/migrate up
$compose up --no-build -d --remove-orphans
$compose ps
```

The API container also runs migrations before starting, but the explicit step
makes migration failure visible before application replacement. Review logs and
health endpoints:

```bash
$compose logs --since=10m api ai-worker ai-worker-loop dashboard guidelines
curl --fail --silent https://api.example.org/api/readyz
curl --fail --silent https://admin.example.org/
curl --fail --silent https://guidelines.example.org/healthz
```

Perform smoke tests for login/session refresh, a public guideline, dashboard
CRUD, PDF/Markdown reading, AI retrieval, object upload, background ingestion,
and one signed Android installation. Confirm that the deployed image digests
match those inspected in GHCR.

## Rollback and incident handling

Application rollback means restoring the previous four immutable image tags in
`infra/production.env`, running `pull`, and running `up --no-build -d` again.
Do not roll database migrations down automatically: first determine whether the
migration is backward compatible and restore from the verified backup when it
is not. Retain failed release logs, digests, migration output, and health-check
evidence. Publish the fix under a new patch tag.

## Current readiness snapshot (2026-08-13)

- No release tags existed locally before this work.
- `release-apps` pointed at the same commit as `upstream/main`, and the worktree
  was initially clean.
- Development and production Compose files render successfully.
- Backend tests, vet, and build pass locally.
- Dashboard lint has no errors but reports existing warnings; typecheck and 60
  tests pass. The production build passes on the patched Next.js 16.2.11 line.
- Dashboard and guidelines production dependency audits report zero known
  vulnerabilities after targeted lockfile/security updates.
- Guidelines clean-install lint, 27 tests, and production build pass under the
  required Node 22 container runtime.
- AI-worker has 54 passing tests under the release Python 3.12 image.
- Flutter analysis, the 85-case full-screen visual matrix, all 209 tests, and a
  release APK compile pass with Flutter 3.44.8. The local APK used fallback
  debug signing; tag CI fails unless the real upload-key secrets are configured.
- All four first-party production Dockerfiles build successfully, and the
  currently running development Compose services report healthy where defined.
- Android previously used the debug key for release builds. Tag CI now requires
  the secure signing secrets listed above.
- iOS remains unsigned and is not App-Store ready.
- Android/macOS use `com.mediguide.ug`, while iOS currently uses the historical
  `com.omarsoft.mediguide` bundle identifier and team `399FSBA8SX`. Confirm that
  this is the intended registered App Store identity before configuring signing;
  changing an identifier creates a different application.
- A tag must not be pushed until all modified workflow/runbook files are merged
  to `main` and both required GitHub workflows are green.
