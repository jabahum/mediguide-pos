package main

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/services"
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
	Title      string
	Slug       string
	ParentSlug string
	Level      int
	Blocks     []demoBlock
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
			func() error { return seedDemoOutbreaks(ctx, tx, store, admin.ID, clinician.ID) },
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
		checksum, ok := services.ReviewedLegacyCalculatorChecksum(sample.FileName)
		if !ok {
			return fmt.Errorf("calculator seed artifact is not reviewed: %s", sample.FileName)
		}
		artifact, _ := json.Marshal(map[string]string{"name": sample.Name, "path": sample.FileName, "sha256": checksum})
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
	for _, guideline := range demoGuidelines() {
		if err := seedDemoGuideline(ctx, database, store, reviewerID, guideline); err != nil {
			return err
		}
	}
	return nil
}

func demoGuidelines() []demoGuideline {
	return []demoGuideline{
		{Key: "malaria-adults", Title: "Malaria in Adults", Description: "Diagnosis and management of uncomplicated and severe malaria in adults.", ProgramArea: "Malaria", Population: "Adults (18 years and older)", Healthcare: "All healthcare levels", Version: "1.4", Publication: "2026-05-21", Review: "2028-05-21", Sections: []demoSection{
			{Title: "1. Overview", Slug: "overview", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Malaria is a potentially life-threatening febrile illness. Test suspected cases promptly and assess every patient for danger signs."}}, {Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Confirm infection", "content": "Confirm suspected malaria with parasitological testing before treatment whenever testing is available.", "severity": "standard"}}}},
			{Title: "2. Diagnosis and assessment", Slug: "diagnosis-and-assessment", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Take a focused history, measure vital signs, assess hydration and consciousness, and look actively for severe-malaria features."}}}},
			{Title: "2.1 Clinical assessment", Slug: "clinical-assessment", ParentSlug: "diagnosis-and-assessment", Level: 2, Blocks: []demoBlock{{Type: "unordered_list", Payload: map[string]any{"type": "unordered_list", "items": []string{"Document fever history and prior antimalarial use", "Assess mental state, respiratory distress and ability to drink", "Check pregnancy status and important comorbidities", "Identify signs requiring urgent referral"}}}, {Type: "warning", Payload: map[string]any{"type": "warning", "title": "Danger signs", "content": "Altered consciousness, repeated convulsions, respiratory distress, shock, severe anaemia or inability to take oral treatment require urgent severe-malaria management.", "severity": "critical"}}}},
			{Title: "2.2 Parasitological testing", Slug: "parasitological-testing", ParentSlug: "diagnosis-and-assessment", Level: 2, Blocks: []demoBlock{{Type: "recommendation", Payload: map[string]any{"type": "recommendation", "title": "Testing recommendation", "content": "Use a quality-assured RDT or microscopy and assess for severe disease before choosing treatment.", "evidence_grade": "National guidance"}}, {Type: "table", Payload: map[string]any{"type": "table", "title": "Diagnostic test comparison", "columns": []string{"Test", "Typical setting", "Result"}, "rows": [][]string{{"RDT", "Point of care", "Antigen detected or not detected"}, {"Microscopy", "Laboratory", "Parasite detection and density"}}, "footnotes": []string{"Follow current national testing algorithms."}}}}},
			{Title: "3. Treatment", Slug: "treatment", Level: 1, Blocks: []demoBlock{{Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Treatment principle", "content": "Classify uncomplicated versus severe disease before selecting the regimen and route.", "severity": "high"}}}},
			{Title: "3.1 Uncomplicated malaria", Slug: "uncomplicated-malaria", ParentSlug: "treatment", Level: 2, Blocks: []demoBlock{{Type: "procedure", Payload: map[string]any{"type": "procedure", "title": "Initial management", "content": "Treat confirmed uncomplicated malaria using the current nationally recommended first-line ACT, with weight-based dosing and adherence counselling.", "severity": "standard"}}, {Type: "clinical_note", Payload: map[string]any{"type": "clinical_note", "title": "Follow-up", "content": "Advise the patient to return promptly for deterioration, persistent vomiting or failure to improve.", "severity": "standard"}}}},
			{Title: "3.2 Severe malaria", Slug: "severe-malaria", ParentSlug: "treatment", Level: 2, Blocks: []demoBlock{{Type: "referral_criteria", Payload: map[string]any{"type": "referral_criteria", "title": "Urgent escalation", "content": "Start emergency management without delaying referral, correct hypoglycaemia when present and arrange monitored transfer.", "severity": "critical"}}, {Type: "algorithm", Payload: map[string]any{"type": "algorithm", "title": "Severe malaria triage", "nodes": []map[string]any{{"id": "start", "label": "Suspected malaria", "kind": "start", "next": []string{"test"}}, {"id": "test", "label": "Test and assess danger signs", "kind": "decision", "next": []string{"treat", "refer"}}, {"id": "treat", "label": "Treat uncomplicated malaria", "kind": "action"}, {"id": "refer", "label": "Urgent severe-malaria management and referral", "kind": "warning"}}}}}},
			{Title: "4. Special populations", Slug: "special-populations", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Pregnancy, renal or hepatic impairment and significant comorbidity require regimen and referral decisions consistent with the approved national guideline."}}}},
			{Title: "5. Follow-up and prevention", Slug: "follow-up-prevention", Level: 1, Blocks: []demoBlock{{Type: "ordered_list", Payload: map[string]any{"type": "ordered_list", "items": []string{"Confirm clinical improvement", "Reassess adherence and vomiting", "Investigate persistent or recurrent symptoms", "Reinforce insecticide-treated net use and prevention advice"}}}}},
		}},
		{Key: "ebola-marburg", Title: "Ebola and Marburg Disease Preparedness", Description: "Recognition, isolation, notification and safe initial management of suspected viral haemorrhagic fever.", ProgramArea: "Emergency preparedness", Population: "All ages", Healthcare: "All facilities and community response teams", Version: "2.0", Publication: "2026-05-28", Review: "2027-05-28", Sections: []demoSection{
			{Title: "1. Purpose and scope", Slug: "purpose-scope", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "This preparedness guide supports early recognition and safe initial action while the designated surveillance and treatment system is activated."}}}},
			{Title: "2. Recognition and immediate action", Slug: "recognition", Level: 1, Blocks: []demoBlock{{Type: "warning", Payload: map[string]any{"type": "warning", "title": "Immediate action", "content": "Isolate a suspected case, apply appropriate IPC precautions and notify the designated surveillance authority immediately.", "severity": "critical"}}, {Type: "unordered_list", Payload: map[string]any{"type": "unordered_list", "items": []string{"Avoid unnecessary contact", "Use appropriate PPE", "Record exposure history", "Arrange safe referral"}}}}},
			{Title: "2.1 Case recognition", Slug: "case-recognition", ParentSlug: "recognition", Level: 2, Blocks: []demoBlock{{Type: "definition", Payload: map[string]any{"type": "definition", "title": "Suspected case", "content": "Apply the current surveillance case definition and evaluate symptoms together with travel, contact and exposure history.", "severity": "high"}}, {Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Do not delay notification", "content": "A suspected case should trigger immediate notification and IPC precautions; laboratory confirmation is coordinated through the response system.", "severity": "critical"}}}},
			{Title: "2.2 Notification and referral", Slug: "notification-referral", ParentSlug: "recognition", Level: 2, Blocks: []demoBlock{{Type: "procedure", Payload: map[string]any{"type": "procedure", "title": "Notification sequence", "content": "Contact the designated district surveillance focal person, document essential details, restrict movement and follow instructions for safe transfer.", "severity": "critical"}}}},
			{Title: "3. Infection prevention and control", Slug: "infection-prevention", Level: 1, Blocks: []demoBlock{{Type: "recommendation", Payload: map[string]any{"type": "recommendation", "title": "IPC recommendation", "content": "Use trained donning and doffing observers and maintain a clear separation between clean and contaminated zones.", "evidence_grade": "Operational guidance"}}}},
			{Title: "3.1 PPE and hand hygiene", Slug: "ppe-hand-hygiene", ParentSlug: "infection-prevention", Level: 2, Blocks: []demoBlock{{Type: "ordered_list", Payload: map[string]any{"type": "ordered_list", "items": []string{"Select PPE for the assessed exposure risk", "Use a trained observer for donning and doffing", "Perform hand hygiene at every indicated step", "Report and manage breaches immediately"}}}}},
			{Title: "3.2 Environmental controls", Slug: "environmental-controls", ParentSlug: "infection-prevention", Level: 2, Blocks: []demoBlock{{Type: "table", Payload: map[string]any{"type": "table", "title": "Control zones", "columns": []string{"Zone", "Access", "Core control"}, "rows": [][]string{{"Clean", "Authorized staff", "Keep supplies uncontaminated"}, {"Transition", "Trained staff", "Supervised PPE change"}, {"Patient care", "Essential staff only", "Exposure-based PPE and waste control"}}, "footnotes": []string{"Follow the activated response team's current IPC instructions."}}}}},
			{Title: "4. Supportive care", Slug: "supportive-care", Level: 1, Blocks: []demoBlock{{Type: "clinical_note", Payload: map[string]any{"type": "clinical_note", "title": "Safe supportive care", "content": "Provide clinically indicated supportive care only within the available isolation, IPC and staff-competency controls.", "severity": "high"}}}},
			{Title: "5. Exposure management", Slug: "exposure-management", Level: 1, Blocks: []demoBlock{{Type: "referral_criteria", Payload: map[string]any{"type": "referral_criteria", "title": "Occupational exposure", "content": "Stop work safely, wash the exposed site as appropriate, report immediately and follow the designated exposure-management pathway.", "severity": "critical"}}}},
		}},
		{Key: "hypertension", Title: "Hypertension Screening and Management", Description: "Practical screening, cardiovascular risk assessment and longitudinal management guidance.", ProgramArea: "Non-communicable diseases", Population: "Adults", Healthcare: "Primary care and referral facilities", Version: "1.1", Publication: "2026-04-12", Review: "2028-04-12", Sections: []demoSection{
			{Title: "1. Introduction", Slug: "introduction", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Hypertension care combines accurate blood-pressure measurement, assessment of total cardiovascular risk, appropriate treatment and sustained follow-up."}}}},
			{Title: "2. Screening and diagnosis", Slug: "screening", Level: 1, Blocks: []demoBlock{{Type: "paragraph", Payload: map[string]any{"type": "paragraph", "text": "Measure blood pressure with validated equipment after appropriate rest, and confirm persistent elevation using repeat readings."}}, {Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Measurement", "content": "Use the correct cuff size and document repeat measurements.", "severity": "standard"}}}},
			{Title: "2.1 Accurate measurement", Slug: "accurate-measurement", ParentSlug: "screening", Level: 2, Blocks: []demoBlock{{Type: "procedure", Payload: map[string]any{"type": "procedure", "title": "Measurement steps", "content": "Seat the patient appropriately, support the arm, select the correct cuff, allow rest and repeat an elevated measurement.", "severity": "standard"}}}},
			{Title: "2.2 Confirming hypertension", Slug: "confirming-hypertension", ParentSlug: "screening", Level: 2, Blocks: []demoBlock{{Type: "table", Payload: map[string]any{"type": "table", "title": "Assessment plan", "columns": []string{"Finding", "Next action", "Timing"}, "rows": [][]string{{"Normal reading", "Continue routine screening", "At recommended interval"}, {"Elevated reading without emergency features", "Repeat and confirm", "According to clinical risk"}, {"Severe elevation or emergency features", "Urgent clinical assessment", "Immediately"}}, "footnotes": []string{"Use approved national thresholds and pathways."}}}}},
			{Title: "3. Cardiovascular risk assessment", Slug: "risk-assessment", Level: 1, Blocks: []demoBlock{{Type: "unordered_list", Payload: map[string]any{"type": "unordered_list", "items": []string{"Assess smoking, diabetes and lipid risk", "Look for renal and cardiovascular disease", "Review medicines and secondary causes", "Document target-organ damage"}}}}},
			{Title: "4. Management", Slug: "management", Level: 1, Blocks: []demoBlock{{Type: "ordered_list", Payload: map[string]any{"type": "ordered_list", "items": []string{"Assess cardiovascular risk and target-organ damage", "Support lifestyle measures", "Initiate medicines when indicated", "Schedule monitoring and adherence review"}}}}},
			{Title: "4.1 Lifestyle support", Slug: "lifestyle-support", ParentSlug: "management", Level: 2, Blocks: []demoBlock{{Type: "recommendation", Payload: map[string]any{"type": "recommendation", "title": "Lifestyle measures", "content": "Support reduced dietary salt, regular appropriate physical activity, healthy weight, tobacco cessation and moderation of alcohol.", "evidence_grade": "National guidance"}}}},
			{Title: "4.2 Medicines", Slug: "medicines", ParentSlug: "management", Level: 2, Blocks: []demoBlock{{Type: "clinical_note", Payload: map[string]any{"type": "clinical_note", "title": "Individualize therapy", "content": "Select and titrate medicines according to cardiovascular risk, comorbidity, contraindications, pregnancy potential and response.", "severity": "high"}}}},
			{Title: "5. Follow-up", Slug: "follow-up", Level: 1, Blocks: []demoBlock{{Type: "key_point", Payload: map[string]any{"type": "key_point", "title": "Continuity of care", "content": "At each review assess blood pressure, adherence, adverse effects, lifestyle goals and new target-organ symptoms.", "severity": "standard"}}}},
		}},
	}
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

	// A development fixture owns the complete structured representation for its
	// deterministic version. Rebuild it on every run so renamed or removed demo
	// chapters do not survive as stale rows.
	if err := database.Unscoped().Where("version_id = ?", versionID).Delete(&models.GuidelineChunk{}).Error; err != nil {
		return err
	}
	if err := database.Unscoped().Where("version_id = ?", versionID).Delete(&models.GuidelineContentBlock{}).Error; err != nil {
		return err
	}
	if err := database.Unscoped().Where("version_id = ?", versionID).Delete(&models.GuidelineSection{}).Error; err != nil {
		return err
	}

	blockCount, tableCount, algorithmCount := 0, 0, 0
	sectionIDs := make(map[string]uuid.UUID, len(guideline.Sections))
	for _, section := range guideline.Sections {
		sectionIDs[section.Slug] = demoID("guideline-section", guideline.Key+"-"+section.Slug)
	}
	for sectionIndex, section := range guideline.Sections {
		sectionID := sectionIDs[section.Slug]
		level := section.Level
		if level < 1 {
			level = 1
		}
		var parentID any
		if section.ParentSlug != "" {
			resolved, ok := sectionIDs[section.ParentSlug]
			if !ok {
				return fmt.Errorf("demo guideline %q section %q has unknown parent %q", guideline.Key, section.Slug, section.ParentSlug)
			}
			parentID = resolved
		}
		page := sectionIndex + 1
		if err := upsertByID(database, "guideline_sections", map[string]any{"id": sectionID, "version_id": versionID, "parent_id": parentID, "title": section.Title, "slug": section.Slug, "level": level, "text": section.Title, "page_start": page, "page_end": page, "sort_order": sectionIndex}); err != nil {
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
		level := section.Level
		if level < 1 {
			level = 1
		}
		fmt.Fprintf(&buffer, "%s %s\n\n", strings.Repeat("#", level+1), section.Title)
		for _, block := range section.Blocks {
			if text := demoBlockMarkdown(block.Payload); text != "" {
				fmt.Fprintf(&buffer, "%s\n\n", text)
			}
		}
	}
	return buffer.Bytes()
}

func demoBlockMarkdown(payload map[string]any) string {
	if columns, ok := payload["columns"].([]string); ok && len(columns) > 0 {
		var buffer bytes.Buffer
		if title, ok := payload["title"].(string); ok && title != "" {
			fmt.Fprintf(&buffer, "**%s**\n\n", title)
		}
		fmt.Fprintf(&buffer, "| %s |\n", strings.Join(columns, " | "))
		separators := make([]string, len(columns))
		for index := range separators {
			separators[index] = "---"
		}
		fmt.Fprintf(&buffer, "| %s |\n", strings.Join(separators, " | "))
		if rows, ok := payload["rows"].([][]string); ok {
			for _, row := range rows {
				fmt.Fprintf(&buffer, "| %s |\n", strings.Join(row, " | "))
			}
		}
		return strings.TrimSpace(buffer.String())
	}
	if items, ok := payload["items"].([]string); ok {
		ordered := payload["type"] == "ordered_list"
		var buffer bytes.Buffer
		for index, item := range items {
			if ordered {
				fmt.Fprintf(&buffer, "%d. %s\n", index+1, item)
			} else {
				fmt.Fprintf(&buffer, "- %s\n", item)
			}
		}
		return strings.TrimSpace(buffer.String())
	}
	if content, ok := payload["content"].(string); ok && content != "" {
		title, _ := payload["title"].(string)
		if title != "" {
			return fmt.Sprintf("> **%s:** %s", title, content)
		}
		return "> " + content
	}
	return demoBlockText(payload)
}

func demoBlockText(payload map[string]any) string {
	parts := make([]string, 0, 8)
	for _, key := range []string{"title", "text", "content"} {
		if value, ok := payload[key].(string); ok && value != "" {
			parts = append(parts, value)
		}
	}
	if items, ok := payload["items"].([]string); ok {
		parts = append(parts, items...)
	}
	if columns, ok := payload["columns"].([]string); ok {
		parts = append(parts, columns...)
	}
	if rows, ok := payload["rows"].([][]string); ok {
		for _, row := range rows {
			parts = append(parts, row...)
		}
	}
	if nodes, ok := payload["nodes"].([]map[string]any); ok {
		for _, node := range nodes {
			if label, ok := node["label"].(string); ok && label != "" {
				parts = append(parts, label)
			}
		}
	}
	return strings.Join(parts, " ")
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

func seedDemoOutbreaks(ctx context.Context, database *gorm.DB, store storage.ObjectStore, authorID, clinicianID uuid.UUID) error {
	// This fixture mirrors the public WHO/MoH record available when the seed was
	// authored. Keep the dates and figures fixed: using time.Now here would make
	// historical surveillance data appear current after every seed run.
	reportDate := time.Date(2026, time.July, 26, 12, 0, 0, 0, time.UTC)
	publicationDate := time.Date(2026, time.May, 16, 12, 0, 0, 0, time.UTC)
	startDate := time.Date(2026, time.May, 15, 0, 0, 0, 0, time.UTC)
	ebolaID := demoID("outbreak", "bundibugyo-uganda-2026")
	// Retire the earlier fictional fixtures when upgrading an existing local DB.
	legacyOutbreakIDs := []uuid.UUID{
		demoID("outbreak", "ebola-kasese"),
		demoID("outbreak", "cholera-kampala"),
	}
	if err := database.Exec("DELETE FROM outbreak_updates WHERE outbreak_id IN ?", legacyOutbreakIDs).Error; err != nil {
		return err
	}
	if err := database.Exec("DELETE FROM outbreak_resources WHERE outbreak_id IN ?", legacyOutbreakIDs).Error; err != nil {
		return err
	}
	if err := database.Exec("DELETE FROM situation_reports WHERE outbreak_id IN ?", legacyOutbreakIDs).Error; err != nil {
		return err
	}
	if err := database.Exec("DELETE FROM outbreaks WHERE id IN ?", legacyOutbreakIDs).Error; err != nil {
		return err
	}
	rows := []map[string]any{
		{
			"id": ebolaID, "title": "Bundibugyo virus disease response — Uganda", "disease_type": "Bundibugyo virus disease", "status": "monitoring",
			"geographic_area": "Uganda and the Democratic Republic of the Congo border region",
			"summary":         "Uganda entered the 42-day countdown toward ending its outbreak after the last confirmed patient was discharged. Cross-border surveillance and readiness remained necessary while transmission continued in the Democratic Republic of the Congo.",
			"start_date":      startDate, "last_update": reportDate, "visual_tone": "warning", "source_organization": "Ministry of Health Uganda and WHO Regional Office for Africa", "published_at": publicationDate,
			"source_url": "https://www.afro.who.int/countries/uganda/news/uganda-begins-countdown-end-ebola-outbreak", "source_reference": "WHO/MoH Uganda Bundibugyo virus disease response update", "effective_at": publicationDate, "data_as_of": reportDate, "last_verified_at": reportDate, "approved_at": publicationDate,
			"metrics": mustJSON(`[{"key":"uganda_confirmed","label":"Confirmed cases in Uganda","value":"20","numeric_value":20,"unit":"cases","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":1},{"key":"uganda_deaths","label":"Deaths in Uganda","value":"2","numeric_value":2,"unit":"deaths","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":2},{"key":"contacts_followed","label":"Contacts followed up","value":"836","numeric_value":836,"unit":"contacts","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":3},{"key":"high_risk_districts","label":"High-risk districts","value":"36","numeric_value":36,"unit":"districts","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":4}]`),
		},
	}
	for _, row := range rows {
		if err := upsertByID(database, "outbreaks", row); err != nil {
			return err
		}
	}
	updates := []map[string]any{
		{"id": demoID("outbreak-update", "uganda-countdown-2026-07-16"), "outbreak_id": ebolaID, "title": "Uganda begins 42-day countdown", "summary": "The last confirmed patient tested negative for a second time and was discharged; surveillance and rapid investigation of alerts continued.", "status": "published", "published_at": time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)},
		{"id": demoID("outbreak-update", "who-sitrep-11-2026-07-26"), "outbreak_id": ebolaID, "title": "WHO publishes weekly external situation report 11", "summary": "WHO reported no new cases outside the Democratic Republic of the Congo while highlighting continued regional spread risk and the need for cross-border preparedness.", "status": "published", "published_at": reportDate},
	}
	for _, row := range updates {
		if err := upsertByID(database, "outbreak_updates", row); err != nil {
			return err
		}
	}
	resources := []map[string]any{
		{"id": demoID("outbreak-resource", "uganda-moh-press-statement-2026"), "outbreak_id": ebolaID, "title": "Uganda Ministry of Health press statement", "resource_type": "official_statement", "url": "https://health.go.ug/download/press-statement-ebola-bundibugyo-virus-disease-outbreak-2026/", "asset_url": "", "sort_order": 1, "status": "published", "published_at": publicationDate},
		{"id": demoID("outbreak-resource", "who-uganda-countdown-2026"), "outbreak_id": ebolaID, "title": "Uganda begins countdown to end of outbreak", "resource_type": "official_update", "url": "https://www.afro.who.int/countries/uganda/news/uganda-begins-countdown-end-ebola-outbreak", "asset_url": "", "sort_order": 2, "status": "published", "published_at": publicationDate},
		{"id": demoID("outbreak-resource", "local-ebola-guideline"), "outbreak_id": ebolaID, "title": "Ebola and Marburg preparedness guideline", "resource_type": "guideline", "url": "/public/guidelines/" + demoID("guideline", "ebola-marburg").String(), "asset_url": "", "sort_order": 3, "status": "published", "published_at": publicationDate},
	}
	for _, row := range resources {
		if err := upsertByID(database, "outbreak_resources", row); err != nil {
			return err
		}
	}
	if err := seedDemoOutbreakDocuments(ctx, database, store, ebolaID, authorID, clinicianID); err != nil {
		return err
	}
	if err := upsertByID(database, "situation_reports", map[string]any{
		"id": demoID("situation-report", "who-bvd-11-2026-07-26"), "outbreak_id": ebolaID, "title": "Bundibugyo virus disease weekly external situation report 11",
		"geographic_area": "Democratic Republic of the Congo and Uganda", "summary": "WHO's weekly external situation report with data as of 26 July 2026. It documents continued transmission in the Democratic Republic of the Congo and continuing regional preparedness needs.",
		"source_organization": "WHO Regional Office for Africa", "publication_date": reportDate, "status": "published", "published_at": reportDate, "approved_at": reportDate, "effective_at": reportDate, "data_as_of": reportDate, "last_verified_at": reportDate, "source_reference": "WHO weekly external situation report 11", "source_url": "https://www.who.int/emergencies/situations", "report_asset_url": "https://iris.who.int/bitstreams/e5023872-6b1c-446e-992d-7c92810d730a/download",
		"key_highlights": mustJSON(`["No new cases were reported outside the Democratic Republic of the Congo during the reporting period","Regional cross-border spread risk remained high","Sustained surveillance and preparedness remained necessary"]`),
		"metrics":        mustJSON(`[{"key":"uganda_confirmed","label":"Confirmed cases in Uganda","value":"20","numeric_value":20,"unit":"cases","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":1},{"key":"uganda_deaths","label":"Deaths in Uganda","value":"2","numeric_value":2,"unit":"deaths","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":2},{"key":"contacts_followed","label":"Contacts followed up","value":"836","numeric_value":836,"unit":"contacts","as_of":"2026-07-26T12:00:00Z","source_reference":"WHO situation report 11","sort_order":3}]`),
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

func seedDemoNotifications(database *gorm.DB, clinicianID uuid.UUID) error {
	rows := []map[string]any{
		{
			"id": notificationID, "title": "New malaria guideline available",
			"message": "Malaria in Adults version 1.4 is published and ready to read or download.",
			"type":    "success", "priority": "high",
			"action_url":  "/public/guidelines/" + demoID("guideline", "malaria-adults").String(),
			"action_json": mustJSON(`{"type":"guideline","resource_id":"` + demoID("guideline", "malaria-adults").String() + `","parameters":{}}`),
			"created_at":  time.Date(2026, time.May, 28, 9, 0, 0, 0, time.UTC),
		},
		{
			"id": demoID("notification", "outbreak-update"), "title": "Outbreak situation report updated",
			"message": "The latest Bundibugyo virus disease situation report is now available.",
			"type":    "warning", "priority": "urgent", "action_url": "/outbreak-hub",
			"action_json": mustJSON(`{"type":"internal_route","route":"/outbreak-hub","parameters":{}}`),
			"created_at":  time.Date(2026, time.July, 26, 14, 30, 0, 0, time.UTC),
		},
		{
			"id": demoID("notification", "offline-reminder"), "user_id": clinicianID,
			"title":   "Prepare guidelines for offline use",
			"message": "Download the guidance you need before working in an area with limited connectivity.",
			"type":    "info", "priority": "normal", "action_url": "/offline-content",
			"action_json": mustJSON(`{"type":"internal_route","route":"/offline-content","parameters":{}}`),
			"created_at":  time.Date(2026, time.July, 27, 8, 15, 0, 0, time.UTC),
		},
		{
			"id": demoID("notification", "system-ready"), "title": "MediGuide is ready",
			"message": "Clinical references, calculators and offline content are available from the Tools screen.",
			"type":    "info", "priority": "low", "action_url": "/tools",
			"action_json": mustJSON(`{"type":"internal_route","route":"/tools","parameters":{}}`),
			"created_at":  time.Date(2026, time.July, 28, 7, 45, 0, 0, time.UTC),
		},
	}
	for _, row := range rows {
		if err := upsertByID(database, "notifications", row); err != nil {
			return err
		}
	}

	if err := upsertByID(database, "notification_templates", map[string]any{
		"id": notificationTemplateID, "name": "Clinical content published",
		"template_key": "clinical-content-published", "current_version": 1, "locale": "en",
		"type": "in-app", "category": "Content Updates", "status": "published",
		"subject":  "New clinical guidance is available",
		"content":  "{{title}} version {{version}} is now published.",
		"audience": "all", "variables_json": mustJSON(`{"title":"string","version":"string"}`),
	}); err != nil {
		return err
	}
	templateVersionID := demoID("notification-template-version", "clinical-content-published-v1")
	if err := upsertByID(database, "notification_template_versions", map[string]any{
		"id": templateVersionID, "template_id": notificationTemplateID, "version": 1,
		"channel": "in-app", "title_template": "New clinical guidance is available",
		"body_template":        "{{title}} version {{version}} is now published.",
		"action_template_json": mustJSON(`{"type":"none","parameters":{}}`),
		"variable_schema_json": mustJSON(`{"title":{"type":"string","required":true,"sample_value":"Malaria in Adults"},"version":{"type":"string","required":true,"sample_value":"1.4"}}`),
		"category":             "Content Updates", "locale": "en", "status": "published",
	}); err != nil {
		return err
	}

	return upsertByID(database, "notification_campaigns", map[string]any{
		"id": notificationCampaignID, "name": "Development content announcements",
		"type": "announcement", "status": "draft", "channels_json": mustJSON(`["in-app"]`),
		"audience_countries_json":  mustJSON(`["Uganda"]`),
		"audience_roles_json":      mustJSON(`["clinician"]`),
		"template_version_id":      templateVersionID,
		"rendered_title":           "New clinical guidance is available",
		"rendered_body":            "Malaria in Adults version 1.4 is now published.",
		"action_snapshot_json":     mustJSON(`{"type":"none","parameters":{}}`),
		"audience_definition_json": mustJSON(`{"all_eligible":false,"countries":["Uganda"]}`),
		"requested_channels_json":  mustJSON(`["in-app"]`),
		"timezone":                 "Africa/Kampala", "priority": "normal",
		"idempotency_key": "demo:development-content-announcements", "lock_version": 1,
	})
}
