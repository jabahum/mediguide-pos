package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type GuidelineBlockType string

const (
	GuidelineBlockHeading            GuidelineBlockType = "heading"
	GuidelineBlockParagraph          GuidelineBlockType = "paragraph"
	GuidelineBlockOrderedList        GuidelineBlockType = "ordered_list"
	GuidelineBlockUnorderedList      GuidelineBlockType = "unordered_list"
	GuidelineBlockTable              GuidelineBlockType = "table"
	GuidelineBlockFigure             GuidelineBlockType = "figure"
	GuidelineBlockRecommendation     GuidelineBlockType = "recommendation"
	GuidelineBlockWarning            GuidelineBlockType = "warning"
	GuidelineBlockCaution            GuidelineBlockType = "caution"
	GuidelineBlockKeyPoint           GuidelineBlockType = "key_point"
	GuidelineBlockContraindication   GuidelineBlockType = "contraindication"
	GuidelineBlockDosage             GuidelineBlockType = "dosage"
	GuidelineBlockEvidence           GuidelineBlockType = "evidence"
	GuidelineBlockDefinition         GuidelineBlockType = "definition"
	GuidelineBlockProcedure          GuidelineBlockType = "procedure"
	GuidelineBlockClinicalNote       GuidelineBlockType = "clinical_note"
	GuidelineBlockReferralCriteria   GuidelineBlockType = "referral_criteria"
	GuidelineBlockAlgorithmReference GuidelineBlockType = "algorithm_reference"
	GuidelineBlockAlgorithm          GuidelineBlockType = "algorithm"
	GuidelineBlockReference          GuidelineBlockType = "reference"
	GuidelineBlockPageBreak          GuidelineBlockType = "page_break"
	GuidelineBlockUnknown            GuidelineBlockType = "unknown"
)

type GuidelineBlockReviewStatus string

const (
	GuidelineBlockDraft    GuidelineBlockReviewStatus = "draft"
	GuidelineBlockReviewed GuidelineBlockReviewStatus = "reviewed"
	GuidelineBlockRejected GuidelineBlockReviewStatus = "rejected"
)

type GuidelineContentBlock struct {
	Base
	VersionID            uuid.UUID                  `gorm:"type:uuid;index;not null" json:"version_id"`
	SectionID            *uuid.UUID                 `gorm:"type:uuid;index" json:"section_id,omitempty"`
	Type                 GuidelineBlockType         `gorm:"type:text;not null" json:"type"`
	SortOrder            int                        `gorm:"not null;default:0" json:"sort_order"`
	ContentJSON          json.RawMessage            `gorm:"column:content_json;type:jsonb;not null" json:"content" swaggertype:"object"`
	SourceFingerprint    string                     `gorm:"not null" json:"source_fingerprint"`
	ProvenanceJSON       datatypes.JSON             `gorm:"column:provenance_json;type:jsonb;not null;default:'{}'" json:"provenance" swaggertype:"object"`
	PageStart            *int                       `json:"page_start,omitempty"`
	PageEnd              *int                       `json:"page_end,omitempty"`
	ExtractionConfidence *float64                   `json:"extraction_confidence,omitempty"`
	ReviewStatus         GuidelineBlockReviewStatus `gorm:"type:text;not null;default:'draft';index" json:"review_status"`
	ReviewedBy           *uuid.UUID                 `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt           *time.Time                 `json:"reviewed_at,omitempty"`
}

type GuidelineAssetType string

const (
	GuidelineAssetOriginalPDF           GuidelineAssetType = "original_pdf"
	GuidelineAssetFigure                GuidelineAssetType = "figure"
	GuidelineAssetDiagram               GuidelineAssetType = "diagram"
	GuidelineAssetThumbnail             GuidelineAssetType = "thumbnail"
	GuidelineAssetSupplementaryDocument GuidelineAssetType = "supplementary_document"
	GuidelineAssetOfflinePackage        GuidelineAssetType = "offline_package"
)

type GuidelineAsset struct {
	Base
	VersionID           uuid.UUID                  `gorm:"type:uuid;index;not null" json:"version_id"`
	SectionID           *uuid.UUID                 `gorm:"type:uuid;index" json:"section_id,omitempty"`
	Type                GuidelineAssetType         `gorm:"type:text;not null" json:"type"`
	MIMEType            string                     `gorm:"not null" json:"mime_type"`
	Checksum            string                     `gorm:"not null" json:"checksum"`
	StorageKey          string                     `gorm:"not null" json:"-"`
	SizeBytes           int64                      `gorm:"not null" json:"size_bytes"`
	OriginalFilename    *string                    `json:"original_filename,omitempty"`
	AlternativeText     string                     `json:"alternative_text"`
	Caption             string                     `json:"caption"`
	Source              string                     `json:"source"`
	Attribution         string                     `json:"attribution"`
	License             string                     `json:"license"`
	FigureNumber        *int                       `json:"figure_number,omitempty"`
	ClinicallySensitive bool                       `json:"clinically_sensitive"`
	UploadedBy          *uuid.UUID                 `gorm:"type:uuid" json:"uploaded_by,omitempty"`
	SourceFingerprint   string                     `gorm:"not null" json:"source_fingerprint"`
	ProvenanceJSON      datatypes.JSON             `gorm:"column:provenance_json;type:jsonb;not null;default:'{}'" json:"provenance" swaggertype:"object"`
	PageStart           *int                       `json:"page_start,omitempty"`
	PageEnd             *int                       `json:"page_end,omitempty"`
	ReviewStatus        GuidelineBlockReviewStatus `gorm:"type:text;not null;default:'draft';index" json:"review_status"`
	ReviewedBy          *uuid.UUID                 `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt          *time.Time                 `json:"reviewed_at,omitempty"`
}

