# Guideline publication architecture

- Status: Accepted for staged implementation
- Date: 2026-08-10
- Scope: backend, AI worker, dashboard, Flutter `user_app`, and `guidelines-platform`

## Decision summary

`guideline_documents` and their immutable `guideline_versions` are the canonical identity and publication model for uploaded clinical publications. A published version owns its extracted sections, content blocks, tables, assets, search chunks, and capability manifest.

`medical_guidelines` is a legacy, fixed-field clinical-record model. It remains available behind its existing typed API while its records and consumers are migrated. It must not receive new PDF uploads and must not be treated as the identity of a newly uploaded publication.

The two UUID domains are currently independent. A UUID from `medical_guidelines` must never be sent to a document/version endpoint, and a `guideline_documents` UUID must never be validated against `medical_guidelines`. A persisted compatibility mapping will be introduced before bookmarks, progress, usage, downloads, or mobile routes are moved to canonical documents.

This decision deliberately precedes the database and UI work. It resolves the identity ambiguity that caused progress and usage foreign-key failures and prevents the mobile redesign from encoding another fixed PDF structure.

## Current-state inventory

### Representation A: uploaded publications

The upload and publishing pipeline already uses these models:

- `GuidelineDocument`: stable publication identity and descriptive metadata.
- `GuidelineVersion`: version metadata, publication state, approval audit fields, checksum, and original/HTML/Markdown object keys.
- `GuidelineSection`: extracted hierarchy, text/HTML, source pages, and order.
- `GuidelineTable`: extracted tabular HTML/JSON with source page.
- `GuidelineChunk`: searchable/RAG content with document metadata, review status, source pages, and embedding.
- `IngestionJob`: queued PDF processing work.

The AI worker downloads the original PDF from object storage, extracts text, inferred headings, section hierarchy and tables, generates HTML and Markdown, chunks section text, computes embeddings, and atomically replaces extraction rows. Publishing sets the selected version to `published`, approves its chunks, and assigns it as the document's current version.

Known limitations that later phases must address:

- Sections and chunks are deleted and recreated on re-ingestion, so their UUIDs are not stable.
- Tables are currently persisted without their detected section relationship.
- There is no typed heterogeneous content-block stream or capability manifest.
- Heading inference is heuristic and therefore requires review before clinical publication.
- Markdown can be edited, but structured rows are not rebuilt from the edited Markdown.
- A checksum field exists but ingestion is not yet checksum-idempotent.

### Representation B: fixed clinical records

`medical_guidelines` represents one condition as a fixed set of columns such as definition, causes, clinical features, classifications, management, medication and dosage fields. It also stores category, tag, index, priority, publication, version and usage projections.

This representation currently powers the Flutter guideline list and reader. Its fixed columns produce a fixed set of reader sections and cannot faithfully represent arbitrary uploaded PDFs with different headings, tables, figures, algorithms, annexes, or missing capabilities.

### Current identity mismatch

`reading_progress.guideline_document_id` and `guideline_usage_logs.guideline_document_id` were originally created with foreign keys to `guideline_documents`. Migration `00013_align_progress_with_medical_guidelines.sql` changed those foreign keys to `medical_guidelines` because the active Flutter reader sends medical-guideline IDs. The Go fields and API parameter names still say `guideline_document_id`/`guidelineId`.

Consequences:

- The column name implies canonical document identity while the database currently enforces legacy record identity.
- Public and uploaded guideline IDs cannot be recorded by the current progress service.
- Switching the foreign key back without a mapping would invalidate current mobile progress.
- IDs must be resolved explicitly before any migration; matching UUID values by coincidence is forbidden.

## Consumer and relationship inventory

