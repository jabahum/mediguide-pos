package main

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"gorm.io/gorm"
)

const demoNamespace = "https://mediguide.local/development-seed/"

type demoGuideline struct {
	Key         string
	Title       string
	Description string
	ProgramArea string
	Population  string
	Healthcare  string
	Version     string
	Publication string
	Review      string
	Sections    []demoSection
}

type demoSection struct {
	Title  string
	Slug   string
	Blocks []demoBlock
}

type demoBlock struct {
	Type    string
	Payload map[string]any
}

func seedDemoData(ctx context.Context, database *gorm.DB, store storage.ObjectStore, admin, clinician *models.User) error {
	return database.Transaction(func(tx *gorm.DB) error {
		steps := []func() error{
			func() error { return seedDemoReferenceContent(tx) },
			func() error { return seedDemoCalculators(tx, admin.ID) },
			func() error { return seedDemoDrugs(tx) },
			func() error { return seedDemoGuidelines(ctx, tx, store, admin.ID) },
			func() error { return seedDemoOutbreaks(tx) },
			func() error { return seedDemoPeopleAndHelp(tx, admin.ID, clinician.ID) },
		}
		for _, step := range steps {
			if err := step(); err != nil {
				return err
			}
		}
		log.Info().Msg("seeded deterministic development demo content")
		return nil
	})
}

func demoID(kind, key string) uuid.UUID {
	return uuid.NewSHA1(uuid.NameSpaceURL, []byte(demoNamespace+kind+"/"+key))
}

func seedDemoReferenceContent(database *gorm.DB) error {
	languages := []map[string]any{
		{"id": languageENID, "code": "en", "name": "English", "native_name": "English", "is_active": true, "is_default": true, "translations_json": mustJSON(`{}`), "version": 1.0, "status": "published", "progress": 100.0, "enabled_for_users": true},
		{"id": languageSWID, "code": "sw", "name": "Swahili", "native_name": "Kiswahili", "is_active": true, "is_default": false, "translations_json": mustJSON(`{}`), "version": 1.0, "status": "published", "progress": 78.0, "enabled_for_users": true},
	}
	for _, row := range languages {
		if err := upsertByID(database, "languages", row); err != nil {
			return err
		}
	}

	pages := []map[string]any{
		{"id": demoID("page", "about"), "key": "about-us", "title": "About MediGuide", "description": "Official clinical guidance at the point of care", "content_json": mustJSON(`{"body":"MediGuide helps health workers discover approved clinical guidance, decision tools and reference information online or offline."}`)},
		{"id": demoID("page", "privacy"), "key": "privacy-policy", "title": "Privacy Policy", "description": "How MediGuide protects your information", "content_json": mustJSON(`{"body":"Development demonstration policy. Production deployments must publish the approved privacy policy."}`)},
		{"id": demoID("page", "terms"), "key": "terms-and-conditions", "title": "Terms and Conditions", "description": "Clinical-use terms", "content_json": mustJSON(`{"body":"MediGuide supports clinical decisions and does not replace professional judgement or local escalation protocols."}`)},
	}
	for _, row := range pages {
		if err := upsertByID(database, "generic_pages", row); err != nil {
			return err
		}
	}

	categoryID := guidelineCategoryID
	if err := upsertByID(database, "guideline_categories", map[string]any{"id": categoryID, "name": "Infectious Diseases", "slug": "infectious-diseases", "description": "Prevention, diagnosis and treatment guidance", "sort_order": 1, "status": "active", "color": "#0B63CE", "icon": "shield-plus"}); err != nil {
		return err
	}
	if err := upsertByID(database, "guideline_tags", map[string]any{"id": guidelineTagID, "name": "National guideline", "description": "Approved national clinical guidance"}); err != nil {
		return err
	}
	if err := upsertByID(database, "guideline_index", map[string]any{"id": guidelineIndexID, "title": "Infectious Diseases", "sort_order": 1, "description": "Clinical guidance for infectious diseases", "level": 1, "has_children": true}); err != nil {
		return err
	}

	for index, item := range []struct{ short, meaning, description string }{
		{"ACT", "Artemisinin-based Combination Therapy", "First-line medicines used to treat uncomplicated malaria."},
		{"RDT", "Rapid Diagnostic Test", "Point-of-care test used to detect malaria antigens."},
		{"ORS", "Oral Rehydration Salts", "Glucose-electrolyte solution for treating dehydration."},
		{"IPC", "Infection Prevention and Control", "Measures that reduce transmission in healthcare settings."},
		{"PPE", "Personal Protective Equipment", "Protective clothing and equipment used to reduce exposure."},
	} {
		if err := upsertByID(database, "abbreviations", map[string]any{"id": demoID("abbreviation", item.short), "abbreviation": item.short, "meaning": item.meaning, "description": item.description, "common_usage": true, "category_json": mustJSON(`["Clinical"]`), "tags_json": mustJSON(`["demo"]`), "usage_count": 10 + index}); err != nil {
			return err
		}
	}
	return nil
}

