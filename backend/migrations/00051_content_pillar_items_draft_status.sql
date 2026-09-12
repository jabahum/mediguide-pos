-- +goose Up
ALTER TABLE content_pillar_items
  DROP CONSTRAINT IF EXISTS content_pillar_items_status_check;
ALTER TABLE content_pillar_items
  ALTER COLUMN status SET DEFAULT 'draft';
ALTER TABLE content_pillar_items
  ADD CONSTRAINT content_pillar_items_status_check
  CHECK (status IN ('draft','active','inactive','archived'));

-- +goose Down
ALTER TABLE content_pillar_items
  DROP CONSTRAINT IF EXISTS content_pillar_items_status_check;
UPDATE content_pillar_items SET status = 'inactive' WHERE status = 'draft';
ALTER TABLE content_pillar_items
  ALTER COLUMN status SET DEFAULT 'active';
ALTER TABLE content_pillar_items
  ADD CONSTRAINT content_pillar_items_status_check
  CHECK (status IN ('active','inactive','archived'));
