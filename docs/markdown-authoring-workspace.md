# Clinical Markdown authoring workspace

The dashboard guideline editor uses CodeMirror 6 and treats Markdown drafts as
immutable revisions. Saving text and regenerating structured/RAG content are
separate operations.

## Lifecycle

The supported lifecycle is:

1. Edit a writable guideline version.
2. Save a draft or named checkpoint.
3. The version is marked `outdated`; the last successful generated content is
   retained until replacement succeeds.
4. Explicitly request regeneration for the exact current revision.
5. The worker marks the revision `queued`, `processing`, then
   `review_required` or `failed`.
6. Review generated sections and blocks in the existing editorial workspace.
7. Publish only when the current and structured revision IDs match and all
   publication validation succeeds.

An ordinary save never queues ingestion, section extraction, chunking, or
embeddings. A Markdown-only version can follow the complete lifecycle without
an original PDF. It will not provide PDF page citations.

## Backend contract

Authenticated guideline editors use:

- `GET/PUT /api/v2/guideline-versions/:id/markdown-draft`
- `GET/POST /api/v2/guideline-versions/:id/markdown-revisions`
- `GET /api/v2/guideline-versions/:id/markdown-revisions/:revisionId`
- `GET /api/v2/guideline-versions/:id/markdown-revisions/:revisionId/download`
- `POST /api/v2/guideline-versions/:id/markdown-revisions/:revisionId/restore`
- `POST /api/v2/guideline-versions/:id/duplicate`
- `POST /api/v2/guideline-versions/:id/regenerate`

The current permission model maps these operations to `guideline.write`.
Publication remains protected by `guideline.publish`. Requests are rate-limited,
and regeneration is concurrency-limited per authenticated user.

Each revision stores a version-scoped immutable object key, SHA-256 checksum,
monotonic revision number, source and parent metadata, editor, checkpoint
metadata, structured-content status, review status, and publication status.
Object keys are never returned to clients.

Draft writes accept an expected revision/ETag and return HTTP 409 for stale
writes. A failed database transaction attempts to remove only the newly written
object; historical objects are not removed. Restore always creates a new
revision. Regeneration requires the current revision UUID and uses an
idempotency key so a lost response can be retried without creating another job.
Version duplication copies one exact immutable source revision into a new,
independent draft object. A draft branches from its current revision, while a
published version branches from its published revision. The new version starts
with structured content marked `outdated`; duplication never starts ingestion.

## Dashboard behavior

The workspace provides edit, split and preview modes, resizable panels,
fullscreen and distraction-free modes, light/dark CodeMirror themes, line
numbers, folding, Markdown highlighting, history-aware undo/redo, search and
replace, indentation, wrapping and font preferences. Editor preferences and a
crash-recovery draft are browser-local.

Split mode can synchronize editor and preview scrolling, and cursor/scroll
position is restored when switching between edit, split and preview modes.
Preview presentations include rendered Markdown, a draft public-reader shell,
a draft structured-reader shell, responsive mobile/tablet/desktop widths and a
print layout. These previews stay inside the authenticated dashboard and do not
publish or expose draft content.

It includes:

- manual and debounced save indicators;
- offline and failed-save recovery;
- ETag conflict choices that preserve local content;
- named checkpoints and paginated revision history;
- revision download, restore and safe line comparison;
- a live heading outline and structural/unsafe-content validation;
- six structure-only clinical templates;
- `.md`/`.markdown` loading, current Markdown download and clipboard copy;
- formatting for headings, emphasis, lists, links, images, tables, code,
  footnotes, references, and documented clinical callouts;
- safe GFM preview with raw HTML disabled;
- explicit regeneration and worker-status polling;
- a visual GFM table editor with spreadsheet/CSV import, CSV export, row and
  column reordering, alignment, metadata, preview, and non-mutating clinical
  number/unit warnings;
- a private version-scoped image library with drag/drop, clipboard and file
  upload, metadata editing, review state, signed previews, stable references,
  and unused/broken-reference reporting.