type GuidelineTextBlockPayload struct {
	Type GuidelineBlockType `json:"type"`
	Text string             `json:"text"`
}

type GuidelineHeadingBlockPayload struct {
	Type  GuidelineBlockType `json:"type"`
	Text  string             `json:"text"`
	Level int                `json:"level"`
}

type GuidelineListBlockPayload struct {
	Type  GuidelineBlockType `json:"type"`
	Items []string           `json:"items"`
}

type GuidelineTableBlockPayload struct {
	Type      GuidelineBlockType `json:"type"`
	Title     string             `json:"title,omitempty"`
	Columns   []string           `json:"columns"`
	Rows      [][]string         `json:"rows"`
	Footnotes []string           `json:"footnotes"`
}

type GuidelineFigureBlockPayload struct {
	Type            GuidelineBlockType `json:"type"`
	AssetID         uuid.UUID          `json:"asset_id"`
	Caption         string             `json:"caption,omitempty"`
	AlternativeText string             `json:"alternative_text"`
}

type GuidelineCalloutBlockPayload struct {
	Type          GuidelineBlockType `json:"type"`
	Title         string             `json:"title,omitempty"`
	Content       string             `json:"content"`
	Severity      string             `json:"severity,omitempty"`
	EvidenceGrade string             `json:"evidence_grade,omitempty"`
	Source        string             `json:"source,omitempty"`
}

type GuidelineAlgorithmNode struct {
	ID    string   `json:"id"`
	Label string   `json:"label"`
	Kind  string   `json:"kind"`
	Next  []string `json:"next,omitempty"`
}

type GuidelineAlgorithmBlockPayload struct {
	Type  GuidelineBlockType       `json:"type"`
	Title string                   `json:"title,omitempty"`
	Nodes []GuidelineAlgorithmNode `json:"nodes"`
}

type GuidelineReferenceBlockPayload struct {
	Type     GuidelineBlockType `json:"type"`
	Citation string             `json:"citation"`
	URL      string             `json:"url,omitempty"`
}

type GuidelinePageBreakBlockPayload struct {
	Type GuidelineBlockType `json:"type"`
	Page int                `json:"page"`
}
