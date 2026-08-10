package services

import (
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrGuidelineLibraryInvalid  = errors.New("invalid guideline library request")
	ErrGuidelineLibraryConflict = errors.New("guideline library conflict")
)

type GuidelineLibraryService struct{ DB *gorm.DB }

type GuidelineCollectionDTO struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	ItemCount   int64     `json:"item_count"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type GuidelineCollectionInput struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

type GuidelineCollectionItemInput struct {
	GuidelineID uuid.UUID `json:"guideline_id" binding:"required"`
	SortOrder   int       `json:"sort_order"`
}

type GuidelineCollectionItemDTO struct {
	ID        uuid.UUID       `json:"id"`
	Guideline PublicGuideline `json:"guideline"`
	SortOrder int             `json:"sort_order"`
	AddedAt   time.Time       `json:"added_at"`
}

type GuidelineDownloadInput struct {
	GuidelineID uuid.UUID `json:"guideline_id" binding:"required"`
	AssetType   string    `json:"asset_type" binding:"required"`
}

type GuidelineDownloadDTO struct {
	ID           uuid.UUID `json:"id"`
	GuidelineID  uuid.UUID `json:"guideline_id"`
	VersionID    uuid.UUID `json:"version_id"`
	AssetType    string    `json:"asset_type"`
	DownloadedAt time.Time `json:"downloaded_at"`
}

func (s GuidelineLibraryService) ListCollections(userID uuid.UUID, page PageInput, sortValue, orderValue string) (*PageResult[GuidelineCollectionDTO], error) {
	p := page.Normalize(20, 100)
	order, err := publicOrder(sortValue, orderValue, map[string]string{"name": "gc.name", "created_at": "gc.created_at", "updated_at": "gc.updated_at"}, "gc.updated_at DESC")
	if err != nil {
		return nil, ErrGuidelineLibraryInvalid
	}
	base := s.DB.Table("guideline_collections AS gc").Where("gc.user_id = ? AND gc.deleted_at IS NULL", userID)
	var total int64
	if err := base.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []GuidelineCollectionDTO
	err = base.Session(&gorm.Session{}).Select(`gc.id, gc.name, gc.description, gc.created_at, gc.updated_at,
		(SELECT COUNT(*) FROM guideline_collection_items item WHERE item.collection_id = gc.id AND item.deleted_at IS NULL) AS item_count`).
		Order(order).Limit(p.PerPage).Offset(p.Offset()).Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	return NewPageResult(rows, p, total), nil
}

func (s GuidelineLibraryService) GetCollection(userID, id uuid.UUID) (*GuidelineCollectionDTO, error) {
	var row GuidelineCollectionDTO
	err := s.DB.Table("guideline_collections AS gc").Where("gc.id = ? AND gc.user_id = ? AND gc.deleted_at IS NULL", id, userID).
		Select(`gc.id, gc.name, gc.description, gc.created_at, gc.updated_at,
		(SELECT COUNT(*) FROM guideline_collection_items item WHERE item.collection_id = gc.id AND item.deleted_at IS NULL) AS item_count`).Take(&row).Error
	return &row, err
}

func (s GuidelineLibraryService) CreateCollection(userID uuid.UUID, in GuidelineCollectionInput) (*GuidelineCollectionDTO, error) {
	name := strings.TrimSpace(in.Name)
	if name == "" || len(name) > 120 || len(in.Description) > 1000 {
		return nil, ErrGuidelineLibraryInvalid
	}
	var duplicate int64
	if err := s.DB.Model(&models.GuidelineCollection{}).Where("user_id = ? AND lower(name) = ?", userID, strings.ToLower(name)).Count(&duplicate).Error; err != nil {
		return nil, err
	}
	if duplicate > 0 {
		return nil, ErrGuidelineLibraryConflict
	}
	row := models.GuidelineCollection{UserID: userID, Name: name, Description: strings.TrimSpace(in.Description)}
	if err := s.DB.Create(&row).Error; err != nil {
		return nil, err
	}
	return collectionDTO(row, 0), nil
}

func (s GuidelineLibraryService) UpdateCollection(userID, id uuid.UUID, in GuidelineCollectionInput) (*GuidelineCollectionDTO, error) {
	name := strings.TrimSpace(in.Name)
	if name == "" || len(name) > 120 || len(in.Description) > 1000 {
		return nil, ErrGuidelineLibraryInvalid
	}
	result := s.DB.Model(&models.GuidelineCollection{}).Where("id = ? AND user_id = ?", id, userID).Updates(map[string]any{"name": name, "description": strings.TrimSpace(in.Description)})
	if result.Error != nil {
		return nil, result.Error
	}
	if result.RowsAffected == 0 {
		return nil, gorm.ErrRecordNotFound
	}
	return s.GetCollection(userID, id)
}

func (s GuidelineLibraryService) DeleteCollection(userID, id uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.GuidelineCollection
		if err := tx.Where("id = ? AND user_id = ?", id, userID).First(&row).Error; err != nil {
			return err
		}
		if err := tx.Where("collection_id = ?", id).Delete(&models.GuidelineCollectionItem{}).Error; err != nil {
			return err
		}
		return tx.Delete(&row).Error
	})
}

func (s GuidelineLibraryService) AddCollectionItem(userID, collectionID uuid.UUID, in GuidelineCollectionItemInput) error {
	if in.GuidelineID == uuid.Nil || in.SortOrder < 0 {
		return ErrGuidelineLibraryInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var owned int64
		if err := tx.Model(&models.GuidelineCollection{}).Where("id = ? AND user_id = ?", collectionID, userID).Count(&owned).Error; err != nil {
			return err
		}
		if owned != 1 {
			return gorm.ErrRecordNotFound
		}
		if err := requirePublishedGuidelineDocument(tx, in.GuidelineID, nil); err != nil {
			return err
		}
		var existing models.GuidelineCollectionItem
		err := tx.Unscoped().Where("collection_id = ? AND guideline_id = ?", collectionID, in.GuidelineID).First(&existing).Error
		if err == nil {
			return tx.Unscoped().Model(&existing).Updates(map[string]any{"deleted_at": nil, "sort_order": in.SortOrder}).Error
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		return tx.Create(&models.GuidelineCollectionItem{CollectionID: collectionID, GuidelineID: in.GuidelineID, SortOrder: in.SortOrder}).Error
	})
}

func (s GuidelineLibraryService) ListCollectionItems(userID, collectionID uuid.UUID, page PageInput) (*PageResult[GuidelineCollectionItemDTO], error) {
	p := page.Normalize(20, 100)
	var owned int64
	if err := s.DB.Model(&models.GuidelineCollection{}).Where("id = ? AND user_id = ?", collectionID, userID).Count(&owned).Error; err != nil {
		return nil, err
	}
	if owned != 1 {
		return nil, gorm.ErrRecordNotFound
	}
	base := s.DB.Table("guideline_collection_items AS item").
		Joins("JOIN guideline_documents gd ON gd.id = item.guideline_id AND gd.deleted_at IS NULL").
		Joins("JOIN guideline_versions gv ON gv.id = gd.current_version_id AND gv.deleted_at IS NULL AND lower(gv.status) = 'published'").
		Where("item.collection_id = ? AND item.deleted_at IS NULL", collectionID)
	var total int64
	if err := base.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	type collectionItemRow struct {
		ItemID          uuid.UUID `gorm:"column:item_id"`
		ItemSortOrder   int       `gorm:"column:item_sort_order"`
		ItemCreatedAt   time.Time `gorm:"column:item_created_at"`
		GuidelineID     uuid.UUID `gorm:"column:guideline_id"`
		Title           string
		Description     string
		Country         string
		SourceOrg       string
		ProgramArea     string
		Language        string
		PublicationDate string
		ReviewDate      string
		Version         string
		VersionUpdated  time.Time
	}
	var rows []collectionItemRow
	selectColumns := `item.id AS item_id, item.sort_order AS item_sort_order, item.created_at AS item_created_at,
		gd.id AS guideline_id, gd.title, gd.description, gd.country, gd.source_org, gd.program_area, gd.language,
		gv.publication_date, gv.review_date, gv.version, gv.updated_at AS version_updated`
	if err := base.Session(&gorm.Session{}).Select(selectColumns).Order("item.sort_order ASC, item.created_at ASC").Limit(p.PerPage).Offset(p.Offset()).Scan(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]GuidelineCollectionItemDTO, 0, len(rows))
	for _, row := range rows {
		guideline := publicGuidelineRow{ID: row.GuidelineID, Title: row.Title, Description: row.Description, Country: row.Country, SourceOrg: row.SourceOrg, ProgramArea: row.ProgramArea, Language: row.Language, PublicationDate: row.PublicationDate, ReviewDate: row.ReviewDate, Version: row.Version, VersionUpdated: row.VersionUpdated}.public()
		items = append(items, GuidelineCollectionItemDTO{ID: row.ItemID, Guideline: guideline, SortOrder: row.ItemSortOrder, AddedAt: row.ItemCreatedAt})
	}
	return NewPageResult(items, p, total), nil
}

func (s GuidelineLibraryService) RemoveCollectionItem(userID, collectionID, guidelineID uuid.UUID) error {
	result := s.DB.Where("collection_id = ? AND guideline_id = ? AND EXISTS (SELECT 1 FROM guideline_collections gc WHERE gc.id = collection_id AND gc.user_id = ? AND gc.deleted_at IS NULL)", collectionID, guidelineID, userID).Delete(&models.GuidelineCollectionItem{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s GuidelineLibraryService) RecordDownload(userID uuid.UUID, in GuidelineDownloadInput) (*GuidelineDownloadDTO, error) {
	if in.GuidelineID == uuid.Nil || (in.AssetType != string(models.GuidelineAssetOriginalPDF) && in.AssetType != string(models.GuidelineAssetOfflinePackage)) {
		return nil, ErrGuidelineLibraryInvalid
	}
	var versionID uuid.UUID
	if err := requirePublishedGuidelineDocument(s.DB, in.GuidelineID, &versionID); err != nil {
		return nil, err
	}
	var available int64
	if in.AssetType == string(models.GuidelineAssetOriginalPDF) {
		if err := s.DB.Model(&models.GuidelineVersion{}).Where("id = ? AND original_file_key <> ''", versionID).Count(&available).Error; err != nil {
			return nil, err
		}
	} else if err := s.DB.Model(&models.GuidelineAsset{}).Where("version_id = ? AND type = ? AND review_status = ? AND storage_key <> ''", versionID, models.GuidelineAssetOfflinePackage, models.GuidelineBlockReviewed).Count(&available).Error; err != nil {
		return nil, err
	}
	if available == 0 {
		return nil, gorm.ErrRecordNotFound
	}
	now := time.Now().UTC()
	row := models.GuidelineDownload{UserID: userID, GuidelineID: in.GuidelineID, VersionID: versionID, AssetType: in.AssetType, DownloadedAt: now}
	if err := s.DB.Create(&row).Error; err != nil {
		return nil, err
	}
	return downloadDTO(row), nil
}

func (s GuidelineLibraryService) ListDownloads(userID uuid.UUID, page PageInput, assetType, sortValue, orderValue string) (*PageResult[GuidelineDownloadDTO], error) {
	p := page.Normalize(20, 100)
	order, err := publicOrder(sortValue, orderValue, map[string]string{"downloaded_at": "downloaded_at", "asset_type": "asset_type"}, "downloaded_at DESC")
	if err != nil {
		return nil, ErrGuidelineLibraryInvalid
	}
	q := s.DB.Model(&models.GuidelineDownload{}).Where("user_id = ?", userID)
	if assetType != "" {
		if assetType != string(models.GuidelineAssetOriginalPDF) && assetType != string(models.GuidelineAssetOfflinePackage) {
			return nil, ErrGuidelineLibraryInvalid
		}
		q = q.Where("asset_type = ?", assetType)
	}
	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.GuidelineDownload
	if err := q.Session(&gorm.Session{}).Order(order).Limit(p.PerPage).Offset(p.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]GuidelineDownloadDTO, 0, len(rows))
	for _, row := range rows {
		items = append(items, *downloadDTO(row))
	}
	return NewPageResult(items, p, total), nil
}

func requirePublishedGuidelineDocument(db *gorm.DB, guidelineID uuid.UUID, versionID *uuid.UUID) error {
	var row struct{ ID string }
	err := db.Table("guideline_documents AS gd").Joins("JOIN guideline_versions gv ON gv.id = gd.current_version_id AND gv.deleted_at IS NULL").
		Where("gd.id = ? AND gd.deleted_at IS NULL AND lower(gv.status) = 'published'", guidelineID).Select("CAST(gv.id AS TEXT) AS id").Take(&row).Error
	if err != nil {
		return err
	}
	value, err := uuid.Parse(row.ID)
	if err != nil || value == uuid.Nil {
		return gorm.ErrRecordNotFound
	}
	if versionID != nil {
		*versionID = value
	}
	return nil
}

func collectionDTO(row models.GuidelineCollection, count int64) *GuidelineCollectionDTO {
	return &GuidelineCollectionDTO{ID: row.ID, Name: row.Name, Description: row.Description, ItemCount: count, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}
}
func downloadDTO(row models.GuidelineDownload) *GuidelineDownloadDTO {
	return &GuidelineDownloadDTO{ID: row.ID, GuidelineID: row.GuidelineID, VersionID: row.VersionID, AssetType: row.AssetType, DownloadedAt: row.DownloadedAt}
}
