package services

import (
	"errors"
	"strings"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestRAGAskRejectsInvalidQuestionsBeforeDatabaseAccess(t *testing.T) {
	t.Parallel()

	service := RAGService{}
	for _, question := range []string{"", " ", "x", strings.Repeat("x", 12001)} {
		_, err := service.Ask(nil, AskRequest{Question: question})
		if !errors.Is(err, ErrInvalidRAGQuestion) {
			t.Fatalf("question length %d: expected ErrInvalidRAGQuestion, got %v", len(question), err)
		}
	}
}

func TestPublishedRAGAskRejectsInvalidQuestionsBeforeDatabaseAccess(t *testing.T) {
	t.Parallel()

	service := RAGService{}
	for _, question := range []string{"", " ", "x", strings.Repeat("x", 1201)} {
		_, err := service.AskPublishedGuideline(t.Context(), uuid.New(), AskRequest{Question: question})
		if !errors.Is(err, ErrInvalidPublicRAGQuestion) {
			t.Fatalf("question length %d: expected ErrInvalidPublicRAGQuestion, got %v", len(question), err)
		}
	}
}

func TestPublicRAGAskRejectsInvalidQuestionsBeforeDatabaseAccess(t *testing.T) {
	t.Parallel()
	service := RAGService{}
	for _, question := range []string{"", "x", strings.Repeat("x", 1201)} {
		_, err := service.AskPublic(AskRequest{Question: question})
		if !errors.Is(err, ErrInvalidPublicRAGQuestion) {
			t.Fatalf("question length %d: expected ErrInvalidPublicRAGQuestion, got %v", len(question), err)
		}
	}
}

func TestRAGCitationEnrichmentUsesAuthoritativeChunkNavigation(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.GuidelineDocument{}, &models.GuidelineVersion{}, &models.GuidelineChunk{}); err != nil {
		t.Fatal(err)
	}
	sectionID := uuid.New()
	blockID := uuid.New()
	document := models.GuidelineDocument{Title: "Current guideline"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "published"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&document).Update("current_version_id", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	chunk := models.GuidelineChunk{
		DocumentID:   document.ID,
		VersionID:    version.ID,
		SectionID:    &sectionID,
		BlockID:      &blockID,
		Title:        "Reviewed source",
		ReviewStatus: "approved",
	}
	if err := db.Create(&chunk).Error; err != nil {
		t.Fatal(err)
	}
	citations := RAGService{DB: db}.enrichCitations([]Citation{
		{ChunkID: chunk.ID.String()},
		{ChunkID: uuid.NewString(), Title: "Stale worker citation"},
	})

	if len(citations) != 1 || citations[0].GuidelineID != chunk.DocumentID.String() || citations[0].GuidelineVersionID != version.ID.String() || citations[0].ContentType != "guideline" || citations[0].SectionID != sectionID.String() || citations[0].BlockID != blockID.String() {
		t.Fatalf("unexpected citation navigation: %+v", citations)
	}
	if citations[0].Route != "/guidelines/"+document.ID.String() || citations[0].Metadata["review_state"] != "approved" {
		t.Fatalf("citation metadata is incomplete: %+v", citations[0])
	}
}
