# MediGuide platform release process

This runbook releases the backend, AI worker, dashboard, public guidelines
site, and Flutter clients from one immutable Git tag. Once production
deployment secrets are configured, a release tag also replaces the production
Compose stack after all immutable container images have passed verification.

## Release model

Use one SemVer tag in the form `vMAJOR.MINOR.PATCH`. The root `VERSION` file is
the source of truth. `make release-prepare` synchronizes the dashboard,
guidelines site, backend Swagger, AI worker, and Flutter manifests. The Flutter
build number remains after the `+` and must increase for every store upload.

For example, the current mobile version `2.0.17+44` is released with Git tag
`v2.0.17`. That tag produces these immutable container tags:

- `ghcr.io/<owner>/mediguide-pos-api:2.0.17`
- `ghcr.io/<owner>/mediguide-pos-ai-worker:2.0.17`
- `ghcr.io/<owner>/mediguide-pos-dashboard:2.0.17`
- `ghcr.io/<owner>/mediguide-pos-guidelines:2.0.17`

The AI HTTP service and background loop intentionally use the same AI-worker
image. PostgreSQL, Redis, MinIO, Ollama, and the Ollama model-pull helper are
third-party infrastructure images and are not republished to GHCR.

Do not run component-level `npm version` or mobile-only bump scripts for a
monorepo release; they can create drift and incorrect component tags. The root
preparation command and repository tag are the platform release interface.

## One-time GitHub setup

Repository Actions must have permission to write packages and releases. The
container workflow uses its scoped `GITHUB_TOKEN` for GHCR. Set these repository
variables to real public endpoints before tagging:

```bash
gh variable set PUBLIC_API_BASE_URL --body 'https://mediguide.example.org'
gh variable set MOBILE_API_BASE_URL --body 'https://mediguide.example.org'
gh variable set DASHBOARD_BASE_PATH --body '/admin'
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

### Production deployment secrets

Create a protected GitHub Environment named `production`. Require approval for
that environment when releases should pause for an operator before server
mutation. Store every connection credential and production setting as a GitHub
Environment or repository Actions secret:

| Secret | Purpose |
|---|---|
| `DEPLOY_HOST` | Production SSH hostname or IP address |
| `DEPLOY_PORT` | SSH port, normally `22` |
| `DEPLOY_USER` | Dedicated non-root deployment account |
| `DEPLOY_PATH` | Absolute server directory, for example `/opt/mediguide` |
| `DEPLOY_SSH_PRIVATE_KEY` | Private key dedicated to GitHub Actions deployment |
| `DEPLOY_KNOWN_HOSTS` | Pinned host-key line for strict SSH verification |
| `PRODUCTION_ENV_FILE` | Complete contents of the production Compose environment file |

The workflow uses the job-scoped `GITHUB_TOKEN` to pull this repository's GHCR
packages. It streams that token over verified SSH into a temporary Docker
configuration and deletes the configuration after deployment; no registry PAT
is stored on the server or in the repository.

Create a dedicated key and install only its public half in the deployment
account's `authorized_keys` file. Run these commands from a secure operator
machine, replacing the example host and values:

```bash
ssh-keygen -t ed25519 -N '' -f mediguide-deploy -C mediguide-github-actions
ssh-copy-id -i mediguide-deploy.pub deploy@production.example.org

gh secret set DEPLOY_HOST --env production --body 'production.example.org'
gh secret set DEPLOY_PORT --env production --body '22'
gh secret set DEPLOY_USER --env production --body 'deploy'
gh secret set DEPLOY_PATH --env production --body '/opt/mediguide'
gh secret set DEPLOY_SSH_PRIVATE_KEY --env production < mediguide-deploy
ssh-keyscan -H production.example.org | \
  gh secret set DEPLOY_KNOWN_HOSTS --env production