func seedDemoCalculators(database *gorm.DB, adminID uuid.UUID) error {
	for _, sample := range seededCalculatorSamples() {
		artifact, _ := json.Marshal(map[string]string{"name": sample.Name, "path": sample.FileName})
		if err := upsertByID(database, "calculators", map[string]any{
			"id": sample.ID, "added_by_user_id": adminID, "name": sample.Name,
			"description": sample.Description, "icon": sample.Icon, "color": sample.Color,
			"background_color": sample.BackgroundColor, "app_file_json": artifact,
			"version": "1.0.0", "type": sample.Type, "status": "active",
			"usage_count": sample.UsageCount, "featured": sample.Featured,
		}); err != nil {
			return err
		}
	}
	return nil
}

func seedDemoDrugs(database *gorm.DB) error {
	classID := drugClassID
	therapyID := therapeuticCategoryID
	if err := upsertByID(database, "drug_classes", map[string]any{"id": classID, "name": "Essential medicines", "description": "Common medicines used in routine clinical care", "status": "active", "sort_order": 1}); err != nil {
		return err
	}
	if err := upsertByID(database, "therapeutic_categories", map[string]any{"id": therapyID, "name": "General therapeutics", "description": "Demonstration therapeutic reference", "status": "active", "sort_order": 1}); err != nil {
		return err
	}
	drugs := []struct {
		name, brands, description, adultDose, indications, warnings string
		who, antimicrobial                                          bool
	}{
		{"Amlodipine", "Norvasc", "Calcium-channel blocker used for hypertension.", "5 mg orally once daily; titrate according to response.", "Hypertension and selected angina syndromes.", "Monitor blood pressure and peripheral oedema.", true, false},
		{"Amoxicillin", "Amoxil, Trimox", "Penicillin antibiotic for susceptible bacterial infections.", "Dose by indication and national antimicrobial guidance.", "Susceptible respiratory, ENT and other bacterial infections.", "Confirm allergy history and follow antimicrobial stewardship guidance.", true, true},
		{"Aspirin", "Disprin, Ecotrin", "Antiplatelet and analgesic medicine.", "Use an indication-specific dose.", "Selected cardiovascular and pain indications.", "Avoid in active bleeding and use caution in children.", true, false},
		{"Atorvastatin", "Lipitor", "HMG-CoA reductase inhibitor for lipid lowering.", "10–80 mg orally once daily depending on indication.", "Cardiovascular risk reduction and dyslipidaemia.", "Review interactions, liver disease and pregnancy status.", true, false},
		{"Azithromycin", "Zithromax, Z-Pak", "Macrolide antibiotic.", "Dose by indication and local antimicrobial guidance.", "Selected susceptible bacterial infections.", "Review QT risk and antimicrobial stewardship guidance.", true, true},
		{"Cetirizine", "Zyrtec", "Second-generation antihistamine.", "10 mg orally once daily for adults when appropriate.", "Allergic rhinitis and urticaria.", "May cause drowsiness in some patients.", true, false},
		{"Ciprofloxacin", "Cipro", "Fluoroquinolone antibiotic reserved for appropriate indications.", "Dose by infection, renal function and national guidance.", "Selected susceptible bacterial infections.", "Reserve use, review interactions and monitor tendon or neurologic symptoms.", true, true},
	}
	for index, item := range drugs {
		if err := upsertByID(database, "drugs", map[string]any{
			"id": demoID("drug", item.name), "drug_class_id": classID, "therapeutic_category_id": therapyID,
			"name": item.name, "brand_names": item.brands, "description": item.description,
			"adult_dose": item.adultDose, "route_of_administration": "oral", "indications": item.indications,
			"warnings": item.warnings, "categories_json": mustJSON(`["Essential medicines"]`),
			"tags_json": mustJSON(`["WHO","demo"]`), "who_eml_status": item.who,
			"antimicrobial_status": item.antimicrobial, "status": "active", "review_status": "approved",
			"search_keywords": item.name + " medicine dose indications", "reference_text": "Development demo based on representative clinical reference fields; verify against approved guidance.", "usage_count": 20 + index,
		}); err != nil {
			return err
		}
	}
	return nil
}

