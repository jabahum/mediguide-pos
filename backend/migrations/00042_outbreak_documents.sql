-- +goose Up
ALTER TABLE outbreak_resources
  ADD COLUMN description TEXT NOT NULL DEFAULT '',
  ADD COLUMN document_kind TEXT NOT NULL DEFAULT 'other',
  ADD COLUMN issuing_authority TEXT NOT NULL DEFAULT '',
  ADD COLUMN document_number TEXT NOT NULL DEFAULT '',
  ADD COLUMN version TEXT NOT NULL DEFAULT '',
  ADD COLUMN language TEXT NOT NULL DEFAULT 'en',
  ADD COLUMN audience TEXT NOT NULL DEFAULT '',
  ADD COLUMN effective_date TIMESTAMPTZ,
  ADD COLUMN review_date TIMESTAMPTZ,
  ADD COLUMN expires_at TIMESTAMPTZ,
  ADD COLUMN storage_key TEXT NOT NULL DEFAULT '',
  ADD COLUMN original_filename TEXT NOT NULL DEFAULT '',
  ADD COLUMN mime_type TEXT NOT NULL DEFAULT '',
  ADD COLUMN file_size BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN checksum_sha256 TEXT NOT NULL DEFAULT '',
  ADD COLUMN page_count INTEGER,
  ADD CONSTRAINT outbreak_resources_document_kind_check CHECK (
    document_kind IN (
      'sop','case_definition','ipc_protocol','laboratory_protocol',
      'surveillance_protocol','contact_tracing_guide','treatment_protocol',
      'referral_protocol','training_material','checklist',
      'communication_material','form','policy','situation_report_attachment','other'
    )
  ),
  ADD CONSTRAINT outbreak_resources_file_size_check CHECK (file_size >= 0),
  ADD CONSTRAINT outbreak_resources_page_count_check CHECK (page_count IS NULL OR page_count > 0),
  ADD CONSTRAINT outbreak_resources_document_dates_check CHECK (
    (review_date IS NULL OR effective_date IS NULL OR review_date >= effective_date)
    AND (expires_at IS NULL OR effective_date IS NULL OR expires_at >= effective_date)
  ),
  ADD CONSTRAINT outbreak_resources_checksum_check CHECK (
    checksum_sha256 = '' OR checksum_sha256 ~ '^[0-9a-f]{64}$'
  );

UPDATE outbreak_resources
SET document_kind = CASE resource_type
  WHEN 'situation_report' THEN 'situation_report_attachment'
  ELSE 'other'
END,
language = 'en';

CREATE INDEX idx_outbreak_resources_documents
  ON outbreak_resources (outbreak_id, document_kind, status, effective_date DESC, id DESC)
  WHERE deleted_at IS NULL AND resource_type IN ('managed_document','downloadable_asset');
CREATE INDEX idx_outbreak_resources_document_authority
  ON outbreak_resources (lower(issuing_authority), language, id)
  WHERE deleted_at IS NULL AND resource_type IN ('managed_document','downloadable_asset');
CREATE INDEX idx_outbreak_resources_document_search
  ON outbreak_resources USING GIN (
    to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
      coalesce(document_number, '') || ' ' || coalesce(issuing_authority, '') || ' ' ||
      coalesce(document_kind, '') || ' ' || coalesce(audience, ''))
  )
  WHERE deleted_at IS NULL AND resource_type IN ('managed_document','downloadable_asset');
CREATE UNIQUE INDEX idx_outbreak_resources_published_document_version
  ON outbreak_resources (outbreak_id, lower(document_number), lower(version))
  WHERE deleted_at IS NULL AND status = 'published'
    AND resource_type IN ('managed_document','downloadable_asset')
    AND document_number <> '' AND version <> '';
CREATE UNIQUE INDEX idx_outbreak_resources_storage_key
  ON outbreak_resources (storage_key)
  WHERE deleted_at IS NULL AND storage_key <> '';

-- +goose Down
DROP INDEX IF EXISTS idx_outbreak_resources_storage_key;
DROP INDEX IF EXISTS idx_outbreak_resources_published_document_version;
DROP INDEX IF EXISTS idx_outbreak_resources_document_search;
DROP INDEX IF EXISTS idx_outbreak_resources_document_authority;
DROP INDEX IF EXISTS idx_outbreak_resources_documents;
ALTER TABLE outbreak_resources
  DROP CONSTRAINT IF EXISTS outbreak_resources_checksum_check,
  DROP CONSTRAINT IF EXISTS outbreak_resources_document_dates_check,
  DROP CONSTRAINT IF EXISTS outbreak_resources_page_count_check,
  DROP CONSTRAINT IF EXISTS outbreak_resources_file_size_check,
  DROP CONSTRAINT IF EXISTS outbreak_resources_document_kind_check,
  DROP COLUMN IF EXISTS page_count,
  DROP COLUMN IF EXISTS checksum_sha256,
  DROP COLUMN IF EXISTS file_size,
  DROP COLUMN IF EXISTS mime_type,
  DROP COLUMN IF EXISTS original_filename,
  DROP COLUMN IF EXISTS storage_key,
  DROP COLUMN IF EXISTS expires_at,
  DROP COLUMN IF EXISTS review_date,
  DROP COLUMN IF EXISTS effective_date,
  DROP COLUMN IF EXISTS audience,
  DROP COLUMN IF EXISTS language,
  DROP COLUMN IF EXISTS version,
  DROP COLUMN IF EXISTS document_number,
  DROP COLUMN IF EXISTS issuing_authority,
  DROP COLUMN IF EXISTS document_kind,
  DROP COLUMN IF EXISTS description;
