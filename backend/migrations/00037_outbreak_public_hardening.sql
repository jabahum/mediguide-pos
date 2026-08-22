-- +goose Up
ALTER TABLE outbreaks
  ADD CONSTRAINT outbreaks_metrics_array_check CHECK (jsonb_typeof(metrics) = 'array');
ALTER TABLE situation_reports
  ADD CONSTRAINT situation_reports_metrics_array_check CHECK (jsonb_typeof(metrics) = 'array'),
  ADD CONSTRAINT situation_reports_highlights_array_check CHECK (jsonb_typeof(key_highlights) = 'array');

CREATE INDEX idx_outbreaks_public_filters
  ON outbreaks (status, region_id, effective_at, last_update DESC, id DESC)
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND published_at IS NOT NULL;
CREATE INDEX idx_outbreaks_public_disease
  ON outbreaks (lower(disease_type), last_update DESC, id DESC)
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND published_at IS NOT NULL;
CREATE INDEX idx_outbreaks_public_search
  ON outbreaks USING GIN (
    to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(disease_type, '') || ' ' || coalesce(geographic_area, '') || ' ' || coalesce(source_organization, ''))
  )
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND published_at IS NOT NULL;

CREATE INDEX idx_situation_reports_public_filters
  ON situation_reports (region_id, effective_at, updated_at DESC, publication_date DESC, id DESC)
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND status = 'published' AND published_at IS NOT NULL;
CREATE INDEX idx_situation_reports_public_outbreak
  ON situation_reports (outbreak_id, publication_date DESC, id DESC)
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND status = 'published' AND published_at IS NOT NULL;
CREATE INDEX idx_situation_reports_public_search
  ON situation_reports USING GIN (
    to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(geographic_area, '') || ' ' || coalesce(source_organization, ''))
  )
  WHERE deleted_at IS NULL AND withdrawn_at IS NULL AND status = 'published' AND published_at IS NOT NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_situation_reports_public_search;
DROP INDEX IF EXISTS idx_situation_reports_public_outbreak;
DROP INDEX IF EXISTS idx_situation_reports_public_filters;
DROP INDEX IF EXISTS idx_outbreaks_public_search;
DROP INDEX IF EXISTS idx_outbreaks_public_disease;
DROP INDEX IF EXISTS idx_outbreaks_public_filters;
ALTER TABLE situation_reports
  DROP CONSTRAINT IF EXISTS situation_reports_highlights_array_check,
  DROP CONSTRAINT IF EXISTS situation_reports_metrics_array_check;
ALTER TABLE outbreaks DROP CONSTRAINT IF EXISTS outbreaks_metrics_array_check;
