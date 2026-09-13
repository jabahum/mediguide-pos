-- +goose Up

INSERT INTO permissions (id, code, name, created_at, updated_at) VALUES
  (gen_random_uuid(), 'disease.taxonomy.read', 'Read the disease taxonomy', now(), now()),
  (gen_random_uuid(), 'disease.taxonomy.manage', 'Manage diseases, aliases and codes', now(), now()),
  (gen_random_uuid(), 'disease.assignment.read', 'Read disease-content assignments', now(), now()),
  (gen_random_uuid(), 'disease.assignment.manage', 'Manage disease-content assignments', now(), now()),
  (gen_random_uuid(), 'content_hub.read', 'Read content hub administration data', now(), now()),
  (gen_random_uuid(), 'content_hub.manage', 'Manage content hub metadata and disease relationships', now(), now()),
  (gen_random_uuid(), 'content_hub.publish', 'Publish content hubs', now(), now()),
  (gen_random_uuid(), 'content_hub.archive', 'Archive content hubs', now(), now()),
  (gen_random_uuid(), 'content_pillar.read', 'Read content pillars and assignments', now(), now()),
  (gen_random_uuid(), 'content_pillar.manage', 'Manage content pillars and assignments', now(), now()),
  (gen_random_uuid(), 'content_hub.template.read', 'Read content hub templates', now(), now()),
  (gen_random_uuid(), 'content_hub.template.manage', 'Apply and manage content hub templates', now(), now())
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = now(), deleted_at = NULL;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('super_admin','admin')
  AND p.code IN (
    'disease.taxonomy.read','disease.taxonomy.manage','disease.assignment.read','disease.assignment.manage',
    'content_hub.read','content_hub.manage','content_hub.publish','content_hub.archive',
    'content_pillar.read','content_pillar.manage','content_hub.template.read','content_hub.template.manage'
  )
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('content_manager','editor')
  AND p.code IN (
    'disease.taxonomy.read','disease.taxonomy.manage','disease.assignment.read','disease.assignment.manage',
    'content_hub.read','content_hub.manage','content_pillar.read','content_pillar.manage',
    'content_hub.template.read','content_hub.template.manage'
  )
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) = 'reviewer'
  AND p.code IN (
    'disease.taxonomy.read','disease.assignment.read','content_hub.read',
    'content_pillar.read','content_hub.template.read'
  )
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM role_permissions WHERE permission_id IN (
  SELECT id FROM permissions WHERE code IN (
    'disease.taxonomy.read','disease.taxonomy.manage','disease.assignment.read','disease.assignment.manage',
    'content_hub.read','content_hub.manage','content_hub.publish','content_hub.archive',
    'content_pillar.read','content_pillar.manage','content_hub.template.read','content_hub.template.manage'
  )
);
DELETE FROM permissions WHERE code IN (
  'disease.taxonomy.read','disease.taxonomy.manage','disease.assignment.read','disease.assignment.manage',
  'content_hub.read','content_hub.manage','content_hub.publish','content_hub.archive',
  'content_pillar.read','content_pillar.manage','content_hub.template.read','content_hub.template.manage'
);
