# Disease-aware content workflow: phases 1 and 2

## Scope

This note records the repository audit and the canonical disease taxonomy introduced in phases 1 and 2. It deliberately does not implement category links for modern guideline documents, disease-to-content assignments, hubs, pillars, public/mobile disease browsing, or RAG disease metadata. Those belong to later phases.

Operational surveillance remains out of scope. The taxonomy can classify surveillance guidance, but it does not store cases, line lists, alerts, signals, thresholds, facility reports, or patient-identifiable information.

## Domain boundaries

| Concept | Responsibility | Existing or planned source of truth |
|---|---|---|
| Category | Broad search and browsing classification | Existing `guideline_categories` |
| Disease | Canonical clinical subject, aliases, and codes | New `diseases`, `disease_aliases`, and `disease_codes` |
| Hub | Curated public presentation | Later phase |
| Pillar | Ordered navigation within a hub | Later phase |
| Content type | Underlying resource kind | Existing guideline, outbreak, document, report, tool, and reference models |

The disease taxonomy does not replace categories and does not infer public eligibility.

## Current repository audit

### Guidelines and categories

- Modern publications use `guideline_documents`, immutable/versioned `guideline_versions`, hierarchical sections, reviewed content blocks, chunks, assets, and manifests.
- `GuidelineDocument.ProgramArea` is free text. There was no relationship from modern guideline documents to the category taxonomy before this phase.
- `guideline_categories` is already hierarchical, but its legacy use is through UUID strings stored in `MedicalGuideline.Categories` JSON.
- `MedicalGuideline.ConditionName` and optional `ICD10Code` are legacy clinical-content fields, not a reusable disease taxonomy.
- Publishing validates extraction, structured regeneration, review coverage, approved blocks, assets, manifests, and embeddings. A taxonomy entry must never bypass those checks.

### Outbreaks and surveillance documents

- `Outbreak.DiseaseType` is free text.
- Outbreak updates, managed documents, resources, and situation reports have independent review/publication lifecycle fields.
- Managed outbreak documents already recognize `surveillance_protocol`, case definitions, contact-tracing guides, forms, policies, and other operational/reference document kinds.
- Outbreak metrics and situation-report metrics are reviewed publication metadata; they are not an operational surveillance database.
- Mobile outbreak quick-access and clinical-care groupings still contain hard-coded pillar mappings. Their replacement belongs to the hub phases.

### Search and RAG

- Public guideline search joins the current published guideline version and requires approved chunks.
- Outbreak search requires a published, non-withdrawn parent and eligible status. Managed-document discovery also enforces publication/review conditions.
- The RAG boundary retrieves approved chunks from current published guideline versions. Disease metadata is not yet included.
- Assigning a disease in a later phase must add filtering metadata only; it must not duplicate vectors or broaden eligibility.

### Existing public-eligibility rules

| Resource | Existing public boundary |
|---|---|
| Guideline | The document points to the exact current version, that version is `published`, and readers/search/RAG receive approved blocks or chunks only. Superseded and unreviewed content is excluded. |
| Outbreak | `published_at` has arrived, `withdrawn_at` is empty, and status is one of the explicitly public outbreak states. |
| Outbreak update/resource | The item and its parent outbreak must be public; withdrawn content is excluded. Allowed resource targets are validated before they are returned. |
| Managed outbreak document | Status is `published`, approval and publication timestamps exist, its effective date has arrived, it is not expired or withdrawn, and its parent outbreak is public. |
| Situation report | Status is `published`, its publication time has arrived, it is not withdrawn, and any linked outbreak is also public. |

Disease classification must never weaken these predicates. The future assignment and hub queries must join through the source service's public projection instead of treating an assignment as publication.

### Offline and public presentation

- Offline packages belong to a specific published guideline version and its approved projection.
- Public guideline readers consume reviewed blocks and public assets.
- Phase 2 does not alter packages, readers, routes, or public APIs.

### Permissions and audit

- Existing guideline taxonomy endpoints use `guideline.read` and `guideline.write`.
- Phase 2 disease endpoints use the same permissions to avoid introducing the more granular permission work planned for the API/permission phase.
- Disease mutations record the actor in `created_by`/`updated_by` and append `audit_logs` entries when an authenticated actor is supplied.

### Feature flags

- The backend and dashboard already expose protected Firebase Remote Config administration.
- The mobile application fetches Remote Config and currently uses flags such as `enable_ai_assistant`, `outbreak_banner_enabled`, `maintenance_mode`, and `enable_push_notifications`.
- Phase 2 does not gate the taxonomy schema or protected administration API behind a flag. Public disease browsing does not exist yet, so rollout flags for that experience belong to the later public/mobile phase.

### Reused abstractions

- Models embed the existing UUID/timestamp/soft-delete `Base` model.
- List endpoints reuse the existing `PageInput`, `PageResult`, allowlisted sorting, and response envelope conventions.
- Routes reuse `guideline.read` and `guideline.write` authorization and the existing claims-to-actor pattern.
- Mutations reuse `AuditLog` rather than introducing a second audit stream.
- Taxonomy slug validation follows the existing guideline category/tag conventions.

