-- +goose Up

INSERT INTO permissions (id, code, name, created_at, updated_at) VALUES
  (gen_random_uuid(), 'calculator.read', 'Read clinical tools', now(), now()),
  (gen_random_uuid(), 'calculator.write', 'Author clinical tools', now(), now()),
  (gen_random_uuid(), 'calculator.review', 'Review clinical tools', now(), now()),
  (gen_random_uuid(), 'calculator.publish', 'Publish clinical tools', now(), now()),
  (gen_random_uuid(), 'calculator.withdraw', 'Withdraw clinical tools', now(), now())
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = now(), deleted_at = NULL;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('super_admin','admin')
  AND p.code IN ('calculator.read','calculator.write','calculator.review','calculator.publish','calculator.withdraw')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) IN ('content_manager','editor')
  AND p.code IN ('calculator.read','calculator.write')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.deleted_at IS NULL AND lower(coalesce(r.role_key, r.name)) = 'reviewer'
  AND p.code IN ('calculator.read','calculator.review')
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('calculator.read','calculator.write','calculator.review','calculator.publish','calculator.withdraw'));
DELETE FROM permissions WHERE code IN ('calculator.read','calculator.write','calculator.review','calculator.publish','calculator.withdraw');
