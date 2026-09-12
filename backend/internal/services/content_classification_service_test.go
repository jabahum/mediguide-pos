package services

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func classificationTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(fmt.Sprintf("file:%s?mode=memory&cache=shared", uuid.New())), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(
		&models.GuidelineCategory{}, &models.GuidelineDocument{}, &models.GuidelineVersion{},
		&models.Disease{}, &models.ContentDiseaseAssignment{}, &models.GuidelineContentBlock{},
		&models.Outbreak{}, &models.OutbreakResource{}, &models.SituationReport{},
		&models.Calculator{}, &models.CalculatorVersion{}, &models.Drug{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}

func TestGuidelineCategoryAssignmentsCreateFilterUpdateAndPreserveProgramArea(t *testing.T) {
	db := classificationTestDB(t)
	active := models.GuidelineCategory{Name: "Communicable diseases", Status: "active"}
	second := models.GuidelineCategory{Name: "Emergency care", Status: "active"}
	inactive := models.GuidelineCategory{Name: "Retired", Status: "inactive"}
	for _, category := range []*models.GuidelineCategory{&active, &second, &inactive} {
		if err := db.Create(category).Error; err != nil {
			t.Fatal(err)
		}
	}
	service := GuidelineService{DB: db}
	document, err := service.CreateDocument(CreateGuidelineInput{Title: "Malaria", ProgramArea: "Legacy malaria", CategoryIDs: []uuid.UUID{active.ID, second.ID}})
	if err != nil {
		t.Fatal(err)
	}
	if document.ProgramArea != "Legacy malaria" || len(document.Categories) != 2 {
		t.Fatalf("legacy field or categories were not preserved: %#v", document)
	}
	page, err := service.ListDocuments(GuidelineDocumentFilter{CategoryID: &active.ID, Page: PageInput{Page: 1, PerPage: 10}})
	if err != nil || len(page.Items) != 1 || page.Items[0].ID != document.ID {
		t.Fatalf("category filter failed: %#v, %v", page, err)
	}
	description := "kept categories"
	if _, err := service.UpdateDocument(document.ID, UpdateGuidelineInput{Description: &description}); err != nil {
		t.Fatal(err)
	}
	loaded, _ := service.GetDocument(document.ID)
	if len(loaded.Categories) != 2 || loaded.ProgramArea != "Legacy malaria" {
		t.Fatalf("omitted category_ids changed existing classification: %#v", loaded)
	}
	empty := []uuid.UUID{}
	if _, err := service.UpdateDocument(document.ID, UpdateGuidelineInput{CategoryIDs: &empty}); err != nil {
		t.Fatal(err)
	}
	loaded, _ = service.GetDocument(document.ID)
	if len(loaded.Categories) != 0 {
		t.Fatalf("explicit empty category list did not clear assignments: %#v", loaded.Categories)
	}
	if _, err := service.CreateDocument(CreateGuidelineInput{Title: "Invalid", CategoryIDs: []uuid.UUID{inactive.ID}}); !errors.Is(err, ErrGuidelineCategoryAssignment) {
		t.Fatalf("inactive category should be rejected, got %v", err)
	}
}

func TestContentDiseaseAssignmentsEnforceIdentityPrimaryAndNonDestructiveDelete(t *testing.T) {
	db := classificationTestDB(t)
	active := models.Disease{Name: "Malaria", Slug: "malaria", NormalizedName: "malaria", Status: models.DiseaseStatusActive}
	other := models.Disease{Name: "Severe malaria", Slug: "severe-malaria", NormalizedName: "severe malaria", Status: models.DiseaseStatusActive}
	inactive := models.Disease{Name: "Old", Slug: "old", NormalizedName: "old", Status: models.DiseaseStatusArchived}
	document := models.GuidelineDocument{Title: "Malaria in adults"}
	for _, item := range []any{&active, &other, &inactive, &document} {
		if err := db.Create(item).Error; err != nil {
			t.Fatal(err)
		}
	}
	service := ContentDiseaseService{DB: db}
	created, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: active.ID, ContentType: " GUIDELINE ", ContentID: document.ID, Primary: true})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: active.ID, ContentType: "guideline", ContentID: document.ID}); !errors.Is(err, ErrContentDiseaseDuplicate) {
		t.Fatalf("duplicate should be rejected, got %v", err)
	}
	if _, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: other.ID, ContentType: "guideline", ContentID: document.ID, Primary: true}); !errors.Is(err, ErrContentDiseasePrimaryConflict) {
		t.Fatalf("second primary should be rejected, got %v", err)
	}
	if _, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: inactive.ID, ContentType: "guideline", ContentID: document.ID}); !errors.Is(err, ErrContentDiseaseUnavailable) {
		t.Fatalf("archived disease should be rejected, got %v", err)
	}
	if _, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: active.ID, ContentType: "patient", ContentID: document.ID}); !errors.Is(err, ErrContentDiseaseUnsupported) {
		t.Fatalf("unsupported type should be rejected, got %v", err)
	}
	if err := service.Delete(ContentDiseaseActor{}, created.ID); err != nil {
		t.Fatal(err)
	}
	var sourceCount int64
	if err := db.Model(&models.GuidelineDocument{}).Where("id = ?", document.ID).Count(&sourceCount).Error; err != nil || sourceCount != 1 {
		t.Fatalf("removing assignment deleted source: count=%d err=%v", sourceCount, err)
	}
}

