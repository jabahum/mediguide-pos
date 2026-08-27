# MediGuide infrastructure

For versioning, tag creation, mobile signing, GHCR publication, production
deployment, verification, and rollback, see
[`docs/release-process.md`](../docs/release-process.md).
For local demo data and guarded production metadata or administrator seeding,
see [`docs/seeding.md`](../docs/seeding.md).

The `infra` directory is the single deployment entry point for the MediGuide
backend, AI workers, dashboard, data services, Ollama, and public Clinical
Guidelines Platform.

## Compose files

- `docker-compose.yml` is the production-oriented base stack. The Guidelines
  Platform is built as static assets and served by unprivileged Nginx.
- `docker-compose.dev.yml` adds local database ports and replaces the
  Guidelines service with Vite, source mounting, and hot reload.
- `development.env` contains safe local defaults.
- `staging.env.example` documents the staging values. Copy it to the ignored
  `staging.env` and replace all placeholders.
- `production.env.example` documents production variables. Copy it to the
  ignored `production.env` and replace every placeholder before deployment.

All three files intentionally expose the same variable names. Values and
credentials remain environment-specific; blank secret values must be injected
from the shell, the protected CI environment, or the deployment secret. Check
the templates, any existing ignored environment files, and Compose references
without printing secret values:

```bash
make env-check
```

When adding a Compose variable, add it to all three templates in the same
change. `FIREBASE_SERVICE_ACCOUNT_BASE64` must contain the one-line encoded
JSON contents at runtime, never a filename.

`APP_ENV` is also the source of truth for the backend Gin runtime mode. The API
uses Gin debug mode for `development`, test mode for `test`, and release mode
for production, staging, or an unknown value. This fail-closed mapping prevents
a misspelled hosted environment from enabling verbose Gin debug output; a
startup log records both `app_env` and the selected `gin_mode`.

