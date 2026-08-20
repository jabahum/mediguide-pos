-- +goose Up

CREATE TABLE notification_preferences (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_preference_category CHECK (category IN (
    'clinical_content_updates', 'outbreak_alerts', 'emergency_alerts',
    'reminders', 'system_notices', 'product_announcements'
  ))
);
CREATE UNIQUE INDEX idx_notification_preference_user_category
  ON notification_preferences(user_id, category) WHERE deleted_at IS NULL;

CREATE TABLE notification_campaign_recipients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id uuid NOT NULL REFERENCES notification_campaigns(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_recipient_status CHECK (status IN ('pending', 'processing', 'completed', 'partially_failed', 'failed', 'cancelled'))
);
CREATE UNIQUE INDEX idx_notification_campaign_recipient
  ON notification_campaign_recipients(campaign_id, user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_campaign_recipients_user
  ON notification_campaign_recipients(user_id, campaign_id) WHERE deleted_at IS NULL;

CREATE TABLE notification_outbox_jobs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id uuid NOT NULL REFERENCES notification_campaigns(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES notification_campaign_recipients(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  firebase_device_id uuid REFERENCES firebase_devices(id) ON DELETE SET NULL,
  channel text NOT NULL,
  status text NOT NULL DEFAULT 'held',
  idempotency_key text NOT NULL,
  payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  attempt_count integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 8,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  locked_at timestamptz,
  locked_by text,
  provider_message_id text,
  last_error_code text,
  last_error_message text,
  accepted_at timestamptz,
  completed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_outbox_channel CHECK (channel IN ('in-app', 'push', 'email', 'sms')),
  CONSTRAINT chk_notification_outbox_status CHECK (status IN ('held', 'pending', 'processing', 'retry', 'accepted', 'failed', 'cancelled')),
  CONSTRAINT chk_notification_outbox_attempts CHECK (attempt_count >= 0 AND max_attempts BETWEEN 1 AND 20)
);
CREATE UNIQUE INDEX idx_notification_outbox_idempotency
  ON notification_outbox_jobs(idempotency_key) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_outbox_claim
  ON notification_outbox_jobs(status, next_attempt_at, created_at)
  WHERE deleted_at IS NULL AND status IN ('pending', 'retry');
CREATE INDEX idx_notification_outbox_campaign
  ON notification_outbox_jobs(campaign_id, status) WHERE deleted_at IS NULL;

CREATE TABLE notification_delivery_attempts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  outbox_job_id uuid NOT NULL REFERENCES notification_outbox_jobs(id) ON DELETE CASCADE,
  attempt_number integer NOT NULL,
  outcome text NOT NULL,
  provider_message_id text,
  error_code text,
  error_message text,
  retry_after_seconds integer,
  duration_ms bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_attempt_outcome CHECK (outcome IN ('validated', 'accepted', 'retryable', 'rejected')),
  CONSTRAINT uq_notification_delivery_attempt UNIQUE (outbox_job_id, attempt_number)
);

-- +goose Down
DROP TABLE IF EXISTS notification_delivery_attempts;
DROP TABLE IF EXISTS notification_outbox_jobs;
DROP TABLE IF EXISTS notification_campaign_recipients;
DROP TABLE IF EXISTS notification_preferences;
