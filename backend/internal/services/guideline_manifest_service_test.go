package services

import (
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestGenerateGuidelineVersionManifestUsesReviewedContentOnly(t *testing.T) {
	db := guidelineManifestTestDB(t)
	document, version, sections := guidelineManifestFixture(t, db)
	reviewer := uuid.New()
	reviewedAt := time.Date(2026, 8, 10, 10, 0, 0, 0, time.UTC)

	blocks := []models.GuidelineContentBlock{
		reviewedBlock(version.ID, sections[0].ID, models.GuidelineBlockHeading, reviewer, reviewedAt),
		reviewedBlock(version.ID, sections[0].ID, models.GuidelineBlockKeyPoint, reviewer, reviewedAt),
		reviewedBlock(version.ID, sections[1].ID, models.GuidelineBlockTable, reviewer, reviewedAt),
		reviewedBlock(version.ID, sections[1].ID, models.GuidelineBlockFigure, reviewer, reviewedAt),
		reviewedBlock(version.ID, sections[1].ID, models.GuidelineBlockAlgorithm, reviewer, reviewedAt),
		{
			VersionID: version.ID, SectionID: &sections[1].ID, Type: models.GuidelineBlockTable,
			ContentJSON: []byte(`{"type":"table"}`), ReviewStatus: models.GuidelineBlockDraft,
		},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.GuidelineAsset{
		VersionID: version.ID, Type: models.GuidelineAssetOfflinePackage,
		MIMEType: "application/zip", Checksum: "package-checksum",
		StorageKey: "guidelines/version/offline.zip", SizeBytes: 2048,
	}).Error; err != nil {
		t.Fatal(err)
	}

	generatedAt := time.Date(2026, 8, 10, 11, 0, 0, 0, time.UTC)
	manifest, err := generateGuidelineVersionManifest(db, version.ID, generatedAt)
	if err != nil {
		t.Fatal(err)
	}

	if manifest.GuidelineID != document.ID || manifest.VersionID != version.ID || manifest.Version != "1.4" {
		t.Fatalf("unexpected manifest identity: %#v", manifest)
	}
	if manifest.ExtractionQuality != models.GuidelineExtractionPartiallyReviewed {
		t.Fatalf("unexpected quality: %s", manifest.ExtractionQuality)
	}
	if !manifest.HasChapters || !manifest.HasKeyPoints || !manifest.HasTables || !manifest.HasFigures || !manifest.HasAlgorithms {
		t.Fatalf("reviewed capabilities missing: %#v", manifest)
	}
	if !manifest.HasOriginalPDF || !manifest.HasOfflinePackage {
		t.Fatalf("asset capabilities missing: %#v", manifest)
	}
	if manifest.SectionCount != 2 || manifest.BlockCount != 5 || manifest.TableCount != 1 || manifest.FigureCount != 1 || manifest.AlgorithmCount != 1 {
		t.Fatalf("unexpected reviewed counts: %#v", manifest)
	}
	if len(manifest.Checksum) != 64 || manifest.ETag != `"sha256-`+manifest.Checksum+`"` {
		t.Fatalf("invalid cache identity: checksum=%q etag=%q", manifest.Checksum, manifest.ETag)
	}

	again, err := generateGuidelineVersionManifest(db, version.ID, generatedAt.Add(time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if again.Checksum != manifest.Checksum || again.ETag != manifest.ETag {
		t.Fatalf("generation time changed deterministic identity: %#v %#v", manifest, again)
	}
	var count int64
	if err := db.Model(&models.GuidelineVersionManifest{}).Where("version_id = ?", version.ID).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("expected one upserted manifest, got %d", count)
	}
}

func TestGenerateGuidelineVersionManifestHidesUnreviewedCapabilities(t *testing.T) {
	db := guidelineManifestTestDB(t)
	_, version, sections := guidelineManifestFixture(t, db)
	if err := db.Create(&models.GuidelineContentBlock{
		VersionID: version.ID, SectionID: &sections[0].ID, Type: models.GuidelineBlockAlgorithm,
		ContentJSON: []byte(`{"type":"algorithm"}`), ReviewStatus: models.GuidelineBlockDraft,
	}).Error; err != nil {
		t.Fatal(err)
	}

	manifest, err := generateGuidelineVersionManifest(db, version.ID, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if manifest.ExtractionQuality != models.GuidelineExtractionUnreviewed {
		t.Fatalf("unexpected quality: %s", manifest.ExtractionQuality)
	}
	if manifest.HasAlgorithms || manifest.HasChapters || manifest.BlockCount != 0 || manifest.AlgorithmCount != 0 {
		t.Fatalf("unreviewed content leaked into capabilities: %#v", manifest)
	}
}

func TestGenerateGuidelineVersionManifestRequiresPublishedVersion(t *testing.T) {
	db := guidelineManifestTestDB(t)
	_, version, _ := guidelineManifestFixture(t, db)
	if err := db.Model(&version).Update("status", "draft").Error; err != nil {
		t.Fatal(err)
	}
	if _, err := generateGuidelineVersionManifest(db, version.ID, time.Now().UTC()); err != ErrGuidelineManifestUnavailable {
		t.Fatalf("expected unavailable manifest error, got %v", err)
	}
}

func guidelineManifestTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(
		&models.GuidelineDocument{},
		&models.GuidelineVersion{},
		&models.GuidelineSection{},
		&models.GuidelineContentBlock{},
		&models.GuidelineAsset{},
		&models.GuidelineVersionManifest{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}

func guidelineManifestFixture(t *testing.T, db *gorm.DB) (models.GuidelineDocument, models.GuidelineVersion, []models.GuidelineSection) {
	t.Helper()
	document := models.GuidelineDocument{Title: "Malaria in Adults", Language: "en"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{
		DocumentID: document.ID, Version: "1.4", Status: "published",
		OriginalFileKey: "guidelines/version/original.pdf", MarkdownFileKey: "guidelines/version/content.md",
	}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	sections := []models.GuidelineSection{
		{VersionID: version.ID, Title: "Overview", Slug: "overview", SortOrder: 1},
		{VersionID: version.ID, Title: "Diagnosis", Slug: "diagnosis", SortOrder: 2},
	}
	if err := db.Create(&sections).Error; err != nil {
		t.Fatal(err)
	}
	return document, version, sections
}

func reviewedBlock(versionID, sectionID uuid.UUID, blockType models.GuidelineBlockType, reviewer uuid.UUID, reviewedAt time.Time) models.GuidelineContentBlock {
	payload := `{"type":"` + string(blockType) + `","text":"` + strings.ReplaceAll(string(blockType), "_", " ") + `"}`
	return models.GuidelineContentBlock{
		VersionID: versionID, SectionID: &sectionID, Type: blockType,
		ContentJSON: []byte(payload), ReviewStatus: models.GuidelineBlockReviewed,
		ReviewedBy: &reviewer, ReviewedAt: &reviewedAt,
	}
}