| Concern | Current source and identity | Temporary compatibility requirement |
| --- | --- | --- |
| Dashboard publication upload, version review and publish | `/api/v2/guidelines` and `/api/v2/guideline-versions/*`; document/version IDs | Keep; evolve into the canonical editorial workflow. |
| Dashboard fixed clinical content, categories, tags and index | `/api/v2/medical-guidelines` plus taxonomy endpoints; medical-guideline IDs | Keep until records and screens use canonical DTOs or an adapter. |
| Flutter guideline list, search and detail | `GuidelineContentRepository` calls `/api/v2/medical-guidelines`; medical-guideline IDs | Keep throughout dual-read migration. |
| Flutter reader | Fixed `Guideline` fields converted into a fixed list of UI sections | Keep as legacy reader mode; canonical reader must be manifest/block driven. |
| Flutter bookmarks | `ReadingProgress.is_bookmarked`; scoped locally by user and guideline ID | Preserve and translate through the compatibility mapping. |
| Flutter reading progress | `/api/v2/reading-progress/:guidelineId`; currently a medical-guideline ID | Preserve endpoint during migration, but make identity type explicit in the next API version/DTO. |
| Flutter guideline usage | `/api/v2/usage/guidelines`; currently validates a medical-guideline ID | Preserve until canonical event DTO and mapping exist. |
| Flutter offline content | Local cache stores fixed `Guideline` JSON; progress is user-scoped and offline-first | Version cache keys and migrate without dropping pending progress/bookmarks. |
| Downloads | No dedicated canonical guideline-download model or production repository was found | Add versioned package records later; do not infer a download from cached fixed JSON. |
| Backend text search | `/api/v2/search` searches approved `guideline_chunks`; chunk IDs | Keep; enrich results with document, version and section IDs. |
| RAG | AI worker retrieves approved version chunks and cites source/page metadata | Keep; add stable document/version/section/page citation targets. |
| Public web library | `/api/public/guidelines` and `/:id/markdown`; canonical document IDs | Keep as the public compatibility surface while structured endpoints are added. |
| `guidelines-platform` | Fetches canonical public metadata and Markdown; builds TOC from Markdown headings | Keep Markdown fallback; migrate to per-document manifests and blocks. |
| Static platform content | Bundled `chapters_split` files and a global generated manifest | Development/demo only; production clinical publications must not be bundled into the image. |

## Canonical publication model

### Stable identities

- `document_id` is the durable identity used by routes, bookmarks, progress, usage, library entries and user-visible links.
- `version_id` identifies an immutable publication revision and scopes all extracted or reviewed content.
- `section_id` is stable within a version after editorial review. Re-ingestion must reconcile deterministic source anchors instead of blindly replacing reviewed IDs.
- `block_id` identifies an ordered content unit within a version and section.
- `asset_id` identifies a version-owned original, PDF, figure, downloadable table, HTML, Markdown or package asset.
- Search and RAG results always include `document_id`, `version_id`, optional `section_id`, optional `block_id`, and source page range. Chunk IDs remain retrieval implementation details.

The canonical API must not overload a UUID field to mean either a legacy record or a document. Compatibility requests carry an explicit identity kind internally even where an old route cannot yet expose one.

### Content ownership

A guideline version owns an ordered, typed block stream. The following phase will introduce `guideline_content_blocks` (or an equivalent normalized model), version assets and a capability manifest. Blocks preserve the source document's actual structure; the client does not synthesize absent chapters, tables, figures or algorithms.

The original PDF remains an immutable source artifact. Extracted content is untrusted until reviewed. Publishing requires reviewed content and records the approver and time. Clinical values, dosages, units, mathematical symbols, contraindications and recommendations may not be silently normalized.

### Reader modes

The server recommends one of these modes in the version manifest:

- `structured`: reviewed typed blocks are the primary reader.
- `markdown`: sanitized published Markdown is the compatibility reader.
- `original_document`: the reviewed structured representation is unavailable; offer the source PDF without claiming structured review.
- `legacy_fixed`: a temporary adapter exposes a `medical_guidelines` record.

Clients render only declared capabilities. The shared UI shell may be consistent, but per-document navigation, tabs and actions are generated from the manifest.

## Compatibility and migration plan

### 1. Introduce mapping without destructive cleanup

Add a reversible mapping table before changing existing foreign keys. The intended shape is:

| Field | Purpose |
| --- | --- |
| `id` | Mapping-row UUID. |
| `medical_guideline_id` | Unique legacy record reference. |
| `guideline_document_id` | Canonical document reference. |
| `migration_status` | `pending`, `mapped`, `converted`, `needs_review`, or `retired`. |
| `mapping_reason` | Imported, manually linked, newly converted, or other controlled value. |
| `verified_by`, `verified_at` | Editorial verification audit. |

