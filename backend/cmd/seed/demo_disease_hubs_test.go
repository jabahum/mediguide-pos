package main

import (
	"testing"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestSeedDemoDiseaseHubsIsCompleteAndIdempotent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}

	statements := []string{
		`CREATE TABLE diseases (id text PRIMARY KEY, name text, normalized_name text, slug text UNIQUE, short_name text, description text, icon text, color text, status text, sort_order integer, updated_by text, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP)`,
		`CREATE TABLE disease_aliases (id text PRIMARY KEY, disease_id text, alias text, normalized_alias text, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, UNIQUE(disease_id, normalized_alias))`,
		`CREATE TABLE disease_codes (id text PRIMARY KEY, disease_id text, code_system text, code text, display_name text, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, UNIQUE(code_system, code))`,
		`CREATE TABLE guideline_categories (id text PRIMARY KEY, name text, slug text UNIQUE, description text, sort_order integer, status text, color text, icon text, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP)`,
		`CREATE TABLE guideline_document_categories (guideline_document_id text, category_id text, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(guideline_document_id, category_id))`,
		`CREATE TABLE content_disease_assignments (id text PRIMARY KEY, disease_id text, content_type text, content_id text, is_primary boolean, created_by text, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, UNIQUE(disease_id, content_type, content_id))`,
		`CREATE TABLE content_hubs (id text PRIMARY KEY, name text, slug text UNIQUE, description text, icon text, color text, audience text, status text, sort_order integer, created_by text, updated_by text, published_at datetime, lock_version integer, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP)`,
		`CREATE TABLE content_hub_diseases (content_hub_id text, disease_id text, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(content_hub_id, disease_id))`,
		`CREATE TABLE content_hub_outbreaks (content_hub_id text, outbreak_id text, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(content_hub_id, outbreak_id))`,
		`CREATE TABLE content_pillars (id text PRIMARY KEY, hub_id text, parent_id text, name text, slug text, description text, icon text, color text, sort_order integer, status text, lock_version integer, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, UNIQUE(hub_id, slug))`,
		`CREATE TABLE content_pillar_items (id text PRIMARY KEY, pillar_id text, content_type text, content_id text, target text, label_override text, description_override text, icon_override text, sort_order integer, featured boolean, status text, created_by text, lock_version integer, deleted_at datetime, created_at datetime DEFAULT CURRENT_TIMESTAMP, updated_at datetime DEFAULT CURRENT_TIMESTAMP, UNIQUE(pillar_id, content_type, content_id))`,
	}
	for _, statement := range statements {
		if err := database.Exec(statement).Error; err != nil {
			t.Fatal(err)
		}
	}

	// Migrations already own this canonical alias and category. Keeping them in
	// the test catches accidental duplication by the development-only seed.
	if err := database.Exec(
		`INSERT INTO disease_aliases (id, disease_id, alias, normalized_alias) VALUES (?, ?, ?, ?)`,
		"91000000-0000-4000-8000-000000000008",
		demoHypertensionDiseaseID,
		"High blood pressure",
		"high blood pressure",
	).Error; err != nil {
		t.Fatal(err)
	}
	if err := database.Exec(
		`INSERT INTO guideline_categories (id, name, slug, status) VALUES (?, ?, ?, ?)`,
		guidelineCategoryID,
		"Infectious Diseases",
		"infectious-diseases",
		"active",
	).Error; err != nil {
		t.Fatal(err)
	}

	adminID := uuid.New()
	for range 2 {
		if err := seedDemoDiseaseHubs(database, adminID); err != nil {
			t.Fatal(err)
		}

		assertSeedTableCount(t, database, "diseases", 6)
		assertSeedTableCount(t, database, "disease_aliases", 4)
		assertSeedTableCount(t, database, "disease_codes", 6)
		assertSeedTableCount(t, database, "guideline_categories", 3)
		assertSeedTableCount(t, database, "guideline_document_categories", 4)
		assertSeedTableCount(t, database, "content_disease_assignments", 23)
		assertSeedTableCount(t, database, "content_hubs", 3)
		assertSeedTableCount(t, database, "content_hub_diseases", 3)
		assertSeedTableCount(t, database, "content_hub_outbreaks", 1)
		assertSeedTableCount(t, database, "content_pillars", 10)
		assertSeedTableCount(t, database, "content_pillar_items", 10)
	}

	var activeHubs int64
	if err := database.Table("content_hubs").
		Where("status = ? AND published_at IS NOT NULL", "active").
		Count(&activeHubs).Error; err != nil {
		t.Fatal(err)
	}
	if activeHubs != 3 {
		t.Fatalf("expected all demo hubs to be publicly eligible, got %d", activeHubs)
	}
}

func assertSeedTableCount(t *testing.T, database *gorm.DB, table string, want int64) {
	t.Helper()
	var got int64
	if err := database.Table(table).Count(&got).Error; err != nil {
		t.Fatal(err)
	}
	if got != want {
		t.Fatalf("%s: got %d rows, want %d", table, got, want)
	}
}