func seedDemoGuidelines(ctx context.Context, database *gorm.DB, store storage.ObjectStore, reviewerID uuid.UUID) error {
	guidelines := []demoGuideline{
		{Key: "malaria-adults", Title: "Malaria in Adults", Description: "Diagnosis and management of uncomplicated and severe malaria in adults.", ProgramArea: "Malaria", Population: "Adults (18 years and older)", Healthcare: "All healthcare levels", Version: "1.4", Publication: "2026-05-21", Review: "2028-05-21", Sections: []demoSection{
			{Title: "Overview", Slug: "overview", Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Malaria is a potentially life-threatening febrile illness. Test suspected cases promptly and assess every patient for danger signs."}}, {Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Key point", "content": "Confirm suspected malaria with parasitological testing before treatment whenever testing is available.", "severity": "info"}}}},
			{Title: "Diagnosis and assessment", Slug: "diagnosis-and-assessment", Blocks: []demoBlock{{Type: "recommendation", Payload: map[string]any{"type": "recommendation", "title": "Recommendation", "content": "Use a quality-assured RDT or microscopy and assess for severe disease before choosing treatment.", "evidence_grade": "National guidance"}}, {Type: "table", Payload: map[string]any{"type": "table", "title": "Diagnostic test comparison", "columns": []string{"Test", "Typical setting", "Result"}, "rows": [][]string{{"RDT", "Point of care", "Antigen detected or not detected"}, {"Microscopy", "Laboratory", "Parasite detection and density"}}, "footnotes": []string{"Follow current national testing algorithms."}}}, {Type: "algorithm", Payload: map[string]any{"type": "algorithm", "title": "Severe malaria triage", "nodes": []map[string]any{{"id": "start", "label": "Suspected malaria", "kind": "start", "next": []string{"test"}}, {"id": "test", "label": "Test and assess danger signs", "kind": "decision", "next": []string{"treat", "refer"}}, {"id": "treat", "label": "Treat uncomplicated malaria", "kind": "action"}, {"id": "refer", "label": "Urgent severe-malaria management and referral", "kind": "warning"}}}}}},
		}},
		{Key: "ebola-marburg", Title: "Ebola and Marburg Disease Preparedness", Description: "Recognition, isolation, notification and safe initial management of suspected viral haemorrhagic fever.", ProgramArea: "Emergency preparedness", Population: "All ages", Healthcare: "All facilities and community response teams", Version: "2.0", Publication: "2026-05-28", Review: "2027-05-28", Sections: []demoSection{
			{Title: "Recognition and immediate action", Slug: "recognition", Blocks: []demoBlock{{Type: "warning", Payload: map[string]any{"type": "warning", "title": "Immediate action", "content": "Isolate a suspected case, apply appropriate IPC precautions and notify the designated surveillance authority immediately.", "severity": "critical"}}, {Type: "unordered_list", Payload: map[string]any{"type": "unordered_list", "items": []string{"Avoid unnecessary contact", "Use appropriate PPE", "Record exposure history", "Arrange safe referral"}}}}},
			{Title: "Infection prevention and control", Slug: "infection-prevention", Blocks: []demoBlock{{Type: "recommendation", Payload: map[string]any{"type": "recommendation", "title": "IPC recommendation", "content": "Use trained donning and doffing observers and maintain a clear separation between clean and contaminated zones.", "evidence_grade": "Operational guidance"}}}},
		}},
		{Key: "hypertension", Title: "Hypertension Screening and Management", Description: "Practical screening, cardiovascular risk assessment and longitudinal management guidance.", ProgramArea: "Non-communicable diseases", Population: "Adults", Healthcare: "Primary care and referral facilities", Version: "1.1", Publication: "2026-04-12", Review: "2028-04-12", Sections: []demoSection{
			{Title: "Screening", Slug: "screening", Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Measure blood pressure with validated equipment after appropriate rest, and confirm persistent elevation using repeat readings."}}, {Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Measurement", "content": "Use the correct cuff size and document repeat measurements.", "severity": "info"}}}},
			{Title: "Management", Slug: "management", Blocks: []demoBlock{{Type: "ordered_list", Payload: map[string]any{"type": "ordered_list", "items": []string{"Assess cardiovascular risk and target-organ damage", "Support lifestyle measures", "Initiate medicines when indicated", "Schedule monitoring and adherence review"}}}}},
		}},
	}

	for _, guideline := range guidelines {
		if err := seedDemoGuideline(ctx, database, store, reviewerID, guideline); err != nil {
			return err
		}
	}
	return nil
}

