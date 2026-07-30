-- +goose Up
CREATE TABLE account_action_tokens (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose text NOT NULL CHECK (purpose IN ('password_reset', 'email_verification')),
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_account_action_tokens_lookup
  ON account_action_tokens(token_hash, purpose, expires_at)
  WHERE consumed_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS account_action_tokens;
