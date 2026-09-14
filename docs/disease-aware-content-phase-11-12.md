# Disease-aware content: API, permissions, flags and rollout

This runbook completes Phases 11 and 12 of the disease-aware content workflow. It covers canonical diseases, disease-to-content assignments, generic and disease hubs, outbreak hubs, pillars, templates, public discovery and staged rollout. Operational surveillance remains out of scope.

For the dashboard steps used by authors, reviewers and publishers, use the
[content hub and document publishing workflow](content-hub-and-document-publishing-workflow.md).

## API surface

All administrative routes require a bearer token. List routes support bounded pagination and filters; service queries use stable ordering so repeated requests are deterministic. Hub and pillar mutations use `lock_version` where concurrent editing can overwrite state and return `409 Conflict` for a stale version.

| Area | Administrative API | Public API |
|---|---|---|
| Diseases | `GET/POST /api/v2/diseases`, `GET/PATCH/DELETE /api/v2/diseases/{id}` | `GET /api/public/diseases`, `GET /api/public/diseases/{slug}` |
| Hierarchy | `GET /api/v2/diseases/hierarchy?status=` | `GET /api/public/diseases/hierarchy`; disease details also include eligible children |
| Aliases | `GET/PUT /api/v2/diseases/{id}/aliases` | Used by disease search |
| Codes | `GET/PUT /api/v2/diseases/{id}/codes` | Not exposed as an editing surface |
| Assignments | `GET/POST /api/v2/content-disease-assignments`, `PUT .../replace`, `DELETE .../{id}` | Eligible assignments are included in disease discovery |
| Hubs | `GET/POST /api/v2/content-hubs`, `GET/PATCH/DELETE .../{id}` | `GET /api/public/hubs`, `GET /api/public/hubs/{slug}` |
| Hub diseases | `GET/PUT /api/v2/content-hubs/{id}/diseases` | Public hubs include active disease summaries |
| Preview | `GET /api/v2/content-hubs/{id}/preview` | Uses the same resource-eligibility rules as public responses |
| Pillars and items | `/api/v2/content-hubs/{id}/pillars` and nested item/reorder routes | `GET /api/public/hubs/{hubSlug}/pillars/{pillarSlug}` |
| Templates | `GET /api/v2/content-hub-templates`, `GET .../{id}`, `POST /api/v2/content-hubs/{id}/apply-template` | Not exposed publicly |
| Outbreak hub | `POST /api/v2/outbreaks/{id}/content-hub` | `GET /api/public/outbreaks/{id}/hub` with legacy client fallback |
| Unified search | Configuration and assignment happen through the APIs above | `GET /api/public/search?q=&limit=` |

The OpenAPI specification and generated TypeScript/Dart contracts are the canonical payload reference. Regenerate them with `scripts/generate-contracts.sh` after changing handlers or models.

## Permissions

| Permission | Capability |
|---|---|
| `disease.taxonomy.read` | View diseases, hierarchy, aliases, codes and migration reports |
| `disease.taxonomy.manage` | Create/update/archive taxonomy and refresh migration reports |
| `disease.assignment.read` | View disease-to-content assignments |
| `disease.assignment.manage` | Create, replace or delete assignments |
| `content_hub.read` | View hub metadata, previews, workspaces and audit history |
| `content_hub.manage` | Create/update draft hub metadata and disease/outbreak relationships |
| `content_hub.publish` | Publish a validated draft hub |
| `content_hub.archive` | Archive a hub |
| `content_pillar.read` | View pillars, items and assignable resources |
| `content_pillar.manage` | Create/update/reorder/delete pillars and items |
| `content_hub.template.read` | View templates |
| `content_hub.template.manage` | Apply/manage templates |

Standard admins receive all permissions. Content managers/editors can manage taxonomy, assignments, hubs and pillars but cannot publish or archive hubs. Reviewers receive read permissions. Custom roles must be granted only the capabilities they need.

These permissions do not replace the existing document upload, clinical review, guideline publish, withdraw or archive permissions. Assigning a resource to a disease, hub or pillar never changes its clinical approval state. Public APIs call the central eligibility service and exclude drafts, unreviewed clinical content, withdrawn publications, unavailable documents and inactive taxonomy entries.

## Feature flags

The rollout flags are Firebase Remote Config Boolean parameters. Public disease
and hub discovery now default to `true`; mutating and integration capabilities
remain `false` until separately rolled out.

| Flag | Controls | Compatibility behavior while off |
|---|---|---|
| `disease_taxonomy_enabled` | Mobile disease directory and entry point | Existing guideline/category navigation remains |
| `disease_content_assignment` | Administrative disease assignment rollout | Existing content remains unassigned/unchanged |
| `disease_hubs_enabled` | Disease-specific hub links and pages | Disease resources remain available directly |
| `generic_hubs_enabled` | Non-disease hub pages | Existing content directories remain |
| `api_driven_outbreak_pillars` | API-configured outbreak hub layout | Existing outbreak presentation is used |
| `guideline_category_assignment` | Guideline-category assignment workflow | Existing category behavior remains |
| `unified_document_search` | Taxonomy/hub/pillar-aware mobile search | Disease search uses the dedicated disease directory API; other existing per-domain searches continue |
| `pillar_rag_metadata` | Pillar context in RAG retrieval metadata | RAG uses existing approved-document metadata |