func seedDemoGuideline(ctx context.Context, database *gorm.DB, store storage.ObjectStore, reviewerID uuid.UUID, guideline demoGuideline) error {
	documentID := demoID("guideline", guideline.Key)
	versionID := demoID("guideline-version", guideline.Key+"-"+guideline.Version)
	markdownKey := fmt.Sprintf("demo/guidelines/%s/%s.md", guideline.Key, guideline.Version)
	markdown := demoMarkdown(guideline)
	sum := sha256.Sum256(markdown)
	checksum := hex.EncodeToString(sum[:])
	if err := store.Put(ctx, markdownKey, bytes.NewReader(markdown), int64(len(markdown)), "text/markdown; charset=utf-8"); err != nil {
		return err
	}

	if err := upsertByID(database, "guideline_documents", map[string]any{
		"id": documentID, "title": guideline.Title, "country": "Uganda", "source_org": "Ministry of Health Uganda",
		"program_area": guideline.ProgramArea, "language": "en", "description": guideline.Description,
		"intended_population": guideline.Population, "healthcare_level": guideline.Healthcare,
	}); err != nil {
		return err
	}
	if err := upsertByID(database, "guideline_versions", map[string]any{
		"id": versionID, "document_id": documentID, "version": guideline.Version, "publication_date": guideline.Publication,
		"review_date": guideline.Review, "status": "published", "markdown_file_key": markdownKey, "checksum": checksum,
		"approved_by": reviewerID, "approved_at": guideline.Publication + "T09:00:00Z", "extraction_schema_version": 1,
		"extraction_metadata_json": mustJSON(`{"source":"development_seed","parser":"curated"}`), "extraction_warnings_json": mustJSON(`[]`),
		"structured_content_status": "approved",
	}); err != nil {
		return err
	}
	if err := database.Table("guideline_documents").Where("id = ?", documentID).Updates(map[string]any{"current_version_id": versionID, "updated_at": time.Now().UTC()}).Error; err != nil {
		return err
	}

	blockCount, tableCount, algorithmCount := 0, 0, 0
	for sectionIndex, section := range guideline.Sections {
		sectionID := demoID("guideline-section", guideline.Key+"-"+section.Slug)
		page := sectionIndex + 1
		if err := upsertByID(database, "guideline_sections", map[string]any{"id": sectionID, "version_id": versionID, "title": section.Title, "slug": section.Slug, "level": 1, "text": section.Title, "page_start": page, "page_end": page, "sort_order": sectionIndex}); err != nil {
			return err
		}
		for blockIndex, block := range section.Blocks {
			blockID := demoID("guideline-block", fmt.Sprintf("%s-%s-%d", guideline.Key, section.Slug, blockIndex))
			payload, _ := json.Marshal(block.Payload)
			if err := upsertByID(database, "guideline_content_blocks", map[string]any{
				"id": blockID, "version_id": versionID, "section_id": sectionID, "type": block.Type,
				"sort_order": blockIndex, "content_json": payload, "source_fingerprint": "demo:" + blockID.String(),
				"provenance_json": mustJSON(fmt.Sprintf(`{"source":"development_seed","page":%d}`, page)), "page_start": page, "page_end": page,
				"extraction_confidence": 1.0, "review_status": "reviewed", "reviewed_by": reviewerID, "reviewed_at": time.Now().UTC(),
			}); err != nil {
				return err
			}
			text := demoBlockText(block.Payload)
			if text != "" {
				if err := upsertByID(database, "guideline_chunks", map[string]any{
					"id": demoID("guideline-chunk", blockID.String()), "document_id": documentID, "version_id": versionID,
					"section_id": sectionID, "block_id": blockID, "title": section.Title, "content": text,
					"html": "<p>" + text + "</p>", "page_start": page, "page_end": page, "language": "en",
					"program_area": guideline.ProgramArea, "source_name": guideline.Title, "source_version": guideline.Version,
					"review_status": "reviewed", "embedding_text": text,
				}); err != nil {
					return err
				}
			}
			blockCount++
			if block.Type == "table" {
				tableCount++
			}
			if block.Type == "algorithm" {
				algorithmCount++
			}
		}
	}
	if err := upsertByID(database, "guideline_version_manifests", map[string]any{
		"id": demoID("guideline-manifest", guideline.Key), "guideline_id": documentID, "version_id": versionID,
		"version": guideline.Version, "schema_version": 1, "package_version": 1, "extraction_quality": "reviewed",
		"has_chapters": true, "has_key_points": true, "has_tables": tableCount > 0, "has_figures": false,
		"has_algorithms": algorithmCount > 0, "has_original_pdf": false, "has_offline_package": true,
		"section_count": len(guideline.Sections), "block_count": blockCount, "table_count": tableCount,
		"figure_count": 0, "algorithm_count": algorithmCount, "checksum": checksum, "etag": "sha256-" + checksum, "generated_at": time.Now().UTC(),
	}); err != nil {
		return err
	}

	offline, err := demoOfflinePackage(guideline, markdown)
	if err != nil {
		return err
	}
	offlineKey := fmt.Sprintf("demo/guidelines/%s/%s-offline.zip", guideline.Key, guideline.Version)
	offlineSum := sha256.Sum256(offline)
	if err := store.Put(ctx, offlineKey, bytes.NewReader(offline), int64(len(offline)), "application/zip"); err != nil {
		return err
	}
	filename := guideline.Key + "-offline.zip"
	if err := upsertByID(database, "guideline_assets", map[string]any{
		"id": demoID("guideline-asset", guideline.Key+"-offline"), "version_id": versionID, "type": "offline_package",
		"mime_type": "application/zip", "checksum": hex.EncodeToString(offlineSum[:]), "storage_key": offlineKey,
		"size_bytes": len(offline), "original_filename": filename, "alternative_text": guideline.Title + " offline package",
		"caption": "Development offline package", "source": "development_seed", "attribution": "Ministry of Health Uganda",
		"license": "development demonstration", "clinically_sensitive": false, "uploaded_by": reviewerID,
		"source_fingerprint": "demo-offline:" + guideline.Key, "provenance_json": mustJSON(`{"source":"development_seed"}`),
		"review_status": "reviewed", "reviewed_by": reviewerID, "reviewed_at": time.Now().UTC(),
	}); err != nil {
		return err
	}
	return nil
}

