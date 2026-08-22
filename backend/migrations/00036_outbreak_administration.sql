-- +goose Up
ALTER TABLE outbreaks DROP CONSTRAINT IF EXISTS outbreaks_status_check;
ALTER TABLE outbreaks
  ADD COLUMN author_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN region_id UUID REFERENCES regions(id) ON DELETE SET NULL,
  ADD COLUMN district_id UUID REFERENCES districts(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at TIMESTAMPTZ,
  ADD COLUMN approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN approved_at TIMESTAMPTZ,
  ADD COLUMN withdrawn_at TIMESTAMPTZ,
  ADD COLUMN withdrawal_reason TEXT NOT NULL DEFAULT '',
  ADD COLUMN supersedes_id UUID REFERENCES outbreaks(id) ON DELETE SET NULL,
  ADD COLUMN source_url TEXT NOT NULL DEFAULT '',
  ADD COLUMN source_reference TEXT NOT NULL DEFAULT '',
  ADD COLUMN effective_at TIMESTAMPTZ,
  ADD COLUMN data_as_of TIMESTAMPTZ,
  ADD COLUMN last_verified_at TIMESTAMPTZ,
  ADD COLUMN lock_version INTEGER NOT NULL DEFAULT 1,
  ADD CONSTRAINT outbreaks_status_check CHECK (status IN ('draft','pending_review','published','active','monitoring','contained','closed','withdrawn'));

UPDATE outbreaks SET
  source_reference = CASE WHEN source_reference = '' THEN source_organization ELSE source_reference END,
  effective_at = COALESCE(effective_at, published_at, last_update),
  data_as_of = COALESCE(data_as_of, last_update),
  last_verified_at = COALESCE(last_verified_at, published_at, last_update),
  approved_at = COALESCE(approved_at, published_at)
WHERE published_at IS NOT NULL;

ALTER TABLE outbreak_updates
  ALTER COLUMN published_at DROP NOT NULL,
  ADD COLUMN status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_review','published','archived','withdrawn')),
  ADD COLUMN author_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at TIMESTAMPTZ,
  ADD COLUMN approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN approved_at TIMESTAMPTZ,
  ADD COLUMN withdrawn_at TIMESTAMPTZ,
  ADD COLUMN withdrawal_reason TEXT NOT NULL DEFAULT '',
  ADD COLUMN supersedes_id UUID REFERENCES outbreak_updates(id) ON DELETE SET NULL,
  ADD COLUMN lock_version INTEGER NOT NULL DEFAULT 1;
UPDATE outbreak_updates SET status = 'published', approved_at = published_at WHERE published_at IS NOT NULL;

ALTER TABLE outbreak_resources
  ADD COLUMN status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_review','published','archived','withdrawn')),
  ADD COLUMN published_at TIMESTAMPTZ,
  ADD COLUMN author_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at TIMESTAMPTZ,
  ADD COLUMN approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN approved_at TIMESTAMPTZ,
  ADD COLUMN withdrawn_at TIMESTAMPTZ,
  ADD COLUMN withdrawal_reason TEXT NOT NULL DEFAULT '',
  ADD COLUMN supersedes_id UUID REFERENCES outbreak_resources(id) ON DELETE SET NULL,
  ADD COLUMN lock_version INTEGER NOT NULL DEFAULT 1;
UPDATE outbreak_resources SET status = 'published', published_at = created_at, approved_at = created_at;

ALTER TABLE situation_reports DROP CONSTRAINT IF EXISTS situation_reports_status_check;
ALTER TABLE situation_reports
  ADD COLUMN standalone_allowed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN region_id UUID REFERENCES regions(id) ON DELETE SET NULL,
  ADD COLUMN district_id UUID REFERENCES districts(id) ON DELETE SET NULL,
  ADD COLUMN author_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN published_at TIMESTAMPTZ,
  ADD COLUMN reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN reviewed_at TIMESTAMPTZ,
  ADD COLUMN approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN approved_at TIMESTAMPTZ,
  ADD COLUMN withdrawn_at TIMESTAMPTZ,
  ADD COLUMN withdrawal_reason TEXT NOT NULL DEFAULT '',
  ADD COLUMN correction_reason TEXT NOT NULL DEFAULT '',
  ADD COLUMN supersedes_id UUID REFERENCES situation_reports(id) ON DELETE SET NULL,
  ADD COLUMN source_url TEXT NOT NULL DEFAULT '',
  ADD COLUMN source_reference TEXT NOT NULL DEFAULT '',
  ADD COLUMN effective_at TIMESTAMPTZ,
  ADD COLUMN data_as_of TIMESTAMPTZ,
  ADD COLUMN last_verified_at TIMESTAMPTZ,
  ADD COLUMN lock_version INTEGER NOT NULL DEFAULT 1,
  ADD CONSTRAINT situation_reports_status_check CHECK (status IN ('draft','pending_review','published','archived','withdrawn'));
UPDATE situation_reports SET
  published_at = publication_date::timestamptz,
  approved_at = publication_date::timestamptz,
  source_reference = CASE WHEN source_reference = '' THEN source_organization ELSE source_reference END,
  effective_at = publication_date::timestamptz,
  data_as_of = publication_date::timestamptz,
  last_verified_at = publication_date::timestamptz,
  standalone_allowed = (outbreak_id IS NULL)
WHERE status = 'published';

CREATE TABLE situation_report_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  situation_report_id UUID NOT NULL REFERENCES situation_reports(id) ON DELETE CASCADE,
  storage_key TEXT NOT NULL UNIQUE,
  file_name TEXT NOT NULL,
  content_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes > 0),
  checksum_sha256 TEXT NOT NULL,
  uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
