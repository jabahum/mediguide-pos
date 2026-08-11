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

## Dashboard behavior

The workspace provides edit, split and preview modes, resizable panels,
fullscreen and distraction-free modes, light/dark CodeMirror themes, line
numbers, folding, Markdown highlighting, history-aware undo/redo, search and
replace, indentation, wrapping and font preferences. Editor preferences and a
crash-recovery draft are browser-local.

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
- explicit regeneration and worker-status polling.

Supported callout fences are `recommendation`, `warning`, `caution`,
`key-point`, `contraindication`, `dosage`, `evidence`, `definition`, `procedure`,
`algorithm`, `clinical-note`, and `referral-criteria`. They are transformed to
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
- Asset-library upload, threaded review comments, drag-to-reorder outline
  sections, word-level/side-by-side diff controls, and dedicated public/mobile/
  print preview shells require separate typed contracts and are not represented
  as complete by this implementation.

## Validation

Migration `00018_guideline_markdown_revisions.sql` has been validated up/down/up
against a disposable PostgreSQL 16/pgvector database. Backend focused tests
cover save-only behavior, optimistic conflicts, immutable restore, explicit
regeneration, and idempotent retries. Dashboard focused tests cover permission
states, editing, modes, keyboard save, failed-save preservation, publication
immutability, safe HTML handling, GFM, and clinical callouts. OpenAPI,
TypeScript, and Dart contracts are regenerated from the backend specification.