## Selected phase-2 model

```text
diseases
├── parent_id ────────────────> diseases.id
├── disease_aliases           normalized alternative names
└── disease_codes             codes from multiple named systems
```

`normalized_name` and `normalized_alias` are internal lookup keys. Normalization lowercases text, keeps Unicode letters and numbers, converts punctuation/spacing runs to one space, and trims the result.

The schema provides:

- globally unique live slugs;
- unique active canonical normalized names;
- unique normalized aliases within a disease;
- service-level prevention of ambiguity between active names and aliases;
- unique code-system/code pairs;
- indexed parent/status ordering;
- service and PostgreSQL-trigger cycle protection;
- active-parent enforcement for new or changed hierarchy links;
- soft-delete columns plus explicit active, inactive, and archived states.

Aliases and codes are returned with each disease. Codes do not assume one standard: an administrator supplies both `code_system` and `code`.

## Seed data

Migration `00048_disease_taxonomy.sql` creates these initial active records:

- Ebola virus disease
- Malaria
- Cholera
- Marburg virus disease
- Measles
- Diabetes mellitus
- Hypertension

Only safe common aliases are seeded. Standard codes are deliberately not guessed; they can be added with an explicit coding system through the API.

## Non-destructive legacy migration report

The migration does not rewrite or connect legacy content. It snapshots values from:

- `outbreaks.disease_type`;
- `medical_guidelines.condition_name`;
- `guideline_documents.program_area`.

Each row is classified as:

- `matched`: exactly one active canonical name or alias matched;
- `ambiguous`: more than one candidate matched;
- `unmatched`: no safe exact match exists.

Review the report with:

```sql
SELECT source_table, source_id, source_field, source_value,
       resolution_status, disease_id, candidate_disease_ids
FROM disease_taxonomy_migration_report
ORDER BY resolution_status, source_table, source_value;
```

Refresh it after taxonomy changes:

```sql
SELECT refresh_disease_taxonomy_migration_report();
```

The authenticated API equivalents are:

```text
GET  /api/v2/diseases/migration-report
GET  /api/v2/diseases/migration-report?status=unmatched
GET  /api/v2/diseases/migration-report?status=ambiguous
POST /api/v2/diseases/migration-report/refresh
```

No matched row becomes a content assignment in Phase 2. Later-phase backfill must consume only reviewed `matched` rows and leave ambiguous/unmatched rows for manual resolution.

## Administrative API

```text
GET    /api/v2/diseases
GET    /api/v2/diseases/:id
POST   /api/v2/diseases
PATCH  /api/v2/diseases/:id
DELETE /api/v2/diseases/:id
```

List filters include `search`, `status`, `parent_id`, `root_only`, pagination, and allowlisted sorting. Search resolves canonical names, aliases, and slugs.

Example create payload:

```json
{
  "name": "Lassa fever",
  "short_name": "LF",
  "status": "active",
  "sort_order": 80,
  "aliases": [
    {"alias": "Lassa haemorrhagic fever"}
  ],
  "codes": [
    {"code_system": "ICD-11", "code": "1D61", "display_name": "Lassa fever"}
  ]
}
```

`DELETE` archives rather than physically deleting a disease. A disease with non-archived children cannot be archived until its children are archived or reparented. Archived records remain available to editors and for future historical assignments, but reader-level listing returns active records only.

## Backward compatibility and risks

| Risk | Mitigation in phases 1–2 |
|---|---|
| Free-text values differ in spelling or scope | Exact normalized matching only; unmatched values are reported, not guessed |
| A program area is broader than a disease | It remains unmatched and unchanged |
| Alias collides with another active disease | Service rejects active name/alias ambiguity |
| Hierarchy is made cyclic outside the service | PostgreSQL trigger rejects the cycle |
| Existing routes or publication state change | No existing model or route is modified |
| Rollback loses content relationships | None exist yet; rollback drops only new taxonomy/report tables |
| Archived taxonomy is needed historically | Archive is a status transition, not deletion |
| Standard-code semantics are uncertain | No code system is assumed and no uncertain code is seeded |

## Migration and rollback

Apply migrations using the existing Goose workflow:

```bash
cd backend
go run ./cmd/migrate up
```

The down migration removes only the new report function/table, hierarchy trigger, aliases, codes, and diseases. It does not modify the legacy free-text fields or existing guideline/outbreak data.

Before a rollback after later phases are implemented, remove or roll back future foreign-key/assignment migrations first.

## Deferred to later phases

- Modern guideline-category links
- Disease-to-content assignments
- Primary-disease rules for content
- Dashboard disease-management screens
- Public disease directory and mobile routes
- Hubs, pillars, and templates
- Outbreak-pillar migration
- Disease-aware unified search and RAG metadata
- Dedicated disease-taxonomy permissions and feature flags