ALTER TABLE situation_reports ADD COLUMN report_asset_id UUID REFERENCES situation_report_assets(id) ON DELETE SET NULL;

DROP INDEX IF EXISTS idx_outbreak_updates_public;
CREATE INDEX idx_outbreak_updates_public ON outbreak_updates(outbreak_id, published_at DESC, id DESC)
  WHERE deleted_at IS NULL AND status = 'published' AND published_at IS NOT NULL;
DROP INDEX IF EXISTS idx_outbreak_resources_public;
CREATE INDEX idx_outbreak_resources_public ON outbreak_resources(outbreak_id, sort_order, id)
  WHERE deleted_at IS NULL AND status = 'published' AND published_at IS NOT NULL;
DROP INDEX IF EXISTS idx_situation_reports_public;
CREATE INDEX idx_situation_reports_public ON situation_reports(publication_date DESC, id DESC)
  WHERE deleted_at IS NULL AND status = 'published' AND published_at IS NOT NULL;

INSERT INTO permissions (id, code, name, created_at, updated_at) VALUES
  (gen_random_uuid(), 'outbreak.read', 'Read outbreak administration content', now(), now()),
  (gen_random_uuid(), 'outbreak.manage', 'Create and edit outbreak content', now(), now()),
  (gen_random_uuid(), 'outbreak.review', 'Review and approve outbreak content', now(), now()),
  (gen_random_uuid(), 'outbreak.publish', 'Publish outbreak content', now(), now()),
  (gen_random_uuid(), 'outbreak.withdraw', 'Withdraw outbreak content', now(), now()),
  (gen_random_uuid(), 'situation_report.read', 'Read situation report administration content', now(), now()),
  (gen_random_uuid(), 'situation_report.manage', 'Create and edit situation reports', now(), now()),
  (gen_random_uuid(), 'situation_report.review', 'Review and approve situation reports', now(), now()),
  (gen_random_uuid(), 'situation_report.publish', 'Publish situation reports', now(), now()),
  (gen_random_uuid(), 'situation_report.withdraw', 'Withdraw situation reports', now(), now())
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = now(), deleted_at = NULL;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('super_admin','admin')
  AND p.code IN ('outbreak.read','outbreak.manage','outbreak.review','outbreak.publish','outbreak.withdraw','situation_report.read','situation_report.manage','situation_report.review','situation_report.publish','situation_report.withdraw')
ON CONFLICT DO NOTHING;
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('content_manager','editor')
  AND p.code IN ('outbreak.read','outbreak.manage','situation_report.read','situation_report.manage')
