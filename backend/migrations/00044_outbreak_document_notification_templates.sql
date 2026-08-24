-- +goose Up
-- Lifecycle services currently render these messages from trusted server data.
-- The published templates make the same event catalogue available to future
-- campaign/channel expansion without allowing clients to author deep links.
-- +goose StatementBegin
DO $$
DECLARE
  definition record;
  template_id uuid;
BEGIN
  FOR definition IN
    SELECT * FROM (VALUES
      ('outbreak-document-review-requested', 'Outbreak document review requested', '{{document_title}} needs clinical review', '{{document_title}} was submitted for clinician review in {{outbreak_title}}.'),
      ('outbreak-document-approved', 'Outbreak document approved', '{{document_title}} is approved', '{{document_title}} has clinician approval and is ready to publish.'),
      ('outbreak-document-published', 'Outbreak document published', 'New outbreak guidance: {{document_title}}', '{{document_title}} from {{authority}} is now available.'),
      ('outbreak-document-replacement-published', 'Replacement outbreak document published', 'Updated outbreak guidance: {{document_title}}', 'A reviewed replacement for {{document_title}} is now available.'),
      ('outbreak-document-withdrawn', 'Outbreak document withdrawn', '{{document_title}} was withdrawn', 'Open the outbreak hub for current guidance.'),
      ('outbreak-document-review-due', 'Outbreak document review due', 'Review date approaching: {{document_title}}', 'Review {{document_title}} before its clinical review date.'),
      ('outbreak-document-expired', 'Outbreak document expired', 'Expired guidance: {{document_title}}', '{{document_title}} has expired and is no longer shown publicly.')
    ) AS value(template_key, name, title_template, body_template)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM notification_templates WHERE template_key = definition.template_key AND deleted_at IS NULL) THEN
      template_id := uuid_generate_v4();
      INSERT INTO notification_templates (
        id, name, template_key, type, category, status, current_version,
        locale, subject, content, variables_json
      ) VALUES (
        template_id, definition.name, definition.template_key, 'in-app',
        'Emergency Alerts', 'published', 1, 'en', definition.title_template,
        definition.body_template,
        jsonb_build_object(
          'document_id', jsonb_build_object('type', 'string', 'required', true),
          'outbreak_id', jsonb_build_object('type', 'string', 'required', true),
          'document_title', jsonb_build_object('type', 'string', 'required', true),
          'outbreak_title', jsonb_build_object('type', 'string', 'required', false),
          'authority', jsonb_build_object('type', 'string', 'required', false)
        )
      );
      INSERT INTO notification_template_versions (
        template_id, version, channel, title_template, body_template,
        action_template_json, variable_schema_json, category, locale,
        status, published_at
      ) VALUES (
        template_id, 1, 'in-app', definition.title_template,
        definition.body_template,
        jsonb_build_object('type', 'outbreak_document', 'resource_id', '{{document_id}}', 'parameters', jsonb_build_object('outbreak_id', '{{outbreak_id}}')),
        jsonb_build_object(
          'document_id', jsonb_build_object('type', 'string', 'required', true),
          'outbreak_id', jsonb_build_object('type', 'string', 'required', true),
          'document_title', jsonb_build_object('type', 'string', 'required', true),
          'outbreak_title', jsonb_build_object('type', 'string', 'required', false),
          'authority', jsonb_build_object('type', 'string', 'required', false)
        ),
        'Emergency Alerts', 'en', 'published', now()
      );
    END IF;
  END LOOP;
END $$;
-- +goose StatementEnd

-- +goose Down
DELETE FROM notification_templates
WHERE template_key IN (
  'outbreak-document-review-requested',
  'outbreak-document-approved',
  'outbreak-document-published',
  'outbreak-document-replacement-published',
  'outbreak-document-withdrawn',
  'outbreak-document-review-due',
  'outbreak-document-expired'
)
AND NOT EXISTS (
  SELECT 1 FROM notification_campaigns campaign
  JOIN notification_template_versions version ON version.id = campaign.template_version_id
  WHERE version.template_id = notification_templates.id
);
