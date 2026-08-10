-- +goose Up
ALTER TABLE guideline_versions
  ADD COLUMN extraction_schema_version integer NOT NULL DEFAULT 0,
  ADD COLUMN extraction_metadata_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN extraction_warnings_json jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE guideline_content_blocks
  ADD COLUMN source_fingerprint text,
  ADD COLUMN provenance_json jsonb NOT NULL DEFAULT '{}'::jsonb;

UPDATE guideline_content_blocks SET source_fingerprint = id::text WHERE source_fingerprint IS NULL;
ALTER TABLE guideline_content_blocks ALTER COLUMN source_fingerprint SET NOT NULL;
CREATE UNIQUE INDEX idx_guideline_content_blocks_source_fingerprint
  ON guideline_content_blocks(version_id, source_fingerprint) WHERE deleted_at IS NULL;

ALTER TABLE guideline_assets
  ADD COLUMN source_fingerprint text,
  ADD COLUMN provenance_json jsonb NOT NULL DEFAULT '{}'::jsonb;

UPDATE guideline_assets SET source_fingerprint = id::text WHERE source_fingerprint IS NULL;
ALTER TABLE guideline_assets ALTER COLUMN source_fingerprint SET NOT NULL;
CREATE UNIQUE INDEX idx_guideline_assets_source_fingerprint
  ON guideline_assets(version_id, source_fingerprint) WHERE deleted_at IS NULL;

ALTER TABLE guideline_chunks
  ADD COLUMN document_id uuid REFERENCES guideline_documents(id) ON DELETE CASCADE,
  ADD COLUMN block_id uuid REFERENCES guideline_content_blocks(id) ON DELETE SET NULL;

UPDATE guideline_chunks gc
SET document_id = gv.document_id
FROM guideline_versions gv
WHERE gv.id = gc.version_id AND gc.document_id IS NULL;

ALTER TABLE guideline_chunks ALTER COLUMN document_id SET NOT NULL;
CREATE INDEX idx_guideline_chunks_document_id
  ON guideline_chunks(document_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_chunks_block_id
  ON guideline_chunks(block_id) WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_guideline_chunks_block_id;
DROP INDEX IF EXISTS idx_guideline_chunks_document_id;
ALTER TABLE guideline_chunks DROP COLUMN IF EXISTS block_id, DROP COLUMN IF EXISTS document_id;

DROP INDEX IF EXISTS idx_guideline_assets_source_fingerprint;
ALTER TABLE guideline_assets DROP COLUMN IF EXISTS provenance_json, DROP COLUMN IF EXISTS source_fingerprint;

DROP INDEX IF EXISTS idx_guideline_content_blocks_source_fingerprint;
ALTER TABLE guideline_content_blocks DROP COLUMN IF EXISTS provenance_json, DROP COLUMN IF EXISTS source_fingerprint;

ALTER TABLE guideline_versions
  DROP COLUMN IF EXISTS extraction_warnings_json,
  DROP COLUMN IF EXISTS extraction_metadata_json,
  DROP COLUMN IF EXISTS extraction_schema_version;
