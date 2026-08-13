-- +goose Up
-- Public/mobile guideline IDs are guideline_documents IDs. Keep historical
-- medical_guidelines rows intact, while enforcing the active relationship for
-- all new reading progress and usage events.
ALTER TABLE reading_progress
  DROP CONSTRAINT IF EXISTS reading_progress_guideline_document_id_fkey;
ALTER TABLE reading_progress
  ADD CONSTRAINT reading_progress_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES guideline_documents(id)
  ON DELETE CASCADE NOT VALID;

ALTER TABLE guideline_usage_logs
  DROP CONSTRAINT IF EXISTS guideline_usage_logs_guideline_document_id_fkey;
ALTER TABLE guideline_usage_logs
  ADD CONSTRAINT guideline_usage_logs_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES guideline_documents(id)
  ON DELETE CASCADE NOT VALID;

-- +goose Down
ALTER TABLE guideline_usage_logs
  DROP CONSTRAINT IF EXISTS guideline_usage_logs_guideline_document_id_fkey;
ALTER TABLE guideline_usage_logs
  ADD CONSTRAINT guideline_usage_logs_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES medical_guidelines(id)
  ON DELETE CASCADE NOT VALID;

ALTER TABLE reading_progress
  DROP CONSTRAINT IF EXISTS reading_progress_guideline_document_id_fkey;
ALTER TABLE reading_progress
  ADD CONSTRAINT reading_progress_guideline_document_id_fkey
  FOREIGN KEY (guideline_document_id) REFERENCES medical_guidelines(id)
  ON DELETE CASCADE NOT VALID;
