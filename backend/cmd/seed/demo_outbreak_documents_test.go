package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/url"
	"path"
	"testing"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type demoSeedObjectStore struct {
	objects map[string][]byte
	puts    int
}

func (s *demoSeedObjectStore) Put(_ context.Context, key string, reader io.Reader, _ int64, _ string) error {
	content, err := io.ReadAll(reader)
	if err != nil {
		return err
	}
	s.objects[key] = content
	s.puts++
	return nil
}

func (s *demoSeedObjectStore) Get(_ context.Context, key string) (io.ReadCloser, error) {
	return io.NopCloser(bytes.NewReader(s.objects[key])), nil
}

func (s *demoSeedObjectStore) Delete(_ context.Context, key string) error {
	delete(s.objects, key)
	return nil
}

func (s *demoSeedObjectStore) PresignGet(_ context.Context, key string, _ time.Duration) (*url.URL, error) {
	return url.Parse("https://objects.example.test/" + key)
}

func TestSeedDemoOutbreakDocumentsIsCompleteAndIdempotent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.Outbreak{}, &models.OutbreakResource{}); err != nil {
		t.Fatal(err)
	}
	outbreakID := demoID("outbreak", "bundibugyo-uganda-2026")
	publishedAt := time.Date(2026, time.May, 16, 12, 0, 0, 0, time.UTC)
	if err := database.Create(&models.Outbreak{Base: models.Base{ID: outbreakID}, Title: "Demo outbreak", Status: "published", PublishedAt: &publishedAt, LastUpdate: time.Now().UTC()}).Error; err != nil {
		t.Fatal(err)
	}
	authorID := uuid.New()
	clinicianID := uuid.New()
	store := &demoSeedObjectStore{objects: map[string][]byte{}}

	for range 2 {
		if err := seedDemoOutbreakDocuments(context.Background(), database, store, outbreakID, authorID, clinicianID); err != nil {
			t.Fatal(err)
		}
	}

	fixtures := demoOutbreakDocuments()
	if len(fixtures) != 6 {
		t.Fatalf("expected six required outbreak fixtures, got %d", len(fixtures))
	}
	var rows []models.OutbreakResource
	if err := database.Where("outbreak_id = ? AND resource_type = ?", outbreakID, "managed_document").Order("sort_order ASC").Find(&rows).Error; err != nil {
		t.Fatal(err)
	}
	if len(rows) != len(fixtures) || len(store.objects) != len(fixtures) {
		t.Fatalf("seed was not idempotent: rows=%d objects=%d fixtures=%d", len(rows), len(store.objects), len(fixtures))
	}
	if store.puts != len(fixtures)*2 {
		t.Fatalf("expected deterministic object replacement on each run, got %d puts", store.puts)
	}

	seenKinds := map[string]bool{}
	for index, row := range rows {
		content, exists := store.objects[row.StorageKey]
		if !exists || len(content) == 0 {
			t.Fatalf("published seed %s references a missing object %q", row.ID, row.StorageKey)
		}
		digest := sha256.Sum256(content)
		if row.ChecksumSHA256 != hex.EncodeToString(digest[:]) || row.FileSize != int64(len(content)) {
			t.Fatalf("stored metadata does not match fixture for %s", row.ID)
		}
		projection := services.DeriveOutbreakDocumentProjection(path.Ext(fixtures[index].Fixture), content)
		if row.ExtractionStatus != "ready" || row.SearchIndexStatus != "indexed" || row.IndexedAt == nil || row.ExtractedAt == nil || row.ExtractionSourceChecksum != row.ChecksumSHA256 || row.DerivedContentChecksum != projection.Checksum || row.SearchSchemaVersion != services.OutbreakDocumentSearchSchemaVersion || row.SearchContent != projection.Search || row.SearchHeadings != projection.Headings || row.RenderedContent != projection.Rendered || !bytes.Equal(row.ContentSections, projection.SectionsJSON) || !bytes.Equal(row.SourcePageMap, projection.PageMapJSON) {
			t.Fatalf("seeded document is not honestly extracted and indexed for %s: %#v", row.ID, row)
		}
		if row.ID != demoID("outbreak-document", fixtures[len(seenKinds)].Key) {
			t.Fatalf("document ID is not deterministic for sort position %d", len(seenKinds))
		}
		if row.Status != "published" || row.PublishedAt == nil || row.ReviewedBy == nil || *row.ReviewedBy != clinicianID || row.ApprovedBy == nil || *row.ApprovedBy != clinicianID {
			t.Fatalf("invalid publication metadata for %s: %#v", row.ID, row)
		}
		if row.EffectiveDate == nil || row.ReviewDate == nil || row.ExpiresAt == nil || !row.ReviewDate.After(*row.EffectiveDate) || !row.ExpiresAt.After(*row.ReviewDate) {
			t.Fatalf("invalid lifecycle dates for %s", row.ID)
		}
		seenKinds[row.DocumentKind] = true
	}
	for _, kind := range []string{"sop", "ipc_protocol", "laboratory_protocol", "contact_tracing_guide", "checklist", "communication_material"} {
		if !seenKinds[kind] {
			t.Fatalf("required document kind %q was not seeded", kind)
		}
	}
}

func TestSeedDemoOutbreakDocumentsRequiresStorage(t *testing.T) {
	if err := seedDemoOutbreakDocuments(context.Background(), nil, nil, uuid.New(), uuid.New(), uuid.New()); err == nil {
		t.Fatal("expected a missing object-store error")
	}
}
