package services

import (
	"bytes"
	"context"
	"encoding/json"
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
func (f *fakePublicStore) PresignGet(_ context.Context, key string, _ time.Duration) (*url.URL, error) {
	f.mutex.Lock()
	f.key = key
	f.mutex.Unlock()
	return url.Parse("https://objects.example.test/" + key)
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

func TestPublicStructuredGuidelineExposesOnlyReviewedPublishedContent(t *testing.T) {
	db := publicGuidelineTestDB(t)
	store := &fakePublicStore{objects: map[string][]byte{}}
	document := models.GuidelineDocument{Title: "Emergency care"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "published", OriginalFileKey: "source/care.pdf"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	document.CurrentVersionID = &version.ID
	if err := db.Save(&document).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Assessment", Slug: "assessment", Level: 1}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	reviewer := uuid.New()
	reviewedAt := time.Now().UTC()
	reviewed := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Assess airway"}`), SourceFingerprint: "private-source", ProvenanceJSON: []byte(`{"page":7}`), ReviewStatus: models.GuidelineBlockReviewed, ReviewedBy: &reviewer, ReviewedAt: &reviewedAt}
	draft := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockWarning, SortOrder: 1, ContentJSON: []byte(`{"type":"warning","content":"DRAFT SECRET","severity":"high"}`), SourceFingerprint: "draft", ProvenanceJSON: []byte(`{}`), ReviewStatus: models.GuidelineBlockDraft}
	if err := db.Create(&[]models.GuidelineContentBlock{reviewed, draft}).Error; err != nil {
		t.Fatal(err)
	}
	manifest := models.GuidelineVersionManifest{GuidelineID: document.ID, VersionID: version.ID, Version: version.Version, SchemaVersion: 1, PackageVersion: 1, ExtractionQuality: models.GuidelineExtractionReviewed, HasChapters: true, SectionCount: 1, BlockCount: 1, Checksum: "safe", ETag: `"manifest-safe"`, GeneratedAt: reviewedAt}
	if err := db.Create(&manifest).Error; err != nil {
		t.Fatal(err)
	}

	service := PublicGuidelineService{DB: db, Store: store}
	sections, err := service.Sections(context.Background(), document.ID, PublicGuidelineContentQuery{})
	if err != nil || len(sections.Items) != 1 {
		t.Fatalf("unexpected sections: %#v %v", sections, err)
	}
	detail, err := service.Section(context.Background(), document.ID, section.ID)
	if err != nil {
		t.Fatal(err)
	}
	if len(detail.Blocks) != 1 || string(detail.Blocks[0].Content) == "" {
		t.Fatalf("draft content leaked or reviewed content missing: %#v", detail)
	}
	encoded, err := json.Marshal(detail)
	if err != nil {
		t.Fatal(err)
	}
	for _, forbidden := range []string{"DRAFT SECRET", "private-source", "provenance", "reviewed_by", "extraction_confidence"} {
		if bytes.Contains(encoded, []byte(forbidden)) {
			t.Fatalf("public content leaked %q: %s", forbidden, encoded)
		}
	}
	gotManifest, err := service.Manifest(context.Background(), document.ID)
	if err != nil || gotManifest.ETag != `"manifest-safe"` {
		t.Fatalf("unexpected manifest: %#v %v", gotManifest, err)
	}
	link, err := service.Original(context.Background(), document.ID)
	if err != nil || link.URL != "https://objects.example.test/source/care.pdf" {
		t.Fatalf("unexpected original link: %#v %v", link, err)
	}
}

func TestPublishedMarkdownEndToEndUsesCurrentVersionAndChangesETag(t *testing.T) {
	db := publicGuidelineTestDB(t)
	store := &fakePublicStore{objects: map[string][]byte{"guidelines/source.pdf": []byte("%PDF-test")}}
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
		&models.GuidelineMarkdownRevision{},
		&models.GuidelineSection{},
		&models.GuidelineChunk{},
		&models.GuidelineContentBlock{},
		&models.GuidelineTable{},
		&models.GuidelineAsset{},
		&models.GuidelineVersionManifest{},
		&models.IngestionJob{},
		&models.GuidelineRegenerationReview{},
		&models.GuidelineReviewComment{},
		&models.GuidelineReviewAssignment{},
		&models.GuidelineEditorComment{},
		&models.User{},
		&models.AuditLog{},
		&models.ClinicalProtocol{},
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