func demoMarkdown(g demoGuideline) []byte {
	var buffer bytes.Buffer
	fmt.Fprintf(&buffer, "# %s\n\n%s\n\n> Development demonstration content. Verify all clinical decisions against the approved source.\n\n", g.Title, g.Description)
	for _, section := range g.Sections {
		fmt.Fprintf(&buffer, "## %s\n\n", section.Title)
		for _, block := range section.Blocks {
			if text := demoBlockText(block.Payload); text != "" {
				fmt.Fprintf(&buffer, "%s\n\n", text)
			}
		}
	}
	return buffer.Bytes()
}

func demoBlockText(payload map[string]any) string {
	for _, key := range []string{"text", "content", "title"} {
		if value, ok := payload[key].(string); ok && value != "" {
			return value
		}
	}
	if items, ok := payload["items"].([]string); ok {
		var buffer bytes.Buffer
		for _, item := range items {
			fmt.Fprintf(&buffer, "- %s\n", item)
		}
		return buffer.String()
	}
	return ""
}

func demoOfflinePackage(g demoGuideline, markdown []byte) ([]byte, error) {
	var output bytes.Buffer
	writer := zip.NewWriter(&output)
	manifest, _ := writer.Create("manifest.json")
	if _, err := fmt.Fprintf(manifest, `{"schema_version":1,"title":%q,"version":%q}`, g.Title, g.Version); err != nil {
		return nil, err
	}
	content, _ := writer.Create("guideline.md")
	if _, err := content.Write(markdown); err != nil {
		return nil, err
	}
	if err := writer.Close(); err != nil {
		return nil, err
	}
	return output.Bytes(), nil
}

