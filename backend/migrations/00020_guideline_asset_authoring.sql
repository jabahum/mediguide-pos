-- +goose Up
ALTER TABLE guideline_assets
  ADD COLUMN alternative_text TEXT NOT NULL DEFAULT '',
  ADD COLUMN caption TEXT NOT NULL DEFAULT '',
  ADD COLUMN source TEXT NOT NULL DEFAULT '',
  ADD COLUMN attribution TEXT NOT NULL DEFAULT '',
  ADD COLUMN license TEXT NOT NULL DEFAULT '',
  ADD COLUMN figure_number INTEGER,
  ADD COLUMN clinically_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD CONSTRAINT guideline_assets_figure_number_positive
    CHECK (figure_number IS NULL OR figure_number > 0);

CREATE INDEX idx_guideline_assets_uploaded_by
  ON guideline_assets(uploaded_by) WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_guideline_assets_uploaded_by;
ALTER TABLE guideline_assets
  DROP CONSTRAINT IF EXISTS guideline_assets_figure_number_positive,
  DROP COLUMN IF EXISTS uploaded_by,
  DROP COLUMN IF EXISTS clinically_sensitive,
  DROP COLUMN IF EXISTS figure_number,
  DROP COLUMN IF EXISTS license,
  DROP COLUMN IF EXISTS attribution,
  DROP COLUMN IF EXISTS source,
  DROP COLUMN IF EXISTS caption,
  DROP COLUMN IF EXISTS alternative_text;
