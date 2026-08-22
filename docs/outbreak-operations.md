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
