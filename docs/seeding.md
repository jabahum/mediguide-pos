# Database and object-storage seeding

This guide covers the two supported seed workflows:

- deterministic demonstration data for local development;
- narrowly scoped metadata and administrator bootstrap operations in production.

Seeding mutates PostgreSQL and, for demo clinical content, MinIO. Run it only against the intended environment. Seeds are designed to be idempotent, but idempotency is not a substitute for a verified production backup.

## Supported scopes

| Scope | Environment | Creates or updates |
|---|---|---|
| `demo` | Development and controlled demo/staging only | Demo users and permissions, facility baseline data, guidelines, drugs, calculators, notifications, outbreak content and repository-owned MinIO fixtures |
| `admin` | Production | The configured administrator and system admin-role assignment |
| `facilities` | Production | Ministry of Health geographic hierarchy, facility levels, ownership/authority metadata and the facility master dataset |
| `notifications` | Development only | Demonstration notification records for the seeded clinician |
| `clinical-tools-rehearsal` | Disposable rehearsal only | Synthetic actors and schema clinical tools for retirement validation |

The production helper accepts only `admin` and `facilities`. It rejects all other scopes before starting a backup or seed container. Never enable demo fixtures in a real clinical production environment.

## Local development demo data

### Prerequisites

From the repository root, verify that `infra/development.env` exists and contains only local-development values. Start the stack and wait for healthy dependencies:

```bash
make config
make up

docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  ps
```

PostgreSQL and MinIO must be healthy. If seed source code or embedded fixture files changed after the current API image was built, rebuild the development API image first:

```bash
docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  build api
```

### Apply migrations and seed

Use one-off containers connected to the running development services:

```bash
docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  run --rm --no-deps api /app/migrate up

docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  run --rm --no-deps \
  -e SEED_SCOPE=demo \
  api /app/seed
```

Rerunning the demo command is supported. Stable UUIDs and natural keys update the owned fixtures rather than creating duplicate logical records. MinIO fixture objects use deterministic storage keys and are replaced with the repository version while their checksums and sizes are recalculated.

The demo scope creates these development-only accounts:

| Purpose | Email | Password |
|---|---|---|
| Administrator and assigning editor | `admin@mediguide.health.go.ug` | `Admin123!` |
| Frontline clinician | `clinician@mediguide.health.go.ug` | `Clinician123!` |
| Clinical guideline reviewer | `reviewer@mediguide.health.go.ug` | `Reviewer123!` |

Never reuse these credentials outside local development or a controlled demonstration environment. The production `admin` and `facilities` scopes do not create this demo reviewer account.

The same scope also creates disease-aware discovery data so the dashboard,
public web application and mobile application can be tested without manually
classifying content:

- active Ebola, Malaria, Marburg and Hypertension disease metadata, aliases and
  representative ICD-10 codes;
- Infectious Diseases, Emergency Preparedness and Non-Communicable Diseases
  guideline-category links;
- disease assignments for the demo guidelines, outbreak, situation report and
  all managed outbreak documents;
- published `demo-ebola-response`, `demo-malaria-care` and
  `demo-hypertension-care` content hubs with usable pillars and items.

These are deterministic development fixtures. Rerunning `SEED_SCOPE=demo`
restores their repository-defined state and does not create duplicate hubs,
pillars, category links or disease assignments.

### Exercise the guideline review workflow

The demo scope leaves the public `Malaria in Adults` version `1.4` published and creates a separate editable `1.5-review` version. That review draft includes:

- a current Markdown revision stored in MinIO;
- an active assignment to `Dr. Amina Clinical Reviewer`;
- one unresolved reviewer comment;
- assignment and comment audit events.

To test the complete workflow:

1. Sign in to the dashboard as the demo administrator.
2. Open **Clinical Guidelines**, select **Malaria in Adults**, then select version **1.5-review**.
3. Open the Markdown workspace and choose **Review & activity**. Confirm that the reviewer is shown by name and email, the seeded comment is visible, and the activity feed contains the assignment and comment events.
4. Use the reviewer selector to verify that **Dr. Amina Clinical Reviewer** is available. Assigning the same reviewer while the seeded assignment is active should be rejected as a duplicate active assignment.
5. Sign in as the demo reviewer, resolve the seeded comment, add another comment, and complete or dismiss the assignment.
6. Refresh the page and confirm the updated state persists. Rerunning the demo seed restores the deterministic active-assignment fixture.

