-- +goose Up
INSERT INTO permissions (id, code, name, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'guideline.markdown.read', 'Read private guideline Markdown drafts and revisions', now(), now()),
  (gen_random_uuid(), 'guideline.markdown.edit', 'Edit guideline Markdown drafts', now(), now()),
  (gen_random_uuid(), 'guideline.markdown.upload', 'Upload guideline Markdown and source documents', now(), now()),
  (gen_random_uuid(), 'guideline.asset.manage', 'Manage private guideline assets', now(), now()),
  (gen_random_uuid(), 'guideline.structure.regenerate', 'Regenerate guideline structured content and search indexes', now(), now()),
  (gen_random_uuid(), 'guideline.review', 'Review guideline revisions and comments', now(), now()),
  (gen_random_uuid(), 'guideline.high_risk.approve', 'Approve high-risk guideline content', now(), now()),
  (gen_random_uuid(), 'guideline.publish', 'Publish reviewed guideline versions', now(), now()),
  (gen_random_uuid(), 'guideline.revision.restore', 'Restore immutable guideline revisions into a new draft', now(), now())
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = now(), deleted_at = NULL;

INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) IN ('super_admin', 'admin')
  AND permission.code IN (
    'guideline.markdown.read', 'guideline.markdown.edit', 'guideline.markdown.upload',
    'guideline.asset.manage', 'guideline.structure.regenerate', 'guideline.review',
    'guideline.high_risk.approve', 'guideline.revision.restore'
  )
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) = 'content_manager'
  AND permission.code IN (
    'guideline.markdown.read', 'guideline.markdown.edit', 'guideline.markdown.upload',
    'guideline.asset.manage', 'guideline.structure.regenerate', 'guideline.review',
    'guideline.revision.restore'
  )
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) = 'reviewer'
  AND permission.code IN (
    'guideline.markdown.read', 'guideline.review',
    'guideline.high_risk.approve', 'guideline.publish'
  )
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM role_permissions
WHERE permission_id IN (
  SELECT id FROM permissions WHERE code IN (
    'guideline.markdown.read', 'guideline.markdown.edit', 'guideline.markdown.upload',
    'guideline.asset.manage', 'guideline.structure.regenerate', 'guideline.review',
    'guideline.high_risk.approve', 'guideline.revision.restore'
  )
);
DELETE FROM permissions WHERE code IN (
  'guideline.markdown.read', 'guideline.markdown.edit', 'guideline.markdown.upload',
  'guideline.asset.manage', 'guideline.structure.regenerate', 'guideline.review',
  'guideline.high_risk.approve', 'guideline.revision.restore'
);
