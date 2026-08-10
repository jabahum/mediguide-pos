package services

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var ErrGuidelineManifestUnavailable = errors.New("guideline manifest is unavailable")

type guidelineTypeCount struct {
	Type  string
	Count int64
}

type guidelineReviewCount struct {
	ReviewStatus string
	Count        int64
}

type guidelineManifestChecksumPayload struct {
	GuidelineID       uuid.UUID                         `json:"guideline_id"`
	VersionID         uuid.UUID                         `json:"version_id"`
	Version           string                            `json:"version"`
	SchemaVersion     int                               `json:"schema_version"`
	PackageVersion    int                               `json:"package_version"`
	ExtractionQuality models.GuidelineExtractionQuality `json:"extraction_quality"`
	HasChapters       bool                              `json:"has_chapters"`
	HasKeyPoints      bool                              `json:"has_key_points"`
	HasTables         bool                              `json:"has_tables"`
	HasFigures        bool                              `json:"has_figures"`
	HasAlgorithms     bool                              `json:"has_algorithms"`
	HasOriginalPDF    bool                              `json:"has_original_pdf"`
	HasOfflinePackage bool                              `json:"has_offline_package"`
	SectionCount      int                               `json:"section_count"`
	BlockCount        int                               `json:"block_count"`
	TableCount        int                               `json:"table_count"`
	FigureCount       int                               `json:"figure_count"`
	AlgorithmCount    int                               `json:"algorithm_count"`
}

func (s GuidelineService) RegenerateManifest(versionID uuid.UUID) (*models.GuidelineVersionManifest, error) {
	var manifest *models.GuidelineVersionManifest
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var err error
		manifest, err = generateGuidelineVersionManifest(tx, versionID, time.Now().UTC())
		return err
	})
	if err != nil {
		return nil, err
	}
	s.invalidatePublishedCaches(context.Background())
	return manifest, nil
}

func generateGuidelineVersionManifest(tx *gorm.DB, versionID uuid.UUID, generatedAt time.Time) (*models.GuidelineVersionManifest, error) {
	var version models.GuidelineVersion
	if err := tx.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	if !strings.EqualFold(strings.TrimSpace(version.Status), "published") {
		return nil, ErrGuidelineManifestUnavailable
	}

	blockCounts, reviewCounts, sectionCount, err := guidelineManifestBlockCounts(tx, versionID)
	if err != nil {
		return nil, err
	}
	assetCounts, err := guidelineManifestAssetCounts(tx, versionID)
	if err != nil {
		return nil, err
	}

	reviewedCount := reviewCounts[string(models.GuidelineBlockReviewed)]
	totalBlocks := int64(0)
	for _, count := range reviewCounts {
		totalBlocks += count
	}
	quality := guidelineExtractionQuality(totalBlocks, reviewedCount)

	manifest := &models.GuidelineVersionManifest{
		GuidelineID:       version.DocumentID,
		VersionID:         version.ID,
		Version:           version.Version,
		SchemaVersion:     models.GuidelineManifestSchemaVersion,
		PackageVersion:    models.GuidelinePackageFormatVersion,
		ExtractionQuality: quality,
		HasChapters:       sectionCount > 0 || blockCounts[string(models.GuidelineBlockHeading)] > 0,
		HasKeyPoints:      blockCounts[string(models.GuidelineBlockKeyPoint)] > 0,
		HasTables:         blockCounts[string(models.GuidelineBlockTable)] > 0,
		HasFigures:        blockCounts[string(models.GuidelineBlockFigure)] > 0,
		HasAlgorithms:     blockCounts[string(models.GuidelineBlockAlgorithm)] > 0,
		HasOriginalPDF:    strings.TrimSpace(version.OriginalFileKey) != "" || assetCounts[string(models.GuidelineAssetOriginalPDF)] > 0,
		HasOfflinePackage: assetCounts[string(models.GuidelineAssetOfflinePackage)] > 0,
		SectionCount:      int(sectionCount),
		BlockCount:        int(reviewedCount),
		TableCount:        int(blockCounts[string(models.GuidelineBlockTable)]),
		FigureCount:       int(blockCounts[string(models.GuidelineBlockFigure)]),
		AlgorithmCount:    int(blockCounts[string(models.GuidelineBlockAlgorithm)]),
		GeneratedAt:       generatedAt.UTC(),
	}
	checksum, err := guidelineManifestChecksum(manifest)
	if err != nil {
		return nil, err
	}
	manifest.Checksum = checksum
	manifest.ETag = fmt.Sprintf(`"sha256-%s"`, checksum)

	err = tx.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "version_id"}},
		DoUpdates: clause.Assignments(map[string]any{
			"guideline_id":        manifest.GuidelineID,
			"version":             manifest.Version,
			"schema_version":      manifest.SchemaVersion,
			"package_version":     manifest.PackageVersion,
			"extraction_quality":  manifest.ExtractionQuality,
			"has_chapters":        manifest.HasChapters,
			"has_key_points":      manifest.HasKeyPoints,
			"has_tables":          manifest.HasTables,
			"has_figures":         manifest.HasFigures,
			"has_algorithms":      manifest.HasAlgorithms,
			"has_original_pdf":    manifest.HasOriginalPDF,
			"has_offline_package": manifest.HasOfflinePackage,
			"section_count":       manifest.SectionCount,
			"block_count":         manifest.BlockCount,
			"table_count":         manifest.TableCount,
			"figure_count":        manifest.FigureCount,
			"algorithm_count":     manifest.AlgorithmCount,
			"checksum":            manifest.Checksum,
			"etag":                manifest.ETag,
			"generated_at":        manifest.GeneratedAt,
			"updated_at":          manifest.GeneratedAt,
			"deleted_at":          nil,
		}),
	}).Create(manifest).Error
	if err != nil {
		return nil, err
	}

	var persisted models.GuidelineVersionManifest
	if err := tx.Where("version_id = ?", versionID).First(&persisted).Error; err != nil {
		return nil, err
	}
	return &persisted, nil
}

