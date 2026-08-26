# Outbreak operations runbook

## Discovery and freshness

Public search returns only published, non-withdrawn guidelines, outbreaks, and situation reports. Results use the explicit `result_type` values `guideline`, `outbreak`, and `situation_report`. Search covers approved editorial fields: title, summary, disease, geography, source organization, source reference, and situation-report highlights.

The mobile app also searches its public outbreak/report cache while offline. Cached results are clearly marked. Stale results never receive the active/recent ranking bonus and are labelled “verify when online.” The app emits `outbreak_cache_access` (`hit`/`miss`) and `outbreak_offline_content_used` through Firebase Analytics with only `content_type`, cache result, and a numeric `stale` flag; it sends no user ID, token, query, or clinical content. Firebase queues analytics locally while the device is offline and uploads them after connectivity returns.

## Metrics and privacy

Prometheus-compatible metrics are exposed at `GET /api/metrics`. Configure the production reverse proxy so only the monitoring network can reach this endpoint.

- `mediguide_outbreak_public_requests_total`
- `mediguide_outbreak_public_request_errors_total`
- `mediguide_outbreak_public_request_duration_seconds_sum`
- `mediguide_cache_hits_total`, `mediguide_cache_misses_total`, `mediguide_cache_errors_total`
- `mediguide_outbreak_verification_age_hours`
- `mediguide_outbreak_publications_total{state="published|withdrawn"}`
- `mediguide_notification_campaigns_total`
- `mediguide_notification_deliveries_total`
- `mediguide_outbreak_report_asset_failures_total`
- `mediguide_outbreak_malformed_actions_total`
- `mediguide_managed_report_storage_healthy`

HTTP metrics use bounded route and status labels. Resource IDs appear only in structured request logs for incident correlation. User identifiers, tokens, search queries, payloads, and private participant data are never metric labels or outbreak-operation log fields.

Outbreak sources are currently editorially entered and reviewed; the runtime does not automatically fetch external outbreak sources. Consequently there is no source-fetch counter to alert on until a source-ingestion worker exists. Managed report-asset failures are measured and alerted now; any future source worker must emit a bounded `source` classification (never a raw URL) and add a repeated-failure rule before it is enabled in production.

Load [the alert rules](../infra/monitoring/outbreak-alerts.yml) into the platform Prometheus-compatible rule evaluator. Route critical alerts to the public-health editorial on-call and infrastructure on-call.

## Storage and failure response

`GET /api/readyz` verifies PostgreSQL, required Redis, and the managed report bucket. A failed object-store check removes the API from readiness without changing published data. For repeated asset failures:

1. Check `mediguide_managed_report_storage_healthy` and MinIO/S3 connectivity.
2. Correlate `outbreak_request_completed` logs using `outbreak_id` and route.
3. Confirm the report asset row points to an object in the configured managed bucket.
4. Restore the missing object from the controlled backup or upload a corrected report through the typed admin endpoint.
5. Never replace a published report silently; use the correction workflow when its content changes.

## Withdrawal and rollback

Withdrawal is the immediate public rollback mechanism. It preserves audit history and prevents the record from appearing in public APIs or search.

1. Confirm the affected UUID and current lock version in the dashboard.
2. Call `POST /api/v2/outbreaks/:id/withdraw` or `POST /api/v2/situation-reports/:id/withdraw` with a specific reason and the current lock version. The caller needs the corresponding withdraw permission.
3. Verify the public detail returns 404 and search no longer returns the item.
4. If replacement content is required, use `POST .../:id/correct`, complete independent review, then publish the correction. Do not edit or republish the withdrawn immutable record.
5. Verify the audit trail, notification state, public endpoint, cache behaviour, and metrics before resolving the incident.

Database rollback is not a content-withdrawal mechanism. Use database restore only for infrastructure disaster recovery, following backups and migration compatibility checks.

## Managed outbreak documents

Outbreak records can carry governed supporting material such as SOPs, response plans, checklists, forms, situation-report annexes and training material. Create and manage these records in the outbreak editor. Public readers only receive a document when its status is `published`, its effective date has arrived and it has not expired.

The managed upload endpoint accepts PDF, DOCX, XLSX, Markdown and UTF-8 text files up to `MAX_UPLOAD_MB` (25 MB by default). The API validates the actual PDF or OOXML structure rather than trusting the filename or browser MIME type, rejects unsafe archives, stores a SHA-256 checksum and writes the object under an immutable content-addressed key. Replacing a draft file advances its optimistic lock and deletes the previous object only when no document version still references it.

Use this lifecycle:

