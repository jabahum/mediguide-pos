package main

import (
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	demoEbolaDiseaseID        = uuid.MustParse("90000000-0000-4000-8000-000000000001")
	demoMalariaDiseaseID      = uuid.MustParse("90000000-0000-4000-8000-000000000002")
	demoMarburgDiseaseID      = uuid.MustParse("90000000-0000-4000-8000-000000000004")
	demoHypertensionDiseaseID = uuid.MustParse("90000000-0000-4000-8000-000000000007")
)

// seedDemoDiseaseHubs connects the existing reviewed demo publications to the
// disease-aware discovery model. It deliberately runs only as part of the
// guarded demo scope and owns deterministic IDs so reruns update, rather than
// duplicate, local fixtures.
func seedDemoDiseaseHubs(database *gorm.DB, adminID uuid.UUID) error {
	publishedAt := time.Date(2026, time.July, 26, 12, 0, 0, 0, time.UTC)

	diseases := []map[string]any{
		{"id": demoEbolaDiseaseID, "name": "Ebola virus disease", "normalized_name": "ebola virus disease", "slug": "ebola-virus-disease", "short_name": "EVD", "description": "Viral haemorrhagic fever guidance and approved response resources.", "icon": "shield-alert", "color": "#C62828", "status": "active", "sort_order": 10, "updated_by": adminID, "deleted_at": nil},
		{"id": demoMalariaDiseaseID, "name": "Malaria", "normalized_name": "malaria", "slug": "malaria", "description": "Approved prevention, diagnosis and treatment resources for malaria.", "icon": "mosquito", "color": "#1565C0", "status": "active", "sort_order": 20, "updated_by": adminID, "deleted_at": nil},
		{"id": demoMarburgDiseaseID, "name": "Marburg virus disease", "normalized_name": "marburg virus disease", "slug": "marburg-virus-disease", "short_name": "MVD", "description": "Preparedness and clinical guidance for Marburg virus disease.", "icon": "shield-alert", "color": "#AD1457", "status": "active", "sort_order": 40, "updated_by": adminID, "deleted_at": nil},
		{"id": demoHypertensionDiseaseID, "name": "Hypertension", "normalized_name": "hypertension", "slug": "hypertension", "short_name": "HTN", "description": "Screening, cardiovascular-risk and longitudinal management resources.", "icon": "heart-pulse", "color": "#6A1B9A", "status": "active", "sort_order": 70, "updated_by": adminID, "deleted_at": nil},
	}
	for _, row := range diseases {
		if err := upsertByID(database, "diseases", row); err != nil {
			return err
		}
	}

	aliases := []map[string]any{
		{"id": demoID("disease-alias", "bundibugyo-virus-disease"), "disease_id": demoEbolaDiseaseID, "alias": "Bundibugyo virus disease", "normalized_alias": "bundibugyo virus disease", "deleted_at": nil},
	}
	for _, row := range aliases {
		if err := upsertByID(database, "disease_aliases", row); err != nil {
			return err
		}
	}
	codes := []map[string]any{
		{"id": demoID("disease-code", "icd10-a98-4"), "disease_id": demoEbolaDiseaseID, "code_system": "ICD-10", "code": "A98.4", "display_name": "Ebola virus disease", "deleted_at": nil},
		{"id": demoID("disease-code", "icd10-b50-b54"), "disease_id": demoMalariaDiseaseID, "code_system": "ICD-10", "code": "B50-B54", "display_name": "Malaria", "deleted_at": nil},
		{"id": demoID("disease-code", "icd10-a98-3"), "disease_id": demoMarburgDiseaseID, "code_system": "ICD-10", "code": "A98.3", "display_name": "Marburg virus disease", "deleted_at": nil},
		{"id": demoID("disease-code", "icd10-i10"), "disease_id": demoHypertensionDiseaseID, "code_system": "ICD-10", "code": "I10", "display_name": "Essential hypertension", "deleted_at": nil},
	}
	for _, row := range codes {
		if err := upsertByID(database, "disease_codes", row); err != nil {
			return err
		}
	}

	ncdCategoryID := demoID("guideline-category", "non-communicable-diseases")
	emergencyCategoryID := demoID("guideline-category", "emergency-preparedness")
	for _, row := range []map[string]any{
		{"id": ncdCategoryID, "name": "Non-Communicable Diseases", "slug": "non-communicable-diseases", "description": "Long-term prevention, screening and management guidance.", "sort_order": 20, "status": "active", "color": "#6A1B9A", "icon": "heart-pulse", "deleted_at": nil},
		{"id": emergencyCategoryID, "name": "Emergency Preparedness", "slug": "emergency-preparedness", "description": "Preparedness and response guidance for urgent public-health threats.", "sort_order": 30, "status": "active", "color": "#C62828", "icon": "shield-alert", "deleted_at": nil},
	} {
		if err := upsertByID(database, "guideline_categories", row); err != nil {
			return err
		}
	}
	categoryLinks := []models.GuidelineDocumentCategory{
		{GuidelineDocumentID: demoID("guideline", "malaria-adults"), CategoryID: guidelineCategoryID},
		{GuidelineDocumentID: demoID("guideline", "ebola-marburg"), CategoryID: guidelineCategoryID},
		{GuidelineDocumentID: demoID("guideline", "ebola-marburg"), CategoryID: emergencyCategoryID},
		{GuidelineDocumentID: demoID("guideline", "hypertension"), CategoryID: ncdCategoryID},
	}
	for _, row := range categoryLinks {
		if err := database.Clauses(clause.OnConflict{DoNothing: true}).Create(&row).Error; err != nil {
			return err
		}
	}

	assignments := []map[string]any{
		demoDiseaseAssignment("guideline-malaria", demoMalariaDiseaseID, models.ContentDiseaseGuideline, demoID("guideline", "malaria-adults"), true, adminID),
		demoDiseaseAssignment("guideline-ebola", demoEbolaDiseaseID, models.ContentDiseaseGuideline, demoID("guideline", "ebola-marburg"), true, adminID),
		demoDiseaseAssignment("guideline-marburg", demoMarburgDiseaseID, models.ContentDiseaseGuideline, demoID("guideline", "ebola-marburg"), false, adminID),
		demoDiseaseAssignment("guideline-hypertension", demoHypertensionDiseaseID, models.ContentDiseaseGuideline, demoID("guideline", "hypertension"), true, adminID),
		demoDiseaseAssignment("outbreak-ebola", demoEbolaDiseaseID, models.ContentDiseaseOutbreak, demoID("outbreak", "bundibugyo-uganda-2026"), true, adminID),
		demoDiseaseAssignment("sitrep-ebola", demoEbolaDiseaseID, models.ContentDiseaseSituationReport, demoID("situation-report", "who-bvd-11-2026-07-26"), true, adminID),
	}
	for _, document := range demoOutbreakDocuments() {
		assignments = append(assignments, demoDiseaseAssignment("outbreak-document-"+document.Key, demoEbolaDiseaseID, models.ContentDiseaseOutbreakDocument, demoID("outbreak-document", document.Key), true, adminID))
	}
	for _, row := range assignments {
		if err := upsertByID(database, "content_disease_assignments", row); err != nil {
			return err
		}
	}

	type hubFixture struct {
		key, name, slug, description, icon, color, audience string
		diseaseID                                           uuid.UUID
		outbreakID                                          *uuid.UUID
		pillars                                             []demoHubPillar
	}
	outbreakID := demoID("outbreak", "bundibugyo-uganda-2026")
	hubs := []hubFixture{
		{"ebola-response", "Ebola Response Hub", "demo-ebola-response", "Reviewed demonstration guidance and response resources for Ebola virus disease.", "shield-alert", "critical", "all", demoEbolaDiseaseID, &outbreakID, []demoHubPillar{
			{"case-definition", "Case Definition", "file-search", "Who is a suspected case?", "outbreak_document", demoID("outbreak-document", "ebola-case-definition")},
			{"screening-triage", "Screening & Triage", "list-checks", "Identify and prioritize suspected cases.", "outbreak_document", demoID("outbreak-document", "ebola-health-worker-checklist")},
			{"clinical-management", "Clinical Management", "stethoscope", "Safe initial assessment, care and referral.", "guideline", demoID("guideline", "ebola-marburg")},
			{"ipc-ppe", "IPC & PPE", "shield-check", "Infection prevention and PPE guidance.", "outbreak_document", demoID("outbreak-document", "ebola-ipc-sop")},
			{"situation-reports", "Situation Reports", "chart-no-axes-column", "Reviewed response updates.", "situation_report", demoID("situation-report", "who-bvd-11-2026-07-26")},
		}},
		{"malaria-care", "Malaria Care Hub", "demo-malaria-care", "A compact development hub for testing disease discovery and clinical navigation.", "mosquito", "clinical", "all", demoMalariaDiseaseID, nil, []demoHubPillar{
			{"overview", "Overview", "book-open", "Key information about malaria.", "guideline", demoID("guideline", "malaria-adults")},
			{"diagnosis", "Diagnosis", "search", "Assessment and parasitological testing.", "guideline", demoID("guideline", "malaria-adults")},
			{"clinical-management", "Clinical Management", "stethoscope", "Uncomplicated and severe-malaria management.", "guideline", demoID("guideline", "malaria-adults")},
		}},
		{"hypertension-care", "Hypertension Care Hub", "demo-hypertension-care", "Development content for testing a non-communicable disease hub.", "heart-pulse", "clinical", "health-workers", demoHypertensionDiseaseID, nil, []demoHubPillar{
			{"overview", "Overview", "book-open", "Screening and diagnosis overview.", "guideline", demoID("guideline", "hypertension")},
			{"clinical-management", "Clinical Management", "stethoscope", "Risk assessment and longitudinal care.", "guideline", demoID("guideline", "hypertension")},
		}},
	}
	for hubIndex, fixture := range hubs {
		hubID := demoID("content-hub", fixture.key)
		if err := upsertByID(database, "content_hubs", map[string]any{
			"id": hubID, "name": fixture.name, "slug": fixture.slug, "description": fixture.description,
			"icon": fixture.icon, "color": fixture.color, "audience": fixture.audience,
			"status": models.ContentHubStatusActive, "sort_order": (hubIndex + 1) * 10,
			"created_by": adminID, "updated_by": adminID, "published_at": publishedAt,
			"lock_version": 1, "deleted_at": nil,
		}); err != nil {
			return err
		}
		if err := database.Clauses(clause.OnConflict{DoNothing: true}).Create(&models.ContentHubDisease{ContentHubID: hubID, DiseaseID: fixture.diseaseID}).Error; err != nil {
			return err
		}
		if fixture.outbreakID != nil {
			if err := database.Clauses(clause.OnConflict{DoNothing: true}).Create(&models.ContentHubOutbreak{ContentHubID: hubID, OutbreakID: *fixture.outbreakID}).Error; err != nil {
				return err
			}
		}
		for pillarIndex, pillar := range fixture.pillars {
			pillarID := demoID("content-pillar", fixture.key+"-"+pillar.slug)
			if err := upsertByID(database, "content_pillars", map[string]any{
				"id": pillarID, "hub_id": hubID, "name": pillar.name, "slug": pillar.slug,
				"description": pillar.description, "icon": pillar.icon, "color": fixture.color,
				"sort_order": (pillarIndex + 1) * 10, "status": models.ContentPillarStatusActive,
				"lock_version": 1, "deleted_at": nil,
			}); err != nil {
				return err
			}
			if err := upsertByID(database, "content_pillar_items", map[string]any{
				"id": demoID("content-pillar-item", fixture.key+"-"+pillar.slug), "pillar_id": pillarID,
				"content_type": pillar.contentType, "content_id": pillar.contentID, "target": "",
				"label_override": pillar.name, "description_override": pillar.description,
				"icon_override": pillar.icon, "sort_order": 10, "featured": pillarIndex == 0,
				"status": models.ContentPillarItemStatusActive, "created_by": adminID,
				"lock_version": 1, "deleted_at": nil,
			}); err != nil {
				return err
			}
		}
	}
	return nil
}

type demoHubPillar struct {
	slug, name, icon, description, contentType string
	contentID                                  uuid.UUID
}

func demoDiseaseAssignment(key string, diseaseID uuid.UUID, contentType string, contentID uuid.UUID, primary bool, adminID uuid.UUID) map[string]any {
	return map[string]any{
		"id": demoID("content-disease-assignment", key), "disease_id": diseaseID,
		"content_type": contentType, "content_id": contentID, "is_primary": primary,
		"created_by": adminID, "deleted_at": nil,
	}
}
