-- +goose Up
CREATE EXTENSION IF NOT EXISTS pg_trgm;

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

CREATE INDEX idx_outbreak_resources_document_title_trgm
  ON outbreak_resources USING GIN (lower(title) gin_trgm_ops)
  WHERE deleted_at IS NULL
    AND resource_type IN ('managed_document','downloadable_asset');

CREATE INDEX idx_outbreak_resources_document_number_trgm
  ON outbreak_resources USING GIN (lower(document_number) gin_trgm_ops)
  WHERE deleted_at IS NULL
    AND resource_type IN ('managed_document','downloadable_asset')
    AND document_number <> '';

CREATE INDEX idx_outbreaks_title_trgm
  ON outbreaks USING GIN (lower(title) gin_trgm_ops)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_outbreaks_title_search
  ON outbreaks USING GIN (setweight(to_tsvector('simple', coalesce(title, '')), 'B'))
  WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_outbreaks_title_search;
DROP INDEX IF EXISTS idx_outbreaks_title_trgm;
DROP INDEX IF EXISTS idx_outbreak_resources_document_number_trgm;
DROP INDEX IF EXISTS idx_outbreak_resources_document_title_trgm;
DROP INDEX IF EXISTS idx_outbreak_resources_document_search_weighted;
