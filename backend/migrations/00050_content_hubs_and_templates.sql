-- +goose Up
CREATE TABLE content_hubs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  slug text NOT NULL,
  description text NOT NULL DEFAULT '',
  icon text NOT NULL DEFAULT '',
  color text NOT NULL DEFAULT '',
  audience text NOT NULL DEFAULT 'all',
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','archived')),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES users(id) ON DELETE SET NULL,
  published_at timestamptz,
  lock_version integer NOT NULL DEFAULT 1 CHECK (lock_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(name)) BETWEEN 2 AND 240),
  CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);
CREATE UNIQUE INDEX idx_content_hubs_slug ON content_hubs (lower(slug)) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_hubs_public_order ON content_hubs (status, sort_order, name, id) WHERE deleted_at IS NULL;

CREATE TABLE content_hub_diseases (
  content_hub_id uuid NOT NULL REFERENCES content_hubs(id) ON DELETE CASCADE,
  disease_id uuid NOT NULL REFERENCES diseases(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (content_hub_id, disease_id)
);
CREATE INDEX idx_content_hub_diseases_disease ON content_hub_diseases (disease_id, content_hub_id);

CREATE TABLE content_pillars (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  hub_id uuid NOT NULL REFERENCES content_hubs(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES content_pillars(id) ON DELETE RESTRICT,
  name text NOT NULL,
  slug text NOT NULL,
  description text NOT NULL DEFAULT '',
  icon text NOT NULL DEFAULT '',
  color text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','archived')),
  lock_version integer NOT NULL DEFAULT 1 CHECK (lock_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(name)) BETWEEN 2 AND 160),
  CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);
CREATE UNIQUE INDEX idx_content_pillars_hub_slug ON content_pillars (hub_id, lower(slug)) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_pillars_tree_order ON content_pillars (hub_id, parent_id, sort_order, name, id) WHERE deleted_at IS NULL;

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION reject_content_pillar_hierarchy_cycle()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  parent_hub uuid;
  cycle_found boolean;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION 'content pillar hierarchy cycle';
  END IF;
  SELECT hub_id INTO parent_hub FROM content_pillars WHERE id = NEW.parent_id AND deleted_at IS NULL;
  IF parent_hub IS NULL OR parent_hub <> NEW.hub_id THEN
    RAISE EXCEPTION 'content pillar parent must belong to the same hub';
  END IF;
  WITH RECURSIVE ancestors AS (
    SELECT id, parent_id FROM content_pillars WHERE id = NEW.parent_id AND deleted_at IS NULL
    UNION ALL
    SELECT p.id, p.parent_id FROM content_pillars p JOIN ancestors a ON p.id = a.parent_id
    WHERE p.deleted_at IS NULL
  )
  SELECT EXISTS (SELECT 1 FROM ancestors WHERE id = NEW.id) INTO cycle_found;
  IF cycle_found THEN
    RAISE EXCEPTION 'content pillar hierarchy cycle';
  END IF;
  RETURN NEW;
END;
$$;
-- +goose StatementEnd

CREATE TRIGGER trg_reject_content_pillar_hierarchy_cycle
BEFORE INSERT OR UPDATE OF parent_id, hub_id ON content_pillars
FOR EACH ROW EXECUTE FUNCTION reject_content_pillar_hierarchy_cycle();

CREATE TABLE content_pillar_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  pillar_id uuid NOT NULL REFERENCES content_pillars(id) ON DELETE CASCADE,
  content_type text NOT NULL CHECK (content_type IN (
    'guideline','outbreak_document','situation_report','algorithm','clinical_tool',
    'form','drug_reference','internal_route','approved_external_url'
  )),
  content_id uuid,
  target text NOT NULL DEFAULT '',
  label_override text NOT NULL DEFAULT '',
  description_override text NOT NULL DEFAULT '',
  icon_override text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  featured boolean NOT NULL DEFAULT false,
  starts_at timestamptz,
  ends_at timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','archived')),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  lock_version integer NOT NULL DEFAULT 1 CHECK (lock_version >= 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at),
  CHECK (
    (content_type IN ('internal_route','approved_external_url') AND content_id IS NULL AND trim(target) <> '') OR
    (content_type NOT IN ('internal_route','approved_external_url') AND content_id IS NOT NULL AND trim(target) = '')
  )
);
CREATE UNIQUE INDEX idx_content_pillar_items_unique_resource
  ON content_pillar_items (pillar_id, content_type, content_id)
  WHERE deleted_at IS NULL AND content_id IS NOT NULL;
