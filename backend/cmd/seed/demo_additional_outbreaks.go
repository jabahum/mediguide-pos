package main

import (
	"context"
	"time"

	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// seedAdditionalDemoOutbreaks provides synthetic, clearly labelled records for
// exercising multiple outbreak lifecycle states. Figures are fixed test data,
// not operational surveillance data, and this function is reachable only from
// the production-guarded demo seed scope.
func seedAdditionalDemoOutbreaks(ctx context.Context, database *gorm.DB, store storage.ObjectStore, authorID, clinicianID uuid.UUID) error {
	publishedAt := time.Date(2026, time.June, 1, 9, 0, 0, 0, time.UTC)
	choleraAsOf := time.Date(2026, time.August, 18, 9, 0, 0, 0, time.UTC)
	measlesAsOf := time.Date(2026, time.July, 8, 9, 0, 0, 0, time.UTC)
	choleraID := demoID("outbreak", "development-cholera-kampala-2026")
	measlesID := demoID("outbreak", "development-measles-gulu-2026")

	outbreaks := []map[string]any{
		{
			"id": choleraID, "title": "[Demo] Cholera response — Kampala", "disease_type": "Cholera", "status": "monitoring",
			"geographic_area": "Kampala, Uganda", "summary": "Synthetic development scenario for testing active outbreak discovery, metrics, updates, quick resources and situation-report navigation.",
			"start_date": time.Date(2026, time.August, 10, 0, 0, 0, 0, time.UTC), "last_update": choleraAsOf,
			"visual_tone": "critical", "source_organization": "MediGuide development fixtures", "published_at": publishedAt,
			"author_id": authorID, "reviewed_by": clinicianID, "reviewed_at": publishedAt, "approved_by": clinicianID, "approved_at": publishedAt,
			"source_reference": "Synthetic local test fixture — not operational surveillance data", "effective_at": publishedAt, "data_as_of": choleraAsOf, "last_verified_at": choleraAsOf, "lock_version": 1,
			"metrics": mustJSON(`[{"key":"demo_suspected","label":"Suspected cases (demo)","value":"34","numeric_value":34,"unit":"cases","as_of":"2026-08-18T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":1},{"key":"demo_admitted","label":"Admitted (demo)","value":"8","numeric_value":8,"unit":"people","as_of":"2026-08-18T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":2},{"key":"demo_recovered","label":"Recovered (demo)","value":"21","numeric_value":21,"unit":"people","as_of":"2026-08-18T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":3}]`),
		},
		{
			"id": measlesID, "title": "[Demo] Measles response — Gulu", "disease_type": "Measles", "status": "contained",
			"geographic_area": "Gulu, Uganda", "summary": "Synthetic contained-outbreak scenario for testing historical discovery, status styling, updates and publication metadata.",
			"start_date": time.Date(2026, time.June, 12, 0, 0, 0, 0, time.UTC), "last_update": measlesAsOf,
			"visual_tone": "success", "source_organization": "MediGuide development fixtures", "published_at": publishedAt,
			"author_id": authorID, "reviewed_by": clinicianID, "reviewed_at": publishedAt, "approved_by": clinicianID, "approved_at": publishedAt,
			"source_reference": "Synthetic local test fixture — not operational surveillance data", "effective_at": publishedAt, "data_as_of": measlesAsOf, "last_verified_at": measlesAsOf, "lock_version": 1,
			"metrics": mustJSON(`[{"key":"demo_confirmed","label":"Confirmed cases (demo)","value":"17","numeric_value":17,"unit":"cases","as_of":"2026-07-08T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":1},{"key":"demo_recovered","label":"Recovered (demo)","value":"17","numeric_value":17,"unit":"people","as_of":"2026-07-08T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":2},{"key":"demo_active","label":"Active cases (demo)","value":"0","numeric_value":0,"unit":"cases","as_of":"2026-07-08T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":3}]`),
		},
	}
	for _, row := range outbreaks {
		if err := upsertByID(database, "outbreaks", row); err != nil {
			return err
		}
	}
	if err := seedDemoManagedOutbreakDocuments(ctx, database, store, choleraID, authorID, clinicianID, demoCholeraOutbreakDocuments(), "cholera case-definition"); err != nil {
		return err
	}
	if err := seedDemoManagedOutbreakDocuments(ctx, database, store, measlesID, authorID, clinicianID, demoMeaslesOutbreakDocuments(), "measles case-definition"); err != nil {
		return err
	}

	updates := []map[string]any{
		{"id": demoID("outbreak-update", "demo-cholera-response-activated"), "outbreak_id": choleraID, "title": "[Demo] Response coordination activated", "summary": "Synthetic update used to test the active-response timeline.", "status": "published", "published_at": time.Date(2026, time.August, 11, 9, 0, 0, 0, time.UTC), "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-update", "demo-cholera-water-safety"), "outbreak_id": choleraID, "title": "[Demo] Water-safety activities expanded", "summary": "Synthetic update for testing chronological outbreak content.", "status": "published", "published_at": choleraAsOf, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-update", "demo-measles-vaccination"), "outbreak_id": measlesID, "title": "[Demo] Vaccination response completed", "summary": "Synthetic update used to test response activity for a contained outbreak.", "status": "published", "published_at": time.Date(2026, time.July, 2, 9, 0, 0, 0, time.UTC), "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-update", "demo-measles-contained"), "outbreak_id": measlesID, "title": "[Demo] Outbreak moved to contained", "summary": "Synthetic final update for testing contained-state presentation.", "status": "published", "published_at": measlesAsOf, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
	}
	for _, row := range updates {
		if err := upsertByID(database, "outbreak_updates", row); err != nil {
			return err
		}
	}

	resources := []map[string]any{
		{"id": demoID("outbreak-resource", "demo-cholera-case-definition"), "outbreak_id": choleraID, "title": "[Demo] Search cholera case definitions", "description": "Synthetic quick resource for local navigation testing.", "issuing_authority": "MediGuide development fixtures", "resource_type": "internal_route", "url": "/search", "asset_url": "", "sort_order": 1, "status": "published", "published_at": publishedAt, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-resource", "demo-cholera-ipc"), "outbreak_id": choleraID, "title": "[Demo] Find cholera IPC resources", "description": "Synthetic search shortcut for local outbreak-hub testing.", "issuing_authority": "MediGuide development fixtures", "resource_type": "internal_route", "url": "/search", "asset_url": "", "sort_order": 2, "status": "published", "published_at": publishedAt, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-resource", "demo-measles-case-definition"), "outbreak_id": measlesID, "title": "[Demo] Search measles case definitions", "description": "Synthetic quick resource for local navigation testing.", "issuing_authority": "MediGuide development fixtures", "resource_type": "internal_route", "url": "/search", "asset_url": "", "sort_order": 1, "status": "published", "published_at": publishedAt, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
		{"id": demoID("outbreak-resource", "demo-measles-vaccination"), "outbreak_id": measlesID, "title": "[Demo] Find measles vaccination guidance", "description": "Synthetic search shortcut for local discovery testing.", "issuing_authority": "MediGuide development fixtures", "resource_type": "internal_route", "url": "/search", "asset_url": "", "sort_order": 2, "status": "published", "published_at": publishedAt, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "lock_version": 1},
	}
	for _, row := range resources {
		if err := upsertByID(database, "outbreak_resources", row); err != nil {
			return err
		}
	}

	reports := []map[string]any{
		{"id": demoID("situation-report", "demo-cholera-kampala-2026-08-18"), "outbreak_id": choleraID, "title": "[Demo] Cholera situation report", "geographic_area": "Kampala, Uganda", "summary": "Synthetic report for testing outbreak report cards and filters.", "source_organization": "MediGuide development fixtures", "publication_date": choleraAsOf, "status": "published", "published_at": choleraAsOf, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "effective_at": publishedAt, "data_as_of": choleraAsOf, "last_verified_at": choleraAsOf, "source_reference": "Synthetic local test fixture", "report_asset_url": "", "key_highlights": mustJSON(`["Synthetic fixture for UI testing","Not operational surveillance data"]`), "metrics": mustJSON(`[{"key":"demo_suspected","label":"Suspected cases (demo)","value":"34","numeric_value":34,"unit":"cases","as_of":"2026-08-18T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":1}]`), "lock_version": 1},
		{"id": demoID("situation-report", "demo-measles-gulu-2026-07-08"), "outbreak_id": measlesID, "title": "[Demo] Measles closure report", "geographic_area": "Gulu, Uganda", "summary": "Synthetic report for testing a contained outbreak and historical filtering.", "source_organization": "MediGuide development fixtures", "publication_date": measlesAsOf, "status": "published", "published_at": measlesAsOf, "author_id": authorID, "reviewed_by": clinicianID, "approved_by": clinicianID, "approved_at": publishedAt, "effective_at": publishedAt, "data_as_of": measlesAsOf, "last_verified_at": measlesAsOf, "source_reference": "Synthetic local test fixture", "report_asset_url": "", "key_highlights": mustJSON(`["Synthetic contained-state fixture","Not operational surveillance data"]`), "metrics": mustJSON(`[{"key":"demo_active","label":"Active cases (demo)","value":"0","numeric_value":0,"unit":"cases","as_of":"2026-07-08T09:00:00Z","source_reference":"Synthetic local fixture","sort_order":1}]`), "lock_version": 1},
	}
	for _, row := range reports {
		if err := upsertByID(database, "situation_reports", row); err != nil {
			return err
		}
	}
	return nil
}