gh secret set PRODUCTION_ENV_FILE --env production < infra/production.env
```

Verify the host key through the hosting provider or server console before
storing it; do not trust an unverified `ssh-keyscan` result. Restrict the
private key file and remove it from the operator machine after backing it up in
the approved secret manager.

The production server must provide Bash, tar, Docker Engine, and Docker Compose
v2. The deployment user needs access to Docker without an interactive password.
The default production listeners are `127.0.0.1:8080` for the API,
`127.0.0.1:3000` for the dashboard, and `127.0.0.1:5000` for guidelines. Route
`/api` to the API, `/admin` to the dashboard, and `/` to Guidelines through a
same-host TLS reverse proxy. The checked-in example is
[`../infra/nginx/mediguide.conf.example`](../infra/nginx/mediguide.conf.example).
PostgreSQL, Redis, MinIO, Ollama,
and both AI-worker ports must not be published by production Compose.
Prepare the target directory once without placing credentials in the checkout:

```bash
sudo install -d -o deploy -g deploy -m 0750 /opt/mediguide
sudo usermod -aG docker deploy
docker compose version
```

The `PRODUCTION_ENV_FILE` secret uses the same keys documented in
`infra/production.env.example`, but it must contain real passwords, URLs, SMTP,
JWT, MinIO, CORS, proxy, and runtime values. Image tags and build metadata in
that secret are ignored during automated deployment: the workflow creates a
second environment file that pins all first-party images to the requested
release version and revision.

For one public domain, use these values (replace the hostname):

```dotenv
PUBLIC_API_BASE_URL=https://mediguide.example.org
ALLOWED_ORIGINS=https://mediguide.example.org
DASHBOARD_BASE_PATH=/admin
DASHBOARD_PUBLIC_URL=https://mediguide.example.org/admin
GUIDELINES_PUBLIC_PORT=5000
```

`PUBLIC_API_BASE_URL` intentionally has no `/api` suffix because clients append
typed `/api/v2/...` routes. CORS origins must never contain a path.

Apple artifacts are currently compile-verified but unsigned. A distributable
iOS IPA still requires an Apple Distribution certificate, provisioning profile,
App Store Connect API credentials, an export-options file, and a dedicated
signed/notarized workflow. Do not submit the unsigned ZIP to the App Store or
describe it as an installable iOS release.

## Prepare the release

1. Choose the new tag and synchronize every component version. Moving to a new
   SemVer automatically increments the existing Flutter build number:

```bash
make release-patch
# Or choose explicitly:
make release-prepare RELEASE_TAG=v2.0.17
```

   `make release-minor` and `make release-major` provide the equivalent SemVer
   bumps. Read the synchronized version printed by the command and use that
   exact value for release notes, preflight, and the eventual Git tag.

   To allocate a specific store build number instead, use:

```bash
make release-prepare RELEASE_TAG=v2.0.17 MOBILE_BUILD_NUMBER=43
```

   Re-running the first command for the same SemVer preserves its current
   Flutter build number, making preparation idempotent. Review and commit all
   generated version changes together.
2. Update user-facing release notes and any migration or operational notes.
3. Run the metadata-only drift check before committing:

```bash
bash scripts/check-release-readiness.sh v2.0.17 --metadata-only
git diff -- VERSION dashboard/package.json \
  guidelines-platform/package.json guidelines-platform/package-lock.json \
  backend/cmd/api/main.go backend/docs ai-worker/pyproject.toml \
  user_app/pubspec.yaml
```

4. Merge the release commit into the canonical `main` branch.
5. Fetch `main` and all existing tags from the canonical remote. This checkout
   currently calls that remote `upstream`; confirm with `git remote -v`.

```bash
git fetch upstream main --tags --prune
git switch main
git pull --ff-only upstream main
git status --short
make release-check RELEASE_TAG=v2.0.17
```

The final status command must be empty. The release check validates every
component against `VERSION`, the mobile build metadata, clean Git state,
reachability from a known `main`, existing-tag safety, and development and
production Compose rendering.

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
git tag -s v2.0.17 -m 'MediGuide v2.0.17'
# Fallback: git tag -a v2.0.17 -m 'MediGuide v2.0.17'
git show --no-patch --decorate v2.0.17
git push upstream refs/tags/v2.0.17
```

Never move, delete, or reuse a published release tag. Fix a bad release with a
new patch version and a higher Flutter build number.

The tag starts two workflows:

