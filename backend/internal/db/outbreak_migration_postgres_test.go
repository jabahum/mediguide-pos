package db

import (
	"context"
	"database/sql"
	"os"
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/google/uuid"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"gorm.io/datatypes"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
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
	if err := goose.UpTo(testDB, "../../migrations", 53); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'guideline_version_manifests' AND column_name IN ('reviewed_section_count','leaf_section_count','reviewed_leaf_section_count','empty_leaf_section_count','reviewed_paragraph_count')`, schema).Scan(&count); err != nil || count != 5 {
		t.Fatalf("guideline completeness columns missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'outbreaks' AND column_name = 'lock_version'`, schema).Scan(&count); err != nil || count != 1 {
		t.Fatalf("outbreak lock_version missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM pg_indexes WHERE schemaname = $1 AND indexname IN ('idx_outbreaks_public_search','idx_situation_reports_public_search')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("outbreak public search indexes missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.table_constraints WHERE constraint_schema = $1 AND constraint_name IN ('outbreaks_metrics_array_check','situation_reports_highlights_array_check')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("outbreak JSON safety constraints missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM notification_templates WHERE template_key IN ('outbreak-alert','outbreak-update','outbreak-status-change','situation-report-publication') AND status = 'published'`).Scan(&count); err != nil || count != 4 {
		t.Fatalf("outbreak notification templates missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM pg_indexes WHERE schemaname = $1 AND indexname IN ('idx_outbreak_resources_document_search_weighted','idx_outbreak_resources_document_title_trgm','idx_outbreaks_title_search')`, schema).Scan(&count); err != nil || count != 3 {
		t.Fatalf("outbreak document discovery indexes missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'outbreak_resources' AND column_name IN ('search_headings','extraction_error','extraction_source_checksum','derived_content_checksum','search_index_status','search_schema_version','content_sections','source_page_map','indexed_at')`, schema).Scan(&count); err != nil || count != 9 {
		t.Fatalf("outbreak document search projection columns missing after up/down/up: count=%d err=%v", count, err)
	}
	var indexPredicate string
	if err := testDB.QueryRowContext(ctx, `SELECT indexdef FROM pg_indexes WHERE schemaname = $1 AND indexname = 'idx_outbreak_resources_document_search_weighted'`, schema).Scan(&indexPredicate); err != nil || !strings.Contains(indexPredicate, "approved_at IS NOT NULL") || !strings.Contains(indexPredicate, "status = 'published'") {
		t.Fatalf("outbreak document search index is not approval-scoped after up/down/up: definition=%q err=%v", indexPredicate, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM notification_templates WHERE template_key LIKE 'outbreak-document-%' AND status = 'published'`).Scan(&count); err != nil || count != 7 {
		t.Fatalf("outbreak document notification templates missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'calculators' AND column_name IN ('runtime_type','current_version_id')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("calculator version columns missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.tables WHERE table_schema = $1 AND table_name IN ('calculator_versions','calculator_test_cases','calculator_citations','calculator_version_audits')`, schema).Scan(&count); err != nil || count != 4 {
		t.Fatalf("calculator version tables missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM pg_indexes WHERE schemaname = $1 AND indexname = 'idx_calculator_versions_one_published'`, schema).Scan(&count); err != nil || count != 1 {
		t.Fatalf("single-published-version index missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.tables WHERE table_schema = $1 AND table_name IN ('diseases','disease_aliases','disease_codes','disease_taxonomy_migration_report')`, schema).Scan(&count); err != nil || count != 4 {
		t.Fatalf("disease taxonomy tables missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM diseases WHERE status = 'active' AND deleted_at IS NULL`).Scan(&count); err != nil || count != 7 {
		t.Fatalf("initial disease taxonomy seed mismatch: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.tables WHERE table_schema = $1 AND table_name IN ('guideline_document_categories','content_disease_assignments')`, schema).Scan(&count); err != nil || count != 2 {
		t.Fatalf("content classification tables missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM pg_indexes WHERE schemaname = $1 AND indexname IN ('idx_guideline_document_categories_category','idx_content_disease_assignment_unique','idx_content_disease_assignment_primary','idx_content_disease_assignment_disease','idx_content_disease_assignment_resource')`, schema).Scan(&count); err != nil || count != 5 {
		t.Fatalf("content classification indexes missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM information_schema.tables WHERE table_schema = $1 AND table_name IN ('content_hubs','content_hub_diseases','content_pillars','content_pillar_items','content_hub_templates','content_hub_template_pillars')`, schema).Scan(&count); err != nil || count != 6 {
		t.Fatalf("content hub tables missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM content_hub_templates WHERE status = 'active' AND deleted_at IS NULL`).Scan(&count); err != nil || count != 3 {
		t.Fatalf("content hub template seed mismatch: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM content_hub_template_pillars WHERE deleted_at IS NULL`).Scan(&count); err != nil || count != 32 {
		t.Fatalf("content hub template pillar seed mismatch: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM permissions WHERE code IN (
		'disease.taxonomy.read','disease.taxonomy.manage','disease.assignment.read','disease.assignment.manage',
		'content_hub.read','content_hub.manage','content_hub.publish','content_hub.archive',
		'content_pillar.read','content_pillar.manage','content_hub.template.read','content_hub.template.manage'
	) AND deleted_at IS NULL`).Scan(&count); err != nil || count != 12 {
		t.Fatalf("disease/hub permissions missing after up/down/up: count=%d err=%v", count, err)
	}
	if err := testDB.QueryRowContext(ctx, `SELECT count(*) FROM role_permissions rp JOIN roles r ON r.id = rp.role_id JOIN permissions p ON p.id = rp.permission_id WHERE lower(coalesce(r.role_key, r.name)) IN ('content_manager','editor') AND p.code IN ('content_hub.publish','content_hub.archive')`).Scan(&count); err != nil || count != 0 {
		t.Fatalf("ordinary editors received hub publication permissions: count=%d err=%v", count, err)
	}
	var pillarItemDefault string
	if err := testDB.QueryRowContext(ctx, `SELECT column_default FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'content_pillar_items' AND column_name = 'status'`, schema).Scan(&pillarItemDefault); err != nil || !strings.Contains(pillarItemDefault, "draft") {
		t.Fatalf("content pillar items do not default to draft: default=%q err=%v", pillarItemDefault, err)
	}
	if _, err := testDB.ExecContext(ctx, `INSERT INTO diseases (id, name, normalized_name, slug) VALUES
		('92000000-0000-4000-8000-000000000001', 'Cycle parent', 'cycle parent', 'cycle-parent'),
		('92000000-0000-4000-8000-000000000002', 'Cycle child', 'cycle child', 'cycle-child')`); err != nil {
		t.Fatal(err)
	}
	if _, err := testDB.ExecContext(ctx, `UPDATE diseases SET parent_id = '92000000-0000-4000-8000-000000000001' WHERE id = '92000000-0000-4000-8000-000000000002'`); err != nil {
		t.Fatal(err)
	}
	if _, err := testDB.ExecContext(ctx, `UPDATE diseases SET parent_id = '92000000-0000-4000-8000-000000000002' WHERE id = '92000000-0000-4000-8000-000000000001'`); err == nil {
		t.Fatal("PostgreSQL disease hierarchy trigger accepted a cycle")
	}

	// Exercise the real PostgreSQL discovery query, not the SQLite fallback.
	// The single-connection search_path above keeps all fixtures isolated in the
	// disposable schema while pg_trgm and tsvector functions remain available
	// from public.
	gormDB, err := gorm.Open(postgres.New(postgres.Config{Conn: testDB}), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC().Add(-time.Hour)
	parent := models.Outbreak{Title: "Ebola response", DiseaseType: "EVD", GeographicArea: "Kampala", Status: "active", VisualTone: "warning", PublishedAt: &now, LastUpdate: now, Metrics: datatypes.JSON(`[]`)}
	if err := gormDB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	pageFour := 4
	documents := []models.OutbreakResource{
		{OutbreakID: parent.ID, Title: "Specimen packaging protocol", Description: "Laboratory SOP", ResourceType: "managed_document", DocumentKind: "laboratory_protocol", IssuingAuthority: "Ministry of Health", DocumentNumber: "LAB-001", Version: "1.0", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &now, SearchHeadings: "Packaging specimens", SearchContent: "Triple package every specimen before referral", ContentSections: []byte(`[{"id":"page-4","heading":"Packaging specimens","level":1,"text":"Triple package every specimen before referral.","page":4}]`), SourcePageMap: []byte(`[{"page":4,"section_id":"page-4"}]`), SortOrder: 2},
		{OutbreakID: parent.ID, Title: "Triple package every specimen before referral", Description: "Exact-title reference", ResourceType: "managed_document", DocumentKind: "laboratory_protocol", IssuingAuthority: "Ministry of Health", DocumentNumber: "LAB-002", Version: "1.0", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &now, SearchContent: "Referral laboratory guidance", ContentSections: []byte(`[]`), SourcePageMap: []byte(`[]`), SortOrder: 1},
		{OutbreakID: parent.ID, Title: "Draft laboratory note", ResourceType: "managed_document", DocumentKind: "laboratory_protocol", Language: "en", Status: "draft", SearchContent: "Triple package every specimen before referral", ContentSections: []byte(`[]`), SourcePageMap: []byte(`[]`)},
	}
	for index := range documents {
		if err := gormDB.Create(&documents[index]).Error; err != nil {
			t.Fatal(err)
		}
	}
	service := services.OutbreakService{DB: gormDB}
	result, err := service.SearchDocuments(services.OutbreakDocumentQuery{Page: services.PageInput{Page: 1, PerPage: 1}, Search: "Triple package every specimen before referral", OutbreakID: &parent.ID, DocumentKind: "laboratory_protocol", Authority: "Ministry of Health", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Sort: "title", Order: "asc"})
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalItems != 2 || result.TotalPages != 2 || len(result.Items) != 1 || result.Items[0].ID != documents[1].ID || result.Items[0].SearchRelevanceScore <= 0 {
		t.Fatalf("PostgreSQL ranking/filter/pagination mismatch: %#v", result)
	}
	pageTwo, err := service.SearchDocuments(services.OutbreakDocumentQuery{Page: services.PageInput{Page: 2, PerPage: 1}, Search: "Triple package every specimen before referral", Sort: "title", Order: "asc"})
	if err != nil || len(pageTwo.Items) != 1 || pageTwo.Items[0].ID != documents[0].ID || pageTwo.Items[0].MatchingPDFPage == nil || *pageTwo.Items[0].MatchingPDFPage != pageFour {
		t.Fatalf("PostgreSQL page match/order mismatch: %#v err=%v", pageTwo, err)
	}
	if _, err := service.SearchDocuments(services.OutbreakDocumentQuery{Sort: "title; DROP TABLE outbreak_resources;--"}); err == nil {
		t.Fatal("malicious PostgreSQL sort was accepted")
	}
	var resourceCount int64
	if err := gormDB.Model(&models.OutbreakResource{}).Count(&resourceCount).Error; err != nil || resourceCount != 3 {
		t.Fatalf("PostgreSQL injection resistance failed: count=%d err=%v", resourceCount, err)
	}
}
