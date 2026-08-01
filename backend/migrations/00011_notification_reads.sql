-- +goose Up
CREATE TABLE notification_reads (
  notification_id uuid NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (notification_id, user_id)
);

CREATE INDEX idx_notification_reads_user_read_at
  ON notification_reads(user_id, read_at DESC);

-- +goose Down
DROP TABLE IF EXISTS notification_reads;