- `Build and publish container images` tests the platform and publishes four
  GHCR packages with `2.0.17`, `2.0`, `2`, and `sha-*` tags, provenance, and an
  SBOM.
- `Test and build mobile release` verifies generated code, analyzes and tests
  Flutter, builds signed Android APK/AAB, Flutter web, unsigned iOS, and macOS,
  then creates a GitHub Release with a manifest and SHA-256 checksums. The
  release is created only after every mobile build succeeds. Mobile artifact
  filenames and the manifest include both the SemVer and Flutter build number,
  for example `mediguide-2.0.17+44-android.aab`.
- After the container workflow verifies all four immutable image tags, it calls
  `Deploy production`. The protected `production` environment supplies SSH and
  Compose secrets and can require operator approval.

Monitor both workflows. The production deployment job begins only after the
container image set is complete:

```bash
release_sha="$(git rev-list -n 1 v2.0.17)"
gh run list --commit "${release_sha}" --limit 10
gh run watch <run-id> --exit-status
gh release view v2.0.17
```

Confirm all four immutable images exist. GHCR SemVer tags omit the leading `v`:

```bash
owner='<lowercase-github-owner>'
for image in api ai-worker dashboard guidelines; do
  docker buildx imagetools inspect \
    "ghcr.io/${owner}/mediguide-pos-${image}:2.0.17"
done
```

Download the release, then verify its checksums before distribution:

```bash
mkdir -p /tmp/mediguide-v2.0.17
gh release download v2.0.17 --dir /tmp/mediguide-v2.0.17
(cd /tmp/mediguide-v2.0.17 && sha256sum --check SHA256SUMS)
```

On macOS, use `shasum -a 256 -c SHA256SUMS` if GNU `sha256sum` is unavailable.

## Deploy immutable images

### Automated release deployment

For a release tag, no operator should copy credentials or Compose files by
hand. The deployment workflow performs this sequence:

1. Check out and validate the immutable release tag and full Git revision.
2. Materialize `infra/production.env` from `PRODUCTION_ENV_FILE` without logging
   it, archive the complete `infra` directory, and copy it over pinned SSH.
3. Preserve the existing server configuration as
   `<DEPLOY_PATH>/infra.previous` and replace `<DEPLOY_PATH>/infra`.
4. Render and validate the production Compose configuration.
5. Capture the currently deployed first-party image references, run Compose
   `down --remove-orphans` without `--volumes`, and remove those captured
   MediGuide images. Unrelated containers, images, and volumes are untouched.
6. Pull the requested immutable GHCR release images, run database migrations,
   start with `--no-build`, and wait for health checks.

To redeploy an existing release or perform an approved manual deployment:

```bash
gh workflow run deploy-production.yml \
  --ref main \
  -f release_tag=v2.0.17
gh run list --workflow deploy-production.yml --limit 5
gh run watch <run-id> --exit-status
```

Do not enter an arbitrary branch in `release_tag`; the workflow accepts a tag
whose checked-out metadata matches the release version. A supplied `revision`
must exactly match the tag commit.

### Operator-led deployment

Prepare `infra/production.env` outside Git. Replace every placeholder and pin
the four first-party images to the exact released version, never `latest`:

```dotenv
API_IMAGE=ghcr.io/<owner>/mediguide-pos-api:2.0.17
AI_WORKER_IMAGE=ghcr.io/<owner>/mediguide-pos-ai-worker:2.0.17
DASHBOARD_IMAGE=ghcr.io/<owner>/mediguide-pos-dashboard:2.0.17
GUIDELINES_IMAGE=ghcr.io/<owner>/mediguide-pos-guidelines:2.0.17
BUILD_VERSION=2.0.17
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

Automated deployments retain the immediately previous configuration at
`<DEPLOY_PATH>/infra.previous`. If a deployment fails after containers have
been removed, inspect its logs before acting. For a compatible application-only
rollback, restore that directory and run its Compose configuration. Never roll
database migrations down automatically:

```bash
cd /opt/mediguide
mv infra infra.failed
mv infra.previous infra
docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  pull
docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  up --no-build -d --remove-orphans --wait --wait-timeout 600
```

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
