# Content hubs and templates (phases 5 and 6)

This document describes the backend-managed content-hub foundation. It does not implement operational surveillance, case records, line lists, alerts, facility reporting, or live epidemiological feeds.

## Domain boundaries

- A category is a broad browsing and search classification.
- A disease is a reusable clinical-condition identity.
- A hub is a curated public experience which may be disease-neutral or associated with one or several diseases.
- A pillar is an ordered, nestable group within one hub.
- A pillar item points to an existing resource or to a validated route. Removing it never deletes the resource.

`ContentHubDisease` is an explicit many-to-many relationship. Pillars are scoped to one hub and have cycle-safe parent relationships. A resource can appear in multiple pillars or hubs, but cannot be duplicated within the same pillar.

## Publication and availability

A hub begins in `draft`. It can be published only after it has an active pillar. Public APIs expose only hubs whose status is `active` and whose `published_at` is set and not in the future.

Within a public hub:

- newly assigned items default to `draft` and require an explicit activation;
- only active pillars and items are returned;
- future and expired item assignments are omitted;
- internal resources are checked using their existing publication, approval, withdrawal and expiry rules;
- invalid or unavailable items are omitted without making the rest of the hub unavailable;
- approved external URLs must use HTTPS and match the configured external-host allowlist;
- internal routes are restricted to known MediGuide route forms; and
- hubs, diseases, pillars and items use deterministic sort ordering.

Archiving a hub removes it from public discovery. A draft hub may be soft-deleted. Pillar and item removal is also soft deletion and does not mutate or delete the underlying guideline, document, report, tool, form, drug reference, or route target.

## Templates

Migration `00050_content_hubs_and_templates.sql` installs three reusable templates. Migration `00051_content_pillar_items_draft_status.sql` makes new resource assignments draft-by-default:

1. Outbreak or emergency response: Case Definition; Screening & Triage; Surveillance Guidance; IPC & PPE; Isolation; Clinical Management; Laboratory; Medicines; Forms; Training; Situation Reports; Contacts; FAQs.
2. Disease care: Overview; Diagnosis; Clinical Management; Medicines; Algorithms; Prevention; Patient Education; Training; References.
3. Surveillance knowledge: Case Definitions; Detection and Screening; Surveillance Protocols; Reporting Forms; Laboratory Guidance; Contact Tracing; Situation Reports; Training Materials; Approved Dashboards; Contacts and Escalation.

Applying a template is permitted only for an empty draft hub. The service copies its pillar definitions into ordinary hub pillars and increments the hub lock version. The copies are independent: administrators can rename, reorder, nest, add, archive, or remove them without modifying the template or deploying code.

## Administrative API

All write operations require an existing administrative content permission and use optimistic `lock_version` checks.

- `GET|POST /api/v2/content-hubs`
- `GET|PATCH|DELETE /api/v2/content-hubs/:id`
- `POST /api/v2/content-hubs/:id/publish`
- `POST /api/v2/content-hubs/:id/archive`
- `GET|POST /api/v2/content-hubs/:id/pillars`
- `PATCH|DELETE /api/v2/content-hubs/:id/pillars/:pillarId`
- `PUT /api/v2/content-hubs/:id/pillars/reorder`
- `GET|POST /api/v2/content-hubs/:id/pillars/:pillarId/items`
- `PATCH|DELETE /api/v2/content-hubs/:id/pillars/:pillarId/items/:itemId`
- `PUT /api/v2/content-hubs/:id/pillars/:pillarId/items/reorder`
- `GET /api/v2/content-hub-templates`
- `GET /api/v2/content-hub-templates/:id`
- `POST /api/v2/content-hubs/:id/apply-template`

For delete operations, pass the current lock version as `?lock_version=N`. Create, update, reorder, template application, publication, archival and deletion actions write audit entries when an authenticated actor is available.

## Public API

- `GET /api/public/hubs?search=&disease_id=&disease_slug=&page=&per_page=`
- `GET /api/public/hubs/:slug`
- `GET /api/public/hubs/:slug/pillars/:pillarSlug`

The hub detail response contains the nested pillar tree and eligible ordered items. These APIs are the contract foundation for the later dashboard administration and public/mobile presentation phases.

## Rollout and rollback

1. Apply database migrations before deploying API code.
2. Verify that all three templates and 32 template pillars exist.
3. Create a draft hub, apply a template, customize it, attach reviewed resources, preview through the public API, and publish.
4. Existing outbreak and guideline routes are unchanged; no current public page is switched to hubs in phases 5 and 6.

Before production data is created, migrations 51 and 50 can be rolled back normally in that order. After hubs are curated, take a database backup before rollback because migration 50's down operation removes hub configuration and template tables. It never deletes the underlying content resources.

## Deferred scope

Phase 7 will migrate outbreak presentation while preserving its compatibility fallback. Phase 8 adds dashboard management screens. Phase 9 renders disease and hub experiences in public web and mobile clients. Search/RAG, offline packages, dedicated permissions, analytics and final rollout automation remain in their later phases.