CREATE UNIQUE INDEX idx_content_pillar_items_unique_target
  ON content_pillar_items (pillar_id, content_type, target)
  WHERE deleted_at IS NULL AND content_id IS NULL;
CREATE INDEX idx_content_pillar_items_order
  ON content_pillar_items (pillar_id, sort_order, id) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_pillar_items_resource
  ON content_pillar_items (content_type, content_id, pillar_id) WHERE deleted_at IS NULL AND content_id IS NOT NULL;
CREATE INDEX idx_content_pillar_items_availability
  ON content_pillar_items (status, starts_at, ends_at) WHERE deleted_at IS NULL;

CREATE TABLE content_hub_templates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  slug text NOT NULL,
  description text NOT NULL DEFAULT '',
  icon text NOT NULL DEFAULT '',
  color text NOT NULL DEFAULT '',
  audience text NOT NULL DEFAULT 'all',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived')),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (length(trim(name)) BETWEEN 2 AND 160),
  CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);
CREATE UNIQUE INDEX idx_content_hub_templates_slug ON content_hub_templates (lower(slug)) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_hub_templates_order ON content_hub_templates (status, sort_order, name, id) WHERE deleted_at IS NULL;

CREATE TABLE content_hub_template_pillars (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id uuid NOT NULL REFERENCES content_hub_templates(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES content_hub_template_pillars(id) ON DELETE RESTRICT,
  name text NOT NULL,
  slug text NOT NULL,
  description text NOT NULL DEFAULT '',
  icon text NOT NULL DEFAULT '',
  color text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (template_id, slug),
  CHECK (length(trim(name)) BETWEEN 2 AND 160),
  CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);
CREATE INDEX idx_content_hub_template_pillars_order
  ON content_hub_template_pillars (template_id, parent_id, sort_order, name, id) WHERE deleted_at IS NULL;

INSERT INTO content_hub_templates (id, name, slug, description, icon, color, audience, sort_order) VALUES
  ('92000000-0000-4000-8000-000000000001', 'Outbreak or emergency response', 'outbreak-emergency-response', 'Initial structure for an outbreak or emergency response hub.', 'warning', 'critical', 'all', 10),
  ('92000000-0000-4000-8000-000000000002', 'Disease care', 'disease-care', 'Initial structure for a disease-specific care hub.', 'clinical-care', 'clinical', 'health-workers', 20),
  ('92000000-0000-4000-8000-000000000003', 'Surveillance knowledge', 'surveillance-knowledge', 'Guidance, forms and training for surveillance knowledge without operational surveillance data.', 'surveillance', 'information', 'health-workers', 30)
ON CONFLICT DO NOTHING;

INSERT INTO content_hub_template_pillars (id, template_id, name, slug, sort_order) VALUES
  ('92100000-0000-4000-8000-000000000001','92000000-0000-4000-8000-000000000001','Case Definition','case-definition',10),
  ('92100000-0000-4000-8000-000000000002','92000000-0000-4000-8000-000000000001','Screening & Triage','screening-triage',20),
  ('92100000-0000-4000-8000-000000000003','92000000-0000-4000-8000-000000000001','Surveillance Guidance','surveillance-guidance',30),
  ('92100000-0000-4000-8000-000000000004','92000000-0000-4000-8000-000000000001','IPC & PPE','ipc-ppe',40),
  ('92100000-0000-4000-8000-000000000005','92000000-0000-4000-8000-000000000001','Isolation','isolation',50),
  ('92100000-0000-4000-8000-000000000006','92000000-0000-4000-8000-000000000001','Clinical Management','clinical-management',60),
  ('92100000-0000-4000-8000-000000000007','92000000-0000-4000-8000-000000000001','Laboratory','laboratory',70),
  ('92100000-0000-4000-8000-000000000008','92000000-0000-4000-8000-000000000001','Medicines','medicines',80),
  ('92100000-0000-4000-8000-000000000009','92000000-0000-4000-8000-000000000001','Forms','forms',90),
  ('92100000-0000-4000-8000-000000000010','92000000-0000-4000-8000-000000000001','Training','training',100),
  ('92100000-0000-4000-8000-000000000011','92000000-0000-4000-8000-000000000001','Situation Reports','situation-reports',110),
  ('92100000-0000-4000-8000-000000000012','92000000-0000-4000-8000-000000000001','Contacts','contacts',120),
  ('92100000-0000-4000-8000-000000000013','92000000-0000-4000-8000-000000000001','FAQs','faqs',130),
  ('92200000-0000-4000-8000-000000000001','92000000-0000-4000-8000-000000000002','Overview','overview',10),
  ('92200000-0000-4000-8000-000000000002','92000000-0000-4000-8000-000000000002','Diagnosis','diagnosis',20),
  ('92200000-0000-4000-8000-000000000003','92000000-0000-4000-8000-000000000002','Clinical Management','clinical-management',30),
  ('92200000-0000-4000-8000-000000000004','92000000-0000-4000-8000-000000000002','Medicines','medicines',40),
  ('92200000-0000-4000-8000-000000000005','92000000-0000-4000-8000-000000000002','Algorithms','algorithms',50),
  ('92200000-0000-4000-8000-000000000006','92000000-0000-4000-8000-000000000002','Prevention','prevention',60),
  ('92200000-0000-4000-8000-000000000007','92000000-0000-4000-8000-000000000002','Patient Education','patient-education',70),
  ('92200000-0000-4000-8000-000000000008','92000000-0000-4000-8000-000000000002','Training','training',80),
  ('92200000-0000-4000-8000-000000000009','92000000-0000-4000-8000-000000000002','References','references',90),
  ('92300000-0000-4000-8000-000000000001','92000000-0000-4000-8000-000000000003','Case Definitions','case-definitions',10),
  ('92300000-0000-4000-8000-000000000002','92000000-0000-4000-8000-000000000003','Detection and Screening','detection-screening',20),
  ('92300000-0000-4000-8000-000000000003','92000000-0000-4000-8000-000000000003','Surveillance Protocols','surveillance-protocols',30),
  ('92300000-0000-4000-8000-000000000004','92000000-0000-4000-8000-000000000003','Reporting Forms','reporting-forms',40),
  ('92300000-0000-4000-8000-000000000005','92000000-0000-4000-8000-000000000003','Laboratory Guidance','laboratory-guidance',50),
  ('92300000-0000-4000-8000-000000000006','92000000-0000-4000-8000-000000000003','Contact Tracing','contact-tracing',60),
  ('92300000-0000-4000-8000-000000000007','92000000-0000-4000-8000-000000000003','Situation Reports','situation-reports',70),
  ('92300000-0000-4000-8000-000000000008','92000000-0000-4000-8000-000000000003','Training Materials','training-materials',80),
  ('92300000-0000-4000-8000-000000000009','92000000-0000-4000-8000-000000000003','Approved Dashboards','approved-dashboards',90),
  ('92300000-0000-4000-8000-000000000010','92000000-0000-4000-8000-000000000003','Contacts and Escalation','contacts-escalation',100)
ON CONFLICT DO NOTHING;

-- +goose Down
DROP TABLE IF EXISTS content_hub_template_pillars;
DROP TABLE IF EXISTS content_hub_templates;
DROP TABLE IF EXISTS content_pillar_items;
DROP TRIGGER IF EXISTS trg_reject_content_pillar_hierarchy_cycle ON content_pillars;
DROP FUNCTION IF EXISTS reject_content_pillar_hierarchy_cycle();
DROP TABLE IF EXISTS content_pillars;
DROP TABLE IF EXISTS content_hub_diseases;
DROP TABLE IF EXISTS content_hubs;
