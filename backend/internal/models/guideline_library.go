package models

import (
	"time"

	"github.com/google/uuid"
)

type GuidelineCollection struct {
	Base
	UserID      uuid.UUID `gorm:"type:uuid;not null;index" json:"user_id"`
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
}

type GuidelineCollectionItem struct {
	Base
	CollectionID uuid.UUID `gorm:"type:uuid;not null;index" json:"collection_id"`
	GuidelineID  uuid.UUID `gorm:"type:uuid;not null;index" json:"guideline_id"`
	SortOrder    int       `gorm:"not null;default:0" json:"sort_order"`
}

type GuidelineDownload struct {
	Base
	UserID       uuid.UUID `gorm:"type:uuid;not null;index" json:"user_id"`
	GuidelineID  uuid.UUID `gorm:"type:uuid;not null;index" json:"guideline_id"`
	VersionID    uuid.UUID `gorm:"type:uuid;not null;index" json:"version_id"`
	AssetType    string    `gorm:"type:text;not null" json:"asset_type"`
	DownloadedAt time.Time `gorm:"not null;index" json:"downloaded_at"`
}
