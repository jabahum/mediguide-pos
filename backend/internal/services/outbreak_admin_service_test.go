package services

import (
	"errors"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func outbreakAdminTestService(t *testing.T) OutbreakAdminService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.AuditLog{}, &models.Region{}, &models.HealthSubRegion{}, &models.District{}, &models.Outbreak{}, &models.OutbreakUpdate{}, &models.OutbreakResource{}, &models.SituationReport{}, &models.SituationReportAsset{}); err != nil {
		t.Fatal(err)
	}
	return OutbreakAdminService{DB: db}
}

func TestOutbreakTypedMetricsRejectDuplicatesAndInvalidFreshness(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC().Add(-time.Hour)
	metric := OutbreakMetric{Key: "confirmed_cases", Label: "Confirmed cases", Value: "20", NumericValue: ptr(20.0), Unit: "cases", AsOf: now, SourceReference: "WHO report 11", SortOrder: 1}
	input := validOutbreakDraftInput(now)
	input.Metrics = &[]OutbreakMetric{metric, metric}
	if _, err := service.CreateOutbreak(OutbreakActor{ID: uuid.New()}, input); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("duplicate metric key accepted: %v", err)
	}
	input.Metrics = &[]OutbreakMetric{metric}
	input.LastVerifiedAt = ptr(now.Add(-time.Hour))
	input.DataAsOf = &now
	if _, err := service.CreateOutbreak(OutbreakActor{ID: uuid.New()}, input); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("verification older than data accepted: %v", err)
	}
}

func TestOutbreakGeographyAndResourceSafetyValidation(t *testing.T) {
	service := outbreakAdminTestService(t)
	regionOne := models.Region{Name: "Central"}
	regionTwo := models.Region{Name: "Northern"}
	if err := service.DB.Create(&regionOne).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&regionTwo).Error; err != nil {
		t.Fatal(err)
	}
	district := models.District{Name: "Kampala", RegionID: regionOne.ID, HealthSubRegionID: uuid.New()}
	if err := service.DB.Create(&district).Error; err != nil {
		t.Fatal(err)
	}
	input := validOutbreakDraftInput(time.Now().UTC().Add(-time.Hour))
	input.RegionID = &regionTwo.ID
	input.DistrictID = &district.ID
	if _, err := service.CreateOutbreak(OutbreakActor{ID: uuid.New()}, input); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("cross-region district accepted: %v", err)
	}

	parent := models.Outbreak{Title: "Response", DiseaseType: "Ebola", Status: "draft", LastUpdate: time.Now(), VisualTone: "warning"}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	title, kind, hostile := "Unsafe resource", "approved_external_url", "javascript:alert(1)"
	if _, err := service.CreateResource(OutbreakActor{ID: uuid.New()}, parent.ID, ChildContentInput{Title: &title, ResourceType: &kind, URL: &hostile}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("hostile resource URL accepted: %v", err)
	}
}

func TestSituationReportHighlightsAreBoundedAndUnique(t *testing.T) {
	service := outbreakAdminTestService(t)
	title := "Weekly report"
	highlights := []string{"New cases investigated", " new cases investigated "}
	if _, err := service.CreateReport(OutbreakActor{ID: uuid.New()}, SituationReportInput{Title: &title, StandaloneAllowed: ptr(true), KeyHighlights: &highlights}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("duplicate highlight accepted: %v", err)
	}
}

func ptr[T any](value T) *T { return &value }

func validOutbreakDraftInput(now time.Time) OutbreakInput {
	metrics := []OutbreakMetric{}
	return OutbreakInput{Title: ptr("Ebola response"), DiseaseType: ptr("Ebola"), GeographicArea: ptr("Uganda"), Summary: ptr("Public health response"), LastUpdate: &now, VisualTone: ptr("critical"), SourceOrganization: ptr("Ministry of Health"), SourceReference: ptr("MOH-2026-01"), EffectiveAt: &now, DataAsOf: &now, LastVerifiedAt: &now, Metrics: &metrics}
}

