# MediGuide dashboard

## Guideline Markdown editor

Create a guideline version and upload either a PDF or a UTF-8 `.md`/`.markdown` file. After the
source has been processed, open **Medical Guidelines** and choose **Edit Markdown** or
**Preview Markdown**. The editor route is:

```text
/guidelines/{guideline-document-id}/versions/{version-id}/markdown
```

Users with dashboard content read access can preview extracted Markdown. Users with content update
access can edit draft versions and save with the button or `Command+S`/`Ctrl+S`. Published versions
are read-only; create a new version before revising published content.

The preview uses `react-markdown` and GFM support. Raw embedded HTML is disabled. Saving uses the
permission-protected v2 guideline API rather than the legacy collection API. Each save stores a
new immutable Markdown source object and queues regeneration of sections, typed blocks, search
chunks, and embeddings. The version returns to draft/review-required while that work runs; review
the regenerated structure before publishing.

Markdown-only versions do not expose an original PDF or PDF page citations. Editing Markdown that
was generated from a PDF keeps the original PDF available as the fidelity reference.

The API currently returns no revision or ETag for extracted Markdown, so the editor cannot detect
another user saving the same version concurrently. Autosave is intentionally disabled until the
backend supports optimistic concurrency.

## Quality commands

```bash
bun run lint
bun run typecheck
bun run test
bun run build
```
