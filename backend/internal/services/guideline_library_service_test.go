package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestGuidelineLibraryScopesCollectionsAndDownloadsToOwner(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.GuidelineDocument{}, &models.GuidelineVersion{}, &models.GuidelineCollection{}, &models.GuidelineCollectionItem{}, &models.GuidelineDownload{}); err != nil {
		t.Fatal(err)
	}
	owner, other := uuid.New(), uuid.New()
	for id, email := range map[uuid.UUID]string{owner: "owner@example.test", other: "other@example.test"} {
		if err := db.Create(&models.User{Base: models.Base{ID: id}, Name: "Reader", Email: email, PasswordHash: "hash"}).Error; err != nil {
			t.Fatal(err)
		}
	}
	document := models.GuidelineDocument{Title: "Care"}
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

	service := GuidelineLibraryService{DB: db}
	collection, err := service.CreateCollection(owner, GuidelineCollectionInput{Name: "Ward round"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.GetCollection(other, collection.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("other user read collection: %v", err)
	}
	if err := service.AddCollectionItem(other, collection.ID, GuidelineCollectionItemInput{GuidelineID: document.ID}); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("other user changed collection: %v", err)
	}
	if err := service.AddCollectionItem(owner, collection.ID, GuidelineCollectionItemInput{GuidelineID: document.ID}); err != nil {
		t.Fatal(err)
	}
	collectionItems, err := service.ListCollectionItems(owner, collection.ID, PageInput{})
	if err != nil || collectionItems.TotalItems != 1 || collectionItems.Items[0].Guideline.ID != document.ID {
		t.Fatalf("unexpected collection items: %#v %v", collectionItems, err)
	}
	owned, err := service.GetCollection(owner, collection.ID)
	if err != nil || owned.ItemCount != 1 {
		t.Fatalf("unexpected owned collection: %#v %v", owned, err)
	}
	if _, err := service.RecordDownload(owner, GuidelineDownloadInput{GuidelineID: document.ID, AssetType: string(models.GuidelineAssetOriginalPDF)}); err != nil {
		t.Fatal(err)
	}
	ownerDownloads, err := service.ListDownloads(owner, PageInput{}, "", "", "")
	if err != nil || ownerDownloads.TotalItems != 1 {
		t.Fatalf("missing owner download: %#v %v", ownerDownloads, err)
	}
	otherDownloads, err := service.ListDownloads(other, PageInput{}, "", "", "")
	if err != nil || otherDownloads.TotalItems != 0 {
		t.Fatalf("download leaked to other user: %#v %v", otherDownloads, err)
	}
}
