# Content hub and document publishing workflow

This is the operator runbook for publishing disease-aware content in
MediGuide. It covers disease taxonomy, general disease hubs, generic hubs,
outbreak response hubs, guidelines, managed outbreak documents, situation
reports, mobile discovery, rollout, correction and troubleshooting.

Operational case surveillance, line lists and automatic ingestion from external
surveillance systems are not part of this workflow.

## The governing rule

A content hub is a curated navigation layer. It does not own uploaded files and
does not approve clinical content. The safe publication order is:

1. Create the source in its owning module.
2. Complete that module's review and publication lifecycle.
3. Create or select a content hub.
4. Add pillars and assign the published source.
5. Preview the hub and publish it.
6. Verify guest and authenticated public discovery.

Assigning an item to a disease, category, hub or pillar never makes a draft
public and never changes its clinical approval state.

## Content model

| Concept | Purpose |
|---|---|
| Disease | Canonical disease identity, hierarchy, aliases and codes |
| Category | Broad editorial grouping such as communicable diseases |
| Content hub | Public landing page for a disease, outbreak or cross-disease subject |
| Pillar | Ordered group inside a hub, such as Clinical Care, IPC or Laboratory |
| Pillar item | Reference to an eligible published resource or an approved route/URL |
| Outbreak | Governed event record that can optionally own a response hub |
| Source resource | Guideline, outbreak document, situation report, algorithm, tool, form or drug reference |

A hub may be linked to one or more diseases without being linked to an
outbreak. This is how non-outbreak disease hubs are represented. A generic hub
may intentionally have neither a disease nor an outbreak relationship. An
outbreak response hub links to an outbreak and normally to its disease.

## Roles and permissions

Use least privilege and retain separation of duties for clinically sensitive
material.

| Work | Permission |
|---|---|
| Read/manage disease taxonomy | `disease.taxonomy.read`, `disease.taxonomy.manage` |
| Read/manage disease assignments | `disease.assignment.read`, `disease.assignment.manage` |
| Read/manage a hub | `content_hub.read`, `content_hub.manage` |
| Publish/archive a hub | `content_hub.publish`, `content_hub.archive` |
| Read/manage pillars and items | `content_pillar.read`, `content_pillar.manage` |
| Read/apply hub templates | `content_hub.template.read`, `content_hub.template.manage` |
| Author/review/publish guidelines | `guideline.markdown.edit`, `guideline.review`, `guideline.high_risk.approve`, `guideline.publish` |
| Author/review/publish outbreak content | `outbreak.manage`, `outbreak.review`, `outbreak.publish` |
| Withdraw outbreak content | `outbreak.withdraw` |
| Author/review/publish situation reports | `situation_report.manage`, `situation_report.review`, `situation_report.publish` |
| Withdraw situation reports | `situation_report.withdraw` |

An outbreak-document author cannot approve their own work, and its publisher
cannot be its author or clinical approver. Apply the same organizational
separation to guidelines and situation reports even where a custom role has
multiple permissions.

## Workflow A: prepare disease taxonomy

1. Open **Clinical Guidelines → Diseases** in the dashboard.
2. Search by name and alias before creating a record to avoid duplicates.
3. Create or update the canonical name, slug, short name and description.
4. Select a parent only when there is a real clinical taxonomy relationship.
5. Add recognized aliases and codes. Do not use a display category as a disease
   alias.
6. Set the disease to active only after its identity and hierarchy are checked.
7. Confirm it appears in the admin hierarchy and public disease directory.

Hierarchy updates reject cycles. Archive obsolete taxonomy entries instead of
reusing their identity for another disease.

## Workflow B: publish a general clinical document

Use this route for guidelines, protocols, manuals and clinical PDFs that are
not governed outbreak resources.

1. Open **Clinical Guidelines → Create Guideline**.
2. Enter authoritative metadata and create a version.
3. Load the Markdown or upload the authoritative source. Upload the original
   PDF when available.
4. Format and validate Markdown, regenerate the structured projection and
   resolve validation errors.
5. Review low-risk content in appropriate batches and individually verify
   high-risk blocks, tables, doses, units and figures.
6. Accept the regenerated projection.
7. Check publication completeness, preview and publish the version.
8. Verify that public read, search, offline and RAG paths return only the
   reviewed projection.

Published versions are immutable. Correct content by creating and publishing a
new version. The complete procedure and its safeguards are in
[Guideline authoring, clinical review, and publication workflow](guideline-authoring-and-publication-workflow.md).

There is no generic, standalone file uploader for non-outbreak hubs. This is
intentional: a hub cannot turn an unreviewed file into public clinical content.
Use the guideline workflow or, for a non-clinical external resource, an
allow-listed `approved_external_url`.

## Workflow C: create a non-outbreak disease hub

1. Publish the source resources using their owning workflows.
2. Open **Clinical Guidelines → Content Hubs** and select **Create hub**.
3. Enter a unique name and slug, description, icon, colour, audience and order.
4. Select one or more active diseases. Leave the outbreak field empty.
5. Save the draft and optionally apply a template.
6. Add, rename and order the pillars required for that disease.
7. In each pillar select **Add item**, choose the resource type and search for
   the published resource.
