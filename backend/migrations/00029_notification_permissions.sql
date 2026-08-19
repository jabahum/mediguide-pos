-- +goose Up
INSERT INTO permissions (id, code, name, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'notification.read', 'Read own and global notifications', now(), now()),
  (gen_random_uuid(), 'notification.compose', 'Compose notification drafts', now(), now()),
  (gen_random_uuid(), 'notification.publish', 'Publish in-app notifications', now(), now()),
  (gen_random_uuid(), 'notification.template.read', 'Read notification templates', now(), now()),
  (gen_random_uuid(), 'notification.template.manage', 'Manage notification templates', now(), now()),
  (gen_random_uuid(), 'notification.campaign.read', 'Read notification campaigns', now(), now()),
  (gen_random_uuid(), 'notification.campaign.manage', 'Manage notification campaigns', now(), now()),
  (gen_random_uuid(), 'notification.campaign.approve', 'Approve notification campaigns', now(), now()),
  (gen_random_uuid(), 'notification.analytics.read', 'Read notification analytics', now(), now()),
  (gen_random_uuid(), 'firebase.status.read', 'Read Firebase integration status', now(), now()),
  (gen_random_uuid(), 'firebase.push.test', 'Send Firebase test pushes', now(), now()),
  (gen_random_uuid(), 'firebase.config.manage', 'Manage Firebase Remote Config', now(), now())
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = now(), deleted_at = NULL;

-- Every authenticated application role may use its own notification inbox.
INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE role.deleted_at IS NULL
  AND permission.code = 'notification.read'
ON CONFLICT DO NOTHING;

-- Administrators retain all notification and Firebase operations.
INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) IN ('super_admin', 'admin')
  AND permission.code IN (
    'notification.compose', 'notification.publish',
    'notification.template.read', 'notification.template.manage',
    'notification.campaign.read', 'notification.campaign.manage',
    'notification.campaign.approve', 'notification.analytics.read',
    'firebase.status.read', 'firebase.push.test', 'firebase.config.manage'
  )
ON CONFLICT DO NOTHING;

-- Content managers may author metadata and drafts, but cannot approve campaigns.
INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) IN ('content_manager', 'editor')
  AND permission.code IN (
    'notification.compose', 'notification.template.read', 'notification.template.manage',
    'notification.campaign.read', 'notification.campaign.manage', 'firebase.status.read'
  )
ON CONFLICT DO NOTHING;

-- Reviewers can inspect notification material and approve future workflows.
INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
CROSS JOIN permissions permission
WHERE lower(coalesce(role.role_key, role.name)) = 'reviewer'
  AND permission.code IN (
    'notification.template.read', 'notification.campaign.read',
    'notification.campaign.approve', 'notification.analytics.read', 'firebase.status.read'
  )
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM role_permissions
WHERE permission_id IN (
  SELECT id FROM permissions WHERE code IN (
    'notification.read', 'notification.compose', 'notification.publish',
    'notification.template.read', 'notification.template.manage',
    'notification.campaign.read', 'notification.campaign.manage',
    'notification.campaign.approve', 'notification.analytics.read',
    'firebase.status.read', 'firebase.push.test', 'firebase.config.manage'
  )
);
DELETE FROM permissions WHERE code IN (
  'notification.read', 'notification.compose', 'notification.publish',
  'notification.template.read', 'notification.template.manage',
  'notification.campaign.read', 'notification.campaign.manage',
  'notification.campaign.approve', 'notification.analytics.read',
  'firebase.status.read', 'firebase.push.test', 'firebase.config.manage'
);