Never match records only by title. Candidate matching may use normalized title, source, version and taxonomy, but a collision or uncertain match must be marked `needs_review`.

### 2. Convert legacy content safely

For each fixed record:

1. Reuse a manually verified canonical document or create one.
2. Create a draft canonical version.
3. Convert non-empty fixed fields into ordered legacy-adapter blocks without inventing missing content.
4. Preserve category/tag/index metadata through typed relationships.
5. Review the converted clinical content.
6. Publish the canonical version.
7. Mark the mapping converted only after validation.

`medical_guidelines` remains readable throughout this process. Deletion is a separate future decision after consumer telemetry and data verification.

### 3. Dual-read and canonical-write rollout

- New PDF uploads write only to document/version storage.
- Existing fixed editors continue writing legacy records until their dashboard screens migrate.
- Canonical list/detail APIs return canonical documents and may expose verified legacy records through a server-side adapter with an explicit `legacy_fixed` mode.
- Flutter reads canonical results behind a feature flag and falls back to legacy endpoints during rollout.
- `guidelines-platform` prefers structured manifest/block APIs and falls back to the existing Markdown endpoint.
- Search indexes both sources only through canonical projections; results must never produce ambiguous IDs.

Dual writing progress into both ID domains is prohibited. The backend resolves a legacy ID through the verified mapping and persists one canonical document ID once canonical progress storage is introduced.

### 4. Migrate user relationships

Create new canonical relationship columns or tables rather than retargeting the existing misleading foreign key in place. Backfill only rows whose legacy ID has a verified mapping. Preserve unresolved rows and report them for review.

The migration order is:

1. Mapping table and audit report.
2. Nullable canonical document/version/section fields alongside legacy reference fields.
3. Backfill verified mappings.
4. Update services to accept explicit legacy or canonical identities and return canonical IDs.
5. Migrate Flutter offline keys and pending sync records idempotently.
6. Make canonical document identity required for new writes.
7. Retain legacy columns for rollback and unresolved records.
8. Remove legacy relationships only in a later, separately approved migration.

Bookmarks remain part of reading progress for now. Downloads will be version-scoped so an offline package cannot silently change when a new current version is published. Usage events will record canonical document and version context and retain idempotency keys.

### 5. Migrate clients

Dashboard:

- Consolidate the fixed-content and document/version editorial experiences around a canonical document.
- Add extraction-review tooling before enabling structured publication.
- Keep legacy editing clearly labelled until conversion.

Flutter:

- Add canonical Freezed DTOs, repositories and Drift tables rather than widening the fixed `Guideline` model with dynamic maps.
- Cache manifest, sections, blocks and assets by document ID plus version ID.
- Preserve user-scoped progress and pending writes during cache migration.
- Route using document IDs; version and section are optional deep-link context.
- Retain the fixed reader only for `legacy_fixed` responses.

`guidelines-platform`:

- Consume per-document manifest, navigation and blocks.
- Retain sanitized Markdown rendering as fallback.
- Remove the global static clinical manifest only after production content is backend-driven.

## APIs retained during migration

The following are compatibility surfaces, not the final canonical contract:

- `/api/v2/medical-guidelines` and `/api/v2/medical-guidelines/:id`
- `/api/v2/reading-progress` and `/api/v2/reading-progress/:guidelineId`
- `/api/v2/usage/guidelines`
- `/api/public/guidelines` and `/api/public/guidelines/:id/markdown`
- Current `/api/v2/guidelines` document/version editorial routes
- Current category, tag and index endpoints

The canonical structured read API will be additive. Existing routes are removed only after repository searches, usage verification, offline-data migration and client release adoption show no production consumer remains.

## Required safeguards

- Every public response exposes published, approved content only.
- Draft blocks, extraction confidence and reviewer metadata require authenticated editorial permission.
- HTML and Markdown remain sanitized at render boundaries.
- Asset access uses controlled API responses or short-lived signed access; raw object keys are not public contracts.
- Version publication is transactional and invalidates relevant caches.
- Re-ingestion of a published version is forbidden; create a new version instead.
- A manifest declares schema/package versions for forward compatibility.
- RAG retrieves approved chunks only and citations resolve to the exact published document version and available section/page.
- Migration scripts emit counts for mapped, converted, unresolved and orphaned relationships and support up/down/up validation.

