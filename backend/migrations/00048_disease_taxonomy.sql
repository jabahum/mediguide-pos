-- +goose Up
CREATE TABLE diseases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id uuid REFERENCES diseases(id) ON DELETE SET NULL,
  name text NOT NULL,
  normalized_name text NOT NULL,
  slug text NOT NULL,
  short_name text,
  description text,
  icon text,
  color text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','archived')),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(name)) BETWEEN 2 AND 240),
  CHECK (normalized_name = trim(normalized_name) AND normalized_name <> ''),
  CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

CREATE UNIQUE INDEX idx_diseases_slug
  ON diseases (lower(slug)) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_diseases_active_normalized_name
  ON diseases (normalized_name) WHERE deleted_at IS NULL AND status = 'active';
CREATE INDEX idx_diseases_parent_order
  ON diseases (parent_id, sort_order, name) WHERE deleted_at IS NULL;
CREATE INDEX idx_diseases_status_order
  ON diseases (status, sort_order, name) WHERE deleted_at IS NULL;

CREATE TABLE disease_aliases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  disease_id uuid NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
  alias text NOT NULL,
  normalized_alias text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(alias)) BETWEEN 1 AND 240),
  CHECK (normalized_alias = trim(normalized_alias) AND normalized_alias <> '')
);

CREATE UNIQUE INDEX idx_disease_aliases_disease_normalized
  ON disease_aliases (disease_id, normalized_alias) WHERE deleted_at IS NULL;
CREATE INDEX idx_disease_aliases_normalized
  ON disease_aliases (normalized_alias) WHERE deleted_at IS NULL;
CREATE INDEX idx_disease_aliases_disease
  ON disease_aliases (disease_id, alias) WHERE deleted_at IS NULL;

CREATE TABLE disease_codes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  disease_id uuid NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
  code_system text NOT NULL,
  code text NOT NULL,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(code_system)) BETWEEN 1 AND 80),
  CHECK (length(trim(code)) BETWEEN 1 AND 120)
);

CREATE UNIQUE INDEX idx_disease_codes_system_code
  ON disease_codes (lower(code_system), lower(code)) WHERE deleted_at IS NULL;
CREATE INDEX idx_disease_codes_disease
  ON disease_codes (disease_id, code_system, code) WHERE deleted_at IS NULL;

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION reject_disease_hierarchy_cycle()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  cycle_found boolean;
  parent_status text;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION 'disease hierarchy cycle';
  END IF;
  SELECT status INTO parent_status
  FROM diseases
  WHERE id = NEW.parent_id AND deleted_at IS NULL;
  IF parent_status IS NULL THEN
    RAISE EXCEPTION 'disease parent does not exist';
  END IF;
  IF (TG_OP = 'INSERT' OR OLD.parent_id IS DISTINCT FROM NEW.parent_id)
     AND parent_status <> 'active' THEN
    RAISE EXCEPTION 'new disease parent must be active';
  END IF;
  WITH RECURSIVE ancestors AS (
    SELECT id, parent_id FROM diseases WHERE id = NEW.parent_id AND deleted_at IS NULL
    UNION ALL
    SELECT d.id, d.parent_id
    FROM diseases d
    JOIN ancestors a ON d.id = a.parent_id
    WHERE d.deleted_at IS NULL
  )
  SELECT EXISTS (SELECT 1 FROM ancestors WHERE id = NEW.id) INTO cycle_found;
  IF cycle_found THEN
    RAISE EXCEPTION 'disease hierarchy cycle';
  END IF;
  RETURN NEW;
END;
$$;
-- +goose StatementEnd

CREATE TRIGGER trg_reject_disease_hierarchy_cycle
BEFORE INSERT OR UPDATE OF parent_id ON diseases
FOR EACH ROW EXECUTE FUNCTION reject_disease_hierarchy_cycle();

INSERT INTO diseases (id, name, normalized_name, slug, short_name, sort_order, status) VALUES
  ('90000000-0000-4000-8000-000000000001', 'Ebola virus disease', 'ebola virus disease', 'ebola-virus-disease', 'EVD', 10, 'active'),
  ('90000000-0000-4000-8000-000000000002', 'Malaria', 'malaria', 'malaria', NULL, 20, 'active'),
  ('90000000-0000-4000-8000-000000000003', 'Cholera', 'cholera', 'cholera', NULL, 30, 'active'),
  ('90000000-0000-4000-8000-000000000004', 'Marburg virus disease', 'marburg virus disease', 'marburg-virus-disease', 'MVD', 40, 'active'),
  ('90000000-0000-4000-8000-000000000005', 'Measles', 'measles', 'measles', NULL, 50, 'active'),
  ('90000000-0000-4000-8000-000000000006', 'Diabetes mellitus', 'diabetes mellitus', 'diabetes-mellitus', 'DM', 60, 'active'),
  ('90000000-0000-4000-8000-000000000007', 'Hypertension', 'hypertension', 'hypertension', 'HTN', 70, 'active')