The mobile client defines safe defaults in `user_app/lib/core/services/firebase_service.dart`. Public disease taxonomy and content-hub discovery default to enabled now that their public eligibility checks and reader paths are complete; Remote Config still provides an emergency rollback. Mutating assignment, API-driven outbreak presentation, unified search and RAG metadata capabilities remain dark until explicitly enabled. The dashboard Firebase page has an **Add rollout flags** action that merges missing parameters without overwriting existing values. Validate before publishing. A standalone template is available at `firebase/remote-config.disease-hubs.defaults.json`.

Flags control presentation and gradual adoption; they do not weaken server-side authorization, clinical review or public eligibility.

## Rollout procedure

The procedure is idempotent: migrations use conflict-safe inserts, seeds upsert canonical records, assignment backfills are rerunnable, and Remote Config merges preserve existing parameters.

1. Deploy migration `00053_disease_hub_permissions.sql` and the compatible APIs with every new flag disabled.
2. Run the normal seed command to ensure standard role permissions and canonical disease/template seeds exist.
3. Run the disease backfill and refresh `POST /api/v2/diseases/migration-report/refresh`.
4. Resolve every `ambiguous` and clinically meaningful `unmatched` migration-report row. Never guess disease identity from a loose title match.
5. Verify aliases/codes, parent-child hierarchy and deterministic ordering in the admin API.
6. Create hubs from templates; configure disease relationships, pillars and items. Keep hubs in draft.
7. Configure the default outbreak hub and migrate outbreak resources. Do not remove the legacy outbreak UI or data path.
8. Use each hub preview to confirm that only approved, active and publicly eligible resources appear. Verify empty states, removed resources and stale `lock_version` conflicts.
9. In development, enable flags one at a time in this order: taxonomy, assignments/categories, disease/generic hubs, unified search, pillar RAG metadata, then API-driven outbreak pillars. Test guest and authenticated users, offline fallback and deep links.
10. Repeat the same checks in staging using production-like data. Test editor, reviewer, publisher and custom-role denial cases. Confirm an editor cannot publish a hub or expose unreviewed content through assignment.
11. Deploy the verified build to production with flags still disabled. Run API/public-eligibility smoke tests, create/preview one draft hub, verify search latency/error rate, and confirm migration/backfill counts.
12. Enable production flags progressively, beginning with an internal audience/low percentage where Firebase conditions are available. Observe errors, empty results, response time, RAG citations and audit logs before widening.

## Rollback

Turn off the affected Remote Config flag first. For outbreak hubs, the client immediately returns to the legacy presentation. Do not roll back additive production schema migrations merely to disable a feature. Keep canonical taxonomy and assignments; they are inert while their UI flags are off. If an incorrect hub was published, archive it with an authorized publisher/admin account and keep its audit history.

## Publishing documents into a content hub

Content hubs are public navigation and curation surfaces. They do not own an
uploaded file and they never bypass clinical review. A source resource must be
created, reviewed and published first; an editor then assigns it to a hub
pillar.

### General disease guidance

1. Open **Clinical Guidelines → Create Guideline**.
2. Enter its metadata, create a version and upload/load the authoritative
   Markdown. Upload the original PDF where available.
3. Format and validate the Markdown, regenerate its structured projection and
   complete editorial review.
4. Publish the guideline version.
5. Open **Clinical Guidelines → Content Hubs**, select the hub and a pillar,
   select resource type `guideline`, and search for the publication.
6. Assign it, activate the assignment and publish the hub.

There is currently no generic review-governed standalone file uploader for a
non-outbreak hub. Clinical PDFs, protocols and manuals must use the guideline
workflow. A suitable externally hosted resource can use
`approved_external_url` when its HTTPS host is allow-listed.

### Outbreak-response documents

1. Open **Outbreak Management → Outbreaks** and select the outbreak.
2. Under **Outbreak documents and SOPs**, select **Document draft**.
3. Enter its title, document kind, issuing authority, version, language,
   audience and lifecycle dates, then save the draft.
4. Select **Upload original**, submit the resource for review, have a different
   authorized reviewer approve it, and publish it with an authorized publisher.
5. Open the linked content hub, choose a pillar and resource type
   `outbreak_document` or `form`, find the published resource and assign it.
6. Activate the assignment and publish the hub. Situation reports follow their
   own review/publish workflow and are assigned as `situation_report`.

### Mobile visibility checklist

- The disease is active.
- The hub is active, published and its publication time has passed.
- The hub is linked to the intended disease (an outbreak link is optional).
- Pillars and item assignments are active; scheduling dates do not hide them.
- The source resource is approved, published, effective and not expired or
  withdrawn.
- In **Settings → Firebase**, `disease_taxonomy_enabled`,
  `disease_hubs_enabled` and `generic_hubs_enabled` are `true`; validate and
  publish the Remote Config template after changing an existing value.
- Refresh or relaunch mobile. Both guest and authenticated Home screens expose
  **Content hubs**; guests can also use **More → Content Hubs**.

## Verification checklist

- Public requests require no authentication and return only eligible content.
- Administrative requests return `401` without authentication and `403` without the specific permission.
- Searches and lists have bounded pagination, supported filters and stable ordering.
- Duplicate names, aliases, codes and relationships return consistent validation/conflict responses.
- Disease hierarchy updates reject cycles and invalid/inactive parents.
- Concurrent hub/pillar edits reject stale lock versions.
- Assignment does not approve, publish or resurrect a clinical resource.
- Hub preview matches the eventual public payload for eligible resources.
- Publish/archive actions appear in the audit log with actor and target.
- Mobile navigation and unified search obey activated Remote Config values.
- Turning flags off restores the documented compatibility paths without a redeploy.
