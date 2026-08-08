package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func progressUsageTestService(t *testing.T) ProgressUsageService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.MedicalGuideline{}, &models.ReadingProgress{}, &models.GuidelineUsageLog{}, &models.AbbreviationUsageLog{}, &models.ConsultantUsageLog{}, &models.AIUsageLog{}); err != nil {
		t.Fatal(err)
	}
	return ProgressUsageService{DB: db}
}

func createProgressTestGuideline(t *testing.T, s ProgressUsageService) uuid.UUID {
	t.Helper()
	guideline := models.MedicalGuideline{ConditionName: "Test guideline", Status: "published", IsPublished: true}
	if err := s.DB.Create(&guideline).Error; err != nil {
		t.Fatal(err)
	}
	return guideline.ID
}

func TestProgressUsageOwnershipAndValidation(t *testing.T) {
	s := progressUsageTestService(t)
	owner, other := uuid.New(), uuid.New()
	guideline := createProgressTestGuideline(t, s)
	progress := 0.5
	if _, err := s.UpsertProgress(owner, guideline, ReadingProgressInput{ProgressPercentage: &progress}); err != nil {
		t.Fatal(err)
	}
	owned, err := s.ListProgress(owner, ReadingProgressQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || owned.TotalItems != 1 {
		t.Fatalf("owned progress: %#v %v", owned, err)
	}
	notOwned, err := s.ListProgress(other, ReadingProgressQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || notOwned.TotalItems != 0 {
		t.Fatalf("other user's progress leaked: %#v %v", notOwned, err)
	}
	invalid := 1.2
	if _, err := s.UpsertProgress(owner, guideline, ReadingProgressInput{ProgressPercentage: &invalid}); !errors.Is(err, ErrProgressUsageInvalid) {
		t.Fatalf("expected invalid progress, got %v", err)
	}
}

func TestProgressUsageEventsAreIdempotentAndServerOwned(t *testing.T) {
	s := progressUsageTestService(t)
	owner, resource := uuid.New(), createProgressTestGuideline(t, s).String()
	in := UsageEventInput{ResourceID: &resource, IdempotencyKey: "retry-1"}
	if _, err := s.RecordUsage(owner, "guideline", in); err != nil {
		t.Fatal(err)
	}
	if _, err := s.RecordUsage(owner, "guideline", in); err != nil {
		t.Fatal(err)
	}
	var count int64
	if err := s.DB.Model(&models.GuidelineUsageLog{}).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("expected one idempotent event, got %d", count)
	}
	var row models.GuidelineUsageLog
	if err := s.DB.First(&row).Error; err != nil {
		t.Fatal(err)
	}
	if row.UserID != owner {
		t.Fatalf("owner must come from claims, got %s", row.UserID)
	}
}

func TestProgressUsageRejectsUnknownMedicalGuideline(t *testing.T) {
	s := progressUsageTestService(t)
	owner, missing := uuid.New(), uuid.New()
	progress := 0.5
	if _, err := s.UpsertProgress(owner, missing, ReadingProgressInput{ProgressPercentage: &progress}); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected missing guideline for progress, got %v", err)
	}
	resource := missing.String()
	if _, err := s.RecordUsage(owner, "guideline", UsageEventInput{ResourceID: &resource, IdempotencyKey: "missing-guideline"}); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected missing guideline for usage, got %v", err)
	}
}
