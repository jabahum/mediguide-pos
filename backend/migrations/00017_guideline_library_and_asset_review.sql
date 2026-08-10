-- +goose Up
ALTER TABLE guideline_assets
  ADD COLUMN review_status TEXT NOT NULL DEFAULT 'draft',
  ADD COLUMN reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at TIMESTAMPTZ;

CREATE INDEX idx_guideline_assets_review_status ON guideline_assets(review_status) WHERE deleted_at IS NULL;

UPDATE guideline_assets
SET review_status = 'reviewed', reviewed_at = COALESCE(updated_at, NOW())
WHERE deleted_at IS NULL
  AND (type IN ('original_pdf', 'offline_package') OR EXISTS (
    SELECT 1 FROM guideline_content_blocks block
    WHERE block.version_id = guideline_assets.version_id
      AND block.deleted_at IS NULL
      AND block.review_status = 'reviewed'
      AND block.content_json->>'asset_id' = guideline_assets.id::text
  ));

CREATE TABLE guideline_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_guideline_collections_user ON guideline_collections(user_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_guideline_collections_user_name ON guideline_collections(user_id, lower(name)) WHERE deleted_at IS NULL;

CREATE TABLE guideline_collection_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID NOT NULL REFERENCES guideline_collections(id) ON DELETE CASCADE,
  guideline_id UUID NOT NULL REFERENCES guideline_documents(id) ON DELETE CASCADE,
  sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_guideline_collection_items_collection ON guideline_collection_items(collection_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_guideline_collection_item ON guideline_collection_items(collection_id, guideline_id) WHERE deleted_at IS NULL;

CREATE TABLE guideline_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  guideline_id UUID NOT NULL REFERENCES guideline_documents(id) ON DELETE CASCADE,
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  asset_type TEXT NOT NULL CHECK (asset_type IN ('original_pdf', 'offline_package')),
  downloaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_guideline_downloads_user_date ON guideline_downloads(user_id, downloaded_at DESC) WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS guideline_downloads;
DROP TABLE IF EXISTS guideline_collection_items;
DROP TABLE IF EXISTS guideline_collections;
DROP INDEX IF EXISTS idx_guideline_assets_review_status;
ALTER TABLE guideline_assets
  DROP COLUMN IF EXISTS reviewed_at,
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS review_status;
