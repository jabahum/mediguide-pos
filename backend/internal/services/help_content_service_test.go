package services

import (
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func helpContentTestService(t *testing.T) HelpContentService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.Exec(`CREATE TABLE users (id text PRIMARY KEY, name text, email text)`).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.FAQ{}, &models.FAQTag{}, &models.Documentation{}); err != nil {
		t.Fatal(err)
	}
	return HelpContentService{DB: db}
}

func TestHelpContentReaderOnlySeesPublishedItems(t *testing.T) {
	service := helpContentTestService(t)
	items := []models.FAQ{
		{Question: "Published", Answer: "Visible", Status: "published", Priority: "normal", TargetAudience: "all"},
		{Question: "Draft", Answer: "Hidden", Status: "draft", Priority: "normal", TargetAudience: "all"},
	}
	if err := service.DB.Create(&items).Error; err != nil {
		t.Fatal(err)
	}
	reader, err := service.ListFAQs(false, HelpContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if reader.TotalItems != 1 || reader.Items[0].Question != "Published" {
		t.Fatalf("reader visibility incorrect: %#v", reader.Items)
	}
	editor, err := service.ListFAQs(true, HelpContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || editor.TotalItems != 2 {
		t.Fatalf("editor should see drafts: total=%d err=%v", editor.TotalItems, err)
	}
}

func TestHelpContentValidationRejectsInvalidTaxonomy(t *testing.T) {
	service := helpContentTestService(t)
	if _, err := service.SaveTag(nil, FAQTagInput{Name: "Bad", Slug: "Not Valid"}); err != ErrHelpContentInvalid {
		t.Fatalf("expected invalid slug, got %v", err)
	}
	badID := "not-a-uuid"
	if _, err := normalizeFAQInput(FAQInput{Question: "Question", Answer: "Answer", Status: "draft", Priority: "normal", Tags: []string{badID}}); err != ErrHelpContentInvalid {
		t.Fatalf("expected invalid tag UUID, got %v", err)
	}
	if _, err := service.SaveFAQ(nil, uuid.New(), FAQInput{Question: "", Answer: "Answer"}); err != ErrHelpContentInvalid {
		t.Fatalf("expected invalid FAQ, got %v", err)
	}
}

func TestDocumentationReaderVisibility(t *testing.T) {
	service := helpContentTestService(t)
	if _, err := service.SaveDocumentation(nil, DocumentationInput{Title: "Published", Content: "Help", Status: "published"}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.SaveDocumentation(nil, DocumentationInput{Title: "Draft", Content: "Internal", Status: "draft"}); err != nil {
		t.Fatal(err)
	}
	page, err := service.ListDocumentation(false, HelpContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || page.TotalItems != 1 {
		t.Fatalf("reader documentation visibility incorrect: total=%d err=%v", page.TotalItems, err)
	}
}

func TestFAQTagReaderOnlySeesActiveTags(t *testing.T) {
	service := helpContentTestService(t)
	active := true
	inactive := false
	if _, err := service.SaveTag(nil, FAQTagInput{Name: "Visible", Slug: "visible", IsActive: &active}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.SaveTag(nil, FAQTagInput{Name: "Hidden", Slug: "hidden", IsActive: &inactive}); err != nil {
		t.Fatal(err)
	}
	reader, err := service.ListTags(false, HelpContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || reader.TotalItems != 1 || reader.Items[0].Name != "Visible" {
		t.Fatalf("reader tag visibility incorrect: items=%#v err=%v", reader.Items, err)
	}
	editor, err := service.ListTags(true, HelpContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || editor.TotalItems != 2 {
		t.Fatalf("editor should see inactive tags: total=%d err=%v", editor.TotalItems, err)
	}
}