New versions can begin with blank Markdown, one of the six clinical templates,
PDF upload or Markdown upload. Editors can also duplicate an existing draft or
create a new draft from an immutable published revision. Loading another
Markdown file replaces only the unsaved editor source until the editor confirms
the save. Drafts can be compared with the document's published Markdown before
regeneration.

Supported callout fences are `recommendation`, `warning`, `caution`,
`key-point`, `contraindication`, `dosage`, `evidence`, `definition`, `procedure`,
`algorithm-reference`, `clinical-note`, and `referral-criteria`. They are transformed to
safe presentational Markdown before preview; their body is never interpreted as
executable HTML.

## Operational notes and deliberate boundaries

- The object store and PostgreSQL must be available for server draft saves.
- Redis-backed rate limiting should be available in multi-instance deployments.
- Regeneration requires the AI worker and its database/object-store access.
- Generated sections, search chunks, and embeddings remain on the last
  successful revision while a newer draft is merely saved or regeneration
  fails.
- The workspace does not claim real-time co-editing. Concurrency is protected
  by revision ETags and explicit conflict resolution.
- Clinical templates contain headings and placeholders only. They never
  fabricate recommendations or doses.
- Reviewer assignments, revision/section/block comments, resolution state and
  the audit timeline are durable asynchronous collaboration features. Presence,
  live cursors and realtime delivery are not supported; refresh or polling is
  required to observe another editor's changes.
- Revision `anchor_metadata` is stored separately from Markdown. Renames retain
  the stable revision anchor and surface a review warning; outline reordering
  moves the complete source section and its anchor metadata together.

## Validation

Migrations `00018_guideline_markdown_revisions.sql` and
`00019_guideline_markdown_anchor_metadata.sql`, plus asset-authoring migration
`00020_guideline_asset_authoring.sql`, were validated up/down/up
against a disposable PostgreSQL 16/pgvector database. Backend focused tests
cover save-only behavior, optimistic conflicts, immutable restore, exact
revision duplication, published-version branching, explicit regeneration, and
idempotent retries. Dashboard focused tests cover permission
states, editing, modes, keyboard save, failed-save preservation, publication
immutability, preview presentations, published branching, safe HTML handling,
GFM, and clinical callouts. OpenAPI, TypeScript, and Dart contracts are
regenerated from the backend specification. Run `make contracts` at the
repository root after an annotated API DTO or route changes. Run
`make contracts-check` in CI and before review. It regenerates Go Swagger,
TypeScript and Dart into a temporary directory and compares each artifact
byte-for-byte; generated files must never be edited by hand.
## Clinical callout syntax

Clinical callouts use fenced Markdown. Their exact body is retained in the immutable Markdown revision and is never treated as executable HTML.

```md
:::warning title="Renal safety" severity=high evidence_grade="A" source="National guideline"
Do not administer this medicine when severe renal impairment is present.
:::
```

Supported names are `recommendation`, `warning`, `caution`, `key-point`, `contraindication`, `dosage`, `evidence`, `definition`, `procedure`, `algorithm-reference`, `clinical-note`, and `referral-criteria`. Optional metadata uses `key=value` syntax and is limited to `title`, `severity`, `evidence_grade`, and `source`. Quote values containing spaces. Severity, when supplied, must be `standard`, `important`, `high`, or `critical`.

The body is mandatory. Unsupported metadata, invalid quoting, empty or unclosed fences, and executable markup are rejected. Recommendation, warning, caution, contraindication, dosage, procedure, algorithm-reference, and referral-criteria blocks are high risk and require explicit block review before publication. Authors and extractors must never infer or normalize clinical doses, units, contraindications, or recommendations.

## Visual table syntax

The visual editor always writes a normal GFM table into the Markdown revision.
Optional metadata is visible Markdown placed immediately around the table:
`**Table: …**`, `*Caption: …*`, `*Source: …*`, `[^table-N]: …`, and
`**Review status:** Clinical review required.` Empty cells are retained.
Potentially malformed values in columns whose headings suggest dosage, units,
strength, concentration, weight or volume produce warnings only; the editor
never rewrites clinical values.

