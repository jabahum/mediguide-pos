# Guideline ingestion and regeneration pipeline

The worker consumes one immutable guideline version and source revision. It
supports original PDFs and uploaded or edited Markdown.

```text
immutable PDF or Markdown source
  -> download and checksum validation
  -> PDF extraction or UTF-8 Markdown parse
  -> safe normalized Markdown and heading hierarchy
  -> typed sections, blocks, tables, figures and callouts
  -> deterministic overlapping chunks
  -> embeddings
  -> transactional persistence as review-required
  -> regeneration comparison and reviewer decision
  -> publication exposes only the accepted revision
```

## Source fidelity and safety

Markdown parsing preserves headings, paragraphs, ordered/unordered lists, GFM
tables, supported clinical callouts and authoring front matter. Invalid UTF-8,
unsafe raw HTML, malformed callouts and broken asset references produce errors
or warnings; the worker never executes HTML. Clinical doses, units,
contraindications and recommendations are not silently corrected.

PDF extraction uses PyMuPDF for text and pdfplumber for tables. The original
PDF is immutable and remains the fidelity reference. Page provenance is
retained for unchanged PDF-derived blocks only. Markdown-only sources have no
PDF page citations. The worker never fabricates source pages or citations.

## Idempotency, supersession, and failure handling

Jobs carry the exact version, revision, source object key/checksum and
idempotency key. Retrying the same job is safe. Before persistence, the worker
checks that the revision is still current; superseded jobs exit without
overwriting newer author work. Persistence replaces derived rows in one
transaction and uses conflict-safe asset writes, so a retry cannot duplicate a
version/storage-key asset.

Progress stages are downloading, parsing, structure building, chunking,
embedding, persistence, review-required, completed, failed and canceled.
Cancellation is cooperative and is refused after transactional persistence
starts. A failure preserves the immutable source and last successful structured
projection; it never partially replaces public or RAG content.

## Review, embeddings, and retrieval

New sections, blocks and chunks are review-required. High-risk clinical blocks
need explicit authorized review. RAG retrieval filters to the published version
and approved chunks; draft, rejected, failed and superseded chunks are never
eligible. Chunk/block provenance includes document, version, revision, job,
section/block and available page metadata so citations resolve to the accepted
publication.

The embedding provider, model and dimension must match the database schema and
runtime configuration. Changing them requires an explicit re-embedding plan;
incompatible vectors must not be mixed. Provider failures fail the job while
retaining the previous approved index.

## Runtime requirements and troubleshooting

The worker requires PostgreSQL/pgvector, Redis, MinIO-compatible object storage
and the configured embedding provider. Backend and worker must share the worker
API secret. The image must include PDF/native dependencies and run both worker
API and loop health checks in Compose.

- Repeated queue retries: inspect Redis connectivity and the job's last error.
- Source not found: verify the immutable MinIO key; never use a mutable alias.
- Duplicate asset constraint: reuse or conflict-upsert the existing
  version/storage-key row; a retry must not create a second asset.
- Embedding dimension error: align provider, model and dimension before retry.
- Superseded status: regenerate the newest revision explicitly.
- `review_required` is successful processing, not publication. Finish review
  and acceptance in the dashboard before publishing.
