package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type Outbreak struct {
	Base
	Title              string         `json:"title"`
	DiseaseType        string         `json:"disease_type"`
	Status             string         `json:"status"`
	GeographicArea     string         `json:"geographic_area"`
	RegionID           *uuid.UUID     `gorm:"type:uuid;index" json:"region_id,omitempty"`
	DistrictID         *uuid.UUID     `gorm:"type:uuid;index" json:"district_id,omitempty"`
	Summary            string         `json:"summary"`
	StartDate          *time.Time     `json:"start_date,omitempty"`
	LastUpdate         time.Time      `json:"last_update"`
	VisualTone         string         `json:"visual_tone"`
	SourceOrganization string         `json:"source_organization"`
	PublishedAt        *time.Time     `json:"published_at,omitempty"`
	AuthorID           *uuid.UUID     `gorm:"type:uuid;index" json:"author_id,omitempty"`
	ReviewedBy         *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt         *time.Time     `json:"reviewed_at,omitempty"`
	ApprovedBy         *uuid.UUID     `gorm:"type:uuid" json:"approved_by,omitempty"`
	ApprovedAt         *time.Time     `json:"approved_at,omitempty"`
	WithdrawnAt        *time.Time     `json:"withdrawn_at,omitempty"`
	WithdrawalReason   string         `json:"withdrawal_reason,omitempty"`
	SupersedesID       *uuid.UUID     `gorm:"type:uuid;index" json:"supersedes_id,omitempty"`
	SourceURL          string         `json:"source_url,omitempty"`
	SourceReference    string         `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time     `json:"effective_at,omitempty"`
	DataAsOf           *time.Time     `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time     `json:"last_verified_at,omitempty"`
	LockVersion        int            `gorm:"not null;default:1" json:"lock_version"`
	Metrics            datatypes.JSON `gorm:"type:jsonb" json:"metrics" swaggertype:"array,object"`
}

