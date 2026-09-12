package services

import (
	"context"
	"errors"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func contentHubTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db := classificationTestDB(t)
	if err := db.AutoMigrate(
		&models.ContentHub{},
		&models.ContentHubDisease{},
		&models.ContentPillar{},
		&models.ContentPillarItem{},
		&models.ContentHubTemplate{},
		&models.ContentHubTemplatePillar{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}

func TestContentHubSupportsNeutralAndMultipleDiseaseHubs(t *testing.T) {
	db := contentHubTestDB(t)
	malaria := models.Disease{Name: "Malaria", Slug: "malaria", NormalizedName: "malaria", Status: models.DiseaseStatusActive}
	ebola := models.Disease{Name: "Ebola virus disease", Slug: "ebola", NormalizedName: "ebola virus disease", Status: models.DiseaseStatusActive}
	archived := models.Disease{Name: "Old condition", Slug: "old-condition", NormalizedName: "old condition", Status: models.DiseaseStatusArchived}
	for _, disease := range []*models.Disease{&malaria, &ebola, &archived} {
		if err := db.Create(disease).Error; err != nil {
			t.Fatal(err)
		}
	}
	service := ContentHubService{DB: db}
	neutral, err := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "General clinical knowledge", Slug: "general-clinical-knowledge"})
	if err != nil || len(neutral.Diseases) != 0 {
		t.Fatalf("neutral hub failed: hub=%#v err=%v", neutral, err)
	}
	multi, err := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Febrile illness", Slug: "febrile-illness", DiseaseIDs: []uuid.UUID{malaria.ID, ebola.ID}})
	if err != nil || len(multi.Diseases) != 2 {
		t.Fatalf("multi-disease hub failed: hub=%#v err=%v", multi, err)
	}
	secondMalariaHub, err := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Malaria training", Slug: "malaria-training", DiseaseIDs: []uuid.UUID{malaria.ID}})
	if err != nil {
		t.Fatalf("a disease should support multiple hubs: %v", err)
	}
	page, err := service.ListHubs(ContentHubQuery{Page: PageInput{Page: 1, PerPage: 20}, DiseaseID: malaria.ID.String()})
	if err != nil || len(page.Items) != 2 || page.Items[0].ID != multi.ID || page.Items[1].ID != secondMalariaHub.ID {
		t.Fatalf("disease filtering failed: page=%#v err=%v", page, err)
	}
	if _, err := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Invalid", Slug: "invalid", DiseaseIDs: []uuid.UUID{archived.ID}}); !errors.Is(err, ErrContentDiseaseUnavailable) {
		t.Fatalf("archived disease should be rejected, got %v", err)
	}
}

func TestContentPillarHierarchyRejectsCyclesAndCrossHubParents(t *testing.T) {
	service := ContentHubService{DB: contentHubTestDB(t)}
	first, _ := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "First hub", Slug: "first-hub"})
	second, _ := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Second hub", Slug: "second-hub"})
	parent, err := service.CreatePillar(ContentHubActor{}, first.ID, ContentPillarInput{Name: "Clinical care", Slug: "clinical-care"})
	if err != nil {
		t.Fatal(err)
	}
	child, err := service.CreatePillar(ContentHubActor{}, first.ID, ContentPillarInput{Name: "Diagnosis", Slug: "diagnosis", ParentID: &parent.ID})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.UpdatePillar(ContentHubActor{}, first.ID, parent.ID, ContentPillarInput{Name: parent.Name, Slug: parent.Slug, ParentID: &child.ID, LockVersion: parent.LockVersion}); !errors.Is(err, ErrContentPillarCycle) {
		t.Fatalf("cycle should be rejected, got %v", err)
	}
	if _, err := service.CreatePillar(ContentHubActor{}, second.ID, ContentPillarInput{Name: "Wrong parent", Slug: "wrong-parent", ParentID: &parent.ID}); !errors.Is(err, ErrContentPillarWrongHub) {
		t.Fatalf("cross-hub parent should be rejected, got %v", err)
	}
}

func TestHubTemplateIsCopiedOnceAndRemainsEditable(t *testing.T) {
	db := contentHubTestDB(t)
	template := models.ContentHubTemplate{Name: "Disease care", Slug: "disease-care", Status: models.ContentHubStatusActive}
	if err := db.Create(&template).Error; err != nil {
		t.Fatal(err)
	}
	definitions := []models.ContentHubTemplatePillar{
		{TemplateID: template.ID, Name: "Overview", Slug: "overview", SortOrder: 10},
		{TemplateID: template.ID, Name: "Diagnosis", Slug: "diagnosis", SortOrder: 20},
		{TemplateID: template.ID, Name: "Clinical Management", Slug: "clinical-management", SortOrder: 30},
		{TemplateID: template.ID, Name: "Medicines", Slug: "medicines", SortOrder: 40},
		{TemplateID: template.ID, Name: "Algorithms", Slug: "algorithms", SortOrder: 50},
		{TemplateID: template.ID, Name: "Prevention", Slug: "prevention", SortOrder: 60},
		{TemplateID: template.ID, Name: "Patient Education", Slug: "patient-education", SortOrder: 70},
		{TemplateID: template.ID, Name: "Training", Slug: "training", SortOrder: 80},
		{TemplateID: template.ID, Name: "References", Slug: "references", SortOrder: 90},
	}
	if err := db.Create(&definitions).Error; err != nil {
		t.Fatal(err)
	}
	service := ContentHubService{DB: db}
	hub, _ := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Diabetes care", Slug: "diabetes-care"})
	pillars, err := service.ApplyTemplate(ContentHubActor{}, hub.ID, ApplyContentHubTemplateInput{TemplateID: template.ID, LockVersion: hub.LockVersion})
	if err != nil || len(pillars) != 9 || pillars[0].Slug != "overview" || pillars[8].Slug != "references" {
		t.Fatalf("template copy failed: pillars=%#v err=%v", pillars, err)
	}
	updated, err := service.UpdatePillar(ContentHubActor{}, hub.ID, pillars[0].ID, ContentPillarInput{Name: "At a glance", Slug: "at-a-glance", SortOrder: 5, LockVersion: pillars[0].LockVersion})
	if err != nil || updated.Name != "At a glance" {
		t.Fatalf("copied pillar was not editable: %#v %v", updated, err)
	}
	reloaded, _ := service.GetHub(hub.ID)
	if _, err := service.ApplyTemplate(ContentHubActor{}, hub.ID, ApplyContentHubTemplateInput{TemplateID: template.ID, LockVersion: reloaded.LockVersion}); !errors.Is(err, ErrContentHubNotEmpty) {
		t.Fatalf("second template application should be rejected, got %v", err)
	}
	storedTemplate, _ := service.GetTemplate(template.ID)
	if storedTemplate.Pillars[0].Name != "Overview" {
		t.Fatal("editing a copied pillar mutated the template")
	}
}