## Guideline image assets

Editors use `/api/v2/guideline-versions/:id/assets` to upload and list private,
version-scoped PNG, JPEG, GIF or WebP images. SVG is rejected. The API returns
short-lived signed URLs and never returns object-storage keys. Markdown stores
only a stable opaque reference:

```md
![Alternative text](guideline-asset://00000000-0000-0000-0000-000000000000)
```

Replacing an image uploads a new asset and changes the draft reference; it does
not overwrite the previous object. Deleted asset rows are soft-deleted and the
stored object is retained for immutable historical revisions. Published
versions reject upload, metadata update and deletion, so replacement requires
a new draft version. The library reports unused assets and UUID references that
do not resolve in the current draft. Clinically sensitive assets require an
authorized review before publication.

## Save, recovery, conflict, and revision behavior

Autosave is debounced and never discards the editor buffer when a request
fails. The workspace shows `unsaved`, `saving`, `saved`, `offline`, `conflict`
or `failed` rather than inferring success. Browser recovery is scoped by user,
document and version; it records the server ETag on which the local text was
based. A confirmed server save clears only the matching recovery record.

If another writer advances the revision, the API returns `409 Conflict` and
the UI keeps both local and remote text available for compare/copy. It does not
silently merge clinical text. Restoring a checkpoint creates a new head
revision, preserving immutable history and monotonic numbering. Published
revisions are immutable; continue editing by duplicating the accepted source
into a new draft version.

## Draft, regeneration, review, and publication

A Markdown save changes source only. Regeneration is a separate, explicit
operation bound to the current immutable revision and an idempotency key. The
worker rebuilds structured sections, blocks, chunks and embeddings while the
previously published version remains live. Superseded or canceled jobs cannot
persist. Failures preserve both the source revision and previous generated
projection.

Regenerated output is `review_required`. Reviewers compare its before/after
snapshot, resolve comments, and review high-risk blocks individually. Overall
acceptance requires all high-risk blocks to be reviewed; publication requires
the accepted revision to be the current structured revision. Markdown-only
guidelines have no original-PDF or page citation capability. PDF-derived
Markdown retains its fidelity reference, but edited blocks receive page
provenance only when an unchanged source fingerprint proves it.

## Validation and limits

Client validation is advisory. The backend validates the immutable stored
revision and is authoritative for regeneration and publication. Empty or
invalid Markdown may still be saved so work is not lost, but blocking issues
prevent regeneration/publication. Reports include stable codes, severity,
messages and source ranges.

For code-by-code correction guidance covering both Markdown validation and the
post-regeneration publication checks, see
[`guideline-validation-troubleshooting.md`](guideline-validation-troubleshooting.md).

The API accepts `.md` and `.markdown` UTF-8 source files and PDFs. Images are
limited to PNG, JPEG, GIF and WebP; SVG and executable content are rejected.
The deployment-wide source upload ceiling is `MAX_UPLOAD_MB` (100 MiB by
default). Asset endpoints apply content-type and size validation. Reverse
proxy, API, object-store and worker limits must agree.

## Permissions and review workflow

See [`guideline-editor-permissions.md`](guideline-editor-permissions.md) for the
granular permission matrix and default role behavior. Private draft reads,
Markdown edits, asset management, regeneration, ordinary/high-risk review,
revision restore and publication are separate authorities. Actor identity is
derived from JWT claims and state-changing operations are audited.

## Troubleshooting

- `409` while saving: compare the preserved local recovery draft with the
  remote head, then intentionally save a reconciled revision.
- A queued job that does not advance: check Redis, worker loop, PostgreSQL,
  MinIO and the shared worker secret.
- A superseded job: reload and explicitly regenerate the newest revision.
- A broken preview image: verify a same-version `guideline-asset://<uuid>`
  reference and refresh its short-lived signed URL.
- Publication blocked: run authoritative validation, resolve comments, review
  high-risk blocks, accept regeneration and align current/structured/accepted
  revision IDs.
- Missing page citations for Markdown-only sources are intentional; never
  manufacture page numbers.
