-- +goose Up

ALTER TABLE notification_templates
  ADD COLUMN template_key text,
  ADD COLUMN current_version integer NOT NULL DEFAULT 1,
  ADD COLUMN locale text NOT NULL DEFAULT 'en',
  ADD COLUMN created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL;

UPDATE notification_templates
SET template_key = lower(regexp_replace(trim(name), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || left(id::text, 8)
WHERE template_key IS NULL OR btrim(template_key) = '';

ALTER TABLE notification_templates
  ALTER COLUMN template_key SET NOT NULL;

CREATE UNIQUE INDEX idx_notification_templates_key_active
  ON notification_templates (template_key)
  WHERE deleted_at IS NULL;

CREATE TABLE notification_template_versions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id uuid NOT NULL REFERENCES notification_templates(id) ON DELETE CASCADE,
  version integer NOT NULL,
  channel text NOT NULL,
  title_template text,
  body_template text NOT NULL,
  action_template_json jsonb NOT NULL DEFAULT '{"type":"none","parameters":{}}'::jsonb,
  variable_schema_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  category text NOT NULL,
  locale text NOT NULL DEFAULT 'en',
  status text NOT NULL DEFAULT 'draft',
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT uq_notification_template_version UNIQUE (template_id, version),
  CONSTRAINT chk_notification_template_version_positive CHECK (version > 0),
  CONSTRAINT chk_notification_template_channel CHECK (channel IN ('push', 'email', 'sms', 'in-app')),
  CONSTRAINT chk_notification_template_status CHECK (status IN ('draft', 'published', 'archived')),
  CONSTRAINT chk_notification_template_body_length CHECK (char_length(body_template) BETWEEN 1 AND 100000),
  CONSTRAINT chk_notification_template_title_length CHECK (title_template IS NULL OR char_length(title_template) <= 998)
);
CREATE INDEX idx_notification_template_versions_template ON notification_template_versions(template_id, version DESC) WHERE deleted_at IS NULL;

INSERT INTO notification_template_versions (
  template_id, version, channel, title_template, body_template,
  action_template_json, variable_schema_json, category, locale, status,
  created_by, reviewed_by, published_at, created_at, updated_at
)
SELECT
  id, 1, type, subject, content,
  '{"type":"none","parameters":{}}'::jsonb,
  coalesce((
    SELECT jsonb_object_agg(entry.key, CASE
      WHEN jsonb_typeof(entry.value) = 'string' THEN jsonb_build_object(
        'type', trim(both '"' from entry.value::text),
        'required', true,
        'sample_value', entry.key
      )
      ELSE entry.value
    END)
    FROM jsonb_each(coalesce(notification_templates.variables_json, '{}'::jsonb)) AS entry
  ), '{}'::jsonb), category, locale,
  CASE WHEN status = 'active' THEN 'published' WHEN status = 'inactive' THEN 'archived' ELSE 'draft' END,
  created_by, reviewed_by,
  CASE WHEN status = 'active' THEN updated_at ELSE NULL END,
  created_at, updated_at
FROM notification_templates;

UPDATE notification_templates
SET status = CASE WHEN status = 'active' THEN 'published' WHEN status = 'inactive' THEN 'archived' ELSE 'draft' END;

-- +goose StatementBegin
CREATE FUNCTION prevent_published_notification_template_version_update()
RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'published' THEN
    RAISE EXCEPTION 'published notification template versions are immutable';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE TRIGGER notification_template_versions_immutable
BEFORE UPDATE ON notification_template_versions
FOR EACH ROW EXECUTE FUNCTION prevent_published_notification_template_version_update();

ALTER TABLE notification_campaigns
  ADD COLUMN template_version_id uuid REFERENCES notification_template_versions(id) ON DELETE RESTRICT,
  ADD COLUMN rendered_title text,
  ADD COLUMN rendered_body text,
  ADD COLUMN action_snapshot_json jsonb NOT NULL DEFAULT '{"type":"none","parameters":{}}'::jsonb,
  ADD COLUMN audience_definition_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN resolved_recipient_count bigint NOT NULL DEFAULT 0,
  ADD COLUMN scheduled_at timestamptz,
  ADD COLUMN timezone text NOT NULL DEFAULT 'UTC',
  ADD COLUMN expires_at timestamptz,
  ADD COLUMN ttl_seconds integer,
  ADD COLUMN priority text NOT NULL DEFAULT 'normal',
  ADD COLUMN collapse_key text,
  ADD COLUMN requested_channels_json jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at timestamptz,
  ADD COLUMN approved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN approved_at timestamptz,
  ADD COLUMN started_at timestamptz,
  ADD COLUMN completed_at timestamptz,
  ADD COLUMN cancelled_at timestamptz,
  ADD COLUMN failure_reason text,
  ADD COLUMN idempotency_key text,
  ADD COLUMN dispatch_snapshot_json jsonb,
  ADD COLUMN lock_version integer NOT NULL DEFAULT 1;

UPDATE notification_campaigns
SET
  rendered_title = name,
  rendered_body = name,
  requested_channels_json = coalesce(channels_json, '[]'::jsonb),
  audience_definition_json = jsonb_build_object(
    'countries', coalesce(audience_countries_json, '[]'::jsonb),
    'role_ids', coalesce(audience_roles_json, '[]'::jsonb)
  ),
  scheduled_at = CASE
    WHEN schedule_start ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' THEN schedule_start::timestamptz
    ELSE NULL
  END,
  expires_at = CASE
    WHEN schedule_end ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' THEN schedule_end::timestamptz
    ELSE NULL
  END,
  idempotency_key = 'legacy:' || id::text,
  status = CASE status
    WHEN 'running' THEN 'sending'
    WHEN 'paused' THEN 'cancelled'
    ELSE status
  END;

ALTER TABLE notification_campaigns
  ALTER COLUMN rendered_title SET NOT NULL,
  ALTER COLUMN rendered_body SET NOT NULL,
  ALTER COLUMN idempotency_key SET NOT NULL;

ALTER TABLE notification_campaigns
  ADD CONSTRAINT chk_notification_campaign_status CHECK (status IN ('draft', 'pending_review', 'approved', 'scheduled', 'queued', 'sending', 'completed', 'partially_failed', 'failed', 'cancelled')),
  ADD CONSTRAINT chk_notification_campaign_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  ADD CONSTRAINT chk_notification_campaign_schedule CHECK (expires_at IS NULL OR scheduled_at IS NULL OR expires_at > scheduled_at),
  ADD CONSTRAINT chk_notification_campaign_ttl CHECK (ttl_seconds IS NULL OR ttl_seconds BETWEEN 60 AND 2419200),
  ADD CONSTRAINT chk_notification_campaign_content CHECK (char_length(rendered_title) BETWEEN 1 AND 200 AND char_length(rendered_body) BETWEEN 1 AND 4000),
  ADD CONSTRAINT chk_notification_campaign_lock_version CHECK (lock_version > 0);

CREATE UNIQUE INDEX idx_notification_campaigns_idempotency_active
  ON notification_campaigns(idempotency_key) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_campaigns_schedule
  ON notification_campaigns(status, scheduled_at) WHERE deleted_at IS NULL;

ALTER TABLE notifications
  ADD COLUMN source_type text,
  ADD COLUMN source_id uuid,
  ADD COLUMN campaign_id uuid REFERENCES notification_campaigns(id) ON DELETE SET NULL,
  ADD COLUMN publish_at timestamptz,
  ADD COLUMN expires_at timestamptz,
  ADD COLUMN deduplication_key text,
  ADD COLUMN created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN published_by uuid REFERENCES users(id) ON DELETE SET NULL;

UPDATE notifications SET publish_at = created_at WHERE publish_at IS NULL;

ALTER TABLE notifications
  ADD CONSTRAINT chk_notifications_title_length CHECK (char_length(title) BETWEEN 1 AND 200),
  ADD CONSTRAINT chk_notifications_body_length CHECK (char_length(message) BETWEEN 1 AND 4000),
  ADD CONSTRAINT chk_notifications_expiry CHECK (expires_at IS NULL OR publish_at IS NULL OR expires_at > publish_at);

CREATE UNIQUE INDEX idx_notifications_deduplication_active
  ON notifications(deduplication_key) WHERE deduplication_key IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_notifications_campaign ON notifications(campaign_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_publish_window ON notifications(publish_at, expires_at) WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_notifications_publish_window;
DROP INDEX IF EXISTS idx_notifications_campaign;
DROP INDEX IF EXISTS idx_notifications_deduplication_active;
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS chk_notifications_expiry,
  DROP CONSTRAINT IF EXISTS chk_notifications_body_length,
  DROP CONSTRAINT IF EXISTS chk_notifications_title_length,
  DROP COLUMN IF EXISTS published_by,
  DROP COLUMN IF EXISTS created_by,
  DROP COLUMN IF EXISTS deduplication_key,
  DROP COLUMN IF EXISTS expires_at,
  DROP COLUMN IF EXISTS publish_at,
  DROP COLUMN IF EXISTS campaign_id,
  DROP COLUMN IF EXISTS source_id,
  DROP COLUMN IF EXISTS source_type;

DROP INDEX IF EXISTS idx_notification_campaigns_schedule;
DROP INDEX IF EXISTS idx_notification_campaigns_idempotency_active;
ALTER TABLE notification_campaigns
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_lock_version,
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_content,
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_ttl,
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_schedule,
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_priority,
  DROP CONSTRAINT IF EXISTS chk_notification_campaign_status,
  DROP COLUMN IF EXISTS lock_version,
  DROP COLUMN IF EXISTS dispatch_snapshot_json,
  DROP COLUMN IF EXISTS idempotency_key,
  DROP COLUMN IF EXISTS failure_reason,
  DROP COLUMN IF EXISTS cancelled_at,
  DROP COLUMN IF EXISTS completed_at,
  DROP COLUMN IF EXISTS started_at,
  DROP COLUMN IF EXISTS approved_at,
  DROP COLUMN IF EXISTS approved_by,
  DROP COLUMN IF EXISTS reviewed_at,
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS created_by,
  DROP COLUMN IF EXISTS requested_channels_json,
  DROP COLUMN IF EXISTS collapse_key,
  DROP COLUMN IF EXISTS priority,
  DROP COLUMN IF EXISTS ttl_seconds,
  DROP COLUMN IF EXISTS expires_at,
  DROP COLUMN IF EXISTS timezone,
  DROP COLUMN IF EXISTS scheduled_at,
  DROP COLUMN IF EXISTS resolved_recipient_count,
  DROP COLUMN IF EXISTS audience_definition_json,
  DROP COLUMN IF EXISTS action_snapshot_json,
  DROP COLUMN IF EXISTS rendered_body,
  DROP COLUMN IF EXISTS rendered_title,
  DROP COLUMN IF EXISTS template_version_id;

UPDATE notification_campaigns
SET status = CASE status
  WHEN 'pending_review' THEN 'draft'
  WHEN 'approved' THEN 'draft'
  WHEN 'queued' THEN 'running'
  WHEN 'sending' THEN 'running'
  WHEN 'partially_failed' THEN 'completed'
  WHEN 'failed' THEN 'completed'
  WHEN 'cancelled' THEN 'paused'
  ELSE status
END;

DROP TRIGGER IF EXISTS notification_template_versions_immutable ON notification_template_versions;
DROP FUNCTION IF EXISTS prevent_published_notification_template_version_update();
DROP TABLE IF EXISTS notification_template_versions;
DROP INDEX IF EXISTS idx_notification_templates_key_active;
UPDATE notification_templates
SET status = CASE WHEN status = 'published' THEN 'active' WHEN status = 'archived' THEN 'inactive' ELSE 'draft' END;
ALTER TABLE notification_templates
  DROP COLUMN IF EXISTS reviewed_by,
  DROP COLUMN IF EXISTS created_by,
  DROP COLUMN IF EXISTS locale,
  DROP COLUMN IF EXISTS current_version,
  DROP COLUMN IF EXISTS template_key;