## Rollout gates

Each stage is independently releasable and reversible:

1. Canonical block, asset and manifest schema with tests.
2. Idempotent extraction into draft blocks and review tooling.
3. Structured authenticated/public read APIs.
4. Legacy mapping and conversion report.
5. `guidelines-platform` structured reader with Markdown fallback.
6. Flutter canonical repository, offline package and dynamic reader behind a feature flag.
7. Relationship backfill for progress, bookmarks and usage.
8. Canonical reads enabled by default.
9. Compatibility telemetry and unresolved-data review.
10. Separately approved retirement of legacy endpoints and storage.

## Implementation status

Phase 1 is complete: the canonical direction is accepted and the current consumers and compatibility surfaces are recorded.

The first additive Phase 2 foundation is implemented in migration `00014_guideline_content_blocks.sql` and the corresponding Go models. It introduces typed block and asset storage without changing an existing route, foreign key or production consumer. Strict payload validation rejects unsupported fields such as executable HTML and validates discriminators, table shapes, algorithm links and required clinical callout fields.

Phase 3 is implemented in migration `00015_guideline_version_manifests.sql` and the publication service. Every newly published version receives a deterministic, version-scoped manifest in the publication transaction. Existing published versions are backfilled as `markdown_fallback`. Structured capabilities and counts are derived only from reviewed, non-deleted blocks; draft and rejected extraction cannot create public tabs. The manifest includes schema/package versions, extraction quality, original/offline asset availability, a checksum and an ETag. Regeneration is idempotent and available when a published version's package assets change.

Phase 4 is implemented by the AI-worker structured extraction pipeline and migration `00016_structured_guideline_ingestion.sql`. PDF ingestion now calculates a source checksum, skips already-current extraction retries, uses deterministic object keys, records document metadata, OCR and multi-column pages, filters repeated page margins, preserves page provenance, extracts section hierarchy, typed paragraphs/lists/callouts/tables/figures, and stores confidence and warning metadata. Embedded images are stored as review-required assets; possible algorithms and flowcharts remain diagrams rather than executable clinical logic. RAG chunks now carry document, version, section, block and page relationships. All structured blocks and chunks remain draft, the version becomes `review_required`, and the draft manifest exposes no unreviewed capabilities. Published versions cannot be re-ingested, so a prior current publication remains available while a new version is processed.

Phase 5 is implemented by the version-scoped guideline review service and dashboard editorial workspace. Editorial reads require `guideline.write`, draft mutations are rejected after publication, and individual approval/rejection requires `guideline.publish`. Editors can rename and re-level sections, replace the complete hierarchy ordering, split or merge sections, correct typed JSON block payloads, reclassify callouts, and remove extraction artifacts. Any correction resets the affected block to draft. Publisher decisions record actor and time, while block changes, structural changes, removal, review decisions, and publication create audit-log records.

The dashboard review route synchronizes the original PDF page, extracted hierarchy and block editor, and a safe React-rendered preview with web/mobile widths. It displays extraction warnings and publication blockers, links blockers back to affected sections or blocks, and makes the original PDF the fidelity reference. The preview does not execute arbitrary extracted HTML.

Structured publication validation rejects missing source PDFs, empty content, missing or duplicate ordering, invalid levels, missing or duplicate slugs, broken or circular parent relationships, invalid typed payloads, executable markup, broken figure assets, and unreviewed high-risk tables, recommendations, warnings, key points, or algorithms. Legacy schema-version-zero Markdown publications retain their compatibility workflow; they are explicitly reported as legacy fallback rather than being treated as reviewed structured content. Readers continue to use published public endpoints and cannot access the internal draft review routes.

Correcting a block also replaces its linked keyword-search chunk content and resets its review state. The previous vector embedding is cleared so stale clinical text cannot be returned by semantic search. Corrected content remains available to PostgreSQL keyword search after publication; a later embedding refresh workflow must restore semantic-search coverage for corrected blocks without re-running destructive PDF extraction.

This does not complete the overall migration. The next safe slice is Phase 6 public structured-content and asset delivery, capability-driven rendering, and client migration. It must not modify the current progress foreign key or delete `medical_guidelines`.