func guidelineManifestBlockCounts(tx *gorm.DB, versionID uuid.UUID) (map[string]int64, map[string]int64, int64, error) {
	typeCounts := []guidelineTypeCount{}
	if err := tx.Model(&models.GuidelineContentBlock{}).
		Select("type, COUNT(*) AS count").
		Where("version_id = ? AND deleted_at IS NULL AND review_status = ?", versionID, models.GuidelineBlockReviewed).
		Group("type").
		Scan(&typeCounts).Error; err != nil {
		return nil, nil, 0, err
	}

	reviews := []guidelineReviewCount{}
	if err := tx.Model(&models.GuidelineContentBlock{}).
		Select("review_status, COUNT(*) AS count").
		Where("version_id = ? AND deleted_at IS NULL", versionID).
		Group("review_status").
		Scan(&reviews).Error; err != nil {
		return nil, nil, 0, err
	}

	var sectionCount int64
	if err := tx.Model(&models.GuidelineContentBlock{}).
		Where("version_id = ? AND deleted_at IS NULL AND review_status = ? AND section_id IS NOT NULL", versionID, models.GuidelineBlockReviewed).
		Distinct("section_id").
		Count(&sectionCount).Error; err != nil {
		return nil, nil, 0, err
	}

	return guidelineCountMap(typeCounts), guidelineReviewCountMap(reviews), sectionCount, nil
}

func guidelineManifestAssetCounts(tx *gorm.DB, versionID uuid.UUID) (map[string]int64, error) {
	rows := []guidelineTypeCount{}
	if err := tx.Model(&models.GuidelineAsset{}).
		Select("type, COUNT(*) AS count").
		Where("version_id = ? AND deleted_at IS NULL", versionID).
		Group("type").
		Scan(&rows).Error; err != nil {
		return nil, err
	}
	return guidelineCountMap(rows), nil
}

func guidelineCountMap(rows []guidelineTypeCount) map[string]int64 {
	result := make(map[string]int64, len(rows))
	for _, row := range rows {
		result[row.Type] = row.Count
	}
	return result
}

func guidelineReviewCountMap(rows []guidelineReviewCount) map[string]int64 {
	result := make(map[string]int64, len(rows))
	for _, row := range rows {
		result[row.ReviewStatus] = row.Count
	}
	return result
}

func guidelineExtractionQuality(total, reviewed int64) models.GuidelineExtractionQuality {
	switch {
	case total == 0:
		return models.GuidelineExtractionMarkdownFallback
	case reviewed == total:
		return models.GuidelineExtractionReviewed
	case reviewed > 0:
		return models.GuidelineExtractionPartiallyReviewed
	default:
		return models.GuidelineExtractionUnreviewed
	}
}

func guidelineManifestChecksum(manifest *models.GuidelineVersionManifest) (string, error) {
	payload := guidelineManifestChecksumPayload{
		GuidelineID:       manifest.GuidelineID,
		VersionID:         manifest.VersionID,
		Version:           manifest.Version,
		SchemaVersion:     manifest.SchemaVersion,
		PackageVersion:    manifest.PackageVersion,
		ExtractionQuality: manifest.ExtractionQuality,
		HasChapters:       manifest.HasChapters,
		HasKeyPoints:      manifest.HasKeyPoints,
		HasTables:         manifest.HasTables,
		HasFigures:        manifest.HasFigures,
		HasAlgorithms:     manifest.HasAlgorithms,
		HasOriginalPDF:    manifest.HasOriginalPDF,
		HasOfflinePackage: manifest.HasOfflinePackage,
		SectionCount:      manifest.SectionCount,
		BlockCount:        manifest.BlockCount,
		TableCount:        manifest.TableCount,
		FigureCount:       manifest.FigureCount,
		AlgorithmCount:    manifest.AlgorithmCount,
	}
	content, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(content)
	return hex.EncodeToString(sum[:]), nil
}