func TestDiseaseAssignmentDoesNotPublishDraftGuideline(t *testing.T) {
	db := classificationTestDB(t)
	disease := models.Disease{Name: "Diabetes", Slug: "diabetes", NormalizedName: "diabetes", Status: models.DiseaseStatusActive}
	document := models.GuidelineDocument{Title: "Diabetes"}
	if err := db.Create(&disease).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	service := ContentDiseaseService{DB: db}
	assignment, err := service.Create(ContentDiseaseActor{}, ContentDiseaseInput{DiseaseID: disease.ID, ContentType: "guideline", ContentID: document.ID})
	if err != nil {
		t.Fatal(err)
	}
	eligible, err := service.PubliclyEligible(*assignment, time.Now())
	if err != nil || eligible {
		t.Fatalf("draft resource leaked through classification: eligible=%v err=%v", eligible, err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "published"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&document).Update("current_version_id", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	eligible, err = service.PubliclyEligible(*assignment, time.Now())
	if err != nil || !eligible {
		t.Fatalf("current published guideline should be eligible: eligible=%v err=%v", eligible, err)
	}
}

func TestPublicGuidelineCategoryAndDiseaseFiltersNeverExposeDrafts(t *testing.T) {
	db := classificationTestDB(t)
	category := models.GuidelineCategory{Name: "Communicable diseases", Status: "active"}
	disabled := models.GuidelineCategory{Name: "Hidden", Status: "inactive"}
	disease := models.Disease{Name: "Malaria", Slug: "malaria", NormalizedName: "malaria", Status: models.DiseaseStatusActive}
	for _, item := range []any{&category, &disabled, &disease} {
		if err := db.Create(item).Error; err != nil {
			t.Fatal(err)
		}
	}
	published := models.GuidelineDocument{Title: "Published malaria", ProgramArea: "Legacy area"}
	draft := models.GuidelineDocument{Title: "Draft malaria"}
	if err := db.Create(&published).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&draft).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&published).Association("Categories").Append(&category, &disabled); err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&draft).Association("Categories").Append(&category); err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: published.ID, Version: "1", Status: "published"}
	draftVersion := models.GuidelineVersion{DocumentID: draft.ID, Version: "1", Status: "draft"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&draftVersion).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&published).Update("current_version_id", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&draft).Update("current_version_id", draftVersion.ID).Error; err != nil {
		t.Fatal(err)
	}
	assignments := []models.ContentDiseaseAssignment{
		{DiseaseID: disease.ID, ContentType: models.ContentDiseaseGuideline, ContentID: published.ID},
		{DiseaseID: disease.ID, ContentType: models.ContentDiseaseGuideline, ContentID: draft.ID},
	}
	if err := db.Create(&assignments).Error; err != nil {
		t.Fatal(err)
	}
	result, err := (PublicGuidelineService{DB: db}).List(context.Background(), PublicGuidelineFilter{CategoryID: category.ID.String(), DiseaseID: disease.ID.String(), Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Items) != 1 || result.Items[0].ID != published.ID {
		t.Fatalf("public filters leaked a draft or missed publication: %#v", result.Items)
	}
	if len(result.Items[0].Categories) != 1 || result.Items[0].Categories[0].ID != category.ID {
		t.Fatalf("disabled category leaked into public payload: %#v", result.Items[0].Categories)
	}
}

