package services

import (
	"encoding/json"
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestDrugServiceCRUDFilteringAndUsage(t *testing.T) {
	service := testDrugService(t)
	name := "Amoxicillin"
	status := "active"
	reviewStatus := "approved"
	description := "Penicillin antibiotic"
	created, err := service.Create(DrugInput{
		Name: &name, Status: &status, ReviewStatus: &reviewStatus,
		Description: &description, Categories: json.RawMessage(`["Antibiotics"]`),
	})
	if err != nil {
		t.Fatalf("create drug: %v", err)
	}

	result, err := service.List(DrugListInput{
		Page: PageInput{Page: 1, PerPage: 10}, Search: "amoxi",
		Status: "active", Sort: "name", Order: "asc",
	})
	if err != nil {
		t.Fatalf("list drugs: %v", err)
	}
	if result.TotalItems != 1 || len(result.Items) != 1 || result.Items[0].ID != created.ID {
		t.Fatalf("unexpected drug list: %#v", result)
	}

	updatedName := "Amoxicillin 500 mg"
	updated, err := service.Update(created.ID, DrugInput{Name: &updatedName})
	if err != nil || updated.Name != updatedName {
		t.Fatalf("update drug: %#v, %v", updated, err)
	}

	usage, err := service.RecordUsage(uuid.New(), created.ID)
	if err != nil || usage.DrugID != created.ID {
		t.Fatalf("record usage: %#v, %v", usage, err)
	}

	if err := service.Delete(created.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Get(created.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected archived drug to be unavailable, got %v", err)
	}
}

func TestDrugServiceRejectsInvalidEnumsAndUUIDs(t *testing.T) {
	service := testDrugService(t)
	name := "Invalid"
	status := "unknown"
	if _, err := service.Create(DrugInput{Name: &name, Status: &status}); !errors.Is(err, ErrDrugInvalidPayload) {
		t.Fatalf("expected invalid status rejection, got %v", err)
	}
	invalidID := "not-a-uuid"
	if _, err := service.Create(DrugInput{Name: &name, DrugClassID: &invalidID}); !errors.Is(err, ErrDrugInvalidPayload) {
		t.Fatalf("expected invalid class id rejection, got %v", err)
	}
}

func testDrugService(t *testing.T) DrugService {
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
		&models.Drug{},
		&models.DrugUsageLog{},
	); err != nil {
		t.Fatal(err)
	}
	return DrugService{DB: database}
}
