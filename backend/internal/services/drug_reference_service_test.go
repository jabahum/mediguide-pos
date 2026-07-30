package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestDrugReferenceServiceCRUDAndFiltering(t *testing.T) {
	service := testDrugReferenceService(t)
	name := "Antibiotics"
	status := "active"
	item, err := service.CreateCategory(DrugCategoryInput{Name: &name, Status: &status})
	if err != nil {
		t.Fatal(err)
	}
	result, err := service.ListCategories(DrugReferenceListInput{
		Page: PageInput{Page: 1, PerPage: 10}, Search: "antib", Status: "active",
	})
	if err != nil || result.TotalItems != 1 || result.Items[0].ID != item.ID {
		t.Fatalf("unexpected category list: %#v, %v", result, err)
	}
	if err := service.Delete("category", item.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := service.GetCategory(item.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected deleted category to be unavailable, got %v", err)
	}
}

func TestDrugReferenceServiceRejectsUnknownTagCategory(t *testing.T) {
	service := testDrugReferenceService(t)
	name := "Unsafe"
	tagCategory := "unknown"
	if _, err := service.CreateTag(DrugTagInput{Name: &name, TagCategory: &tagCategory}); !errors.Is(err, ErrDrugReferenceInvalidPayload) {
		t.Fatalf("expected invalid tag category rejection, got %v", err)
	}
}

func testDrugReferenceService(t *testing.T) DrugReferenceService {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.DrugCategory{},
		&models.DrugTag{},
		&models.DrugClass{},
		&models.TherapeuticCategory{},
	); err != nil {
		t.Fatal(err)
	}
	return DrugReferenceService{DB: database}
}
