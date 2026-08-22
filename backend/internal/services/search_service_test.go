package services

import (
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestPublicDiscoverySearchIncludesOnlyPublishedOutbreakContent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	for _, statement := range []string{
		`CREATE TABLE guideline_documents (id text primary key, current_version_id text, deleted_at datetime)`,
		`CREATE TABLE guideline_versions (id text primary key, status text, deleted_at datetime)`,
		`CREATE TABLE guideline_chunks (id text primary key, document_id text, version_id text, section_id text, block_id text, title text, content text, source_name text, source_version text, page_start integer, page_end integer, program_area text, review_status text, updated_at datetime, deleted_at datetime)`,
		`CREATE TABLE guideline_content_blocks (id text primary key, type text, deleted_at datetime)`,
	} {
		if err := database.Exec(statement).Error; err != nil {
			t.Fatal(err)
		}
	}
	if err := database.AutoMigrate(&models.Outbreak{}, &models.SituationReport{}); err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC()
	verified := now.Add(-time.Hour)
	public := models.Outbreak{Title: "Ebola response", DiseaseType: "Ebola", GeographicArea: "Uganda", Summary: "Verified response", SourceOrganization: "Ministry of Health", SourceReference: "approved-keyword", Status: "active", PublishedAt: &now, LastUpdate: now, LastVerifiedAt: &verified}
	draft := models.Outbreak{Title: "Ebola internal draft", Status: "draft", LastUpdate: now}
	withdrawnAt := now
	withdrawn := models.Outbreak{Title: "Ebola withdrawn", Status: "active", PublishedAt: &now, WithdrawnAt: &withdrawnAt, LastUpdate: now}
	for _, row := range []*models.Outbreak{&public, &draft, &withdrawn} {
		if err := database.Create(row).Error; err != nil {
			t.Fatal(err)
		}
	}
	report := models.SituationReport{Title: "Ebola situation report", Summary: "Field report", GeographicArea: "Kampala", SourceOrganization: "Ministry", SourceReference: "approved-keyword", PublicationDate: now, Status: "published", PublishedAt: &now, LastVerifiedAt: &verified}
	if err := database.Create(&report).Error; err != nil {
		t.Fatal(err)
	}

	results, err := (SearchService{DB: database}).PublicSearchContext(t.Context(), "Ebola", "", 20)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 2 {
		t.Fatalf("expected published outbreak and report, got %#v", results)
	}
	if results[0].ResultType != "outbreak" || results[0].ID != public.ID.String() {
		t.Fatalf("fresh active outbreak should rank first: %#v", results)
	}
	if results[0].IsStale {
		t.Fatal("recently verified outbreak marked stale")
	}
	for _, result := range results {
		if result.ID == draft.ID.String() || result.ID == withdrawn.ID.String() {
			t.Fatalf("non-public result leaked: %#v", result)
		}
	}
}
