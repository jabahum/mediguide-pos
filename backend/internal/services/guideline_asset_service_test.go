package services

import (
	"context"
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func TestGuidelineAssetAuthoringLifecycleAndReferenceDetection(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "draft"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	store := &fakePublicStore{objects: map[string][]byte{}}
	service := GuidelineService{DB: db, Store: store}
	actor := uuid.New()
	alt := "Treatment pathway"
	sensitive := true
	png := append([]byte("\x89PNG\r\n\x1a\n"), make([]byte, 64)...)
	asset, err := service.CreateGuidelineAsset(context.Background(), version.ID, actor, "pathway.png", png, GuidelineAssetInput{AlternativeText: &alt, ClinicallySensitive: &sensitive}, "")
	if err != nil {
		t.Fatal(err)
	}
	if asset.AlternativeText != alt || asset.ReviewStatus != models.GuidelineBlockDraft || asset.URL == "" || asset.Reference != "guideline-asset://"+asset.ID.String() {
		t.Fatalf("unexpected asset projection: %#v", asset)
	}

	markdown := []byte("# Care\n\n![Treatment pathway](" + asset.Reference + ")\n\n![Missing](guideline-asset://" + uuid.NewString() + ")")
	key := "guidelines/revision.md"
	store.objects[key] = markdown
	revision := models.GuidelineMarkdownRevision{DocumentID: document.ID, VersionID: version.ID, RevisionNumber: 1, StorageKey: key, Checksum: "sum", SizeBytes: int64(len(markdown)), SourceType: "manual_edit", StructuredContentStatus: "outdated", ReviewState: "draft", PublicationState: "draft"}
	if err := db.Create(&revision).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&version).Update("current_markdown_revision_id", revision.ID).Error; err != nil {
		t.Fatal(err)
	}
	list, err := service.ListGuidelineAssets(context.Background(), version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Items) != 1 || !list.Items[0].Referenced || len(list.BrokenReferences) != 1 {
		t.Fatalf("unexpected reference status: %#v", list)
	}

	caption := "Reviewed figure"
	updated, err := service.UpdateGuidelineAsset(context.Background(), version.ID, asset.ID, actor, GuidelineAssetInput{Caption: &caption}, "")
	if err != nil || updated.Caption != caption {
		t.Fatalf("metadata update failed: %#v %v", updated, err)
	}
}

func TestGuidelineAssetRejectsUnsafeFormatsAndPublishedMutation(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "published"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	service := GuidelineService{DB: db, Store: &fakePublicStore{objects: map[string][]byte{}}}
	_, err := service.CreateGuidelineAsset(context.Background(), version.ID, uuid.New(), "unsafe.svg", []byte(`<svg><script>alert(1)</script></svg>`), GuidelineAssetInput{}, "")
	if !errors.Is(err, ErrPublishedVersionImmutable) {
		t.Fatalf("expected published version protection, got %v", err)
	}
	version.Status = "draft"
	if err := db.Save(&version).Error; err != nil {
		t.Fatal(err)
	}
	_, err = service.CreateGuidelineAsset(context.Background(), version.ID, uuid.New(), "unsafe.svg", []byte(`<svg xmlns="http://www.w3.org/2000/svg"/>`), GuidelineAssetInput{}, "")
	if !errors.Is(err, ErrGuidelineAssetInvalid) {
		t.Fatalf("expected SVG rejection, got %v", err)
	}
}
