-- +goose Up
ALTER TABLE notifications
  ADD COLUMN action_json jsonb NOT NULL DEFAULT '{"type":"none","parameters":{}}'::jsonb;

UPDATE notifications
SET action_json = CASE
  WHEN action_url ~ '^/public/guidelines/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    AND EXISTS (
      SELECT 1
      FROM guideline_documents
      WHERE id::text = split_part(notifications.action_url, '/', 4)
        AND deleted_at IS NULL
    )
    THEN jsonb_build_object(
      'type', 'guideline',
      'resource_id', split_part(action_url, '/', 4),
      'route', action_url,
      'parameters', '{}'::jsonb
    )
  WHEN action_url IN (
    '/main', '/home', '/search', '/guidelines', '/public/guidelines', '/tools',
    '/profile', '/library', '/offline-content', '/outbreak-hub', '/situation-reports',
    '/drug-index', '/abbreviations', '/health-infrastructure', '/health-facilities',
    '/consultants', '/ministry-directory', '/calculators', '/ai-assistant', '/chats',
    '/all-actions', '/notifications', '/help-center', '/faq', '/about-us',
    '/terms-and-conditions'
  )
    THEN jsonb_build_object('type', 'internal_route', 'route', action_url, 'parameters', '{}'::jsonb)
  ELSE '{"type":"none","parameters":{}}'::jsonb
END
WHERE action_url IS NOT NULL AND btrim(action_url) <> '';

CREATE INDEX idx_notifications_action_type
  ON notifications ((action_json->>'type'))
  WHERE deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_notifications_action_type;
ALTER TABLE notifications DROP COLUMN IF EXISTS action_json;
