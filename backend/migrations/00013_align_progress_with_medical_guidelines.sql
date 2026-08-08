-- +goose Up
-- Reading progress and mobile usage events use IDs returned by
-- /api/v2/medical-guidelines. Preserve any historical rows created against the
-- older guideline_documents table while enforcing the active relationship for
-- every new row.
ALTER TABLE reading_progress
  DROP CONSTRAINT IF EXISTS reading_progress_guideline_document_id_fkey;
ALTER TABLE reading_progress
  ADD CONSTRAINT reading_progress_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES medical_guidelines(id)
  ON DELETE CASCADE NOT VALID;

ALTER TABLE guideline_usage_logs
  DROP CONSTRAINT IF EXISTS guideline_usage_logs_guideline_document_id_fkey;
ALTER TABLE guideline_usage_logs
  ADD CONSTRAINT guideline_usage_logs_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES medical_guidelines(id)
  ON DELETE CASCADE NOT VALID;

-- +goose Down
ALTER TABLE guideline_usage_logs
  DROP CONSTRAINT IF EXISTS guideline_usage_logs_guideline_document_id_fkey;
ALTER TABLE guideline_usage_logs
  ADD CONSTRAINT guideline_usage_logs_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES guideline_documents(id)
  ON DELETE CASCADE NOT VALID;

ALTER TABLE reading_progress
  DROP CONSTRAINT IF EXISTS reading_progress_guideline_document_id_fkey;
ALTER TABLE reading_progress
  ADD CONSTRAINT reading_progress_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES guideline_documents(id)
  ON DELETE CASCADE NOT VALID;
