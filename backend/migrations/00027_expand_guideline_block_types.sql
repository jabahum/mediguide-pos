-- +goose Up
ALTER TABLE guideline_content_blocks
  DROP CONSTRAINT IF EXISTS guideline_content_blocks_type_check;

ALTER TABLE guideline_content_blocks
  ADD CONSTRAINT guideline_content_blocks_type_check CHECK (type IN (
    'heading', 'paragraph', 'ordered_list', 'unordered_list', 'table',
    'figure', 'recommendation', 'warning', 'caution', 'key_point',
    'contraindication', 'dosage', 'evidence', 'definition', 'procedure',
    'clinical_note', 'referral_criteria', 'algorithm_reference', 'algorithm',
    'reference', 'page_break', 'unknown'
  ));

-- +goose Down
ALTER TABLE guideline_content_blocks
  DROP CONSTRAINT IF EXISTS guideline_content_blocks_type_check;

-- Refuse to narrow the constraint if post-00014 block types are present. This
-- makes rollback explicit instead of leaving rows that violate the old schema.
ALTER TABLE guideline_content_blocks
  ADD CONSTRAINT guideline_content_blocks_type_check CHECK (type IN (
    'heading', 'paragraph', 'ordered_list', 'unordered_list', 'table',
    'figure', 'recommendation', 'warning', 'key_point', 'algorithm',
    'reference', 'page_break', 'unknown'
  ));
