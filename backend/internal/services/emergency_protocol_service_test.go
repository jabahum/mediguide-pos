package services

import (
	"encoding/json"
	"errors"
	"testing"

	"mediguide/internal/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func emergencyProtocolTestService(t *testing.T) EmergencyProtocolService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.EmergencyProtocol{}); err != nil {
		t.Fatal(err)
	}
	return EmergencyProtocolService{DB: db}
}
func TestEmergencyProtocolReaderVisibility(t *testing.T) {
	s := emergencyProtocolTestService(t)
	active, draft := "active", "draft"
	category, title, priority := "Trauma", "Primary survey", "high"
	if _, err := s.Save(nil, EmergencyProtocolInput{Title: &title, Category: &category, Priority: &priority, Status: &active}); err != nil {
		t.Fatal(err)
	}
	draftTitle := "Internal"
	if _, err := s.Save(nil, EmergencyProtocolInput{Title: &draftTitle, Category: &category, Priority: &priority, Status: &draft}); err != nil {
		t.Fatal(err)
	}
	page, err := s.List(false, EmergencyProtocolQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || page.TotalItems != 1 || page.Items[0].Title != title {
		t.Fatalf("reader visibility: %#v err=%v", page, err)
	}
}
func TestEmergencyProtocolValidatesStructuredPayload(t *testing.T) {
	s := emergencyProtocolTestService(t)
	title, category := "Triage", "Unknown"
	if _, err := s.Save(nil, EmergencyProtocolInput{Title: &title, Category: &category}); !errors.Is(err, ErrEmergencyProtocolInvalid) {
		t.Fatalf("expected category validation, got %v", err)
	}
	validCategory := "Trauma"
	invalid := json.RawMessage(`{"broken"`)
	if _, err := s.Save(nil, EmergencyProtocolInput{Title: &title, Category: &validCategory, Steps: &invalid}); !errors.Is(err, ErrEmergencyProtocolInvalid) {
		t.Fatalf("expected JSON validation, got %v", err)
	}
}
