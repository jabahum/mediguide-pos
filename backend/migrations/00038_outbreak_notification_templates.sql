-- +goose Up

-- +goose StatementBegin
DO $$
DECLARE
  definition record;
  template_id uuid;
BEGIN
  FOR definition IN
    SELECT * FROM (VALUES
      ('outbreak-alert', 'Outbreak alert', '{{title}} outbreak alert', '{{title}} is {{status}} in {{area}}. Data verified {{data_as_of}}.', 'outbreak', 'outbreak_id'),
      ('outbreak-update', 'Outbreak update', '{{title}} update', 'A new update is available for {{title}} in {{area}}.', 'outbreak', 'outbreak_id'),
      ('outbreak-status-change', 'Outbreak status change', '{{title}} status: {{status}}', 'The official status for {{title}} in {{area}} is now {{status}}.', 'outbreak', 'outbreak_id'),
      ('situation-report-publication', 'Situation report publication', 'New situation report: {{title}}', '{{title}} for {{area}} was published on {{publication_date}}.', 'situation_report', 'situation_report_id')
    ) AS value(template_key, name, title_template, body_template, action_type, id_variable)
  LOOP
    SELECT id INTO template_id
    FROM notification_templates
    WHERE template_key = definition.template_key AND deleted_at IS NULL
    LIMIT 1;

    IF template_id IS NULL THEN
      template_id := uuid_generate_v4();
      INSERT INTO notification_templates (
        id, name, template_key, type, category, status, current_version,
        locale, subject, content, variables_json
      ) VALUES (
        template_id, definition.name, definition.template_key, 'push',
        'Emergency Alerts', 'published', 1, 'en', definition.title_template,
        definition.body_template,
        jsonb_build_object(
          definition.id_variable, jsonb_build_object('type', 'string', 'required', true),
          'title', jsonb_build_object('type', 'string', 'required', true),
          'area', jsonb_build_object('type', 'string', 'required', true)
        )
      );

      INSERT INTO notification_template_versions (
        template_id, version, channel, title_template, body_template,
        action_template_json, variable_schema_json, category, locale,
        status, published_at
      ) VALUES (
        template_id, 1, 'push', definition.title_template,
        definition.body_template,
        jsonb_build_object('type', definition.action_type, 'resource_id', '{{' || definition.id_variable || '}}', 'parameters', '{}'::jsonb),
        CASE
          WHEN definition.action_type = 'situation_report' THEN
            jsonb_build_object(
              'situation_report_id', jsonb_build_object('type', 'string', 'required', true),
              'title', jsonb_build_object('type', 'string', 'required', true),
              'area', jsonb_build_object('type', 'string', 'required', true),
              'publication_date', jsonb_build_object('type', 'string', 'required', true)
            )
          ELSE
            jsonb_build_object(
              'outbreak_id', jsonb_build_object('type', 'string', 'required', true),
              'title', jsonb_build_object('type', 'string', 'required', true),
              'status', jsonb_build_object('type', 'string', 'required', true),
              'area', jsonb_build_object('type', 'string', 'required', true),
              'data_as_of', jsonb_build_object('type', 'string', 'required', false)
            )
        END,
        'Emergency Alerts', 'en', 'published', now()
      );
    END IF;
  END LOOP;
END $$;
-- +goose StatementEnd

-- +goose Down
DELETE FROM notification_templates AS template
WHERE template.template_key IN (
  'outbreak-alert',
  'outbreak-update',
  'outbreak-status-change',
  'situation-report-publication'
)
AND NOT EXISTS (
  SELECT 1
  FROM notification_campaigns AS campaign
  JOIN notification_template_versions AS version
    ON version.id = campaign.template_version_id
  WHERE version.template_id = template.id
);
