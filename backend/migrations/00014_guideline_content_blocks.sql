-- +goose Up
CREATE TABLE guideline_content_blocks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  version_id uuid NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  section_id uuid REFERENCES guideline_sections(id) ON DELETE SET NULL,
  type text NOT NULL CHECK (type IN (
    'heading', 'paragraph', 'ordered_list', 'unordered_list', 'table',
    'figure', 'recommendation', 'warning', 'key_point', 'algorithm',
    'reference', 'page_break', 'unknown'
  )),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  content_json jsonb NOT NULL CHECK (jsonb_typeof(content_json) = 'object'),
  page_start integer CHECK (page_start IS NULL OR page_start > 0),
  page_end integer CHECK (page_end IS NULL OR page_end > 0),
  extraction_confidence double precision CHECK (
    extraction_confidence IS NULL OR
    (extraction_confidence >= 0 AND extraction_confidence <= 1)
  ),
  review_status text NOT NULL DEFAULT 'draft'
    CHECK (review_status IN ('draft', 'reviewed', 'rejected')),
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT guideline_content_blocks_page_range
    CHECK (page_start IS NULL OR page_end IS NULL OR page_end >= page_start),
  CONSTRAINT guideline_content_blocks_review_audit
    CHECK (
      (review_status = 'draft' AND reviewed_by IS NULL AND reviewed_at IS NULL) OR
      (review_status IN ('reviewed', 'rejected') AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE INDEX idx_guideline_content_blocks_version_order
  ON guideline_content_blocks(version_id, sort_order)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_content_blocks_section_order
  ON guideline_content_blocks(section_id, sort_order)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_content_blocks_review_status
  ON guideline_content_blocks(version_id, review_status)
  WHERE deleted_at IS NULL;

CREATE TABLE guideline_assets (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  version_id uuid NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  section_id uuid REFERENCES guideline_sections(id) ON DELETE SET NULL,
  type text NOT NULL CHECK (type IN (
    'original_pdf', 'figure', 'diagram', 'thumbnail',
    'supplementary_document', 'offline_package'
  )),
  mime_type text NOT NULL,
  checksum text NOT NULL,
  storage_key text NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  original_filename text,
  page_start integer CHECK (page_start IS NULL OR page_start > 0),
  page_end integer CHECK (page_end IS NULL OR page_end > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT guideline_assets_page_range
    CHECK (page_start IS NULL OR page_end IS NULL OR page_end >= page_start)
);

CREATE UNIQUE INDEX idx_guideline_assets_version_storage_key
  ON guideline_assets(version_id, storage_key)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_assets_version_type
  ON guideline_assets(version_id, type)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_assets_section
  ON guideline_assets(section_id)
  WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS guideline_assets;
DROP TABLE IF EXISTS guideline_content_blocks;
