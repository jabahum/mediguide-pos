-- +goose Up
-- Constraint names are operational metadata. Rename the historical PocketBase
-- suffixes without rewriting already-applied schema migrations.
-- +goose StatementBegin
DO $$
DECLARE
  constraint_row record;
  neutral_name text;
BEGIN
  FOR constraint_row IN
    SELECT
      constraint_record.conrelid,
      constraint_record.conname,
      constraint_record.conrelid::regclass AS table_name
    FROM pg_constraint AS constraint_record
    JOIN pg_class AS table_record
      ON table_record.oid = constraint_record.conrelid
    JOIN pg_namespace AS namespace_record
      ON namespace_record.oid = table_record.relnamespace
    WHERE namespace_record.nspname = current_schema()
      AND constraint_record.conname LIKE '%\_pb' ESCAPE '\'
  LOOP
    neutral_name := regexp_replace(constraint_row.conname, '_pb$', '');
    IF NOT EXISTS (
      SELECT 1
      FROM pg_constraint
      WHERE conrelid = constraint_row.conrelid
        AND conname = neutral_name
    ) THEN
      EXECUTE format(
        'ALTER TABLE %s RENAME CONSTRAINT %I TO %I',
        constraint_row.table_name,
        constraint_row.conname,
        neutral_name
      );
    END IF;
  END LOOP;
END
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DO $$
DECLARE
  constraint_row record;
  historical_name text;
BEGIN
  FOR constraint_row IN
    SELECT
      constraint_record.conrelid,
      constraint_record.conname,
      constraint_record.conrelid::regclass AS table_name
    FROM pg_constraint AS constraint_record
    JOIN pg_class AS table_record
      ON table_record.oid = constraint_record.conrelid
    JOIN pg_namespace AS namespace_record
      ON namespace_record.oid = table_record.relnamespace
    WHERE namespace_record.nspname = current_schema()
      AND constraint_record.contype = 'c'
      AND constraint_record.conname LIKE 'chk_%'
      AND constraint_record.conname NOT LIKE '%\_pb' ESCAPE '\'
  LOOP
    historical_name := constraint_row.conname || '_pb';
    IF EXISTS (
      SELECT 1
      FROM pg_constraint
      WHERE conrelid = constraint_row.conrelid
        AND conname = historical_name
    ) THEN
      CONTINUE;
    END IF;

    IF constraint_row.conname IN (
      'chk_users_status',
      'chk_users_preferred_language',
      'chk_users_specialization_json',
      'chk_drug_categories_status',
      'chk_drug_tags_tag_category',
      'chk_drug_tags_status',
      'chk_drugs_route_of_administration',
      'chk_drugs_pregnancy_category',
      'chk_drugs_controlled_substance',
      'chk_drugs_status',
      'chk_drugs_review_status',
      'chk_drug_classes_status',
      'chk_therapeutic_categories_status',
      'chk_consultants_specialty',
      'chk_consultants_qualifications',
      'chk_consultants_preferred_language',
      'chk_consultants_consultation_types',
      'chk_consultants_status'
    ) THEN
      EXECUTE format(
        'ALTER TABLE %s RENAME CONSTRAINT %I TO %I',
        constraint_row.table_name,
        constraint_row.conname,
        historical_name
      );
    END IF;
  END LOOP;
END
$$;
-- +goose StatementEnd
