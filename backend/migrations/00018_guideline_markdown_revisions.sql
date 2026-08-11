-- +goose Up
CREATE TABLE guideline_markdown_revisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES guideline_documents(id) ON DELETE CASCADE,
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  revision_number INTEGER NOT NULL CHECK (revision_number > 0),
  storage_key TEXT NOT NULL,
  checksum TEXT NOT NULL DEFAULT '',
  size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  source_type TEXT NOT NULL CHECK (source_type IN (
    'blank', 'template', 'uploaded_markdown', 'pdf_generated',
    'manual_edit', 'restored', 'duplicated'
  )),
  parent_revision_id UUID REFERENCES guideline_markdown_revisions(id) ON DELETE SET NULL,
  source_ingestion_job_id UUID REFERENCES ingestion_jobs(id) ON DELETE SET NULL,
  regeneration_job_id UUID REFERENCES ingestion_jobs(id) ON DELETE SET NULL,
  checkpoint_name TEXT NOT NULL DEFAULT '',
  change_summary TEXT NOT NULL DEFAULT '',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  structured_content_status TEXT NOT NULL DEFAULT 'outdated' CHECK (
    structured_content_status IN (
      'not_generated', 'outdated', 'queued', 'processing',
      'review_required', 'approved', 'failed'
    )
  ),
  review_state TEXT NOT NULL DEFAULT 'draft' CHECK (
    review_state IN ('draft', 'review_required', 'approved', 'rejected')
  ),
  publication_state TEXT NOT NULL DEFAULT 'draft' CHECK (
    publication_state IN ('draft', 'published', 'superseded')
  ),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX uq_guideline_markdown_revision_number
  ON guideline_markdown_revisions(version_id, revision_number)
  WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_guideline_markdown_current_revision
  ON guideline_markdown_revisions(version_id)
  WHERE is_current = TRUE AND deleted_at IS NULL;
CREATE INDEX idx_guideline_markdown_revisions_version_date
  ON guideline_markdown_revisions(version_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_markdown_revisions_editor
  ON guideline_markdown_revisions(created_by, created_at DESC)
  WHERE deleted_at IS NULL;

ALTER TABLE guideline_versions
  ADD COLUMN current_markdown_revision_id UUID REFERENCES guideline_markdown_revisions(id) ON DELETE SET NULL,
  ADD COLUMN structured_markdown_revision_id UUID REFERENCES guideline_markdown_revisions(id) ON DELETE SET NULL,
  ADD COLUMN published_markdown_revision_id UUID REFERENCES guideline_markdown_revisions(id) ON DELETE SET NULL,
  ADD COLUMN structured_content_status TEXT NOT NULL DEFAULT 'not_generated' CHECK (
    structured_content_status IN (
      'not_generated', 'outdated', 'queued', 'processing',
      'review_required', 'approved', 'failed'
    )
  );

WITH existing AS (
  SELECT
    gen_random_uuid() AS revision_id,
    gv.document_id,
    gv.id AS version_id,
    gv.markdown_file_key,
    gv.checksum,
    gv.status,
    gv.created_at,
    gv.updated_at
  FROM guideline_versions gv
  WHERE gv.deleted_at IS NULL AND gv.markdown_file_key <> ''
), inserted AS (
  INSERT INTO guideline_markdown_revisions (
    id, document_id, version_id, revision_number, storage_key, checksum,
    source_type, is_current, structured_content_status, review_state,
    publication_state, created_at, updated_at
  )
  SELECT
    revision_id, document_id, version_id, 1, markdown_file_key, checksum,
    CASE WHEN checksum <> '' THEN 'pdf_generated' ELSE 'uploaded_markdown' END,
    TRUE,
    CASE WHEN status = 'published' THEN 'approved' ELSE 'review_required' END,
    CASE WHEN status = 'published' THEN 'approved' ELSE 'review_required' END,
    CASE WHEN status = 'published' THEN 'published' ELSE 'draft' END,
    created_at, updated_at
  FROM existing
  RETURNING id, version_id, structured_content_status, publication_state
)
UPDATE guideline_versions gv
SET current_markdown_revision_id = inserted.id,
    structured_markdown_revision_id = inserted.id,
    published_markdown_revision_id = CASE
      WHEN inserted.publication_state = 'published' THEN inserted.id ELSE NULL END,
    structured_content_status = inserted.structured_content_status
FROM inserted
WHERE gv.id = inserted.version_id;

-- +goose Down
ALTER TABLE guideline_versions
  DROP COLUMN IF EXISTS structured_content_status,
  DROP COLUMN IF EXISTS published_markdown_revision_id,
  DROP COLUMN IF EXISTS structured_markdown_revision_id,
  DROP COLUMN IF EXISTS current_markdown_revision_id;
DROP TABLE IF EXISTS guideline_markdown_revisions;