Inspect the fixture directly when troubleshooting:

```bash
docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  exec -T postgres sh -eu -c \
  'psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c \
    "SELECT gv.version,u.name,u.email,a.status,c.body,c.resolved
       FROM guideline_versions gv
       JOIN guideline_review_assignments a ON a.version_id = gv.id AND a.deleted_at IS NULL
       JOIN users u ON u.id = a.reviewer_id
       LEFT JOIN guideline_editor_comments c ON c.version_id = gv.id AND c.deleted_at IS NULL
      WHERE gv.version = '\''1.5-review'\'';"'
```

Developers running the Go backend outside Docker may use `make seed`, but only when `backend/.env` points to the intended local PostgreSQL, Redis and MinIO services. The Compose command above is preferred because it uses the same runtime and network configuration as the application.

### Verify local results

Check API readiness and public data:

```bash
curl --fail --silent http://localhost:8080/api/readyz
curl --fail --silent \
  'http://localhost:8080/api/public/outbreaks/8148f968-ed21-5145-8100-89e89b948a4f/documents?page=1&per_page=20' \
  | jq '.data | {total_items, documents: [.items[] | {document_number, title, document_kind}]}'

curl --fail --silent \
  'http://localhost:8080/api/public/outbreak-resources?search=Bundibugyo&page=1&per_page=20' \
  | jq '.data | {total_items, resources: [.items[] | {title, resource_type, target_type, issuing_organization}]}'

curl --fail --silent \
  'http://localhost:8080/api/public/outbreak-documents?search=environmental%20decontamination&page=1&per_page=20' \
  | jq '.data | {total_items, documents: [.items[] | {document_number, title, extraction_status}]}'

curl --fail --silent \
  'http://localhost:8080/api/public/diseases' \
  | jq '.data'

curl --fail --silent \
  'http://localhost:8080/api/public/hubs' \
  | jq '.data'

curl --fail --silent \
  'http://localhost:8080/api/public/hubs/demo-ebola-response' \
  | jq '.data | {name, diseases, pillars}'
```

Check deterministic outbreak-document metadata directly when troubleshooting:

```bash
docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  exec -T postgres sh -eu -c \
  'psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c \
    "SELECT document_number,title,document_kind,status,storage_key
       FROM outbreak_resources
      WHERE document_number LIKE '\''DEMO-EVD-%'\''
      ORDER BY sort_order;"'
```

Open the local applications after seeding:

- public guidelines: <http://localhost:5173>
- dashboard: <http://localhost:3000/admin>
- MinIO console: <http://localhost:9001>

A successful seed does not require a stack restart. Refresh clients or invalidate their local cache if they loaded an empty response before the seed completed.

### Start over locally

`make down` preserves data. To intentionally delete all development volumes and rebuild from an empty database and object store:

```bash
make reset
make up

docker compose \
  --env-file infra/development.env \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.dev.yml \
  run --rm --no-deps -e SEED_SCOPE=demo api /app/seed
```

`make reset` is destructive and must never be used against production.

## Production metadata seeding

### Safety model

Production seeding is deliberately narrower than development seeding:

- the GitHub workflow requires the protected `production` environment;
- the operator must enter `SEED_PRODUCTION` exactly;
- only `admin` and `facilities` are accepted;
- `APP_ENV=production` must be present in `infra/production.env`;
- PostgreSQL must already be running and healthy;
- a timestamped `pg_dump` backup is written before mutation;
- the seed runs from the released API image—never from a host-compiled binary;
- rerunning an admin seed preserves the existing password unless reset is explicitly requested.

The released production API image includes `/app/seed`. Its runtime guards still reject general demo seeding under `APP_ENV=production`. Do not copy a host binary into a Linux container; architecture mismatches cause `Exec format error` and bypass the reproducible release artifact.

### Required configuration

Configure the GitHub `production` Environment with deployment approval and these secrets:

- `DEPLOY_HOST`
- `DEPLOY_PORT`
- `DEPLOY_USER`
- `DEPLOY_PATH`
- `DEPLOY_SSH_PRIVATE_KEY`
- `DEPLOY_KNOWN_HOSTS`
- `PRODUCTION_ENV_FILE`

The content installed as `<DEPLOY_PATH>/infra/production.env` must contain:

