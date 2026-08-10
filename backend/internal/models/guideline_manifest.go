package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	GuidelineManifestSchemaVersion = 1
	GuidelinePackageFormatVersion  = 1
)

type GuidelineExtractionQuality string

const (
	GuidelineExtractionReviewed          GuidelineExtractionQuality = "reviewed"
	GuidelineExtractionPartiallyReviewed GuidelineExtractionQuality = "partially_reviewed"
	GuidelineExtractionUnreviewed        GuidelineExtractionQuality = "unreviewed"
	GuidelineExtractionMarkdownFallback  GuidelineExtractionQuality = "markdown_fallback"
)

type GuidelineVersionManifest struct {
	Base
	GuidelineID       uuid.UUID                  `gorm:"type:uuid;not null;uniqueIndex:idx_guideline_manifest_document_version" json:"guideline_id"`
	VersionID         uuid.UUID                  `gorm:"type:uuid;not null;uniqueIndex;uniqueIndex:idx_guideline_manifest_document_version" json:"version_id"`
	Version           string                     `gorm:"not null" json:"version"`
	SchemaVersion     int                        `gorm:"not null;default:1" json:"schema_version"`
	PackageVersion    int                        `gorm:"not null;default:1" json:"package_version"`
	ExtractionQuality GuidelineExtractionQuality `gorm:"type:text;not null" json:"extraction_quality"`
	HasChapters       bool                       `gorm:"not null;default:false" json:"has_chapters"`
	HasKeyPoints      bool                       `gorm:"not null;default:false" json:"has_key_points"`
	HasTables         bool                       `gorm:"not null;default:false" json:"has_tables"`
	HasFigures        bool                       `gorm:"not null;default:false" json:"has_figures"`
	HasAlgorithms     bool                       `gorm:"not null;default:false" json:"has_algorithms"`
	HasOriginalPDF    bool                       `gorm:"not null;default:false" json:"has_original_pdf"`
	HasOfflinePackage bool                       `gorm:"not null;default:false" json:"has_offline_package"`
	SectionCount      int                        `gorm:"not null;default:0" json:"section_count"`
	BlockCount        int                        `gorm:"not null;default:0" json:"block_count"`
	TableCount        int                        `gorm:"not null;default:0" json:"table_count"`
	FigureCount       int                        `gorm:"not null;default:0" json:"figure_count"`
	AlgorithmCount    int                        `gorm:"not null;default:0" json:"algorithm_count"`
	Checksum          string                     `gorm:"not null" json:"checksum"`
	ETag              string                     `gorm:"column:etag;not null" json:"etag"`
	GeneratedAt       time.Time                  `gorm:"not null" json:"generated_at"`
}