func seedDemoOutbreaks(database *gorm.DB) error {
	now := time.Now().UTC().Truncate(time.Second)
	ebolaID := demoID("outbreak", "ebola-kasese")
	choleraID := demoID("outbreak", "cholera-kampala")
	rows := []map[string]any{
		{"id": ebolaID, "title": "Ebola Virus Disease preparedness alert", "disease_type": "Ebola virus disease", "status": "active", "geographic_area": "Kasese District, Uganda", "summary": "Enhanced surveillance, IPC readiness and referral coordination are active. This is development demonstration data.", "start_date": now.AddDate(0, 0, -10), "last_update": now, "visual_tone": "critical", "source_organization": "Ministry of Health Uganda", "published_at": now.Add(-9 * 24 * time.Hour), "metrics": mustJSON(`[{"label":"Confirmed cases","value":0},{"label":"Contacts monitored","value":28},{"label":"Facilities alerted","value":12}]`)},
		{"id": choleraID, "title": "Cholera prevention and monitoring update", "disease_type": "Cholera", "status": "monitoring", "geographic_area": "Kampala Metropolitan Area", "summary": "Water safety, case detection and community prevention activities are being monitored. This is development demonstration data.", "start_date": now.AddDate(0, 0, -18), "last_update": now.Add(-6 * time.Hour), "visual_tone": "warning", "source_organization": "Ministry of Health Uganda", "published_at": now.Add(-17 * 24 * time.Hour), "metrics": mustJSON(`[{"label":"Facilities reporting","value":16},{"label":"Samples tested","value":42}]`)},
	}
	for _, row := range rows {
		if err := upsertByID(database, "outbreaks", row); err != nil {
			return err
		}
	}
	updates := []map[string]any{
		{"id": demoID("outbreak-update", "ebola-1"), "outbreak_id": ebolaID, "title": "Preparedness teams activated", "summary": "District response teams reviewed isolation, specimen referral and IPC readiness.", "published_at": now.Add(-24 * time.Hour)},
		{"id": demoID("outbreak-update", "ebola-2"), "outbreak_id": ebolaID, "title": "Surveillance update", "summary": "No confirmed case is included in this demonstration dataset; enhanced surveillance remains active.", "published_at": now},
		{"id": demoID("outbreak-update", "cholera-1"), "outbreak_id": choleraID, "title": "Community prevention intensified", "summary": "Risk communication emphasizes safe water, sanitation and early care seeking.", "published_at": now.Add(-6 * time.Hour)},
	}
	for _, row := range updates {
		if err := upsertByID(database, "outbreak_updates", row); err != nil {
			return err
		}
	}
	resources := []map[string]any{
		{"id": demoID("outbreak-resource", "ebola-guideline"), "outbreak_id": ebolaID, "title": "Ebola and Marburg preparedness guideline", "resource_type": "guideline", "url": "/guidelines/" + demoID("guideline", "ebola-marburg").String(), "asset_url": "", "sort_order": 1},
		{"id": demoID("outbreak-resource", "cholera-facts"), "outbreak_id": choleraID, "title": "Cholera prevention information", "resource_type": "link", "url": "https://www.health.go.ug/", "asset_url": "", "sort_order": 1},
	}
	for _, row := range resources {
		if err := upsertByID(database, "outbreak_resources", row); err != nil {
			return err
		}
	}
	if err := upsertByID(database, "situation_reports", map[string]any{
		"id": demoID("situation-report", "ebola-1"), "outbreak_id": ebolaID, "title": "Ebola preparedness situation report — demonstration",
		"geographic_area": "Kasese District", "summary": "Demonstration report showing the mobile situation-report experience.",
		"source_organization": "Ministry of Health Uganda", "publication_date": now, "status": "published", "report_asset_url": "https://www.health.go.ug/",
		"key_highlights": mustJSON(`["Response teams briefed","Referral pathways reviewed","PPE readiness assessed"]`),
		"metrics":        mustJSON(`[{"label":"Contacts monitored","value":28},{"label":"Facilities alerted","value":12}]`),
	}); err != nil {
		return err
	}
	return nil
}