The development Compose override builds the backend's `development` target with
[Air](https://github.com/air-verse/air) and mounts `../backend` at `/src`.
Changes to non-test Go files rebuild and restart the API automatically; database
migrations still run once before Air starts. Air and the writable source mount
are absent from the production image and production Compose configuration.

Application-specific container assets live with their application. The
Guidelines Dockerfiles, Nginx configuration, and runtime configuration scripts
are in `../guidelines-platform`; Compose and environment orchestration remain
in `infra`.

Both environments use the same Compose project and `guidelines` service. The
Guidelines application is started, stopped, inspected, and networked as part of
the complete MediGuide stack.

Distributed rate-limit and cache tuning, failure behavior, and data exclusions
are documented in [`../docs/rate-limits-and-cache.md`](../docs/rate-limits-and-cache.md).

## Public guideline API

The public site reads published content through the backend policy boundary:

| Endpoint | Purpose |
|---|---|
| `GET /api/public/guidelines` | Paginated public metadata with search and filters |
| `GET /api/public/guidelines/:id` | Metadata for the current published version |
| `GET /api/public/guidelines/:id/markdown` | Current Markdown with cache validators |

The list supports `search`, `program_area`, `country`, `language`,
`updated_from`, `page`, and `per_page`. Public routes never accept an
administrative token or expose storage keys. Content is visible only when
`current_version_id` points to a version whose status is `published` and which
has Markdown. Draft, archived, invalid, and missing publications return the
same `404`. Publishing updates version status and the document pointer in one
transaction.

Markdown is returned inline with `ETag` and `Last-Modified`. A matching
`If-None-Match` receives `304 Not Modified`. The ETag is calculated from the
stored bytes, so changed published content receives a different validator.

## Development

From the repository root:

```bash
make config
make up
make ps
make guidelines-logs
```

Default local endpoints:

| Service | Host binding | Container port |
|---|---:|---:|
| Guidelines Platform | `127.0.0.1:5173` | `8080` |
| Dashboard | `127.0.0.1:3000` | `3000` |
| API | `127.0.0.1:8080` | `8080` |
| MinIO | `127.0.0.1:9000` | `9000` |
| MinIO console | `127.0.0.1:9001` | `9001` |
| PostgreSQL | `127.0.0.1:5433` | `5432` |

Redis (`6379`), Ollama (`11434`), the AI HTTP API (`8090`), and AI gRPC
(`50051`) are private Compose-network ports in both environments. Development
data ports use `DEV_DATA_BIND_ADDRESS`; keep it on loopback unless a deliberate,
firewalled remote-development setup requires otherwise.

`make down` preserves named data volumes. Use `make reset` only when the local
PostgreSQL, MinIO, Ollama, and frontend dependency volumes should be deleted.

`PUBLIC_API_BASE_URL` is the browser-visible API address and
`ALLOWED_ORIGINS` is its explicit comma-separated CORS allow-list. The
Guidelines service waits for API readiness before starting.

## Production

Create the ignored environment file and replace all placeholder credentials and
public URLs:

```bash
cp infra/production.env.example infra/production.env
make prod-config
make prod-up
make prod-ps
```

The production stack publishes only API `8080`, dashboard `3000`, and
guidelines `5000`, all on `0.0.0.0`. PostgreSQL, Redis, MinIO, Ollama, AI HTTP,
and AI gRPC are reachable only inside the Compose network. Restrict the three
published ports with the host or provider firewall and place a TLS reverse
proxy in front of them.
The supported single-domain layout is `/` for Guidelines, `/admin` for the
dashboard, and `/api` for the backend. Start from
[`nginx/mediguide.conf.example`](nginx/mediguide.conf.example). The dashboard
image must be built with `NEXT_PUBLIC_DASHBOARD_BASE_PATH=/admin`, and Nginx
must preserve—not strip—the `/admin` prefix.

| Public route | Published listener | Service |
|---|---|---|
| `/` | `0.0.0.0:5000` | Guidelines UI |
| `/admin` and `/admin/*` | `0.0.0.0:3000` | Dashboard |
| `/api` and `/api/*` | `0.0.0.0:8080` | Backend API |

On an Nginx host, install and verify the example after replacing its hostname
and TLS certificate paths:

```bash
sudo install -m 0644 \
  /opt/mediguide/infra/nginx/mediguide.conf.example \
  /etc/nginx/conf.d/mediguide.conf
sudoedit /etc/nginx/conf.d/mediguide.conf
sudo nginx -t
sudo systemctl reload nginx

curl --fail https://mediguide.example.org/healthz
curl --fail https://mediguide.example.org/admin
curl --fail https://mediguide.example.org/api/readyz
```
`PUBLIC_BIND_ADDRESS=0.0.0.0` makes these three HTTP ports reachable on every
server interface. Permit them only from approved networks where direct access
is required; normal public traffic should still use HTTPS through the reverse
proxy. A reverse proxy running in another Compose project can instead share an
intentionally managed Docker network.

The queue-only `ai-worker-loop` uses a process-liveness health check because it
does not start the HTTP server. Docker restarts the container if its worker
process exits, while Compose `--wait` can still verify that it is ready. After
Compose reports the stack ready, deployment verifies the browser-visible
Guidelines health route, Dashboard route, and API readiness route through
`PUBLIC_SITE_URL`, `DASHBOARD_PUBLIC_URL`, and `PUBLIC_API_BASE_URL`. This
separates a genuine public routing failure from worker-loop liveness.

CI runs `infra/check-production-ports.py` against the rendered production
definition and fails if a data or worker service is published, a public service
targets the wrong container port, or one of the three HTTP listeners is not
bound to the configured public interface.

For the single-domain layout, set `PUBLIC_API_BASE_URL` to the HTTPS origin
without an `/api` suffix, `DASHBOARD_PUBLIC_URL` to the same origin plus
`/admin`, `PUBLIC_SITE_URL` to the HTTPS origin, and `ALLOWED_ORIGINS` to the
origin only. The Guidelines startup
script injects `MEDIGUIDE_API_URL` at runtime, so an immutable image can move
between environments without a rebuild. No token or secret belongs in public
frontend configuration.

`make prod-up` pulls the configured images, applies migrations through the
production API image, and starts the stack with builds disabled while waiting
for health checks. `make prod-migrate` runs only the migration job. To pull
without starting:

```bash
make prod-pull
```

## Automated production deployment

Every `v*` release tag deploys automatically only after the platform quality
gate has passed, all four immutable GHCR images have been published, and their
release tags have been verified. The same release can be redeployed through the
`Deploy production` workflow's manual dispatch.

The workflow checks out the requested immutable tag, builds a restricted bundle
containing this `infra` directory and the production environment secret,
transfers it over verified SSH, and atomically replaces the server's previous
infra directory. The remote
script validates Compose before mutation, removes the existing `mediguide`
Compose containers without deleting named volumes, removes only the previous
first-party MediGuide images, pulls the immutable release images, applies
migrations, starts the stack, and waits up to ten minutes for Compose health
checks. The SSH deployment connection sends keepalives while first-run Ollama
models are downloaded, and a failed deployment prints bounded status and logs
for the application services. It never runs a global container or image prune and never removes
PostgreSQL, MinIO, or Ollama volumes.

Configure the `production` GitHub Environment with approval protection and the
secrets documented in [`../docs/release-process.md`](../docs/release-process.md).
The production host needs Bash, tar, Docker Engine, Docker Compose v2, and a
deployment user with Docker access. `<DEPLOY_PATH>/infra.previous` retains the
immediately preceding deployment configuration for an operator-led rollback.

## Container image publishing

The `container-images.yml` GitHub Actions workflow builds these first-party
packages:

| Service | GHCR package |
|---|---|
| API | `ghcr.io/<owner>/mediguide-pos-api` |
| AI API and worker loop | `ghcr.io/<owner>/mediguide-pos-ai-worker` |
| Dashboard | `ghcr.io/<owner>/mediguide-pos-dashboard` |
| Guidelines Platform | `ghcr.io/<owner>/mediguide-pos-guidelines` |

Pull requests build all four images without publishing them. Pushes to `main`
publish `main`, `sha-<commit>`, and `latest` tags. Tags matching `v*` publish
semantic-version tags such as `1.2.3`, `1.2`, and `1`.

Publishing uses the workflow's `GITHUB_TOKEN`; no registry password is needed.
Set the repository Actions variable `PUBLIC_API_BASE_URL` to the production
origin and `DASHBOARD_BASE_PATH` to `/admin`; both are embedded in dashboard
builds. After the first publish, configure package
visibility in GitHub and place the desired immutable version or SHA tags in
`infra/production.env`.

Production Dockerfiles use explicit build targets and non-root runtime users.
The API, dashboard, AI worker, and guidelines containers run with read-only root
filesystems, dropped Linux capabilities, `no-new-privileges`, and bounded
temporary filesystems. Language/runtime bases and third-party Compose images
are pinned to exact release tags. Update those pins through a reviewed change,
rebuild all images, and repeat Compose and health validation; do not introduce
mutable `latest` tags into an immutable release environment.

Public GHCR packages can be pulled anonymously. Before deploying private
packages, authenticate the production host with a token that has
`read:packages` access:

```bash
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io \
  --username <github-user> --password-stdin
```

## Guidelines health check

Production exposes a dedicated endpoint:

```bash
curl --fail http://localhost:5000/healthz
```

The Nginx service provides immutable asset caching, no-cache HTML and runtime
configuration, security headers, gzip compression, and SPA fallback for deep
reader URLs.

## Markdown authoring deployment checklist

Authoring and regeneration require the API, PostgreSQL, Redis, MinIO, AI worker
API and worker loop. Apply database migrations before new application images
receive traffic. Migrations 18–23 add immutable Markdown revisions, anchors,
private assets, regeneration review, granular permissions and collaboration.

Before a development rollout:

```bash
make contracts-check
docker compose --env-file infra/development.env \
  -f infra/docker-compose.yml -f infra/docker-compose.dev.yml config
docker compose --env-file infra/development.env \
  -f infra/docker-compose.yml -f infra/docker-compose.dev.yml build \
  api ai-worker dashboard
```

Render production configuration with a populated ignored environment file,
but do not start, migrate or restart production during validation:

```bash
make prod-config
```

Verify `MAX_UPLOAD_MB`, reverse-proxy body limits, object-store credentials,
Redis no-eviction policy, `AI_WORKER_SECRET`, embedding provider/model/dimension
and CORS URLs agree across services. Use immutable image SHA/version tags.

After starting a non-production stack, verify PostgreSQL `pg_isready`, Redis
`PING`, MinIO `/minio/health/live`, API health, dashboard health and both worker
processes. Exercise one PDF and one Markdown job through `review_required`; a
successful queue acknowledgement alone does not prove ingestion. Confirm an
accepted publication is public while a newer draft stays private.

The production Compose definition includes container health checks for the API,
AI worker readiness, dashboard and Guidelines Platform. Validate newly built
images under a separate Compose project name and alternate public ports so the
test has isolated networks and volumes and does not restart development or
production services.

## Rebuild, recovery, and rollback

Generated contracts are build inputs. Run `make contracts`, review the Swagger
source change and commit Go/TypeScript/Dart outputs together.
`make contracts-check` must pass in CI. Never edit generated contracts.

Retry a failed regeneration with its idempotency key or start a job for the
newest revision. Never delete immutable source revisions to repair derived
data. Test database migration up/down/up against disposable PostgreSQL data
containing representative revisions, assets, comments and assignments.
Production mutation, restart or rollback requires a separately approved
operational change.
