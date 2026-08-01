-- +goose Up
CREATE UNIQUE INDEX IF NOT EXISTS idx_reading_progress_user_guideline
  ON reading_progress(user_id, guideline_document_id) WHERE deleted_at IS NULL;
ALTER TABLE reading_progress ADD COLUMN IF NOT EXISTS total_sections bigint;
ALTER TABLE reading_progress ADD COLUMN IF NOT EXISTS is_completed boolean NOT NULL DEFAULT false;
ALTER TABLE reading_progress ADD COLUMN IF NOT EXISTS notes text;

ALTER TABLE guideline_usage_logs ADD COLUMN IF NOT EXISTS idempotency_key text;
ALTER TABLE abbreviation_usage_logs ADD COLUMN IF NOT EXISTS idempotency_key text;
ALTER TABLE consultant_usage_logs ADD COLUMN IF NOT EXISTS idempotency_key text;
ALTER TABLE ai_usage_logs ADD COLUMN IF NOT EXISTS idempotency_key text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_guideline_usage_idempotency
  ON guideline_usage_logs(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_abbreviation_usage_idempotency
  ON abbreviation_usage_logs(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_consultant_usage_idempotency
  ON consultant_usage_logs(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_usage_idempotency
  ON ai_usage_logs(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique_participants
  ON conversations(LEAST(participant1_user_id, participant2_user_id), GREATEST(participant1_user_id, participant2_user_id))
  WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_ai_usage_idempotency;
DROP INDEX IF EXISTS idx_conversations_unique_participants;
DROP INDEX IF EXISTS idx_consultant_usage_idempotency;
DROP INDEX IF EXISTS idx_abbreviation_usage_idempotency;
DROP INDEX IF EXISTS idx_guideline_usage_idempotency;
ALTER TABLE ai_usage_logs DROP COLUMN IF EXISTS idempotency_key;
ALTER TABLE consultant_usage_logs DROP COLUMN IF EXISTS idempotency_key;
ALTER TABLE abbreviation_usage_logs DROP COLUMN IF EXISTS idempotency_key;
ALTER TABLE guideline_usage_logs DROP COLUMN IF EXISTS idempotency_key;
DROP INDEX IF EXISTS idx_reading_progress_user_guideline;
ALTER TABLE reading_progress DROP COLUMN IF EXISTS notes;
ALTER TABLE reading_progress DROP COLUMN IF EXISTS is_completed;
ALTER TABLE reading_progress DROP COLUMN IF EXISTS total_sections;
