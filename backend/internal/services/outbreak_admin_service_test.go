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
	redirect := "https://health.go.ug/open?redirect=https://evil.example"
	if _, err := service.CreateResource(OutbreakActor{ID: uuid.New()}, parent.ID, ChildContentInput{Title: &title, ResourceType: &kind, URL: &redirect}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("redirect-style resource URL accepted: %v", err)
	}
	managed, rawStorageKey := "managed_document", "situation-reports/private/report.pdf"
	if _, err := service.CreateResource(OutbreakActor{ID: uuid.New()}, parent.ID, ChildContentInput{Title: &title, ResourceType: &managed, AssetURL: &rawStorageKey}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("raw managed storage key accepted: %v", err)
	}
}

func TestOutbreakAdministrationFiltersAreTypedAndApplied(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC()
	old := now.Add(-72 * time.Hour)
	region := models.Region{Name: "Central"}
	if err := service.DB.Create(&region).Error; err != nil {
		t.Fatal(err)
	}
	first := models.Outbreak{Base: models.Base{UpdatedAt: now}, Title: "Ebola response", DiseaseType: "Ebola", GeographicArea: "Kampala", RegionID: &region.ID, Status: "active", VisualTone: "critical", LastUpdate: now, EffectiveAt: &now, LockVersion: 1}
	second := models.Outbreak{Base: models.Base{UpdatedAt: old}, Title: "Malaria update", DiseaseType: "Malaria", GeographicArea: "Gulu", Status: "monitoring", VisualTone: "info", LastUpdate: old, EffectiveAt: &old, LockVersion: 1}
	if err := service.DB.Create(&first).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&second).Error; err != nil {
		t.Fatal(err)
	}
	page, err := service.ListOutbreaks(OutbreakAdminQuery{Page: PageInput{Page: 1, PerPage: 20}, Disease: "ebola", RegionID: region.ID.String(), VisualTone: "critical", UpdatedFrom: now.Add(-time.Hour).Format(time.RFC3339), Sort: "effective_at", Order: "desc"})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != first.ID {
		t.Fatalf("typed filters returned %#v err=%v", page, err)
	}
	if _, err := service.ListOutbreaks(OutbreakAdminQuery{UpdatedFrom: "yesterday"}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("malformed date accepted: %v", err)
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
	publisher := OutbreakActor{ID: uuid.New(), IP: "127.0.0.3"}
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
	if _, err = service.TransitionOutbreak(reviewer, item.ID, "publish", TransitionInput{LockVersion: 3, OperationalStatus: "active"}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("critical outbreak reviewer also published: %v", err)
	}
	published, err := service.TransitionOutbreak(publisher, item.ID, "publish", TransitionInput{LockVersion: 3, OperationalStatus: "active"})
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

func TestOutbreakReviewCommentIsValidatedAndAudited(t *testing.T) {
	service := outbreakAdminTestService(t)
	actor := OutbreakActor{ID: uuid.New()}
	item, err := service.CreateOutbreak(actor, validOutbreakDraftInput(time.Now().UTC()))
	if err != nil {
		t.Fatal(err)
	}
	if err := service.AddReviewComment(actor, "outbreak", item.ID, "  Confirm source date before publishing.  "); err != nil {
		t.Fatal(err)
	}
	if err := service.AddReviewComment(actor, "outbreak", item.ID, "  "); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("blank comment accepted: %v", err)
	}
	history, err := service.ListAudit("outbreak", item.ID, PageInput{})
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, event := range history.Items {
		if event.Action == "outbreak.review_comment" && event.Metadata["comment"] == "Confirm source date before publishing." {
			found = true
		}
	}
	if !found {
		t.Fatalf("review comment missing from audit history: %#v", history.Items)
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

func TestOutbreakDocumentLifecycleRequiresReviewAndPublishedParent(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC().Truncate(time.Second)
	parent := models.Outbreak{Title: "Ebola response", DiseaseType: "Ebola", Status: "active", PublishedAt: &now, LastUpdate: now, LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	author := OutbreakActor{ID: uuid.New()}
	reviewer := OutbreakActor{ID: uuid.New()}
	publisher := OutbreakActor{ID: uuid.New()}
	title, kind := "Ebola case-management SOP", "sop"
	number, version := "MOH-EVD-SOP-001", "2.0"
	authority, language := "Ministry of Health Uganda", "en-UG"
	effective, review := now.Add(-time.Hour), now.AddDate(1, 0, 0)
	assetURL := "https://health.go.ug/documents/ebola-sop-v2.pdf"
	document, err := service.CreateDocument(author, parent.ID, OutbreakDocumentInput{
		Title: &title, DocumentKind: &kind, DocumentNumber: &number, Version: &version,
		IssuingAuthority: &authority, Language: &language, EffectiveDate: &effective,
		ReviewDate: &review, AssetURL: &assetURL,
	})
	if err != nil || document.Status != "draft" || document.LockVersion != 1 {
		t.Fatalf("create document: %#v err=%v", document, err)
	}
	if _, err := service.TransitionDocument(author, parent.ID, document.ID, "submit", TransitionInput{LockVersion: 1}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionDocument(author, parent.ID, document.ID, "approve", TransitionInput{LockVersion: 2}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("author self-approved document: %v", err)
	}
	approved, err := service.TransitionDocument(reviewer, parent.ID, document.ID, "approve", TransitionInput{LockVersion: 2})
	if err != nil || approved.ApprovedBy == nil || *approved.ApprovedBy != reviewer.ID {
		t.Fatalf("approve document: %#v err=%v", approved, err)
	}
	published, err := service.TransitionDocument(publisher, parent.ID, document.ID, "publish", TransitionInput{LockVersion: 3})
	if err != nil || published.Status != "published" || published.PublishedAt == nil {
		t.Fatalf("publish document: %#v err=%v", published, err)
	}
	if _, err := service.UpdateDocument(author, parent.ID, document.ID, OutbreakDocumentInput{Title: ptr("silent edit"), LockVersion: &published.LockVersion}); !errors.Is(err, ErrOutbreakImmutable) {
		t.Fatalf("published document edited: %v", err)
	}

	correction, err := service.CorrectDocument(author, parent.ID, document.ID, TransitionInput{LockVersion: published.LockVersion, Reason: "Correct dosage table"})
	if err != nil || correction.Status != "draft" || correction.SupersedesID == nil || *correction.SupersedesID != document.ID {
		t.Fatalf("correct document: %#v err=%v", correction, err)
	}
	versions, err := service.DocumentVersions(parent.ID, document.ID)
	if err != nil || len(versions) != 2 {
		t.Fatalf("document versions: %#v err=%v", versions, err)
	}
	if _, err := service.TransitionDocument(author, parent.ID, correction.ID, "submit", TransitionInput{LockVersion: 1}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionDocument(reviewer, parent.ID, correction.ID, "approve", TransitionInput{LockVersion: 2}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionDocument(publisher, parent.ID, correction.ID, "publish", TransitionInput{LockVersion: 3}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("duplicate published document number/version accepted: %v", err)
	}
}

func TestOutbreakDocumentValidationAndTypedFilters(t *testing.T) {
	service := outbreakAdminTestService(t)
	now := time.Now().UTC()
	parent := models.Outbreak{Title: "Response", Status: "draft", LastUpdate: now, LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	title, invalidKind := "Invalid", "word_document"
	if _, err := service.CreateDocument(OutbreakActor{ID: uuid.New()}, parent.ID, OutbreakDocumentInput{Title: &title, DocumentKind: &invalidKind}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("invalid document kind accepted: %v", err)
	}
	effective, review := now, now.Add(-time.Hour)
	if _, err := service.CreateDocument(OutbreakActor{ID: uuid.New()}, parent.ID, OutbreakDocumentInput{Title: &title, EffectiveDate: &effective, ReviewDate: &review}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("invalid document dates accepted: %v", err)
	}

	sop, checklist := "sop", "checklist"
	authority, language := "Ministry of Health", "en"
	for index, input := range []OutbreakDocumentInput{
		{Title: ptr("Ebola triage SOP"), DocumentKind: &sop, IssuingAuthority: &authority, Language: &language},
		{Title: ptr("Contact tracing checklist"), DocumentKind: &checklist, IssuingAuthority: &authority, Language: &language},
	} {
		if _, err := service.CreateDocument(OutbreakActor{ID: uuid.New()}, parent.ID, input); err != nil {
			t.Fatalf("create document %d: %v", index, err)
		}
	}
	page, err := service.ListDocuments(parent.ID, OutbreakDocumentQuery{Page: PageInput{Page: 1, PerPage: 1}, Search: "triage", DocumentKind: "sop", Authority: "ministry of health", Language: "EN", Sort: "title", Order: "asc"})
	if err != nil || page.TotalItems != 1 || len(page.Items) != 1 || page.Items[0].Title != "Ebola triage SOP" {
		t.Fatalf("typed document filters: %#v err=%v", page, err)
	}
	if _, err := service.ListDocuments(parent.ID, OutbreakDocumentQuery{Sort: "title; DROP TABLE outbreak_resources"}); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("unsafe sort accepted: %v", err)
	}
}
