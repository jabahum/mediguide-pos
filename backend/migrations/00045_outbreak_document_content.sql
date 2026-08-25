-- +goose Up
ALTER TABLE outbreak_resources
  ADD COLUMN search_content text NOT NULL DEFAULT '',
  ADD COLUMN rendered_content text NOT NULL DEFAULT '',
  ADD COLUMN content_format varchar(32) NOT NULL DEFAULT '',
  ADD COLUMN extraction_status varchar(32) NOT NULL DEFAULT 'not_available',
  ADD COLUMN extracted_at timestamptz;

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

-- +goose Down
DROP INDEX IF EXISTS idx_outbreak_resources_document_search_weighted;
CREATE INDEX idx_outbreak_resources_document_search_weighted
  ON outbreak_resources USING GIN ((
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(document_number, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(issuing_authority, '') || ' ' ||
      coalesce(document_kind, '') || ' ' || coalesce(audience, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C')
  ))
  WHERE deleted_at IS NULL
    AND resource_type IN ('managed_document','downloadable_asset');
ALTER TABLE outbreak_resources
  DROP COLUMN IF EXISTS extracted_at,
  DROP COLUMN IF EXISTS extraction_status,
  DROP COLUMN IF EXISTS content_format,
  DROP COLUMN IF EXISTS rendered_content,
  DROP COLUMN IF EXISTS search_content;
