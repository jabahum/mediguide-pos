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

func contentReferenceTestService(t *testing.T) ContentReferenceService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.GenericPage{}, &models.MinistryDirectoryEntry{}, &models.District{}, &models.Region{}, &models.Language{}); err != nil {
		t.Fatal(err)
	}
	return ContentReferenceService{DB: db}
}

func TestContentReferencePageKeyIsUnique(t *testing.T) {
	s := contentReferenceTestService(t)
	title, key := "About", "about-us"
	content := json.RawMessage(`{"intro":"Welcome"}`)
	if _, err := s.SavePage(nil, GenericPageInput{Title: &title, Key: &key, Content: &content}); err != nil {
		t.Fatal(err)
	}
	if _, err := s.SavePage(nil, GenericPageInput{Title: &title, Key: &key}); !errors.Is(err, ErrContentReferenceConflict) {
		t.Fatalf("expected duplicate key conflict, got %v", err)
	}
}

func TestContentReferenceDirectoryValidatesRegionHierarchy(t *testing.T) {
	s := contentReferenceTestService(t)
	region, other := models.Region{Name: "Central"}, models.Region{Name: "Western"}
	if err := s.DB.Create(&region).Error; err != nil {
		t.Fatal(err)
	}
	if err := s.DB.Create(&other).Error; err != nil {
		t.Fatal(err)
	}
	district := models.District{Name: "Kampala", RegionID: region.ID, HealthSubRegionID: uuid.New()}
	if err := s.DB.Create(&district).Error; err != nil {
		t.Fatal(err)
	}
	districtID, otherID := district.ID.String(), other.ID.String()
	name, title, ministry, phone, status := "Desk", "Officer", "Health", "+256", "active"
	_, err := s.SaveDirectory(nil, MinistryDirectoryInput{DistrictID: &districtID, RegionID: &otherID, Name: &name, Title: &title, Ministry: &ministry, Phone: &phone, Status: &status})
	if !errors.Is(err, ErrContentReferenceInvalid) {
		t.Fatalf("expected hierarchy validation, got %v", err)
	}
}

func TestContentReferenceLanguageDefaultIsExclusive(t *testing.T) {
	s := contentReferenceTestService(t)
	active, def := true, true
	status := "complete"
	code, name, native := "en", "English", "English"
	first, err := s.SaveLanguage(nil, LanguageInput{Code: &code, Name: &name, NativeName: &native, IsActive: &active, IsDefault: &def, Status: &status})
	if err != nil {
		t.Fatal(err)
	}
	code, name, native = "lg", "Luganda", "Luganda"
	second, err := s.SaveLanguage(nil, LanguageInput{Code: &code, Name: &name, NativeName: &native, IsActive: &active, IsDefault: &def, Status: &status})
	if err != nil {
		t.Fatal(err)
	}
	var stored models.Language
	if err := s.DB.First(&stored, "id=?", first.ID).Error; err != nil {
		t.Fatal(err)
	}
	if stored.IsDefault || !second.IsDefault {
		t.Fatal("expected only the newest default language to remain default")
	}
	if err := s.DeleteLanguage(second.ID); !errors.Is(err, ErrDefaultLanguage) {
		t.Fatalf("expected default deletion safeguard, got %v", err)
	}
}
