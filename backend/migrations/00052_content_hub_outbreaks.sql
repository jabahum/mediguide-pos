-- +goose Up
CREATE TABLE content_hub_outbreaks (
  content_hub_id uuid NOT NULL REFERENCES content_hubs(id) ON DELETE CASCADE,
  outbreak_id uuid NOT NULL REFERENCES outbreaks(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (content_hub_id, outbreak_id),
  UNIQUE (outbreak_id)
);
CREATE INDEX idx_content_hub_outbreaks_hub ON content_hub_outbreaks (content_hub_id, outbreak_id);

-- +goose Down
DROP TABLE IF EXISTS content_hub_outbreaks;
