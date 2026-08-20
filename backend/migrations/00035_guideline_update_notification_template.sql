-- +goose Up

-- +goose StatementBegin
DO $$
DECLARE
  root_id uuid;
BEGIN
  SELECT id INTO root_id
  FROM notification_templates
  WHERE template_key = 'guideline-update' AND deleted_at IS NULL
  LIMIT 1;

  IF root_id IS NULL THEN
    root_id := uuid_generate_v4();
    INSERT INTO notification_templates (
      id, name, template_key, type, category, status, current_version,
      locale, subject, content, variables_json
    ) VALUES (
      root_id,
      'Published guideline update',
      'guideline-update',
      'push',
      'Content Updates',
      'published',
      1,
      'en',
      '{{title}} updated',
      'Version {{version}} of {{title}} is now available.',
      '{"guideline_id":{"type":"string","required":true},"title":{"type":"string","required":true},"version":{"type":"string","required":true}}'::jsonb
    );

    INSERT INTO notification_template_versions (
      template_id, version, channel, title_template, body_template,
      action_template_json, variable_schema_json, category, locale,
      status, published_at
    ) VALUES (
      root_id,
      1,
      'push',
      '{{title}} updated',
      'Version {{version}} of {{title}} is now available.',
      '{"type":"guideline","resource_id":"{{guideline_id}}","parameters":{}}'::jsonb,
      '{"guideline_id":{"type":"string","required":true},"title":{"type":"string","required":true},"version":{"type":"string","required":true}}'::jsonb,
      'Content Updates',
      'en',
      'published',
      now()
    );
  END IF;
END $$;
-- +goose StatementEnd

-- +goose Down
-- Keep a template that has already been referenced by a campaign. Removing it
-- would violate the audit trail and the version FK is intentionally RESTRICT.
DELETE FROM notification_templates AS template
WHERE template.template_key = 'guideline-update'
  AND NOT EXISTS (
    SELECT 1
    FROM notification_campaigns AS campaign
    JOIN notification_template_versions AS version
      ON version.id = campaign.template_version_id
    WHERE version.template_id = template.id
  );