func TestOutbreakLifecycleRequiresIndependentReviewerAndOptimisticLock(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC()
	author := OutbreakActor{ID: uuid.New(), IP: "127.0.0.1"}
	reviewer := OutbreakActor{ID: uuid.New(), IP: "127.0.0.2"}
	item, err := service.CreateOutbreak(author, validOutbreakDraftInput(now))
	if err != nil || item.Status != "draft" || item.LockVersion != 1 {
		t.Fatalf("create: %#v %v", item, err)
	}
	if _, err = service.TransitionOutbreak(author, item.ID, "submit", TransitionInput{LockVersion: 1}); err != nil {
		t.Fatal(err)
	}
	if _, err = service.TransitionOutbreak(author, item.ID, "approve", TransitionInput{LockVersion: 2}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("self approval allowed: %v", err)
	}
	approved, err := service.TransitionOutbreak(reviewer, item.ID, "approve", TransitionInput{LockVersion: 2})
	if err != nil || approved.ApprovedBy == nil || *approved.ApprovedBy != reviewer.ID {
		t.Fatalf("approve: %#v %v", approved, err)
	}
	if _, err = service.TransitionOutbreak(reviewer, item.ID, "publish", TransitionInput{LockVersion: 2}); !errors.Is(err, ErrOutbreakConflict) {
		t.Fatalf("stale lock accepted: %v", err)
	}
	published, err := service.TransitionOutbreak(reviewer, item.ID, "publish", TransitionInput{LockVersion: 3, OperationalStatus: "active"})
	if err != nil || published.Status != "active" || published.PublishedAt == nil {
		t.Fatalf("publish: %#v %v", published, err)
	}
	if _, err = service.UpdateOutbreak(author, item.ID, OutbreakInput{Title: ptr("silent edit"), LockVersion: &published.LockVersion}); !errors.Is(err, ErrOutbreakImmutable) {
		t.Fatalf("published edit allowed: %v", err)
	}
	corrected, err := service.CorrectOutbreak(author, item.ID, TransitionInput{LockVersion: published.LockVersion, Reason: "Correct case definition"})
	if err != nil || corrected.Status != "draft" || corrected.SupersedesID == nil || *corrected.SupersedesID != item.ID {
		t.Fatalf("correction: %#v %v", corrected, err)
	}
	var auditCount int64
	if err := service.DB.Model(&models.AuditLog{}).Where("entity_type = ?", "outbreak").Count(&auditCount).Error; err != nil || auditCount < 5 {
		t.Fatalf("audit count=%d err=%v", auditCount, err)
	}
}

func TestOutbreakChildrenRequireOwnPublication(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC()
	parent := models.Outbreak{Title: "Published parent", Status: "active", PublishedAt: &now, LastUpdate: now, LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	draft := models.OutbreakUpdate{OutbreakID: parent.ID, Title: "Draft child", Status: "draft", LockVersion: 1}
	published := models.OutbreakUpdate{OutbreakID: parent.ID, Title: "Published child", Status: "published", PublishedAt: &now, LockVersion: 1}
	if err := service.DB.Create(&draft).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&published).Error; err != nil {
		t.Fatal(err)
	}
	page, err := (OutbreakService{DB: service.DB}).Updates(parent.ID, PageInput{})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != published.ID {
		t.Fatalf("public children: %#v %v", page, err)
	}
}

func TestSituationReportPublicationValidatesStandaloneAndSource(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC()
	author := OutbreakActor{ID: uuid.New()}
	if _, err := service.CreateReport(author, SituationReportInput{Title: ptr("Unscoped")}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("unapproved standalone report accepted: %v", err)
	}
	report, err := service.CreateReport(author, SituationReportInput{Title: ptr("Standalone"), StandaloneAllowed: ptr(true), PublicationDate: &now})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.TransitionReport(author, report.ID, "submit", TransitionInput{LockVersion: 1}); err != nil {
		t.Fatal(err)
	}
	reviewer := OutbreakActor{ID: uuid.New()}
	if _, err = service.TransitionReport(reviewer, report.ID, "approve", TransitionInput{LockVersion: 2}); err != nil {
		t.Fatal(err)
	}
	if _, err = service.TransitionReport(reviewer, report.ID, "publish", TransitionInput{LockVersion: 3}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("report without source/asset published: %v", err)
	}
}
