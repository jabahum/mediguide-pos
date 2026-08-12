-- +goose Up
ALTER TABLE guideline_documents
  ADD COLUMN intended_population TEXT NOT NULL DEFAULT '',
  ADD COLUMN healthcare_level TEXT NOT NULL DEFAULT '';

-- +goose Down
ALTER TABLE guideline_documents
  DROP COLUMN IF EXISTS healthcare_level,
  DROP COLUMN IF EXISTS intended_population;
