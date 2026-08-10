package services

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/url"
	"sync"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type fakePublicStore struct {
	mutex   sync.Mutex
	objects map[string][]byte
	err     error
	key     string
}

func (f *fakePublicStore) Put(_ context.Context, key string, reader io.Reader, _ int64, _ string) error {
	content, err := io.ReadAll(reader)
	if err != nil {
		return err
	}
	f.mutex.Lock()
	defer f.mutex.Unlock()
	f.objects[key] = content
	return nil
}
func (f *fakePublicStore) Get(_ context.Context, key string) (io.ReadCloser, error) {
	f.mutex.Lock()
	defer f.mutex.Unlock()
	f.key = key
	if f.err != nil {
		return nil, f.err
	}
	content, ok := f.objects[key]
	if !ok {
		return nil, errors.New("missing")
	}
	return io.NopCloser(bytes.NewReader(content)), nil
}
func (f *fakePublicStore) Delete(context.Context, string) error { return errors.New("not implemented") }
func (f *fakePublicStore) PresignGet(context.Context, string, time.Duration) (*url.URL, error) {
	return nil, errors.New("not implemented")
}

func TestPublicGuidelineProjectionExcludesInternalFields(t *testing.T) {
	id := uuid.New()
	row := publicGuidelineRow{
		ID: id, Title: "Maternal & Newborn Care", Description: "Public description",
		Version: "2.0", VersionID: uuid.New(), MarkdownFileKey: "private/object/key.md",
		VersionUpdated: time.Date(2026, 7, 30, 0, 0, 0, 0, time.UTC),
	}
	got := row.public()
	if got.ID != id || got.Slug != "maternal-newborn-care" || got.Version != "2.0" {
		t.Fatalf("unexpected projection: %#v", got)
	}
}

func TestSlugifyUsesSafeStableCharacters(t *testing.T) {
	for input, expected := range map[string]string{
		"  Malaria Care 2026 ": "malaria-care-2026",
		"Children's Health":    "children-s-health",
		"***":                  "guideline",
	} {
		if got := slugify(input); got != expected {
			t.Fatalf("slugify(%q) = %q, want %q", input, got, expected)
		}
	}
}

func TestPublishedMarkdownEndToEndUsesCurrentVersionAndChangesETag(t *testing.T) {
	db := publicGuidelineTestDB(t)
	store := &fakePublicStore{objects: make(map[string][]byte)}
	admin := GuidelineService{DB: db, Store: store}
	public := PublicGuidelineService{DB: db, Store: store}
	ctx := context.Background()

	document := models.GuidelineDocument{
		Title: "Malaria Management", Country: "Uganda", ProgramArea: "Infectious disease",
		Language: "en", Description: "Current care guidance",
	}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}

	draft := readyVersion(t, db, document.ID, "1.0", "guidelines/v1.md")
	if err := admin.UpdateMarkdown(ctx, draft.ID, []byte("# Draft guidance")); err != nil {
		t.Fatal(err)
	}
	if _, err := public.Markdown(ctx, document.ID); !errors.Is(err, ErrPublicGuidelineNotFound) {
		t.Fatalf("draft was public: %v", err)
	}
	if err := admin.PublishVersion(draft.ID, uuid.New()); err != nil {
		t.Fatal(err)
	}
	var draftManifest models.GuidelineVersionManifest
	if err := db.Where("version_id = ?", draft.ID).First(&draftManifest).Error; err != nil {
		t.Fatalf("published version manifest missing: %v", err)
	}
	if draftManifest.ExtractionQuality != models.GuidelineExtractionMarkdownFallback || !draftManifest.HasOriginalPDF {
		t.Fatalf("unexpected compatibility manifest: %#v", draftManifest)
	}

	first, err := public.Markdown(ctx, document.ID)
	if err != nil {
		t.Fatal(err)
	}
	if string(first.Content) != "# Draft guidance" {
		t.Fatalf("public endpoint did not return dashboard-saved Markdown: %q", first.Content)
	}

	next := readyVersion(t, db, document.ID, "2.0", "guidelines/v2.md")
	if err := admin.UpdateMarkdown(ctx, next.ID, []byte("# New published guidance")); err != nil {
		t.Fatal(err)
	}
	if _, err := public.Get(ctx, document.ID); err != nil {
		t.Fatalf("existing current publication disappeared while a new draft existed: %v", err)
	}
	if err := admin.PublishVersion(next.ID, uuid.New()); err != nil {
		t.Fatal(err)
	}

	second, err := public.Markdown(ctx, document.ID)
	if err != nil {
		t.Fatal(err)
	}
	if string(second.Content) != "# New published guidance" {
		t.Fatalf("expected current version, got %q", second.Content)
	}
	if first.ETag == second.ETag {
		t.Fatalf("publishing changed content did not change ETag: %s", first.ETag)
	}

	result, err := public.List(ctx, PublicGuidelineFilter{
		Search: "malaria", ProgramArea: "infectious disease",
		Page: PageInput{Page: 1, PerPage: 1},
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalItems != 1 || len(result.Items) != 1 || result.Items[0].Version != "2.0" {
		t.Fatalf("unexpected filtered listing: %#v", result)
	}

	if err := db.Model(&next).Update("status", "archived").Error; err != nil {
		t.Fatal(err)
	}
	if _, err := public.Get(ctx, document.ID); !errors.Is(err, ErrPublicGuidelineNotFound) {
		t.Fatalf("archived current version was exposed: %v", err)
	}
}

func publicGuidelineTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(
		&models.GuidelineDocument{},
		&models.GuidelineVersion{},
		&models.GuidelineSection{},
		&models.GuidelineChunk{},
		&models.GuidelineContentBlock{},
		&models.GuidelineAsset{},
		&models.GuidelineVersionManifest{},
		&models.IngestionJob{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}

func readyVersion(t *testing.T, db *gorm.DB, documentID uuid.UUID, version, markdownKey string) models.GuidelineVersion {
	t.Helper()
	row := models.GuidelineVersion{
		DocumentID:      documentID,
		Version:         version,
		Status:          "draft",
		OriginalFileKey: "guidelines/source.pdf",
		HTMLFileKey:     "guidelines/extracted.html",
		MarkdownFileKey: markdownKey,
	}
	if err := db.Create(&row).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.GuidelineSection{
		VersionID: row.ID, Title: "Care", SortOrder: 1,
	}).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.GuidelineChunk{
		DocumentID: documentID, VersionID: row.ID, Title: "Care", Content: "Guidance", ReviewStatus: "draft",
	}).Error; err != nil {
		t.Fatal(err)
	}
	return row
}