8. Save the item, set it active and configure its order or schedule.
9. Use **Preview** to check headings, empty pillars, links and resource
   eligibility.
10. Publish the hub with `content_hub.publish`.
11. Verify the public APIs and both mobile user modes.

Supported pillar item types are `guideline`, `outbreak_document`,
`situation_report`, `algorithm`, `clinical_tool`, `form`, `drug_reference`,
`internal_route` and `approved_external_url`. The chooser lists candidates for
the selected type. A draft may be curated in advance, but the public API will
omit it until the source becomes eligible.

## Workflow D: create a generic or cross-disease hub

Follow Workflow C, but omit diseases for a genuinely generic hub or select all
relevant diseases for a cross-disease subject. Use a generic hub for content
such as antimicrobial stewardship or infection prevention that should not be
misrepresented as one disease. The hub still requires active pillars, eligible
items, preview and publication.

## Workflow E: create and publish an outbreak response hub

### Create the outbreak

1. Open **Outbreak Management → Outbreaks → Create outbreak**.
2. Enter the disease, title, geography, authority/source, start date, summary,
   verification time and other required metadata.
3. Save, submit, independently approve and publish the outbreak.
4. From the outbreak workspace configure its content hub, or create a hub and
   link the outbreak and disease explicitly.
5. Apply the outbreak template and tailor its pillars. Typical pillars include
   Case Definition, Screening & Triage, Clinical Management, IPC & PPE,
   Laboratory, Medicines, Forms, Training, Contacts, FAQs and Situation
   Reports.

Creating an outbreak does not automatically publish its hub. The public
outbreak and the hub have separate lifecycle and validation checks.

### Upload an outbreak SOP, form or supporting document

1. Open the outbreak editor and find **Outbreak documents and SOPs**.
2. Select **Document draft**.
3. Enter title, document kind, issuing authority, document number, version,
   language, audience, effective date, review date and optional expiry date.
4. Save the draft and select **Upload original**.
5. Upload PDF, DOCX, XLSX, Markdown or UTF-8 text. The configured limit is
   `MAX_UPLOAD_MB` and defaults to 25 MB.
6. Check extraction/index status and use the derived preview where supported.
7. Submit for review. A different user records comments and approves with a
   clinical rationale.
8. A separately authorized publisher publishes it.
9. In the hub editor, add it as `outbreak_document`; use `form` when its
   document kind is a form.
10. Activate the assignment, preview and publish the hub.

File extensions and browser MIME labels are not trusted. The API validates the
actual file structure, stores a checksum and uses immutable object keys in the
configured MinIO/S3 bucket. Scanned PDFs may remain original-only because the
current extractor does not provide OCR.

### Publish a situation report

1. Open **Outbreak Management → Situation Reports** and create a report linked
   to the outbreak.
2. Complete its title, reporting period, geography, summary, highlights,
   authority and publication metadata.
3. Upload its governed asset.
4. Submit with `situation_report.manage`, approve with
   `situation_report.review`, and publish with `situation_report.publish`.
5. Add the published report to the Situation Reports pillar as
   `situation_report`.

Published outbreak documents and reports are immutable. Use the correction
action for a replacement, complete review again and withdraw obsolete content
when necessary. See [Outbreak operations runbook](outbreak-operations.md) for
storage, extraction, notifications, offline behavior and incident response.

## Links and routes

Use `internal_route` only for an allow-listed MediGuide application route. Use
`approved_external_url` only for HTTPS resources on a configured allowed host.
External resources are labelled and require confirmation before leaving the
app. Never use either type to bypass a governed upload or clinical review.

## What mobile users should see

Both guest and authenticated users can discover published hubs:

- **Home → Content hubs** opens the hub directory;
- guests can also use **More → Content Hubs**;
- search can return eligible diseases, hubs, guidelines and other enabled
  resource types;
- a hub page displays its ordered pillars and eligible items;
- selecting an item uses the correct reader, tool, internal route or approved
  external action.

The app caches the last successful public hub directory and detail response for
resilient discovery. Relaunch or refresh after a publication or Remote Config
change. Offline content remains subject to normal reconciliation and removal
rules.

## Search and RAG behavior

Public search and the AI assistant use the approved source projection, not the
hub card as a substitute for content. Publishing a hub improves navigation but
does not repair missing chunks, embeddings or extraction output.

1. Confirm the source itself is publicly eligible.
2. Confirm extraction or structured regeneration completed without blocking
   errors.
3. Confirm published blocks have search chunks and required embeddings.
4. Query public search with a distinctive source term and open the returned
   resource.
5. Ask the assistant a question answerable by that source and verify its cited
   guideline/document and section.
6. Enable `pillar_rag_metadata` only after retrieval tests show that hub/pillar
   context improves results without changing clinical eligibility.

Never generate a clinical answer from hub metadata alone. If retrieval has no
eligible evidence, the assistant must return its governed no-answer state.

## Public visibility checklist

Before reporting that a hub or document is missing, confirm all of these:

