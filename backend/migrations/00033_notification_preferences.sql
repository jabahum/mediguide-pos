-- +goose Up

CREATE TABLE notification_preference_settings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_hours_start text,
  quiet_hours_end text,
  quiet_hours_timezone text NOT NULL DEFAULT 'UTC',
  preferred_language text NOT NULL DEFAULT 'en',
  push_enabled boolean NOT NULL DEFAULT true,
  in_app_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_notification_quiet_hours_pair CHECK (
    (quiet_hours_start IS NULL AND quiet_hours_end IS NULL) OR
    (quiet_hours_start ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' AND quiet_hours_end ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
  ),
  CONSTRAINT chk_notification_preferred_language CHECK (length(preferred_language) BETWEEN 2 AND 35)
);
CREATE UNIQUE INDEX idx_notification_preference_settings_user
  ON notification_preference_settings(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_notification_preference_settings_channels
  ON notification_preference_settings(push_enabled, in_app_enabled) WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS notification_preference_settings;