1. A user with `outbreak.manage` creates a draft, completes authority, document number, version, language, audience and effective/review metadata, then uploads the file.
2. The author submits the draft for review. Submission fails when required governance metadata or the file is missing, or the document is already expired.
3. A different user with `outbreak.review` records review comments and approves with a required clinical rationale. Authors cannot approve their own work.
4. A third user with `outbreak.publish` publishes the approved version. The publisher cannot be its author or clinical approver.
5. A user with `outbreak.withdraw` may withdraw a published version with a reason. Published records are immutable; content changes must start through the correction endpoint and complete the full review cycle again.

The document audit endpoint records uploads, comments and every lifecycle transition. Never overwrite an object or directly update a published database row. Malware scanning is an infrastructure concern in addition to the API's structural validation; configure object-storage scanning/quarantine before accepting files from untrusted external contributors.

Public clients load governed documents from `GET /api/public/outbreaks/:id/documents`; they do not infer them from legacy resource links. Cross-outbreak discovery uses `GET /api/public/outbreak-documents`, direct detail uses `GET /api/public/outbreak-documents/:documentId`, and approved derived Markdown/plain text is available from `GET /api/public/outbreak-documents/:documentId/content`. The API returns only current published, effective and non-expired versions and exposes original downloads through the scoped redirect endpoint. Mobile includes outbreak documents in Global Search, routes results directly to their reader, reads approved Markdown/text without requiring a download, caches readable content for offline use, embeds PDFs, and uses controlled operating-system handling for other approved formats.

Metadata and files use the `public` cache scope only. A completed unfiltered sync reconciles the canonical document set: withdrawn/revoked downloads are deleted, newer versions are marked as updates, and a failed replacement download preserves the previous checksum-verified file. Downloads use managed app storage, SHA-256 verification and `.part`/staged/backup atomic replacement. Never cache an admin draft or use an authenticated user's scope as a public document source.

## Document discovery and notifications

PostgreSQL performs all document filtering, sorting and pagination. Search covers title, description, document number, authority, kind, audience, the parent outbreak and safe derived body text. Weighted full-text ranking places exact title and document-number matches ahead of authority/outbreak matches and body text. Expression GIN and trigram indexes are installed by migration `00043`; migration `00045` adds server-owned extraction fields and extends the weighted index with body content; migration `00046` adds checksum-bound sections, page mappings and index lifecycle state. Markdown and UTF-8 text are derived deterministically, DOCX is reduced to plain text, PDFs are indexed as page-numbered extracted text, and XLSX files contribute selected safe textual cell values. The original PDF or spreadsheet remains authoritative: extracted PDF text does not claim layout fidelity, and PDF/XLSX content is not exposed as an inline Markdown reader. Only content belonging to a published, clinically approved, currently effective, unexpired and unwithdrawn document can be read or searched publicly. Client sort fields remain allowlisted and client values are always bound as query parameters.

The dashboard exposes extraction status, extraction time and content format without returning the search-only projection. Authorized staff can preview ready Markdown/plain text through `GET /api/v2/outbreaks/:id/documents/:documentId/content`. If a historical upload has no projection, or the extraction implementation changes, `POST /api/v2/outbreaks/:id/documents/:documentId/reprocess` rebuilds it from the immutable stored object. Reprocessing requires `outbreak.manage`, the current optimistic lock version, a structurally valid object and a matching SHA-256 checksum; it increments the lock and records an immutable audit event. It never changes clinical metadata, the original object or publication state. PDF and XLSX reprocessing rebuilds search-only text and page/cell projections while keeping `can_read_inline: false`; clients must use the governed original-document action for visual fidelity.

### Extraction and index lifecycle

1. Upload validates the file signature and structure, computes the immutable source checksum, stores the source under a content-addressed key and derives a projection for the detected format.
2. A projection records its source checksum, derivation checksum and search-schema version. An identical retry is idempotent. Replacing the source invalidates the prior projection and derives a new one.
3. Draft and pending-review projections remain administrative previews only. They are not clinically approved merely because extraction succeeded.
4. Publication makes a ready projection searchable only after independent clinical approval and the normal publication checks pass.
5. Correction publication removes the superseded version from the public index. Withdrawal marks its index state removed immediately.
6. Reprocessing is used after extractor/schema changes or to recover a failed historical projection. It revalidates the immutable object and checksum before changing derived fields.

Extraction errors are stored as bounded operational messages and shown to authorized staff. They do not expose object-storage credentials or make the document publicly searchable. Scanned/image-only PDFs require an OCR service that is not provided by this extractor. Encrypted PDFs, malformed Office archives, complex spreadsheet formulas/charts and layout-sensitive PDF content may remain original-only or have incomplete search text. Never infer clinical meaning from extracted layout.

