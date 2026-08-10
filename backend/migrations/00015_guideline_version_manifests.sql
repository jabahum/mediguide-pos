-- +goose Up
CREATE TABLE guideline_version_manifests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  guideline_id uuid NOT NULL REFERENCES guideline_documents(id) ON DELETE CASCADE,
  version_id uuid NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  version text NOT NULL,
  schema_version integer NOT NULL DEFAULT 1 CHECK (schema_version > 0),
  package_version integer NOT NULL DEFAULT 1 CHECK (package_version > 0),
  extraction_quality text NOT NULL CHECK (extraction_quality IN (
    'reviewed', 'partially_reviewed', 'unreviewed', 'markdown_fallback'
  )),
  has_chapters boolean NOT NULL DEFAULT false,
  has_key_points boolean NOT NULL DEFAULT false,
  has_tables boolean NOT NULL DEFAULT false,
  has_figures boolean NOT NULL DEFAULT false,
  has_algorithms boolean NOT NULL DEFAULT false,
  has_original_pdf boolean NOT NULL DEFAULT false,
  has_offline_package boolean NOT NULL DEFAULT false,
  section_count integer NOT NULL DEFAULT 0 CHECK (section_count >= 0),
  block_count integer NOT NULL DEFAULT 0 CHECK (block_count >= 0),
  table_count integer NOT NULL DEFAULT 0 CHECK (table_count >= 0),
  figure_count integer NOT NULL DEFAULT 0 CHECK (figure_count >= 0),
  algorithm_count integer NOT NULL DEFAULT 0 CHECK (algorithm_count >= 0),
  checksum text NOT NULL,
  etag text NOT NULL,
  generated_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT guideline_version_manifests_document_version_unique
    UNIQUE (guideline_id, version_id),
  CONSTRAINT guideline_version_manifests_version_unique UNIQUE (version_id)
);

CREATE INDEX idx_guideline_version_manifests_guideline
  ON guideline_version_manifests(guideline_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_guideline_version_manifests_quality
  ON guideline_version_manifests(extraction_quality)
  WHERE deleted_at IS NULL;

-- Existing published versions predate structured blocks. Backfill an explicit
-- Markdown fallback manifest without inferring any reviewed capabilities.
WITH published_versions AS (
  SELECT
    gd.id AS guideline_id,
    gv.id AS version_id,
    gv.version,
    (gv.original_file_key IS NOT NULL AND btrim(gv.original_file_key) <> '') AS has_original_pdf,
    md5(concat_ws(
      '|', gd.id::text, gv.id::text, gv.version, '1', '1',
      'markdown_fallback',
      (gv.original_file_key IS NOT NULL AND btrim(gv.original_file_key) <> '')::text
    )) AS checksum
  FROM guideline_versions gv
  JOIN guideline_documents gd ON gd.id = gv.document_id
  WHERE gv.deleted_at IS NULL
    AND gd.deleted_at IS NULL
    AND lower(btrim(gv.status)) = 'published'
)
INSERT INTO guideline_version_manifests (
  guideline_id,
  version_id,
  version,
  schema_version,
  package_version,
  extraction_quality,
  has_original_pdf,
  checksum,
  etag,
  generated_at
)
SELECT
  guideline_id,
  version_id,
  version,
  1,
  1,
  'markdown_fallback',
  has_original_pdf,
  checksum,
  '"md5-' || checksum || '"',
  now()
FROM published_versions
ON CONFLICT (version_id) DO NOTHING;

-- +goose Down
DROP TABLE IF EXISTS guideline_version_manifests;