ON CONFLICT DO NOTHING;
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) = 'reviewer'
  AND p.code IN ('outbreak.read','outbreak.review','situation_report.read','situation_report.review')
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('outbreak.read','outbreak.manage','outbreak.review','outbreak.publish','outbreak.withdraw','situation_report.read','situation_report.manage','situation_report.review','situation_report.publish','situation_report.withdraw'));
DELETE FROM permissions WHERE code IN ('outbreak.read','outbreak.manage','outbreak.review','outbreak.publish','outbreak.withdraw','situation_report.read','situation_report.manage','situation_report.review','situation_report.publish','situation_report.withdraw');
ALTER TABLE situation_reports DROP COLUMN report_asset_id;
DROP TABLE IF EXISTS situation_report_assets;
ALTER TABLE situation_reports DROP CONSTRAINT IF EXISTS situation_reports_status_check;
UPDATE situation_reports SET status = 'draft' WHERE status IN ('pending_review','withdrawn');
ALTER TABLE situation_reports DROP COLUMN standalone_allowed, DROP COLUMN region_id, DROP COLUMN district_id, DROP COLUMN author_id, DROP COLUMN published_at, DROP COLUMN reviewed_by, DROP COLUMN reviewed_at, DROP COLUMN approved_by, DROP COLUMN approved_at, DROP COLUMN withdrawn_at, DROP COLUMN withdrawal_reason, DROP COLUMN correction_reason, DROP COLUMN supersedes_id, DROP COLUMN source_url, DROP COLUMN source_reference, DROP COLUMN effective_at, DROP COLUMN data_as_of, DROP COLUMN last_verified_at, DROP COLUMN lock_version;
ALTER TABLE situation_reports ADD CONSTRAINT situation_reports_status_check CHECK (status IN ('published','draft','archived'));
ALTER TABLE outbreak_resources DROP COLUMN status, DROP COLUMN published_at, DROP COLUMN author_id, DROP COLUMN reviewed_by, DROP COLUMN reviewed_at, DROP COLUMN approved_by, DROP COLUMN approved_at, DROP COLUMN withdrawn_at, DROP COLUMN withdrawal_reason, DROP COLUMN supersedes_id, DROP COLUMN lock_version;
ALTER TABLE outbreak_updates DROP COLUMN status, DROP COLUMN author_id, DROP COLUMN reviewed_by, DROP COLUMN reviewed_at, DROP COLUMN approved_by, DROP COLUMN approved_at, DROP COLUMN withdrawn_at, DROP COLUMN withdrawal_reason, DROP COLUMN supersedes_id, DROP COLUMN lock_version;
UPDATE outbreak_updates SET published_at = now() WHERE published_at IS NULL;
ALTER TABLE outbreak_updates ALTER COLUMN published_at SET NOT NULL;
ALTER TABLE outbreaks DROP CONSTRAINT IF EXISTS outbreaks_status_check;
UPDATE outbreaks SET status = 'draft' WHERE status = 'pending_review';
UPDATE outbreaks SET status = 'active' WHERE status IN ('published','withdrawn');
ALTER TABLE outbreaks DROP COLUMN author_id, DROP COLUMN region_id, DROP COLUMN district_id, DROP COLUMN reviewed_by, DROP COLUMN reviewed_at, DROP COLUMN approved_by, DROP COLUMN approved_at, DROP COLUMN withdrawn_at, DROP COLUMN withdrawal_reason, DROP COLUMN supersedes_id, DROP COLUMN source_url, DROP COLUMN source_reference, DROP COLUMN effective_at, DROP COLUMN data_as_of, DROP COLUMN last_verified_at, DROP COLUMN lock_version;
ALTER TABLE outbreaks ADD CONSTRAINT outbreaks_status_check CHECK (status IN ('active','monitoring','contained','closed','draft'));
CREATE INDEX idx_outbreak_updates_public ON outbreak_updates(outbreak_id, published_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_outbreak_resources_public ON outbreak_resources(outbreak_id, sort_order ASC) WHERE deleted_at IS NULL;
CREATE INDEX idx_situation_reports_public ON situation_reports(publication_date DESC) WHERE deleted_at IS NULL AND status = 'published';
