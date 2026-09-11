-- +goose Up
CREATE TABLE guideline_document_categories (
  guideline_document_id uuid NOT NULL REFERENCES guideline_documents(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES guideline_categories(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (guideline_document_id, category_id)
);
CREATE INDEX idx_guideline_document_categories_category
  ON guideline_document_categories (category_id, guideline_document_id);
CREATE INDEX idx_guideline_document_categories_document
  ON guideline_document_categories (guideline_document_id, category_id);

-- Preserve ProgramArea and only backfill an unambiguous active exact match.
WITH category_matches AS (
  SELECT gd.id guideline_document_id, min(gc.id::text)::uuid category_id
  FROM guideline_documents gd
  JOIN guideline_categories gc
    ON gc.deleted_at IS NULL AND gc.status = 'active'
   AND (
     lower(trim(gc.name)) = lower(trim(gd.program_area)) OR
     lower(trim(coalesce(gc.slug, ''))) = lower(trim(regexp_replace(gd.program_area, '[^[:alnum:]]+', '-', 'g')))
   )
  WHERE gd.deleted_at IS NULL AND trim(coalesce(gd.program_area, '')) <> ''
  GROUP BY gd.id
  HAVING count(DISTINCT gc.id) = 1
)
INSERT INTO guideline_document_categories (guideline_document_id, category_id)
SELECT guideline_document_id, category_id FROM category_matches
ON CONFLICT DO NOTHING;

CREATE TABLE content_disease_assignments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  disease_id uuid NOT NULL REFERENCES diseases(id) ON DELETE RESTRICT,
  content_type text NOT NULL CHECK (content_type IN (
    'guideline','outbreak','outbreak_document','situation_report',
    'algorithm','clinical_tool','form','drug_reference'
  )),
  content_id uuid NOT NULL,
  is_primary boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE UNIQUE INDEX idx_content_disease_assignment_unique
  ON content_disease_assignments (disease_id, content_type, content_id)
  WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_content_disease_assignment_primary
  ON content_disease_assignments (content_type, content_id)
  WHERE deleted_at IS NULL AND is_primary;
CREATE INDEX idx_content_disease_assignment_disease
  ON content_disease_assignments (disease_id, content_type, content_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_content_disease_assignment_resource
  ON content_disease_assignments (content_type, content_id, disease_id)
  WHERE deleted_at IS NULL;

-- Backfill only free-text outbreak names that the Phase-2 report resolved to
-- exactly one active disease. DiseaseType remains unchanged.
INSERT INTO content_disease_assignments (disease_id, content_type, content_id, is_primary)
SELECT report.disease_id, 'outbreak', report.source_id, true
FROM disease_taxonomy_migration_report report
JOIN diseases disease ON disease.id = report.disease_id
JOIN outbreaks outbreak ON outbreak.id = report.source_id AND outbreak.deleted_at IS NULL
WHERE report.source_table = 'outbreaks'
  AND report.source_field = 'disease_type'
  AND report.resolution_status = 'matched'
  AND disease.status = 'active'
  AND disease.deleted_at IS NULL
ON CONFLICT DO NOTHING;

-- +goose Down
DROP TABLE IF EXISTS content_disease_assignments;
DROP TABLE IF EXISTS guideline_document_categories;
