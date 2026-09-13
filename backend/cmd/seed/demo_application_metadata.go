package main

import "gorm.io/gorm"

// seedDemoApplicationMetadata supplies a coherent metadata catalogue for local
// clients and administration screens. It contains configuration and taxonomy,
// never secrets or environment credentials.
func seedDemoApplicationMetadata(database *gorm.DB) error {
	settings := []map[string]any{
		{"id": demoID("setting", "application-identity"), "key": "application.identity", "value_json": mustJSON(`{"name":"MediGuide","short_name":"MediGuide","publisher":"Ministry of Health Uganda","country_code":"UG","default_language":"en","default_timezone":"Africa/Kampala"}`), "category": "application", "description": "Public product identity and localization defaults.", "is_public": true},
		{"id": demoID("setting", "application-support"), "key": "application.support", "value_json": mustJSON(`{"help_route":"/help-center","faq_route":"/faq","support_email":"support@mediguide.local","emergency_notice":"Use approved local emergency and referral channels."}`), "category": "application", "description": "Development support and escalation metadata.", "is_public": true},
		{"id": demoID("setting", "clinical-safety"), "key": "clinical.safety", "value_json": mustJSON(`{"patient_identifiable_information_allowed":false,"verify_against_cited_sources":true,"professional_judgement_required":true,"show_review_status":true,"show_source_provenance":true}`), "category": "clinical", "description": "Safety messaging and provenance expectations shared by clients.", "is_public": true},
		{"id": demoID("setting", "content-discovery"), "key": "content.discovery", "value_json": mustJSON(`{"enabled_types":["guideline","outbreak","outbreak_document","situation_report","drug_reference","clinical_tool"],"disease_filtering":true,"category_filtering":true,"content_hubs":true,"default_page_size":20}`), "category": "content", "description": "Discoverable content types and local browsing capabilities.", "is_public": true},
		{"id": demoID("setting", "content-review"), "key": "content.review", "value_json": mustJSON(`{"reviewed_content_only":true,"high_risk_requires_individual_review":true,"partial_publication_label":true,"original_source_fallback_required":true}`), "category": "content", "description": "Publication and review-policy metadata for local workflow testing.", "is_public": true},
		{"id": demoID("setting", "offline-capabilities"), "key": "offline.capabilities", "value_json": mustJSON(`{"guideline_packages":true,"outbreak_documents":true,"integrity_checks":true,"background_updates":true}`), "category": "offline", "description": "Supported offline-content capabilities.", "is_public": true},
		{"id": demoID("setting", "outbreak-display"), "key": "outbreak.display", "value_json": mustJSON(`{"show_active_banner":true,"show_data_as_of":true,"show_source_reference":true,"show_last_verified":true,"statuses":["published","active","monitoring","contained","closed"]}`), "category": "outbreak", "description": "Outbreak presentation metadata used by local clients.", "is_public": true},
		{"id": demoID("setting", "development-fixtures"), "key": "development.fixtures", "value_json": mustJSON(`{"synthetic_outbreaks":true,"operational_surveillance":false,"reset_by_demo_seed":true}`), "category": "development", "description": "Internal marker distinguishing synthetic fixtures from authoritative content.", "is_public": false},
	}
	for _, row := range settings {
		if err := upsertByID(database, "settings", row); err != nil {
			return err
		}
	}

	for index, row := range []struct {
		key, name, description, color, icon string
	}{
		{"maternal-health", "Maternal Health", "Pregnancy, childbirth and postnatal clinical guidance.", "#AD1457", "person-standing"},
		{"child-health", "Child Health", "Neonatal, infant, child and adolescent clinical guidance.", "#00838F", "baby"},
		{"emergency-care", "Emergency Care", "Triage, stabilization, referral and emergency clinical guidance.", "#D84315", "siren"},
		{"medicines-and-therapeutics", "Medicines and Therapeutics", "Safe prescribing, essential medicines and antimicrobial stewardship.", "#2E7D32", "pill"},
	} {
		if err := upsertByID(database, "guideline_categories", map[string]any{
			"id": demoID("guideline-category", row.key), "name": row.name, "slug": row.key,
			"description": row.description, "sort_order": 40 + index*10, "status": "active",
			"color": row.color, "icon": row.icon, "deleted_at": nil,
		}); err != nil {
			return err
		}
	}

	for _, row := range []struct{ key, name, description string }{
		{"point-of-care", "Point of care", "Content designed for rapid clinical use."},
		{"emergency-response", "Emergency response", "Preparedness and response content."},
		{"who-reference", "WHO reference", "Content referencing World Health Organization material."},
		{"offline-ready", "Offline ready", "Content with a verified offline representation."},
		{"clinical-review-required", "Clinical review required", "Content requiring explicit clinical approval."},
	} {
		if err := upsertByID(database, "guideline_tags", map[string]any{
			"id": demoID("guideline-tag", row.key), "name": row.name, "description": row.description, "deleted_at": nil,
		}); err != nil {
			return err
		}
	}

	for index, row := range []struct{ key, name, description, color, icon string }{
		{"anti-infectives", "Anti-infectives", "Medicines used to prevent or treat infectious diseases.", "#1565C0", "shield-plus"},
		{"cardiovascular", "Cardiovascular medicines", "Medicines used in cardiovascular disease management.", "#C62828", "heart-pulse"},
		{"analgesics", "Analgesics and antipyretics", "Medicines used for pain and fever management.", "#6A1B9A", "thermometer"},
	} {
		if err := upsertByID(database, "drug_categories", map[string]any{
			"id": demoID("drug-category", row.key), "name": row.name, "description": row.description,
			"color": row.color, "icon": row.icon, "sort_order": (index + 1) * 10, "status": "active", "deleted_at": nil,
		}); err != nil {
			return err
		}
	}

	for index, row := range []struct{ key, name, description, category, color string }{
		{"essential-medicine", "Essential medicine", "Representative medicine from an essential-medicines workflow.", "classification", "#2E7D32"},
		{"antimicrobial", "Antimicrobial", "Medicine requiring antimicrobial-stewardship consideration.", "safety", "#D84315"},
		{"dose-verification", "Dose verification", "Dose must be verified against the approved source and patient context.", "review", "#F9A825"},
	} {
		if err := upsertByID(database, "drug_tags", map[string]any{
			"id": demoID("drug-tag", row.key), "name": row.name, "description": row.description,
			"color": row.color, "tag_category": row.category, "sort_order": (index + 1) * 10, "status": "active", "deleted_at": nil,
		}); err != nil {
			return err
		}
	}
	return nil
}
