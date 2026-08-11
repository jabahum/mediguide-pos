-- +goose Up
ALTER TABLE guideline_markdown_revisions
  ADD COLUMN anchor_metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN guideline_markdown_revisions.anchor_metadata_json IS
  'Stable authoring anchors stored separately from Markdown; revision immutable.';

-- +goose Down
ALTER TABLE guideline_markdown_revisions
  DROP COLUMN IF EXISTS anchor_metadata_json;
