# Clinical Guidelines Platform

A React platform for reading the clinical guidelines published by MediGuide.

The platform is the public entry point to the MediGuide ecosystem. Clinical
publications are available without authentication, while the  login links
to the separately deployed MediGuide administration dashboard.

## Architecture

The application uses a feature-oriented structure:

```text
src/
  components/common/       Shared branding, icons, and loading states
  content/                 Historical migration sources and tooling (not production)
  features/landing/        Public landing page and publication library
  features/reader/         Manifest-driven structured and Markdown readers
  layouts/                 Public application shell
  lib/markdown/            Parsing, headings, paths, and navigation utilities
  styles/                  Design tokens and page-specific style layers
  types/                   Content and publication contracts
```

The main routes are:

```text
/                                                   Public guideline library
/guidelines/:id                                     Published guideline reader
```

Cards come from `GET /api/public/guidelines`. The reader then loads that
document's typed manifest, sections, blocks and declared capabilities from the
public API. Tables, figures and algorithms only appear when the per-document
manifest declares them. Every source/version/page citation therefore refers to
the same publication consumed by the Flutter app.

When reviewed structured content is unavailable, the reader falls back to the
published Markdown compatibility endpoint and retains access to the original
PDF. Raw embedded HTML is disabled. Unknown typed blocks display a safe notice
instead of interpreting arbitrary markup or executable content.

The files under `src/content` are retained only as historical migration input
and for content tooling. They are not reachable from the application route
graph, are not generated during `npm run build`, and must not be used as a
production clinical source. Production guideline changes are published through
the backend and become visible without rebuilding this frontend.

With the backend running, generate that comparison directly:

```bash
MEDIGUIDE_API_URL=http://localhost:8080 npm run migration:report
```

## Requirements

Choose either Docker with Docker Compose, or Node.js `20.19+`/`22.12+` with npm.

## Development containers

All deployment files live under [`infra`](../infra). From the repository root,
start the complete development stack, including the Vite service with hot
module replacement:

```bash
make config
make up
```

Open <http://localhost:5173>. The source tree is mounted into the container, so
edits are reflected without rebuilding.

The “Log in” button opens the Mediguide POS login page configured by
`DASHBOARD_PUBLIC_URL` in `infra/development.env`.

After changing dependencies, recreate the dependency volume:

```bash
make reset
make up
```

## Production containers

The shared production stack builds the optimized frontend and serves it with
unprivileged Nginx. Create the ignored production environment file first and
replace all placeholder values:

```bash
cp infra/production.env.example infra/production.env
make prod-config
make prod-up
```

Open <http://localhost:5000>. Port 5000 avoids the backend API's default 8080
port. The container includes:

- a non-root Nginx runtime;
- read-only root filesystem;
- dropped Linux capabilities;
- runtime dashboard URL validation;
- runtime public API URL validation;
- SPA deep-link fallback;
- immutable asset caching and compression;
- browser security headers;
- `/healthz` container health check.

Configure `DASHBOARD_PUBLIC_URL`, `PUBLIC_API_BASE_URL`, `ALLOWED_ORIGINS`,
`GUIDELINES_PUBLIC_PORT`, image metadata, and production credentials in
`infra/production.env`.

Inspect or stop production:

```bash
make prod-ps
make prod-logs
make prod-down
```

Build or run the production image directly:

```bash
docker build \
  -f guidelines-platform/Dockerfile.prod \
  -t mediguide-guidelines:production .

docker run --rm -p 5000:8080 \
  -e MEDIGUIDE_POS_URL=https://mediguide.example.org/admin \
  -e MEDIGUIDE_API_URL=https://mediguide.example.org \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  mediguide-guidelines:production
```

## Release process

This application is versioned and released with the full MediGuide monorepo.
Do not run `npm version` or create a component-only tag. From the repository
root, synchronize every service and the Flutter app with:

```bash
make release-prepare RELEASE_TAG=vX.Y.Z
# Or calculate it from VERSION: make release-patch
make release-check RELEASE_TAG=vX.Y.Z
```

The first command updates `VERSION`, both guidelines manifests, dashboard,
backend Swagger, AI worker, and `user_app`; it also increments the Flutter build
number when the SemVer changes. Follow the complete review, validation, tagging,
artifact, and deployment procedure in `docs/release-process.md`.

Pushing the `vX.Y.Z` tag starts the repository container workflow. Alongside
the API, AI worker, and dashboard images, it publishes the Guidelines image
with these GHCR tags:

```text
ghcr.io/<github-owner>/mediguide-pos-guidelines:X.Y.Z
ghcr.io/<github-owner>/mediguide-pos-guidelines:X.Y
ghcr.io/<github-owner>/mediguide-pos-guidelines:X
ghcr.io/<github-owner>/mediguide-pos-guidelines:sha-<commit>
```

Default-branch builds additionally publish `main` and `latest`. See
[`infra/README.md`](../infra/README.md#container-image-publishing) for the
complete image list and deployment configuration.

## Local development without Docker

```bash
npm ci
npm run dev
```

Available checks:

```bash
npm run content:manifest
npm run format:markdown
npm run lint
npm run test
npm run build
npm run verify
```

`content:manifest` is a migration-tool command. The production build does not
generate or import that historical manifest.

## Publishing a guideline

Upload and review a guideline in the administrative dashboard, then publish a
version. The backend owns the publication manifest, reviewed blocks, Markdown
compatibility output and original-document asset. No platform source-code or
image rebuild is required.

## Configuration

Deployment environment files are managed centrally as `infra/development.env`
and `infra/production.env.example`. Create the ignored `infra/production.env`
for production values. The dashboard URL is public client configuration rather
than a credential.

The production container writes the public login configuration when it starts,
so the same immutable image can be promoted across environments. Runtime
configuration is written to a temporary filesystem, allowing the application
container to keep its root filesystem read-only. The final image contains only
Nginx and compiled static assets; Node.js, source files, and development
dependencies are excluded.

`VITE_MEDIGUIDE_API_URL` configures local Vite builds.
`MEDIGUIDE_API_URL` configures the production container at startup; neither
value is a secret. The reader keeps bounded in-memory structured-content and
Markdown caches and revalidates them with ETags.

Raw embedded HTML is disabled. Unsafe URL protocols are rejected and external
links use `noopener noreferrer`. Because this is a client-rendered Vite SPA,
document titles and descriptions are updated after loading; server-rendered
social metadata would require a separate SSR or prerendering architecture.