func TestContentHubPublicEligibilityAndNonDestructiveItemRemoval(t *testing.T) {
	db := contentHubTestDB(t)
	service := ContentHubService{DB: db, AllowedExternalHosts: []string{"who.int"}}
	publishedDocument := models.GuidelineDocument{Title: "Approved guidance"}
	draftDocument := models.GuidelineDocument{Title: "Draft guidance"}
	for _, document := range []*models.GuidelineDocument{&publishedDocument, &draftDocument} {
		if err := db.Create(document).Error; err != nil {
			t.Fatal(err)
		}
	}
	version := models.GuidelineVersion{DocumentID: publishedDocument.ID, Version: "1", Status: "published"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&publishedDocument).Update("current_version_id", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	hub, _ := service.CreateHub(ContentHubActor{}, CreateContentHubInput{Name: "Care hub", Slug: "care-hub"})
	pillar, _ := service.CreatePillar(ContentHubActor{}, hub.ID, ContentPillarInput{Name: "Guidelines", Slug: "guidelines"})
	publishedItem, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentDiseaseGuideline, ContentID: &publishedDocument.ID, Status: models.ContentPillarItemStatusActive})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentDiseaseGuideline, ContentID: &publishedDocument.ID, Status: models.ContentPillarItemStatusActive}); !errors.Is(err, ErrContentHubDuplicate) {
		t.Fatalf("duplicate pillar item should be rejected, got %v", err)
	}
	if _, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentDiseaseGuideline, ContentID: &draftDocument.ID, SortOrder: 20, Status: models.ContentPillarItemStatusActive}); err != nil {
		t.Fatal(err)
	}
	past := time.Now().UTC().Add(-time.Hour)
	if _, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentPillarItemApprovedExternalURL, Target: "https://who.int/resource", EndsAt: &past, SortOrder: 30, Status: models.ContentPillarItemStatusActive}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentPillarItemApprovedExternalURL, Target: "https://evil.example/resource", Status: models.ContentPillarItemStatusActive}); !errors.Is(err, ErrContentPillarUnsafeTarget) {
		t.Fatalf("non-allowlisted URL should be rejected, got %v", err)
	}
	if _, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentPillarItemInternalRoute, Target: "/public/guidelines/" + publishedDocument.ID.String(), SortOrder: 40, Status: models.ContentPillarItemStatusActive}); err != nil {
		t.Fatalf("approved internal route failed: %v", err)
	}
	draftItem, err := service.CreatePillarItem(ContentHubActor{}, hub.ID, pillar.ID, ContentPillarItemInput{ContentType: models.ContentPillarItemApprovedExternalURL, Target: "https://who.int/draft", SortOrder: 50})
	if err != nil || draftItem.Status != models.ContentPillarItemStatusDraft {
		t.Fatalf("new pillar items must default to draft: item=%#v err=%v", draftItem, err)
	}
	if _, err := service.GetPublicHub(context.Background(), hub.Slug); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("draft hub leaked publicly: %v", err)
	}
	hub, err = service.TransitionHub(ContentHubActor{}, hub.ID, "publish", ContentHubTransitionInput{LockVersion: hub.LockVersion})
	if err != nil {
		t.Fatal(err)
	}
	publicHub, err := service.GetPublicHub(context.Background(), hub.Slug)
	if err != nil {
		t.Fatal(err)
	}
	if len(publicHub.Pillars) != 1 || len(publicHub.Pillars[0].Items) != 2 {
		t.Fatalf("public hub should keep eligible resource and route, skipping draft/expired items: %#v", publicHub.Pillars)
	}
	if err := service.DeletePillarItem(ContentHubActor{}, hub.ID, pillar.ID, publishedItem.ID, publishedItem.LockVersion); err != nil {
		t.Fatal(err)
	}
	var sourceCount int64
	if err := db.Model(&models.GuidelineDocument{}).Where("id = ?", publishedDocument.ID).Count(&sourceCount).Error; err != nil || sourceCount != 1 {
		t.Fatalf("removing a pillar assignment deleted the source: count=%d err=%v", sourceCount, err)
	}
}
