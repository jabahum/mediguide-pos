package services

import (
	"strings"
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

func TestPublishedGuidelineAssistantSearchStaysInsideCurrentPublishedVersion(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	for _, statement := range []string{
		`CREATE TABLE guideline_documents (id text primary key, current_version_id text, deleted_at datetime)`,
		`CREATE TABLE guideline_versions (id text primary key, document_id text, status text, deleted_at datetime)`,
		`CREATE TABLE guideline_chunks (id text primary key, document_id text, version_id text, section_id text, block_id text, title text, content text, source_name text, source_version text, page_start integer, page_end integer, review_status text, updated_at datetime, deleted_at datetime)`,
	} {
		if err := database.Exec(statement).Error; err != nil {
			t.Fatal(err)
		}
	}
	targetID, otherID := uuid.New(), uuid.New()
	targetVersion, oldVersion, otherVersion := uuid.New(), uuid.New(), uuid.New()
	for _, statement := range []struct {
		query string
		args  []any
	}{
		{`INSERT INTO guideline_documents(id,current_version_id) VALUES (?,?)`, []any{targetID, targetVersion}},
		{`INSERT INTO guideline_documents(id,current_version_id) VALUES (?,?)`, []any{otherID, otherVersion}},
		{`INSERT INTO guideline_versions(id,document_id,status) VALUES (?,?,?)`, []any{targetVersion, targetID, "published"}},
		{`INSERT INTO guideline_versions(id,document_id,status) VALUES (?,?,?)`, []any{oldVersion, targetID, "published"}},
		{`INSERT INTO guideline_versions(id,document_id,status) VALUES (?,?,?)`, []any{otherVersion, otherID, "published"}},
		{`INSERT INTO guideline_chunks(id,document_id,version_id,title,content,source_name,source_version,review_status,updated_at) VALUES (?,?,?,?,?,?,?,?,?)`, []any{uuid.New(), targetID, targetVersion, "Current treatment", "Give intravenous artesunate for severe malaria", "MoH", "2", "approved", time.Now()}},
		{`INSERT INTO guideline_chunks(id,document_id,version_id,title,content,source_name,source_version,review_status,updated_at) VALUES (?,?,?,?,?,?,?,?,?)`, []any{uuid.New(), targetID, targetVersion, "Unreviewed paragraph", "DRAFT malaria paragraph must remain private", "MoH", "2", "draft", time.Now()}},
		{`INSERT INTO guideline_chunks(id,document_id,version_id,title,content,source_name,source_version,review_status,updated_at) VALUES (?,?,?,?,?,?,?,?,?)`, []any{uuid.New(), targetID, oldVersion, "Superseded", "Old severe malaria recommendation", "MoH", "1", "approved", time.Now()}},
		{`INSERT INTO guideline_chunks(id,document_id,version_id,title,content,source_name,source_version,review_status,updated_at) VALUES (?,?,?,?,?,?,?,?,?)`, []any{uuid.New(), otherID, otherVersion, "Other guideline", "Artesunate from another document", "Other", "1", "approved", time.Now()}},
	} {
		if err := database.Exec(statement.query, statement.args...).Error; err != nil {
			t.Fatal(err)
		}
	}

	results, err := (SearchService{DB: database}).SearchPublishedGuidelineContext(t.Context(), targetID, "What is the severe malaria treatment?", 5)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 1 || results[0].Title != "Current treatment" || results[0].GuidelineID != targetID.String() {
		t.Fatalf("assistant search escaped the current publication: %#v", results)
	}

	generalResults, err := (SearchService{DB: database}).SearchApprovedGuidelineContext(t.Context(), "How should severe malaria be treated?", 5)
	if err != nil {
		t.Fatal(err)
	}
	if len(generalResults) != 1 || generalResults[0].Title != "Current treatment" || generalResults[0].GuidelineID != targetID.String() {
		t.Fatalf("general assistant search leaked superseded content: %#v", generalResults)
	}
	draftResults, err := (SearchService{DB: database}).SearchApprovedGuidelineContext(t.Context(), "DRAFT malaria paragraph", 5)
	if err != nil {
		t.Fatal(err)
	}
	for _, result := range draftResults {
		if result.Title == "Unreviewed paragraph" {
			t.Fatalf("unreviewed paragraph leaked into RAG retrieval: %#v", draftResults)
		}
	}
}

func TestPublicAssistantTermsRemovesQuestionNoise(t *testing.T) {
	terms := publicAssistantTerms("What is the treatment for severe malaria, and when should I refer?")
	if strings.Join(terms, ",") != "treatment,severe,malaria,refer" {
		t.Fatalf("unexpected terms: %#v", terms)
	}
}

func TestRAGRetrievalResolvesDiseaseAliasesAndHubScopeWithoutLeakingDrafts(t *testing.T) {
	db := classificationTestDB(t)
	if err := db.AutoMigrate(
		&models.DiseaseAlias{},
		&models.ContentHub{},
		&models.ContentHubDisease{},
		&models.ContentPillar{},
		&models.ContentPillarItem{},
		&models.GuidelineChunk{},
	); err != nil {
		t.Fatal(err)
	}
	disease := models.Disease{Name: "Ebola virus disease", NormalizedName: "ebola virus disease", Slug: "ebola-virus-disease", Status: models.DiseaseStatusActive}
	if err := db.Create(&disease).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.DiseaseAlias{DiseaseID: disease.ID, Alias: "EVD", NormalizedAlias: "evd"}).Error; err != nil {
		t.Fatal(err)
	}
	document := models.GuidelineDocument{Title: "Ebola clinical care", SourceOrg: "Ministry of Health"}
	other := models.GuidelineDocument{Title: "Other infection"}
	outsideHub := models.GuidelineDocument{Title: "Ebola community treatment", SourceOrg: "Ministry of Health"}
	for _, value := range []*models.GuidelineDocument{&document, &other, &outsideHub} {
		if err := db.Create(value).Error; err != nil {
			t.Fatal(err)
		}
		version := models.GuidelineVersion{DocumentID: value.ID, Version: "1", Status: "published"}
		if err := db.Create(&version).Error; err != nil {
			t.Fatal(err)
		}
		if err := db.Model(value).Update("current_version_id", version.ID).Error; err != nil {
			t.Fatal(err)
		}
		status := "approved"
		if value.ID == document.ID || value.ID == outsideHub.ID {
			if err := db.Create(&models.ContentDiseaseAssignment{DiseaseID: disease.ID, ContentType: models.ContentDiseaseGuideline, ContentID: value.ID, IsPrimary: true}).Error; err != nil {
				t.Fatal(err)
			}
		} else {
			status = "draft"
		}
		if err := db.Create(&models.GuidelineChunk{DocumentID: value.ID, VersionID: version.ID, Title: value.Title, Content: "Ebola clinical treatment", ReviewStatus: status}).Error; err != nil {
			t.Fatal(err)
		}
	}
	now := time.Now().UTC()
	hub := models.ContentHub{Name: "Ebola response", Slug: "ebola-response", Status: models.ContentHubStatusActive, PublishedAt: &now}
	if err := db.Create(&hub).Error; err != nil {
		t.Fatal(err)
	}
	pillar := models.ContentPillar{HubID: hub.ID, Name: "Clinical care", Slug: "clinical-care", Status: models.ContentPillarStatusActive}
	if err := db.Create(&pillar).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.ContentPillarItem{PillarID: pillar.ID, ContentType: models.ContentDiseaseGuideline, ContentID: &document.ID, Status: models.ContentPillarItemStatusActive}).Error; err != nil {
		t.Fatal(err)
	}

	service := SearchService{DB: db}
	byAlias, err := service.SearchApprovedGuidelineContextFiltered(t.Context(), "Ebola treatment", PublicSearchFilter{DiseaseSlug: "EVD"}, 5)
	if err != nil || len(byAlias) != 2 {
		t.Fatalf("alias-scoped RAG retrieval failed: %#v %v", byAlias, err)
	}
	byPillar, err := service.SearchApprovedGuidelineContextFiltered(t.Context(), "Ebola treatment", PublicSearchFilter{HubSlug: hub.Slug, PillarSlug: pillar.Slug}, 5)
	if err != nil || len(byPillar) != 1 || byPillar[0].GuidelineID != document.ID.String() {
		t.Fatalf("pillar-scoped RAG retrieval failed: %#v %v", byPillar, err)
	}
	publicByHub, err := service.PublicSearchContextFiltered(t.Context(), "Ebola treatment", PublicSearchFilter{HubSlug: hub.Slug}, 20)
	if err != nil {
		t.Fatal(err)
	}
	for _, result := range publicByHub {
		if result.GuidelineID == outsideHub.ID.String() || result.ID == outsideHub.ID.String() {
			t.Fatalf("disease-assigned resource outside the requested hub leaked into search: %#v", publicByHub)
		}
	}
}
