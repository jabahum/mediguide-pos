# MediGuide

MediGuide is a clinical-guidance platform composed of a public guidelines site,
an administrative dashboard, a typed API, an AI/RAG ingestion worker, and an
offline-first Flutter application. The monorepo ships development and production
Docker Compose stacks, generated API contracts, mobile release automation, and
Firebase-backed push notifications and Remote Config.

## Repository map

| Directory | Purpose | Stack |
|---|---|---|
| [`backend`](backend/README.md) | Typed API, authentication, authorization, migrations and seed data | Go, Gin, GORM, PostgreSQL |
| [`dashboard`](dashboard/README.md) | Staff administration and guideline authoring | Next.js, TypeScript, Bun |
| [`guidelines-platform`](guidelines-platform/README.md) | Public clinical-guidelines experience | React, Vite |
| [`user_app`](user_app/README.md) | Offline-first clinician application | Flutter, Riverpod, Drift |
| [`ai-worker`](ai-worker/README.md) | PDF/Markdown ingestion, extraction, embeddings and RAG | Python, FastAPI |
| [`infra`](infra/README.md) | Development and production orchestration | Docker Compose, Nginx |

Supporting services include PostgreSQL/pgvector, Redis, MinIO and Ollama. The
root [`VERSION`](VERSION) is the source of truth for unified releases.

## Quick start

Prerequisites:

- Docker with Compose v2
- GNU Make
- Git
- Flutter `3.44.8` through FVM for mobile development
- Bun for dashboard work
- Node.js for the guidelines site and release scripts
- Go and Python only when running backend or AI services outside Docker

Start the complete local platform:

```bash
make config
make up
make ps
```

The committed `infra/development.env` contains safe local defaults.

Default local endpoints:

| Application | URL |
|---|---|
| Guidelines | <http://localhost:5173> |
| Dashboard | <http://localhost:3000/admin> |
| API | <http://localhost:8080> |
| API readiness | <http://localhost:8080/readyz> |
| MinIO console | <http://localhost:9001> |

Useful commands:

```bash
make logs                 # follow all containers
make guidelines-logs      # follow the public frontend
make down                 # stop and preserve data
make reset                # destructive: stop and delete development volumes
make seed                 # seed a locally configured backend
make contracts            # regenerate Go/TypeScript/Dart contracts
make contracts-check      # verify contract drift
make test                 # backend and AI-worker tests
```

See [`infra/README.md`](infra/README.md) for ports, health checks, volumes,
production Compose, reverse-proxy routing and deployment.

## Mobile environments

The Flutter app has three installable flavors:

| Environment | Android ID | iOS bundle ID | Entry point |
|---|---|---|---|
| Development | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` | `lib/main_development.dart` |
| Staging | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` | `lib/main_staging.dart` |
| Production | `com.mediguide.ug` | `com.omarsoft.mediguide` | `lib/main_production.dart` |

Run development locally:

```bash
cd user_app
fvm flutter pub get
fvm flutter run \
  --flavor development \
  --target lib/main_development.dart \
  --dart-define-from-file=/secure/mediguide/firebase-development.json
```

Development and staging builds include the draggable debug-tools badge with
network, Remote Config and build inspectors. Production code disables those
tools. Full flavor and Xcode setup is in
[`docs/mobile-environments.md`](docs/mobile-environments.md).

## Firebase

Firebase provides mobile Analytics, Cloud Messaging, Remote Config and App
Distribution. Administrative push and Remote Config operations pass through the
backend; Firebase Admin credentials never enter a frontend image or mobile app.

The abbreviated setup is:

1. Create separate development, staging and production Firebase projects.
2. Register the matching Android and iOS IDs from the table above.
3. Enable Analytics, Cloud Messaging, Remote Config and App Distribution.
4. Upload the APNs key and enable iOS Push Notifications/background delivery.
5. Create the documented Remote Config parameters.
6. Configure backend Admin credentials.
7. Configure protected GitHub `testing` and `production` environments.
8. Create `mediguide-alpha-testers`, `mediguide-beta-testers`, and
   `mediguide-testers` App Distribution groups.
9. Run the status, Remote Config and test-push verification checklist.

Follow the complete copy-and-paste process in
[`docs/firebase-mobile-distribution.md`](docs/firebase-mobile-distribution.md).

## Quality checks

Backend:

```bash
cd backend
go test ./...
go vet ./...
go build ./...
```

Dashboard:

```bash
cd dashboard
bun install --frozen-lockfile
bun run lint
bun run typecheck
bun run test
bun run build
```

Guidelines:

```bash
cd guidelines-platform
npm ci
npm run verify
```

Mobile:

```bash
cd user_app
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze
fvm flutter test
```

## Releases and deployment

| Channel | Workflow | Result |
|---|---|---|
| Alpha | `mobile-alpha.yml` | Firebase alpha groups and internal TestFlight |
| Beta | `mobile-beta.yml` | Firebase beta groups and internal TestFlight |
| Stable platform | `vMAJOR.MINOR.PATCH` tag | GHCR images, signed mobile distribution and GitHub Release |
| Mobile production candidate | `mobile-production.yml` | Draft Google Play release and App Store Connect upload |
| Server production | `deploy-production.yml` | Version-pinned Compose deployment after release gates |

Use [`docs/release-process.md`](docs/release-process.md) for version preparation,
tags, GHCR images, deployment, rollback and health checks. Use
[`docs/mobile-alpha-release.md`](docs/mobile-alpha-release.md) for mobile channel
promotion and store credentials.

## Documentation index

| Document | Covers |
|---|---|
| [`docs/firebase-mobile-distribution.md`](docs/firebase-mobile-distribution.md) | Firebase projects, apps, FCM, APNs, Remote Config, backend Admin and CI secrets |
| [`docs/mobile-environments.md`](docs/mobile-environments.md) | Flutter flavors, bundle IDs, schemes and debug tools |
| [`docs/mobile-alpha-release.md`](docs/mobile-alpha-release.md) | Alpha, beta and production mobile delivery |
| [`docs/mobile-visual-regression.md`](docs/mobile-visual-regression.md) | Golden-image matrix and accessibility sizes |
| [`docs/release-process.md`](docs/release-process.md) | Unified release, deployment and rollback |
| [`docs/guideline-publication-architecture.md`](docs/guideline-publication-architecture.md) | Guideline ingestion and publication architecture |
| [`docs/markdown-authoring-workspace.md`](docs/markdown-authoring-workspace.md) | Dashboard Markdown editor and review workflow |
| [`docs/guideline-editor-permissions.md`](docs/guideline-editor-permissions.md) | Authoring authorization model |
| [`docs/rate-limits-and-cache.md`](docs/rate-limits-and-cache.md) | Redis rate limiting and cache behavior |
| [`docs/pocketbase-removal.md`](docs/pocketbase-removal.md) | Typed-domain migration and historical compatibility notes |

## Security expectations

- Never commit `.env` files containing real credentials, Firebase Admin JSON,
  signing keys, provisioning profiles, keystores or App Store Connect keys.
- Client Firebase identifiers are not Admin credentials, but environment bundles
  remain in GitHub secrets to prevent cross-environment configuration drift.
- Production operations use protected GitHub environments and immutable tags.
- Keep database, Redis, MinIO, Ollama and worker ports private in production.
- Clinical content and AI responses must not be treated as a substitute for
  professional judgment or local Ministry of Health policy.