- the disease is active;
- the source resource is reviewed, published, effective, not expired and not
  withdrawn;
- the hub is active and published, and its publication time has arrived;
- the intended disease and/or outbreak is linked to the hub;
- the pillar and item are active and not hidden by scheduling;
- the item points to the correct resource type and ID;
- the hub preview includes the item;
- `disease_taxonomy_enabled`, `disease_hubs_enabled` and
  `generic_hubs_enabled` are true in the activated Firebase template;
- the device uses the intended API base URL and has refreshed its cache.

Public eligibility is enforced by the backend. A UI flag cannot expose a draft
or withdrawn source.

## Production rollout

1. Apply database migrations and deploy compatible backend, dashboard and
   mobile versions.
2. Confirm standard role permissions and create only approved production
   taxonomy metadata. Do not run demo/outbreak fixture seeds in production.
3. Configure object storage and verify `GET /api/readyz` before accepting
   uploads.
4. Create, review and publish sources, then create hubs in draft.
5. Preview using production-like permissions and verify public eligibility.
6. In **Settings → Firebase**, add missing rollout flags, inspect the values,
   validate and publish the Remote Config template.
7. Enable disease taxonomy and general hubs first. Keep assignment, unified
   search, RAG metadata and API-driven outbreak flags off until their own
   rollout is approved.
8. Verify guest, authenticated, online, offline and deep-link behavior.
9. Monitor API errors, empty responses, latency, audit logs and RAG citations.

Firebase defaults and environment setup are documented in
[Firebase and TestFlight mobile distribution](firebase-mobile-distribution.md).
The technical API, feature-flag and rollback reference is
[Disease-aware content: API, permissions, flags and rollout](disease-aware-content-phase-11-12.md).

## API verification

Set the public API origin without a trailing slash. These requests require no
token and must never return drafts:

```bash
API_BASE_URL=https://mediguide.health.go.ug

curl --fail "$API_BASE_URL/api/public/diseases"
curl --fail "$API_BASE_URL/api/public/hubs?page=1&per_page=20"
curl --fail "$API_BASE_URL/api/public/hubs/malaria"
curl --fail "$API_BASE_URL/api/public/hubs/malaria/pillars/clinical-management"
curl --fail "$API_BASE_URL/api/public/search?q=malaria&limit=20"
```

Replace the sample slugs with the exact published hub and pillar slugs. Public
`404` normally means the requested identity does not exist or is not currently
eligible, not that authentication is required.

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
| Disease category opens all guidelines | Client uses a legacy category route or has no disease assignment | Verify the current mobile build, active taxonomy and content-disease assignments |
| Non-outbreak hub is absent on mobile | Hub flag, relationship or publication state is wrong | Complete the public visibility checklist and refresh Remote Config/cache |
| Hub is visible but a pillar is empty | Item is inactive/scheduled or its source is ineligible | Use hub preview, inspect source state and correct the assignment |
| Published source is absent from **Add item** | Wrong type, source state or outbreak filter | Select the matching type, remove the filter and finish source publication |
| Upload controls are missing | User lacks the owning module's manage permission | Assign the minimum guideline, outbreak or report permission; hub permission is insufficient |
| Upload fails | Invalid format, excessive size or unavailable object storage | Check file structure, `MAX_UPLOAD_MB`, readiness and storage configuration |
| Public hub endpoint returns `500` | Backend/database compatibility issue | Deploy the current backend, inspect request logs and rerun the smoke test |
| Public hub endpoint returns `404` | Wrong slug or unpublished/inactive hub | Copy the slug from the editor and verify status and scheduling |
| A withdrawn item remains offline | Device has not completed reconciliation | Restore connectivity, refresh/sync and verify the public API omits it |
| Search omits a document | Source is ineligible, extraction failed or search is disabled | Inspect lifecycle and extraction; reprocess only through the audited workflow |
| Outbreak hub uses the older layout | `api_driven_outbreak_pillars` is false | This is safe compatibility mode; enable only after rollout approval |

## Correction and rollback

- Turn off the affected Firebase flag to restore a compatibility path without a
  mobile redeployment.
- Archive an incorrect hub; do not delete its audit trail after publication.
- Deactivate or schedule an incorrect pillar item while its source is assessed.
- Withdraw an unsafe outbreak document/report using the authorized transition.
- Publish a new guideline version or governed correction instead of changing a
  published record in place.
- Do not roll back additive database migrations merely to disable discovery.

## Release acceptance checklist

- Administrative operations return `401` without authentication and `403`
  without the exact permission.
- Editors cannot publish sources or hubs unless explicitly authorized.
- Hub preview and public payload contain the same eligible resources.
- Guest and authenticated users can open the hub directory and hub details.
- A disease hub works without an outbreak relationship.
- An outbreak hub opens its expected pillars, documents and reports.
- Public search returns the hub and its eligible resources.
- Original downloads resolve through the governed API/object-storage boundary.
- Published, archived, corrected and withdrawn actions appear in audit history.
- Disabling the relevant Remote Config flag restores the documented fallback.