ON CONFLICT DO NOTHING;

INSERT INTO disease_aliases (id, disease_id, alias, normalized_alias) VALUES
  ('91000000-0000-4000-8000-000000000001', '90000000-0000-4000-8000-000000000001', 'Ebola', 'ebola'),
  ('91000000-0000-4000-8000-000000000002', '90000000-0000-4000-8000-000000000001', 'EVD', 'evd'),
  ('91000000-0000-4000-8000-000000000003', '90000000-0000-4000-8000-000000000004', 'Marburg', 'marburg'),
  ('91000000-0000-4000-8000-000000000004', '90000000-0000-4000-8000-000000000004', 'MVD', 'mvd'),
  ('91000000-0000-4000-8000-000000000005', '90000000-0000-4000-8000-000000000006', 'Diabetes', 'diabetes'),
  ('91000000-0000-4000-8000-000000000006', '90000000-0000-4000-8000-000000000006', 'DM', 'dm'),
  ('91000000-0000-4000-8000-000000000007', '90000000-0000-4000-8000-000000000007', 'HTN', 'htn'),
  ('91000000-0000-4000-8000-000000000008', '90000000-0000-4000-8000-000000000007', 'High blood pressure', 'high blood pressure')
ON CONFLICT DO NOTHING;

CREATE TABLE disease_taxonomy_migration_report (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_table text NOT NULL,
  source_id uuid NOT NULL,
  source_field text NOT NULL,
  source_value text NOT NULL,
  normalized_value text NOT NULL,
  resolution_status text NOT NULL CHECK (resolution_status IN ('matched','ambiguous','unmatched')),
  disease_id uuid REFERENCES diseases(id) ON DELETE SET NULL,
  candidate_disease_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (source_table, source_id, source_field)
);
CREATE INDEX idx_disease_migration_report_status
  ON disease_taxonomy_migration_report (resolution_status, source_table);

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION refresh_disease_taxonomy_migration_report()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM disease_taxonomy_migration_report;
  WITH legacy_values AS (
    SELECT 'outbreaks'::text source_table, id source_id, 'disease_type'::text source_field, trim(disease_type) source_value
    FROM outbreaks WHERE deleted_at IS NULL AND trim(coalesce(disease_type, '')) <> ''
    UNION ALL
    SELECT 'medical_guidelines', id, 'condition_name', trim(condition_name)
    FROM medical_guidelines WHERE deleted_at IS NULL AND trim(coalesce(condition_name, '')) <> ''
    UNION ALL
    SELECT 'guideline_documents', id, 'program_area', trim(program_area)
    FROM guideline_documents WHERE deleted_at IS NULL AND trim(coalesce(program_area, '')) <> ''
  ), normalized AS (
    SELECT *, trim(regexp_replace(lower(source_value), '[^[:alnum:]]+', ' ', 'g')) normalized_value
    FROM legacy_values
  ), matches AS (
    SELECT n.*, coalesce(array_agg(DISTINCT d.id ORDER BY d.id) FILTER (WHERE d.id IS NOT NULL), ARRAY[]::uuid[]) candidate_ids
    FROM normalized n
    LEFT JOIN diseases d ON d.deleted_at IS NULL AND d.status = 'active' AND (
      d.normalized_name = n.normalized_value OR EXISTS (
        SELECT 1 FROM disease_aliases da
        WHERE da.disease_id = d.id AND da.deleted_at IS NULL AND da.normalized_alias = n.normalized_value
      )
    )
    GROUP BY n.source_table, n.source_id, n.source_field, n.source_value, n.normalized_value
  )
  INSERT INTO disease_taxonomy_migration_report (
    source_table, source_id, source_field, source_value, normalized_value,
    resolution_status, disease_id, candidate_disease_ids
  )
  SELECT source_table, source_id, source_field, source_value, normalized_value,
    CASE cardinality(candidate_ids) WHEN 0 THEN 'unmatched' WHEN 1 THEN 'matched' ELSE 'ambiguous' END,
    CASE WHEN cardinality(candidate_ids) = 1 THEN candidate_ids[1] ELSE NULL END,
    to_jsonb(candidate_ids)
  FROM matches;
END;
$$;
-- +goose StatementEnd

SELECT refresh_disease_taxonomy_migration_report();

-- +goose Down
DROP FUNCTION IF EXISTS refresh_disease_taxonomy_migration_report();
DROP TABLE IF EXISTS disease_taxonomy_migration_report;
DROP TRIGGER IF EXISTS trg_reject_disease_hierarchy_cycle ON diseases;
DROP FUNCTION IF EXISTS reject_disease_hierarchy_cycle();
DROP TABLE IF EXISTS disease_codes;
DROP TABLE IF EXISTS disease_aliases;
DROP TABLE IF EXISTS diseases;
