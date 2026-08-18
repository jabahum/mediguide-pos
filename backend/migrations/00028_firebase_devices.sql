-- +goose Up
CREATE TABLE firebase_devices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  installation_id text NOT NULL,
  registration_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  app_version text,
  locale text,
  notifications_enabled boolean NOT NULL DEFAULT true,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT firebase_devices_user_installation_unique UNIQUE (user_id, installation_id),
  CONSTRAINT firebase_devices_registration_token_unique UNIQUE (registration_token)
);

CREATE INDEX idx_firebase_devices_user_enabled
  ON firebase_devices(user_id, notifications_enabled)
  WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS firebase_devices;