func TestDiseaseContentValidatorSupportsOnlyTheDeclaredResourceKinds(t *testing.T) {
	db := classificationTestDB(t)
	guideline := models.GuidelineDocument{Title: "Guideline"}
	outbreak := models.Outbreak{Title: "Outbreak"}
	document := models.OutbreakResource{ResourceType: "managed_document", DocumentKind: "guideline"}
	form := models.OutbreakResource{ResourceType: "downloadable_asset", DocumentKind: "form"}
	ordinaryLink := models.OutbreakResource{ResourceType: "approved_external_url", DocumentKind: "guideline"}
	report := models.SituationReport{Title: "Report"}
	algorithm := models.GuidelineContentBlock{Type: models.GuidelineBlockAlgorithm, ContentJSON: []byte(`{}`), SourceFingerprint: "algorithm"}
	calculator := models.Calculator{Name: "Tool", AddedByUserID: uuid.New(), AppFileJSON: datatypes.JSON(`{}`), Version: "1", Type: "clinical"}
	drug := models.Drug{Name: "Drug"}
	for _, item := range []any{&guideline, &outbreak, &document, &form, &ordinaryLink, &report, &algorithm, &calculator, &drug} {
		if err := db.Create(item).Error; err != nil {
			t.Fatal(err)
		}
	}
	valid := map[string]uuid.UUID{
		models.ContentDiseaseGuideline:        guideline.ID,
		models.ContentDiseaseOutbreak:         outbreak.ID,
		models.ContentDiseaseOutbreakDocument: document.ID,
		models.ContentDiseaseSituationReport:  report.ID,
		models.ContentDiseaseAlgorithm:        algorithm.ID,
		models.ContentDiseaseClinicalTool:     calculator.ID,
		models.ContentDiseaseForm:             form.ID,
		models.ContentDiseaseDrugReference:    drug.ID,
	}
	for kind, id := range valid {
		if err := validateDiseaseContentResource(db, kind, id); err != nil {
			t.Errorf("%s should be supported: %v", kind, err)
		}
	}
	if err := validateDiseaseContentResource(db, models.ContentDiseaseForm, document.ID); !errors.Is(err, ErrContentDiseaseResourceNotFound) {
		t.Fatalf("non-form resource accepted as form: %v", err)
	}
	if err := validateDiseaseContentResource(db, models.ContentDiseaseAlgorithm, guideline.ID); !errors.Is(err, ErrContentDiseaseResourceNotFound) {
		t.Fatalf("non-algorithm resource accepted as algorithm: %v", err)
	}
	if err := validateDiseaseContentResource(db, models.ContentDiseaseOutbreakDocument, ordinaryLink.ID); !errors.Is(err, ErrContentDiseaseResourceNotFound) {
		t.Fatalf("ordinary outbreak link accepted as an outbreak document: %v", err)
	}
}

func TestDiseaseAssignmentsDoNotExposeFutureEffectiveResources(t *testing.T) {
	db := classificationTestDB(t)
	now := time.Now().UTC()
	future := now.Add(time.Hour)
	outbreak := models.Outbreak{Title: "Future outbreak", Status: "published", PublishedAt: &now, EffectiveAt: &future}
	if err := db.Create(&outbreak).Error; err != nil {
		t.Fatal(err)
	}
	service := ContentDiseaseService{DB: db}
	eligible, err := service.PubliclyEligible(models.ContentDiseaseAssignment{ContentType: models.ContentDiseaseOutbreak, ContentID: outbreak.ID}, now)
	if err != nil || eligible {
		t.Fatalf("future-effective outbreak leaked publicly: eligible=%v err=%v", eligible, err)
	}
	outbreak.EffectiveAt = &now
	if err := db.Save(&outbreak).Error; err != nil {
		t.Fatal(err)
	}
	eligible, err = service.PubliclyEligible(models.ContentDiseaseAssignment{ContentType: models.ContentDiseaseOutbreak, ContentID: outbreak.ID}, now)
	if err != nil || !eligible {
		t.Fatalf("effective published outbreak should be eligible: eligible=%v err=%v", eligible, err)
	}
}
