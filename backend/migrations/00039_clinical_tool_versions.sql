-- +goose Up

ALTER TABLE calculators
  ADD COLUMN runtime_type text NOT NULL DEFAULT 'legacy_html',
  ADD COLUMN current_version_id uuid;

ALTER TABLE calculators
  ADD CONSTRAINT chk_calculators_runtime_type
  CHECK (runtime_type IN ('legacy_html', 'schema_v1'));

CREATE TABLE calculator_versions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  calculator_id uuid NOT NULL REFERENCES calculators(id) ON DELETE CASCADE,
  semantic_version text NOT NULL,
  schema_version text NOT NULL,
  definition_json jsonb NOT NULL,
  definition_checksum char(64) NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  change_summary text NOT NULL DEFAULT '',
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  approved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  published_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  approved_at timestamptz,
  published_at timestamptz,
  effective_at timestamptz,
  review_at timestamptz,
  validation_passed boolean NOT NULL DEFAULT false,
  tests_passed boolean NOT NULL DEFAULT false,
  lock_version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT chk_calculator_versions_status CHECK (status IN ('draft','pending_review','approved','published','superseded','withdrawn')),
  CONSTRAINT chk_calculator_versions_lock CHECK (lock_version > 0),
  CONSTRAINT chk_calculator_versions_checksum CHECK (definition_checksum ~ '^[a-f0-9]{64}$'),
  CONSTRAINT uq_calculator_versions_semver UNIQUE (calculator_id, semantic_version)
);

CREATE INDEX idx_calculator_versions_tool_status ON calculator_versions(calculator_id, status) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_calculator_versions_one_published ON calculator_versions(calculator_id) WHERE status = 'published' AND deleted_at IS NULL;
ALTER TABLE calculators
  ADD CONSTRAINT fk_calculators_current_version
  FOREIGN KEY (current_version_id) REFERENCES calculator_versions(id) ON DELETE SET NULL;

CREATE TABLE calculator_test_cases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  calculator_version_id uuid NOT NULL REFERENCES calculator_versions(id) ON DELETE CASCADE,
  test_key text NOT NULL,
  description text NOT NULL DEFAULT '',
  fixed_now timestamptz,
  input_json jsonb NOT NULL,
  expected_json jsonb NOT NULL,
  numeric_tolerance numeric,
  last_result_json jsonb,
  last_passed boolean,
  last_run_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT uq_calculator_test_cases_key UNIQUE (calculator_version_id, test_key),
  CONSTRAINT chk_calculator_test_tolerance CHECK (numeric_tolerance IS NULL OR numeric_tolerance >= 0)
);

CREATE TABLE calculator_citations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  calculator_version_id uuid NOT NULL REFERENCES calculator_versions(id) ON DELETE CASCADE,
  citation_key text NOT NULL,
  title text NOT NULL,
  organization text NOT NULL DEFAULT '',
  url text NOT NULL DEFAULT '',
  published_at date,
  accessed_at date,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT uq_calculator_citations_key UNIQUE (calculator_version_id, citation_key)
);

CREATE TABLE calculator_version_audits (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  calculator_id uuid NOT NULL REFERENCES calculators(id) ON DELETE CASCADE,
  calculator_version_id uuid REFERENCES calculator_versions(id) ON DELETE SET NULL,
  actor_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL,
  from_status text,
  to_status text,
  metadata_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_calculator_version_audits_tool ON calculator_version_audits(calculator_id, created_at DESC);

ALTER TABLE calculator_usage_logs
  ADD COLUMN calculator_version_id uuid REFERENCES calculator_versions(id) ON DELETE SET NULL;

-- Existing records remain explicitly quarantined on the legacy runtime.
UPDATE calculators SET runtime_type = 'legacy_html' WHERE runtime_type IS NULL OR runtime_type = '';

-- +goose Down

ALTER TABLE calculator_usage_logs DROP COLUMN IF EXISTS calculator_version_id;
DROP TABLE IF EXISTS calculator_version_audits;
DROP TABLE IF EXISTS calculator_citations;
DROP TABLE IF EXISTS calculator_test_cases;
ALTER TABLE calculators DROP CONSTRAINT IF EXISTS fk_calculators_current_version;
DROP TABLE IF EXISTS calculator_versions;
ALTER TABLE calculators DROP CONSTRAINT IF EXISTS chk_calculators_runtime_type;
ALTER TABLE calculators DROP COLUMN IF EXISTS current_version_id;
ALTER TABLE calculators DROP COLUMN IF EXISTS runtime_type;
