# MediGuide infrastructure

The `infra` directory is the single deployment entry point for the MediGuide
backend, AI workers, dashboard, data services, Ollama, and public Clinical
Guidelines Platform.

## Compose files

- `docker-compose.yml` is the production-oriented base stack. The Guidelines
  Platform is built as static assets and served by unprivileged Nginx.
- `docker-compose.dev.yml` adds local database ports and replaces the
  Guidelines service with Vite, source mounting, and hot reload.
- `development.env` contains safe local defaults.
- `production.env.example` documents production variables. Copy it to the
  ignored `production.env` and replace every placeholder before deployment.

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

| Service | URL |
|---|---|
| Guidelines Platform | <http://localhost:5173> |
| Dashboard | <http://localhost:3000> |
| API | <http://localhost:8080> |
| MinIO | <http://localhost:9000> |
| MinIO console | <http://localhost:9001> |
| PostgreSQL | `localhost:5433` |

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

The production stack does not publish PostgreSQL or MinIO directly to the host.
The API, dashboard, and guidelines ports remain configurable for connection to
the deployment's reverse proxy.

Set `PUBLIC_API_BASE_URL` to the browser-reachable production API and include
the public Guidelines hostname in `ALLOWED_ORIGINS`. The Guidelines startup
script injects `MEDIGUIDE_API_URL` at runtime, so an immutable image can move
between environments without a rebuild. No token or secret belongs in public
frontend configuration.

`make prod-up` pulls the configured first-party images from GHCR before
starting the stack with builds disabled. To pull without starting:

```bash
make prod-pull
```

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
Set the repository Actions variable `PUBLIC_API_BASE_URL` to the production API
URL embedded in dashboard builds. After the first publish, configure package
visibility in GitHub and place the desired immutable version or SHA tags in
`infra/production.env`.

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
curl --fail http://localhost:8081/healthz
```

The Nginx service provides immutable asset caching, no-cache HTML and runtime
configuration, security headers, gzip compression, and SPA fallback for deep
reader URLs.
