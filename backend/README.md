# MediGuide Backend

Offline-first clinical guideline backend for frontline health workers.

This service provides:

- Auth + JWT + RBAC
- Guideline document/version/section/chunk management
- PDF upload and ingestion job creation
- Search endpoints using PostgreSQL full-text search
- pgvector-ready schema for semantic search
- RAG chatbot endpoint with citation-first response structure
- Clinical protocol engine using YAML/JSON definitions
- Offline sync package metadata and download APIs
- Audit logs
- MinIO/S3-compatible object storage support
- Docker Compose for local development

## Stack

- Go
- Gin
- GORM
- PostgreSQL + pgvector
- MinIO
- Goose migrations
- JWT auth

## Quick start

```bash
cp .env.example .env
docker compose up --build
```

API health:

```bash
curl http://localhost:8080/api/healthz
```

Run migrations manually:

```bash
make migrate-up
```

Seed development data:

```bash
make seed
```

The idempotent seed creates development users, imports the Ministry of Health
facility registry, and adds representative guidelines, structured reader
blocks, offline packages, outbreaks, situation reports, drugs, calculators,
consultants, abbreviations, help content, directory contacts, and support data.
After facilities have already been imported, set
`SEED_SKIP_MASTER_FACILITIES=true` for a fast content-only rerun.

Default development accounts:

```text
email: admin@mediguide.local
password: Admin123!

email: clinician@mediguide.local
password: Clinician123!
```

The guideline, medicine, calculator and account records created by the seed are
demonstration data and must not be treated as approved production guidance.
The Bundibugyo virus disease outbreak fixture is a dated public-information
snapshot sourced from the Uganda Ministry of Health and WHO Regional Office for
Africa publications of May–July 2026. Its dates and figures are deliberately
fixed and its resource links retain the authoritative sources; rerunning the
seed never makes historical surveillance figures appear current.

## Main endpoints

```text
GET    /api/v1/stats
GET    /api/v1/consultants/tree
GET    /api/v1/health-facilities/tree
GET    /api/v1/ministry-directory/tree
GET    /api/v1/overview

POST   /api/v2/auth/login
POST   /api/v2/auth/register
GET    /api/v2/me

POST   /api/v2/guidelines
GET    /api/v2/guidelines
GET    /api/v2/guidelines/:id
POST   /api/v2/guidelines/:id/versions
POST   /api/v2/guideline-versions/:id/upload
POST   /api/v2/guideline-versions/:id/publish
GET    /api/v2/guideline-versions/:id/sections
GET    /api/v2/guideline-versions/:id/chunks

GET    /api/v2/search?q=malaria
POST   /api/v2/chat/ask

POST   /api/v2/protocols
GET    /api/v2/protocols
GET    /api/v2/protocols/:id
POST   /api/v2/protocols/:id/run

GET    /api/v2/sync/manifest
POST   /api/v2/sync/packages
GET    /api/v2/sync/packages/:id/download
```

## Development notes

The PDF-to-HTML/vector process is represented as ingestion jobs. In production, connect the job runner to a Python worker that:

1. Downloads original PDF from object storage.
2. Extracts structured Markdown/HTML.
3. Extracts tables and figures.
4. Creates chunks.
5. Generates embeddings.
6. Saves sections/chunks/embeddings into PostgreSQL.
7. Marks the ingestion job as completed.

The Go backend already has the tables and APIs needed for that workflow.