func seedDemoPeopleAndHelp(database *gorm.DB, adminID, clinicianID uuid.UUID) error {
	consultants := []map[string]any{
		{"id": consultantOneID, "user_id": clinicianID, "name": "Dr. Sarah Nakato", "email": "clinician@mediguide.local", "phone": "+256700000002", "specialty": "Internal Medicine", "license_number": "DEMO-MED-001", "years_of_experience": 9.0, "qualifications": "MD", "city": "Kampala", "region": "Central", "country": "Uganda", "organization": "Kampala Central Health Centre III", "preferred_language": "English", "availability_json": mustJSON(`{"weekdays":"08:00-17:00"}`), "consultation_types": "Telemedicine", "status": "active", "is_verified": true, "rating": 4.8, "total_consultations": 124, "usage_count": 32},
		{"id": consultantTwoID, "name": "Dr. Daniel Okello", "email": "daniel.okello@example.test", "phone": "+256700000004", "specialty": "Pediatrics", "license_number": "DEMO-MED-002", "years_of_experience": 7.0, "qualifications": "MD", "city": "Gulu", "region": "Northern", "country": "Uganda", "organization": "Regional Referral Hospital", "preferred_language": "English", "availability_json": mustJSON(`{"weekdays":"09:00-16:00"}`), "consultation_types": "In-Person", "status": "active", "is_verified": true, "rating": 4.7, "total_consultations": 86, "usage_count": 21},
	}
	for _, row := range consultants {
		if err := upsertByID(database, "consultants", row); err != nil {
			return err
		}
	}

	var district struct{ ID uuid.UUID }
	if err := database.Table("districts").Select("id").Order("name ASC").Take(&district).Error; err == nil {
		var region struct{ ID uuid.UUID }
		_ = database.Table("districts").Select("region_id AS id").Where("id = ?", district.ID).Take(&region).Error
		if err := upsertByID(database, "ministry_directory", map[string]any{"id": ministryDirectoryID, "district_id": district.ID, "region_id": region.ID, "name": "National Health Emergency Desk", "title": "Emergency coordination desk", "ministry": "Ministry of Health", "department": "Emergency Medical Services", "phone": "0800 100066", "alternative_phone": "+256417712260", "email": "demo@health.go.ug", "office_address": "Kampala, Uganda", "priority_level": 1, "availability_hours": "24 hours", "specialization": "Emergency coordination", "status": "active", "notes": "Development demonstration contact; verify production details before publishing."}); err != nil {
			return err
		}
	}

	if err := upsertByID(database, "faq_tags", map[string]any{"id": faqTagID, "name": "Getting started", "slug": "getting-started", "description": "Using MediGuide", "color": "#0B63CE", "icon": "help-circle", "usage_count": 3, "is_active": true, "sort_order": 1}); err != nil {
		return err
	}
	faqs := []map[string]any{
		{"id": faqID, "author_id": adminID, "reviewer_id": adminID, "question": "Can I use guidelines offline?", "answer": "Yes. Open a published guideline and choose Download. MediGuide verifies the package and keeps it available in Offline Content.", "status": "published", "priority": "normal", "sort_order": 1, "is_featured": true, "target_audience": "all", "keywords": "offline download guideline", "published_at": "2026-05-28T09:00:00Z", "review_due": "2027-05-28", "tags_json": mustJSON(fmt.Sprintf(`["%s"]`, faqTagID)), "related_faqs_json": mustJSON(`[]`)},
		{"id": demoID("faq", "clinical-use"), "author_id": adminID, "reviewer_id": adminID, "question": "Does MediGuide replace clinical judgement?", "answer": "No. MediGuide provides decision support. Always apply professional judgement, approved local protocols and escalation pathways.", "status": "published", "priority": "high", "sort_order": 2, "is_featured": true, "target_audience": "all", "keywords": "clinical judgement safety", "published_at": "2026-05-28T09:00:00Z", "review_due": "2027-05-28", "tags_json": mustJSON(fmt.Sprintf(`["%s"]`, faqTagID)), "related_faqs_json": mustJSON(`[]`)},
	}
	for _, row := range faqs {
		if err := upsertByID(database, "faqs", row); err != nil {
			return err
		}
	}
	if err := upsertByID(database, "documentation", map[string]any{"id": documentationID, "title": "MediGuide quick start", "description": "Finding, reading and downloading clinical guidance", "content": "Search for a condition, open an approved guideline, review its source and version, and download it before working offline.", "category": "Getting started", "tags": "guidelines,offline,search", "status": "published"}); err != nil {
		return err
	}

	if err := upsertByID(database, "emergency_protocols", map[string]any{
		"id": emergencyProtocolID, "title": "Initial emergency triage", "description": "A demonstration rapid assessment sequence for an acutely unwell patient.",
		"category": "triage", "priority": "critical", "timeframe": "Immediate", "steps_json": mustJSON(`["Ensure scene safety and apply IPC precautions","Assess airway, breathing and circulation","Identify danger signs","Call for senior support and arrange referral when indicated"]`),
		"critical_actions_json": mustJSON(`["Treat life-threatening problems immediately","Do not delay referral for non-essential documentation"]`), "medications_json": mustJSON(`[]`),
		"contact_info_json": mustJSON(`{"emergency":"Use the approved local emergency number"}`), "transfer_checklist_json": mustJSON(`["Stabilise","Communicate","Document","Escort"]`),
		"status": "active", "access_count": 18, "vital_signs_json": mustJSON(`["Respiratory rate","SpO2","Pulse","Blood pressure","Temperature","Consciousness"]`), "tags_json": mustJSON(`["triage","demo"]`),
	}); err != nil {
		return err
	}

	if err := upsertByID(database, "support_tickets", map[string]any{"id": supportTicketID, "user_id": clinicianID, "assigned_to": adminID, "subject": "Offline guideline download demonstration", "description": "This sample ticket confirms the support workflow has data.", "status": "in_progress", "priority": "normal", "category": "offline-content"}); err != nil {
		return err
	}
	if err := upsertByID(database, "support_ticket_replies", map[string]any{"id": supportReplyID, "ticket_id": supportTicketID, "user_id": adminID, "message": "The sample guideline packages are ready for download. Please retry while online."}); err != nil {
		return err
	}
	return nil
}
