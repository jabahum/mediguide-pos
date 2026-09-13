package main

import (
	"testing"

	"mediguide/internal/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestSeedDemoApplicationMetadataIsCompleteAndIdempotent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.Setting{},
		&models.GuidelineCategory{},
		&models.GuidelineTag{},
		&models.DrugCategory{},
		&models.DrugTag{},
	); err != nil {
		t.Fatal(err)
	}
	// AutoMigrate does not reproduce the PostgreSQL enum-like check, so install
	// the same allowed values here to prevent fixtures drifting from production.
	if err := database.Exec(`DROP TABLE drug_tags`).Error; err != nil {
		t.Fatal(err)
	}
	if err := database.Exec(`CREATE TABLE drug_tags (
		id text PRIMARY KEY,
		name text NOT NULL,
		description text,
		color text,
		tag_category text NOT NULL CHECK (tag_category IN ('clinical','administrative','regulatory','safety')),
		sort_order integer,
		status text NOT NULL,
		created_at datetime DEFAULT CURRENT_TIMESTAMP,
		updated_at datetime DEFAULT CURRENT_TIMESTAMP,
		deleted_at datetime
	)`).Error; err != nil {
		t.Fatal(err)
	}

	for range 2 {
		if err := seedDemoApplicationMetadata(database); err != nil {
			t.Fatal(err)
		}
	}
	assertSeedTableCount(t, database, "settings", 8)
	assertSeedTableCount(t, database, "guideline_categories", 4)
	assertSeedTableCount(t, database, "guideline_tags", 5)
	assertSeedTableCount(t, database, "drug_categories", 3)
	assertSeedTableCount(t, database, "drug_tags", 3)

	var publicSettings int64
	if err := database.Table("settings").Where("is_public = ?", true).Count(&publicSettings).Error; err != nil {
		t.Fatal(err)
	}
	if publicSettings != 7 {
		t.Fatalf("expected seven public application metadata records, got %d", publicSettings)
	}
}
