package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func guidelineContentTestService(t *testing.T) GuidelineContentService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.GuidelineCategory{}, &models.GuidelineTag{}, &models.Abbreviation{}, &models.GuidelineIndexEntry{}, &models.MedicalGuideline{}); err != nil {
		t.Fatal(err)
	}
	return GuidelineContentService{DB: db}
}

func TestGuidelineContentReaderVisibility(t *testing.T) {
	service := guidelineContentTestService(t)
	active, inactive := "active", "inactive"
	if _, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Visible"), Status: &active}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Hidden"), Status: &inactive}); err != nil {
		t.Fatal(err)
	}
	reader, err := service.ListCategories(false, GuidelineContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || reader.TotalItems != 1 || reader.Items[0].Name != "Visible" {
		t.Fatalf("reader categories: %#v err=%v", reader, err)
	}

	published, draft := "published", "draft"
	if _, err := service.SaveMedicalGuideline(nil, MedicalGuidelineInput{ConditionName: stringPtr("Published"), Status: &published}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.SaveMedicalGuideline(nil, MedicalGuidelineInput{ConditionName: stringPtr("Draft"), Status: &draft}); err != nil {
		t.Fatal(err)
	}
	guidelines, err := service.ListMedicalGuidelines(false, GuidelineContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || guidelines.TotalItems != 1 || guidelines.Items[0].ConditionName != "Published" {
		t.Fatalf("reader guidelines: %#v err=%v", guidelines, err)
	}
}

func TestGuidelineCategoryRejectsCyclesAndInvalidParents(t *testing.T) {
	service := guidelineContentTestService(t)
	parent, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Parent")})
	if err != nil {
		t.Fatal(err)
	}
	parentID := parent.ID.String()
	child, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Child"), ParentCategoryID: &parentID})
	if err != nil {
		t.Fatal(err)
	}
	childID := child.ID.String()
	if _, err := service.SaveCategory(&parent.ID, GuidelineCategoryInput{ParentCategoryID: &childID}); !errors.Is(err, ErrGuidelineHierarchyCycle) {
		t.Fatalf("expected cycle error, got %v", err)
	}
	invalid := "not-a-uuid"
	if _, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Invalid"), ParentCategoryID: &invalid}); !errors.Is(err, ErrGuidelineContentInvalid) {
		t.Fatalf("expected invalid parent, got %v", err)
	}
}

func TestGuidelineIndexMaintainsHierarchy(t *testing.T) {
	service := guidelineContentTestService(t)
	parent, err := service.SaveIndex(nil, GuidelineIndexInput{Title: stringPtr("Parent")})
	if err != nil {
		t.Fatal(err)
	}
	parentID := parent.ID.String()
	child, err := service.SaveIndex(nil, GuidelineIndexInput{Title: stringPtr("Child"), ParentID: &parentID})
	if err != nil {
		t.Fatal(err)
	}
	if child.Level != 1 {
		t.Fatalf("expected derived child level 1, got %d", child.Level)
	}
	parent, err = service.GetIndex(parent.ID)
	if err != nil || !parent.HasChildren {
		t.Fatalf("expected parent child marker, item=%#v err=%v", parent, err)
	}
	if err := service.DeleteIndex(parent.ID); !errors.Is(err, ErrGuidelineParentInUse) {
		t.Fatalf("expected parent-in-use error, got %v", err)
	}
}

func TestGuidelineContentRejectsUnknownTaxonomyRelations(t *testing.T) {
	service := guidelineContentTestService(t)
	missing := []string{"dd30e331-04e2-4be2-b919-82f4486032ec"}
	if _, err := service.SaveMedicalGuideline(nil, MedicalGuidelineInput{ConditionName: stringPtr("Invalid"), Categories: &missing}); !errors.Is(err, ErrGuidelineContentInvalid) {
		t.Fatalf("expected invalid relation, got %v", err)
	}
}

func TestMedicalGuidelinesReturnTaxonomyDisplayValues(t *testing.T) {
	service := guidelineContentTestService(t)
	category, err := service.SaveCategory(nil, GuidelineCategoryInput{Name: stringPtr("Infectious diseases")})
	if err != nil {
		t.Fatal(err)
	}
	tag, err := service.SaveTag(nil, GuidelineTagInput{Name: stringPtr("Emergency")})
	if err != nil {
		t.Fatal(err)
	}
	categoryIDs := []string{category.ID.String()}
	tagIDs := []string{tag.ID.String()}
	published := "published"
	created, err := service.SaveMedicalGuideline(nil, MedicalGuidelineInput{
		ConditionName: stringPtr("Ebola"), Status: &published,
		Categories: &categoryIDs, Tags: &tagIDs,
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(created.CategoryDetails) != 1 || created.CategoryDetails[0].Name != "Infectious diseases" {
		t.Fatalf("unexpected category projection: %#v", created.CategoryDetails)
	}
	if len(created.TagDetails) != 1 || created.TagDetails[0].Name != "Emergency" {
		t.Fatalf("unexpected tag projection: %#v", created.TagDetails)
	}

	listed, err := service.ListMedicalGuidelines(false, GuidelineContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if len(listed.Items) != 1 || listed.Items[0].CategoryDetails[0].Name != "Infectious diseases" {
		t.Fatalf("unexpected list projection: %#v", listed.Items)
	}
}

func stringPtr(value string) *string { return &value }
