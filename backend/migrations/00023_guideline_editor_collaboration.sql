-- +goose Up
CREATE TABLE guideline_review_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned','completed','dismissed')),
  due_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX uq_guideline_review_assignment_active
  ON guideline_review_assignments(version_id, reviewer_id)
  WHERE deleted_at IS NULL AND status = 'assigned';
CREATE INDEX idx_guideline_review_assignments_version
  ON guideline_review_assignments(version_id, created_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE guideline_editor_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id UUID NOT NULL REFERENCES guideline_versions(id) ON DELETE CASCADE,
  revision_id UUID REFERENCES guideline_markdown_revisions(id) ON DELETE CASCADE,
  section_id UUID REFERENCES guideline_sections(id) ON DELETE CASCADE,
  block_id UUID REFERENCES guideline_content_blocks(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (length(btrim(body)) BETWEEN 1 AND 10000),
  resolved BOOLEAN NOT NULL DEFAULT false,
  resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT guideline_editor_comment_resolution CHECK (
    (resolved = false AND resolved_by IS NULL AND resolved_at IS NULL) OR
    (resolved = true AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)
  )
);
CREATE INDEX idx_guideline_editor_comments_version
  ON guideline_editor_comments(version_id, resolved, created_at ASC) WHERE deleted_at IS NULL;

-- +goose Down
DROP TABLE IF EXISTS guideline_editor_comments;
DROP TABLE IF EXISTS guideline_review_assignments;