type OutbreakUpdate struct {
	Base
	OutbreakID       uuid.UUID  `gorm:"type:uuid;index" json:"outbreak_id"`
	Title            string     `json:"title"`
	Summary          string     `json:"summary"`
	Status           string     `json:"status"`
	PublishedAt      *time.Time `json:"published_at,omitempty"`
	AuthorID         *uuid.UUID `gorm:"type:uuid;index" json:"author_id,omitempty"`
	ReviewedBy       *uuid.UUID `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt       *time.Time `json:"reviewed_at,omitempty"`
	ApprovedBy       *uuid.UUID `gorm:"type:uuid" json:"approved_by,omitempty"`
	ApprovedAt       *time.Time `json:"approved_at,omitempty"`
	WithdrawnAt      *time.Time `json:"withdrawn_at,omitempty"`
	WithdrawalReason string     `json:"withdrawal_reason,omitempty"`
	SupersedesID     *uuid.UUID `gorm:"type:uuid;index" json:"supersedes_id,omitempty"`
	LockVersion      int        `gorm:"not null;default:1" json:"lock_version"`
}

type OutbreakResource struct {
	Base
	OutbreakID       uuid.UUID  `gorm:"type:uuid;index" json:"outbreak_id"`
	Title            string     `json:"title"`
	Description      string     `json:"description"`
	ResourceType     string     `json:"resource_type"`
	DocumentKind     string     `json:"document_kind"`
	IssuingAuthority string     `json:"issuing_authority"`
	DocumentNumber   string     `json:"document_number"`
	Version          string     `json:"version"`
	Language         string     `json:"language"`
	Audience         string     `json:"audience"`
	EffectiveDate    *time.Time `json:"effective_date,omitempty"`
	ReviewDate       *time.Time `json:"review_date,omitempty"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty"`
	StorageKey       string     `json:"-"`
	OriginalFilename string     `json:"original_filename,omitempty"`
	MIMEType         string     `json:"mime_type,omitempty"`
	FileSize         int64      `json:"file_size"`
	ChecksumSHA256   string     `json:"checksum_sha256,omitempty"`
	PageCount        *int       `json:"page_count,omitempty"`
	URL              string     `json:"url"`
	AssetURL         string     `json:"asset_url"`
	SortOrder        int        `json:"sort_order"`
	Status           string     `json:"status"`
	PublishedAt      *time.Time `json:"published_at,omitempty"`
	AuthorID         *uuid.UUID `gorm:"type:uuid;index" json:"author_id,omitempty"`
	ReviewedBy       *uuid.UUID `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt       *time.Time `json:"reviewed_at,omitempty"`
	ApprovedBy       *uuid.UUID `gorm:"type:uuid" json:"approved_by,omitempty"`
	ApprovedAt       *time.Time `json:"approved_at,omitempty"`
	WithdrawnAt      *time.Time `json:"withdrawn_at,omitempty"`
	WithdrawalReason string     `json:"withdrawal_reason,omitempty"`
	SupersedesID     *uuid.UUID `gorm:"type:uuid;index" json:"supersedes_id,omitempty"`
	LockVersion      int        `gorm:"not null;default:1" json:"lock_version"`
}

type SituationReport struct {
	Base
	OutbreakID         *uuid.UUID     `gorm:"type:uuid;index" json:"outbreak_id,omitempty"`
	Title              string         `json:"title"`
	GeographicArea     string         `json:"geographic_area"`
	RegionID           *uuid.UUID     `gorm:"type:uuid;index" json:"region_id,omitempty"`
	DistrictID         *uuid.UUID     `gorm:"type:uuid;index" json:"district_id,omitempty"`
	Summary            string         `json:"summary"`
	SourceOrganization string         `json:"source_organization"`
	PublicationDate    time.Time      `json:"publication_date"`
	Status             string         `json:"status"`
	ReportAssetURL     string         `json:"report_asset_url"`
	ReportAssetID      *uuid.UUID     `gorm:"type:uuid;index" json:"report_asset_id,omitempty"`
	StandaloneAllowed  bool           `json:"standalone_allowed"`
	AuthorID           *uuid.UUID     `gorm:"type:uuid;index" json:"author_id,omitempty"`
	PublishedAt        *time.Time     `json:"published_at,omitempty"`
	ReviewedBy         *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt         *time.Time     `json:"reviewed_at,omitempty"`
	ApprovedBy         *uuid.UUID     `gorm:"type:uuid" json:"approved_by,omitempty"`
	ApprovedAt         *time.Time     `json:"approved_at,omitempty"`
	WithdrawnAt        *time.Time     `json:"withdrawn_at,omitempty"`
	WithdrawalReason   string         `json:"withdrawal_reason,omitempty"`
	CorrectionReason   string         `json:"correction_reason,omitempty"`
	SupersedesID       *uuid.UUID     `gorm:"type:uuid;index" json:"supersedes_id,omitempty"`
	SourceURL          string         `json:"source_url,omitempty"`
	SourceReference    string         `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time     `json:"effective_at,omitempty"`
	DataAsOf           *time.Time     `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time     `json:"last_verified_at,omitempty"`
	LockVersion        int            `gorm:"not null;default:1" json:"lock_version"`
	KeyHighlights      datatypes.JSON `gorm:"type:jsonb" json:"key_highlights" swaggertype:"array,string"`
	Metrics            datatypes.JSON `gorm:"type:jsonb" json:"metrics" swaggertype:"array,object"`
}

type SituationReportAsset struct {
	Base
	SituationReportID uuid.UUID  `gorm:"type:uuid;index" json:"situation_report_id"`
	StorageKey        string     `gorm:"uniqueIndex" json:"-"`
	FileName          string     `json:"file_name"`
	ContentType       string     `json:"content_type"`
	SizeBytes         int64      `json:"size_bytes"`
	ChecksumSHA256    string     `json:"checksum_sha256"`
	UploadedBy        *uuid.UUID `gorm:"type:uuid" json:"uploaded_by,omitempty"`
}
