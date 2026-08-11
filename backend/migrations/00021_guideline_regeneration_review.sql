-- +goose Up
ALTER TABLE ingestion_jobs
  ADD COLUMN progress_stage TEXT NOT NULL DEFAULT 'queued',
  ADD COLUMN progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  ADD COLUMN cancel_requested_at TIMESTAMPTZ,
  ADD COLUMN canceled_at TIMESTAMPTZ;

ALTER TABLE ingestion_jobs DROP CONSTRAINT IF EXISTS ingestion_jobs_status_check;
ALTER TABLE ingestion_jobs ADD CONSTRAINT ingestion_jobs_status_check
  CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancel_requested', 'canceled'));

ALTER TABLE guideline_markdown_revisions DROP CONSTRAINT IF EXISTS guideline_markdown_revisions_structured_content_status_check;
ALTER TABLE guideline_markdown_revisions ADD CONSTRAINT guideline_markdown_revisions_structured_content_status_check
  CHECK (structured_content_status IN ('not_generated','outdated','queued','processing','review_required','approved','failed','canceled'));

ALTER TABLE guideline_versions DROP CONSTRAINT IF EXISTS guideline_versions_structured_content_status_check;
ALTER TABLE guideline_versions ADD CONSTRAINT guideline_versions_structured_content_status_check
  CHECK (structured_content_status IN ('not_generated','outdated','queued','processing','review_required','approved','failed','canceled'));

CREATE TABLE guideline_regeneration_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  revision_id UUID NOT NULL REFERENCES guideline_markdown_revisions(id) ON DELETE CASCADE,
  job_id UUID NOT NULL UNIQUE REFERENCES ingestion_jobs(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  before_snapshot JSONB NOT NULL DEFAULT '{}',
  after_snapshot JSONB NOT NULL DEFAULT '{}',
  comparison JSONB NOT NULL DEFAULT '{}',
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  decision_comment TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_guideline_regeneration_reviews_version ON guideline_regeneration_reviews(version_id, created_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE guideline_review_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES ingestion_jobs(id) ON DELETE CASCADE,
  block_id UUID REFERENCES guideline_content_blocks(id) ON DELETE SET NULL,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (length(btrim(body)) BETWEEN 1 AND 4000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_guideline_review_comments_job ON guideline_review_comments(job_id, created_at ASC) WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS guideline_review_comments;
DROP TABLE IF EXISTS guideline_regeneration_reviews;
ALTER TABLE ingestion_jobs DROP COLUMN IF EXISTS canceled_at, DROP COLUMN IF EXISTS cancel_requested_at, DROP COLUMN IF EXISTS progress_percent, DROP COLUMN IF EXISTS progress_stage;
ALTER TABLE ingestion_jobs DROP CONSTRAINT IF EXISTS ingestion_jobs_status_check;
ALTER TABLE guideline_markdown_revisions DROP CONSTRAINT IF EXISTS guideline_markdown_revisions_structured_content_status_check;
ALTER TABLE guideline_versions DROP CONSTRAINT IF EXISTS guideline_versions_structured_content_status_check;
UPDATE guideline_markdown_revisions SET structured_content_status='failed' WHERE structured_content_status='canceled';
UPDATE guideline_versions SET structured_content_status='failed' WHERE structured_content_status='canceled';
ALTER TABLE guideline_markdown_revisions ADD CONSTRAINT guideline_markdown_revisions_structured_content_status_check
  CHECK (structured_content_status IN ('not_generated','outdated','queued','processing','review_required','approved','failed'));
ALTER TABLE guideline_versions ADD CONSTRAINT guideline_versions_structured_content_status_check
  CHECK (structured_content_status IN ('not_generated','outdated','queued','processing','review_required','approved','failed'));
