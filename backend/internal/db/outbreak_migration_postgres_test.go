package db

import (
	"context"
	"database/sql"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

func TestOutbreakAdministrationMigrationUpDownUp(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("MEDIGUIDE_TEST_DATABASE_URL"))
	if dsn == "" {
		t.Skip("MEDIGUIDE_TEST_DATABASE_URL is not configured")
	}
	ctx := context.Background()
	admin, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer admin.Close()
	schema := "migration_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	if _, err := admin.ExecContext(ctx, `CREATE SCHEMA "`+schema+`"`); err != nil {
		t.Fatal(err)
	}
	defer admin.ExecContext(ctx, `DROP SCHEMA IF EXISTS "`+schema+`" CASCADE`)

	testDB, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer testDB.Close()
	testDB.SetMaxOpenConns(1)
	testDB.SetMaxIdleConns(1)
	if _, err := testDB.ExecContext(ctx, `SET search_path TO "`+schema+`", public`); err != nil {
		t.Fatal(err)
	}
	var activeSchema string
	if err := testDB.QueryRowContext(ctx, `SELECT current_schema()`).Scan(&activeSchema); err != nil || activeSchema != schema {
		t.Fatalf("isolated migration schema not active: schema=%q err=%v", activeSchema, err)
	}
	if err := goose.SetDialect("postgres"); err != nil {
		t.Fatal(err)
	}
	goose.SetTableName(schema + ".goose_db_version")
	defer goose.SetTableName("goose_db_version")
	if err := goose.Up(testDB, "../../migrations"); err != nil {
		t.Fatal(err)
	}
	if err := goose.DownTo(testDB, "../../migrations", 35); err != nil {
		t.Fatal(err)
	}
	if err := goose.UpTo(testDB, "../../migrations", 37); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'outbreaks' AND column_name = 'lock_version'`, schema).Scan(&count); err != nil || count != 1 {
		t.Fatalf("outbreak lock_version missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM pg_indexes WHERE schemaname = $1 AND indexname IN ('idx_outbreaks_public_search','idx_situation_reports_public_search')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("outbreak public search indexes missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.table_constraints WHERE constraint_schema = $1 AND constraint_name IN ('outbreaks_metrics_array_check','situation_reports_highlights_array_check')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("outbreak JSON safety constraints missing after up/down/up: count=%d err=%v", count, err)
	}
}
