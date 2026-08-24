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

Public clients load governed documents from `GET /api/public/outbreaks/:id/documents`; they do not infer them from legacy resource links. The API returns only current published, effective and non-expired versions and exposes downloads through the scoped redirect endpoint. Mobile provides searchable/filterable document list and detail screens, an embedded PDF reader, a Markdown preview, controlled operating-system handling for other approved formats, progress/cancel/retry states and explicit storage removal.

Metadata and files use the `public` cache scope only. A completed unfiltered sync reconciles the canonical document set: withdrawn/revoked downloads are deleted, newer versions are marked as updates, and a failed replacement download preserves the previous checksum-verified file. Downloads use managed app storage, SHA-256 verification and `.part`/staged/backup atomic replacement. Never cache an admin draft or use an authenticated user's scope as a public document source.

## Document discovery and notifications

PostgreSQL performs all document filtering, sorting and pagination. Search covers title, description, document number, authority, kind, audience and the parent outbreak name. Weighted full-text ranking places exact title and document-number matches ahead of authority/outbreak matches and body text. Expression GIN and trigram indexes are installed by migration `00043`; client sort fields remain allowlisted. Public queries apply publication/effective/expiry visibility before returning results, while admin search remains permission protected.

Document transitions create typed, idempotent notifications in the same database transaction as the audit and state transition:

- submission/review request goes to active users with `outbreak.review` (or `admin.all`);
- clinician approval goes to active users with `outbreak.publish` (or `admin.all`);
- publication and replacement publication use a public `outbreak_document` deep link;
- withdrawal links to the still-public outbreak rather than the withdrawn document;
- review-date and expiry reminders go only to reviewers.

The notification worker scans reminders every six hours and on startup. Deduplication keys include document, event/due state, due date and recipient, so repeated scans are safe. Staff actions include the dashboard route `/outbreaks/:id?document=:documentId`; mobile discards that staff-only parameter. Public mobile deep links are resolved from typed IDs and never trust a caller-supplied route. Templates for the lifecycle catalogue are installed by migration `00044`.
