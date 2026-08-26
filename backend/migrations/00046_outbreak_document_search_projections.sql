-- +goose Up
ALTER TABLE outbreak_resources
  ADD COLUMN search_headings text NOT NULL DEFAULT '',
  ADD COLUMN extraction_error text NOT NULL DEFAULT '',
  ADD COLUMN extraction_source_checksum varchar(64) NOT NULL DEFAULT '',
  ADD COLUMN derived_content_checksum varchar(64) NOT NULL DEFAULT '',
  ADD COLUMN search_index_status varchar(32) NOT NULL DEFAULT 'not_indexed',
  ADD COLUMN search_schema_version integer NOT NULL DEFAULT 1,
  ADD COLUMN content_sections jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN source_page_map jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN indexed_at timestamptz;

UPDATE outbreak_resources
SET extraction_source_checksum = checksum_sha256,
    -- Existing projections predate derived checksums. Reprocessing fills this
    -- value without requiring pgcrypto in production databases.
    derived_content_checksum = '',
    search_index_status = CASE
      WHEN status = 'published' AND approved_at IS NOT NULL AND extraction_status = 'ready' THEN 'indexed'
      WHEN extraction_status = 'ready' THEN 'pending_approval'
      ELSE 'not_indexed'
    END,
    indexed_at = CASE
      WHEN status = 'published' AND approved_at IS NOT NULL AND extraction_status = 'ready' THEN COALESCE(extracted_at, updated_at)
      ELSE NULL
    END
WHERE resource_type IN ('managed_document', 'downloadable_asset');

DROP INDEX IF EXISTS idx_outbreak_resources_document_search_weighted;
CREATE INDEX idx_outbreak_resources_document_search_weighted
  ON outbreak_resources USING GIN ((
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(document_number, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(issuing_authority, '') || ' ' ||
      coalesce(document_kind, '') || ' ' || coalesce(audience, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(search_headings, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C') ||
    setweight(to_tsvector('simple', coalesce(search_content, '')), 'D')
  ))
  WHERE deleted_at IS NULL
    AND status = 'published'
    AND approved_at IS NOT NULL
    AND withdrawn_at IS NULL
    AND resource_type IN ('managed_document','downloadable_asset');

-- +goose Down
DROP INDEX IF EXISTS idx_outbreak_resources_document_search_weighted;
CREATE INDEX idx_outbreak_resources_document_search_weighted
  ON outbreak_resources USING GIN ((
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(document_number, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(issuing_authority, '') || ' ' ||
      coalesce(document_kind, '') || ' ' || coalesce(audience, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C') ||
    setweight(to_tsvector('simple', coalesce(search_content, '')), 'D')
  ))
  WHERE deleted_at IS NULL
    AND resource_type IN ('managed_document','downloadable_asset');

ALTER TABLE outbreak_resources
  DROP COLUMN IF EXISTS indexed_at,
  DROP COLUMN IF EXISTS source_page_map,
  DROP COLUMN IF EXISTS content_sections,
  DROP COLUMN IF EXISTS search_schema_version,
  DROP COLUMN IF EXISTS search_index_status,
  DROP COLUMN IF EXISTS derived_content_checksum,
  DROP COLUMN IF EXISTS extraction_source_checksum,
  DROP COLUMN IF EXISTS extraction_error,
  DROP COLUMN IF EXISTS search_headings;