```dotenv
APP_ENV=production
DEFAULT_ADMIN_NAME=MediGuide Administrator
DEFAULT_ADMIN_EMAIL=admin@mediguide.example.org
DEFAULT_ADMIN_PASSWORD=replace-with-a-unique-strong-password
```

Use a generated password stored only in the protected environment secret. Change it through the normal authenticated account workflow after first login. Do not commit `infra/production.env`.

Before seeding, confirm the deployed immutable release is healthy and contains the seed executable:

```bash
cd /opt/mediguide

docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  ps

docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  run --rm --no-deps api sh -eu -c 'test -x /app/seed'
```

If that check fails, deploy a release containing the corrected production API image. Do not copy a locally compiled seed binary onto the server.

### Preferred GitHub workflow

Create or promote the configured administrator:

```bash
gh workflow run seed-production.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f scope=admin \
  -f reset_admin_password=false \
  -f confirmation=SEED_PRODUCTION
```

Seed facility and geographic metadata:

```bash
gh workflow run seed-production.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f scope=facilities \
  -f reset_admin_password=false \
  -f confirmation=SEED_PRODUCTION
```

Watch and inspect the run:

```bash
run_id="$(gh run list \
  --repo mohuganda/mediguide-pos \
  --workflow seed-production.yml \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId')"

gh run watch "$run_id" \
  --repo mohuganda/mediguide-pos \
  --exit-status
```

The remote script stores its pre-seed backup under `<DEPLOY_PATH>/infra/backups/pre-seed-<scope>-<UTC timestamp>.sql.gz`. Retain and copy that backup according to the production retention policy; a backup left only on the application host is not a disaster-recovery strategy.

### Manual server operation

Use the manual path only during an approved maintenance operation when GitHub Actions is unavailable:

```bash
ssh -i ~/.ssh/mediguide/deploy-production deploy@server
cd /opt/mediguide

CONFIRM_PRODUCTION_SEED=SEED_PRODUCTION \
  bash infra/seed-production.sh facilities false
```

For administrator bootstrap, use `admin false`. Use `admin true` only for deliberate account recovery: it resets the configured administrator password and revokes all active refresh sessions. The script rejects password reset for every other scope.

### Verify production results

Verify the configured administrator without printing password hashes or tokens:

```bash
docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  exec -T postgres sh -eu -c \
  'psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c \
    "SELECT email,name,status,is_active,verified,created_at
       FROM users
      ORDER BY created_at DESC
      LIMIT 20;"'
```

Verify facility metadata counts:

```bash
docker compose \
  --env-file infra/production.env \
  --env-file infra/release.env \
  -f infra/docker-compose.yml \
  exec -T postgres sh -eu -c \
  'psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c \
    "SELECT
       (SELECT count(*) FROM regions WHERE deleted_at IS NULL) AS regions,
       (SELECT count(*) FROM districts WHERE deleted_at IS NULL) AS districts,
       (SELECT count(*) FROM health_facilities WHERE deleted_at IS NULL) AS facilities;"'
```

Then verify API readiness and perform one dashboard login through the public HTTPS route. Do not restart the stack after a successful seed; the API reads the committed data immediately.

## Troubleshooting

### `/app/seed: No such file or directory`

The deployed API image predates production seed packaging or the wrong image tag is active. Verify the immutable image configured in `infra/release.env`, deploy a newer release, and rerun `test -x /app/seed`. Do not install an ad-hoc binary into the container.

### `Exec format error`

A seed binary compiled for the host architecture was copied into the Linux container. Remove the altered container, restore the released image and use its `/app/seed` binary.

### PostgreSQL is unhealthy

Do not seed. Inspect `docker compose logs postgres`, disk capacity, credentials and migration state. Repair health first; deleting production volumes is not a recovery procedure.

### Seed succeeds but the UI remains empty

Confirm the expected rows with the SQL checks, inspect API pagination and publication filters, refresh browser/mobile caches, and verify the client points to the same environment that was seeded. Published clinical content and demo content are intentionally different scopes.

### A seed run fails after its backup

Retain the workflow logs and backup. Determine whether the database transaction rolled back and whether MinIO objects were written before retrying. Because supported scopes are idempotent, retry the same immutable release after fixing the underlying issue. Restore a production backup only through an approved incident procedure.
