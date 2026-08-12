-- +goose Up
CREATE TABLE outbreaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 240),
  disease_type TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('active','monitoring','contained','closed','draft')),
  geographic_area TEXT NOT NULL DEFAULT '',
  summary TEXT NOT NULL DEFAULT '',
  start_date DATE,
  last_update TIMESTAMPTZ NOT NULL DEFAULT now(),
  visual_tone TEXT NOT NULL DEFAULT 'warning' CHECK (visual_tone IN ('info','warning','critical','success','neutral')),
  source_organization TEXT NOT NULL DEFAULT '',
  published_at TIMESTAMPTZ,
  metrics JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_outbreaks_public ON outbreaks(status, last_update DESC)
  WHERE deleted_at IS NULL AND published_at IS NOT NULL;

CREATE TABLE outbreak_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbreak_id UUID NOT NULL REFERENCES outbreaks(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 240),
  summary TEXT NOT NULL DEFAULT '',
  published_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_outbreak_updates_public ON outbreak_updates(outbreak_id, published_at DESC)
  WHERE deleted_at IS NULL;

CREATE TABLE outbreak_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbreak_id UUID NOT NULL REFERENCES outbreaks(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 240),
  resource_type TEXT NOT NULL DEFAULT 'link',
  url TEXT NOT NULL DEFAULT '',
  asset_url TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_outbreak_resources_public ON outbreak_resources(outbreak_id, sort_order ASC)
  WHERE deleted_at IS NULL;

CREATE TABLE situation_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outbreak_id UUID REFERENCES outbreaks(id) ON DELETE SET NULL,
  title TEXT NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 240),
  geographic_area TEXT NOT NULL DEFAULT '',
  summary TEXT NOT NULL DEFAULT '',
  source_organization TEXT NOT NULL DEFAULT '',
  publication_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('published','draft','archived')),
  report_asset_url TEXT NOT NULL DEFAULT '',
  key_highlights JSONB NOT NULL DEFAULT '[]'::jsonb,
  metrics JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_situation_reports_public ON situation_reports(publication_date DESC)
  WHERE deleted_at IS NULL AND status = 'published';

-- +goose Down
DROP TABLE IF EXISTS situation_reports;
DROP TABLE IF EXISTS outbreak_resources;
DROP TABLE IF EXISTS outbreak_updates;
DROP TABLE IF EXISTS outbreaks;