### Reader and offline behavior

The public content manifest returns sanitized Markdown or plain text with stable section anchors, publication/effective dates, an ETag based on the derived checksum and a governed original-download URL. Flutter reads supported content online without a mandatory download, stores successful public content in its normalized cache and falls back to that cache offline. A complete unfiltered synchronization reconciles removals so withdrawn documents are not retained as discoverable content. Search results may carry a matching section anchor or PDF page; Markdown navigates to the matching section and PDF opens the authoritative original at the matching page when the native viewer supports it. Unsupported inline formats display metadata and a clear original/download action rather than an empty reader.

The API never exposes `storage_key`. Object downloads remain behind the validated redirect/streaming boundary. `S3_PUBLIC_ENDPOINT` (or the equivalent reverse-proxy configuration) must resolve from browsers and physical mobile devices; an internal Compose hostname such as `minio:9000` is not a valid public download endpoint.

Document transitions create typed, idempotent notifications in the same database transaction as the audit and state transition:

- submission/review request goes to active users with `outbreak.review` (or `admin.all`);
- clinician approval goes to active users with `outbreak.publish` (or `admin.all`);
- publication and replacement publication use a public `outbreak_document` deep link;
- withdrawal links to the still-public outbreak rather than the withdrawn document;
- review-date and expiry reminders go only to reviewers.

The notification worker scans reminders every six hours and on startup. Deduplication keys include document, event/due state, due date and recipient, so repeated scans are safe. Staff actions include the dashboard route `/outbreaks/:id?document=:documentId`; mobile discards that staff-only parameter. Public mobile deep links are resolved from typed IDs and never trust a caller-supplied route. Templates for the lifecycle catalogue are installed by migration `00044`.

## Quick resources and search operations

Public quick resources are available through `GET /api/public/outbreak-resources`. They cover related published MediGuide guidelines, published situation reports, approved HTTPS official websites, approved official statements and allowlisted internal application routes. Managed SOPs, protocols, checklists and forms remain in the governed outbreak-document API so their approval and download semantics cannot be bypassed.

Each result identifies its parent outbreak, issuer, resource and target type, publication date, safe target, and whether it supports an in-app reader or download. External websites are visibly labelled in mobile search and require confirmation before the operating-system browser opens. The API rejects non-HTTPS external targets and hosts outside `OUTBREAK_ALLOWED_EXTERNAL_HOSTS`; internal targets must use an approved application route. A related guideline or report target is returned only when its referenced record is currently public.

The dashboard document workspace shows the immutable original checksum separately from the derived-content checksum, extraction status and error, search-index status and last-indexed time. The derived preview is read-only. `GET /api/v2/outbreaks/:id/documents/:documentId/search-preview` uses the same body matching rules as public discovery and allows staff to verify a term and snippet without exposing the full internal search projection. A published document that is not indexed is explicitly flagged. Reprocessing remains an audited `outbreak.manage` action; editing derived content requires a new governed document revision rather than mutating a published projection.

## Demo and staging document seed

The standard `SEED_SCOPE=demo` seed publishes six deterministic Markdown fixtures for the Bundibugyo virus disease demonstration outbreak: a case-management SOP, IPC protocol, laboratory specimen-handling protocol, contact-tracing guide, frontline checklist and risk-communication guide. The source files live in `backend/cmd/seed/fixtures/outbreak-documents` and are embedded in the seed binary. Each database record therefore has a corresponding object uploaded to the configured MinIO/S3 bucket under a deterministic `demo/outbreaks/...` key.

Rerunning the seed is safe: document UUIDs, document numbers, versions and storage keys are stable; object contents are replaced from the repository fixture; and SHA-256 checksum and size metadata are recalculated. Each demo outbreak also receives a protocol/SOP, checklist, situation report, related guideline and approved official website quick resource. The seed reads uploaded objects back from storage, verifies non-empty bytes and SHA-256 checksums, and invokes the same projection derivation used by runtime uploads. It persists the runtime search text, rendered body, headings, sections, page map, derived checksum and search-schema version, then verifies public metadata, content, download and body-search paths. A parity test re-derives every fixture and prevents seed/runtime projection drift. The fixtures are clearly marked as demonstration content and are not clinician-approved operational guidance.

Demo seeding is blocked when `APP_ENV=production` unless an operator explicitly sets `SEED_ALLOW_DEMO=true`. That override is intended only for a controlled demo/staging server whose environment happens to use the production Compose profile. Real production deployments should seed only approved scopes such as `SEED_SCOPE=admin` or `SEED_SCOPE=facilities`, then publish clinician-approved documents through the governed dashboard workflow.
