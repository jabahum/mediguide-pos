-- +goose Up

ALTER TABLE notification_campaigns DROP CONSTRAINT chk_notification_campaign_status;
ALTER TABLE notification_campaigns
  ADD CONSTRAINT chk_notification_campaign_status CHECK (status IN ('draft', 'pending_review', 'approved', 'scheduled', 'queued', 'paused', 'sending', 'completed', 'partially_failed', 'failed', 'cancelled'));
ALTER TABLE notification_campaigns
  ADD COLUMN campaign_variables_json jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE notification_deliveries (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id uuid NOT NULL REFERENCES notification_campaigns(id) ON DELETE CASCADE,
  notification_id uuid REFERENCES notifications(id) ON DELETE SET NULL,
  outbox_job_id uuid NOT NULL REFERENCES notification_outbox_jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  firebase_device_id uuid REFERENCES firebase_devices(id) ON DELETE SET NULL,
  channel text NOT NULL,
  provider_message_id text,
  state text NOT NULL DEFAULT 'queued',
  attempt_count integer NOT NULL DEFAULT 0,
  attempted_at timestamptz,
  accepted_at timestamptz,
  failed_at timestamptz,
  delivered_at timestamptz,
  opened_at timestamptz,
  clicked_at timestamptz,
  expired_at timestamptz,
  error_category text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_delivery_channel CHECK (channel IN ('in-app', 'push', 'email', 'sms')),
  CONSTRAINT chk_notification_delivery_state CHECK (state IN ('queued', 'attempted', 'accepted', 'rejected', 'delivered', 'opened', 'clicked', 'expired')),
  CONSTRAINT chk_notification_delivery_attempt_count CHECK (attempt_count >= 0)
);
CREATE UNIQUE INDEX idx_notification_deliveries_outbox_job
  ON notification_deliveries(outbox_job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_deliveries_campaign_state
  ON notification_deliveries(campaign_id, state, created_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_deliveries_user_notification
  ON notification_deliveries(user_id, notification_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_deliveries_daily
  ON notification_deliveries(created_at, channel, state) WHERE deleted_at IS NULL;

CREATE TABLE notification_delivery_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  delivery_id uuid NOT NULL REFERENCES notification_deliveries(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  event_id text NOT NULL,
  event_type text NOT NULL,
  occurred_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_delivery_event_type CHECK (event_type IN ('opened', 'clicked')),
  CONSTRAINT chk_notification_delivery_event_id CHECK (length(event_id) BETWEEN 8 AND 128)
);
CREATE UNIQUE INDEX idx_notification_delivery_event
  ON notification_delivery_events(delivery_id, event_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_delivery_events_user
  ON notification_delivery_events(user_id, occurred_at) WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS notification_delivery_events;
DROP TABLE IF EXISTS notification_deliveries;
ALTER TABLE notification_campaigns DROP COLUMN IF EXISTS campaign_variables_json;
ALTER TABLE notification_campaigns DROP CONSTRAINT chk_notification_campaign_status;
ALTER TABLE notification_campaigns
  ADD CONSTRAINT chk_notification_campaign_status CHECK (status IN ('draft', 'pending_review', 'approved', 'scheduled', 'queued', 'sending', 'completed', 'partially_failed', 'failed', 'cancelled'));
