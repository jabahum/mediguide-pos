package main

import (
	"context"
	"testing"

	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestSeedAdditionalDemoOutbreaksIsPublicAndIdempotent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.Outbreak{}, &models.OutbreakUpdate{}, &models.OutbreakResource{}, &models.SituationReport{}); err != nil {
		t.Fatal(err)
	}

	store := &demoSeedObjectStore{objects: map[string][]byte{}}
	authorID, clinicianID := uuid.New(), uuid.New()
	for range 2 {
		if err := seedAdditionalDemoOutbreaks(context.Background(), database, store, authorID, clinicianID); err != nil {
			t.Fatal(err)
		}
	}
	assertSeedTableCount(t, database, "outbreaks", 2)
	assertSeedTableCount(t, database, "outbreak_updates", 4)
	assertSeedTableCount(t, database, "outbreak_resources", 16)
	assertSeedTableCount(t, database, "situation_reports", 2)
	if len(store.objects) != 12 {
		t.Fatalf("expected twelve managed files in object storage, got %d", len(store.objects))
	}

	publicOutbreaks, err := (services.OutbreakService{DB: database}).List(services.OutbreakQuery{Page: services.PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if publicOutbreaks.TotalItems != 2 {
		t.Fatalf("expected two public synthetic outbreaks, got %d", publicOutbreaks.TotalItems)
	}
	publicResources, err := (services.OutbreakService{DB: database}).ListResources(services.OutbreakResourceQuery{Page: services.PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if publicResources.TotalItems != 4 {
		t.Fatalf("expected four safe public quick resources, got %d", publicResources.TotalItems)
	}
	publicDocuments, err := (services.OutbreakService{DB: database}).SearchDocuments(services.OutbreakDocumentQuery{Page: services.PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if publicDocuments.TotalItems != 12 {
		t.Fatalf("expected twelve public managed documents, got %d", publicDocuments.TotalItems)
	}
	publicReports, err := (services.OutbreakService{DB: database}).ListReports(services.SituationReportQuery{Page: services.PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if publicReports.TotalItems != 2 {
		t.Fatalf("expected two public synthetic situation reports, got %d", publicReports.TotalItems)
	}
}
