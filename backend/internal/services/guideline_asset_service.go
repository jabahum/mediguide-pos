package services

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

const (
	maxGuidelineImageBytes         = 10 << 20
	maxGuidelineAssetMarkdownBytes = 20 << 20
	guidelineAssetURLTTL           = 10 * time.Minute
)

var (
	ErrGuidelineAssetInvalid = errors.New("invalid guideline asset")
	assetReferencePattern    = regexp.MustCompile(`guideline-asset://([0-9a-fA-F-]{36})`)
)

type GuidelineAssetInput struct {
	AlternativeText     *string `json:"alternative_text" form:"alternative_text"`
	Caption             *string `json:"caption" form:"caption"`
	Source              *string `json:"source" form:"source"`
	Attribution         *string `json:"attribution" form:"attribution"`
	License             *string `json:"license" form:"license"`
	FigureNumber        *int    `json:"figure_number" form:"figure_number"`
	ClinicallySensitive *bool   `json:"clinically_sensitive" form:"clinically_sensitive"`
}

type GuidelineAssetDTO struct {
	ID                  uuid.UUID                         `json:"id"`
	VersionID           uuid.UUID                         `json:"version_id"`
	Type                models.GuidelineAssetType         `json:"type"`
	MIMEType            string                            `json:"mime_type"`
	Checksum            string                            `json:"checksum"`
	SizeBytes           int64                             `json:"size_bytes"`
	OriginalFilename    string                            `json:"original_filename"`
	AlternativeText     string                            `json:"alternative_text"`
	Caption             string                            `json:"caption"`
	Source              string                            `json:"source"`
	Attribution         string                            `json:"attribution"`
	License             string                            `json:"license"`
	FigureNumber        *int                              `json:"figure_number,omitempty"`
	ClinicallySensitive bool                              `json:"clinically_sensitive"`
	ReviewStatus        models.GuidelineBlockReviewStatus `json:"review_status"`
	ReviewedBy          *uuid.UUID                        `json:"reviewed_by,omitempty"`
	ReviewedAt          *time.Time                        `json:"reviewed_at,omitempty"`
	UploadedBy          *uuid.UUID                        `json:"uploaded_by,omitempty"`
	Reference           string                            `json:"reference"`
	Referenced          bool                              `json:"referenced"`
	URL                 string                            `json:"url"`
	URLExpiresAt        time.Time                         `json:"url_expires_at"`
	CreatedAt           time.Time                         `json:"created_at"`
	UpdatedAt           time.Time                         `json:"updated_at"`
}

type GuidelineAssetList struct {
	Items            []GuidelineAssetDTO `json:"items"`
	BrokenReferences []string            `json:"broken_references"`
}

func (s GuidelineService) CreateGuidelineAsset(ctx context.Context, versionID, actorID uuid.UUID, filename string, data []byte, in GuidelineAssetInput, ip string) (*GuidelineAssetDTO, error) {
	if err := requireEditableGuidelineVersion(s.DB, versionID); err != nil {
		return nil, err
	}
	mimeType, extension, err := validateGuidelineImage(filename, data)
	if err != nil {
		return nil, err
	}
	if err := validateGuidelineAssetMetadata(in); err != nil {
		return nil, err
	}
	id := uuid.New()
	sum := sha256.Sum256(data)
	checksum := hex.EncodeToString(sum[:])
	key := fmt.Sprintf("guidelines/%s/assets/%s%s", versionID, id, extension)
	if err := s.Store.Put(ctx, key, bytes.NewReader(data), int64(len(data)), mimeType); err != nil {
		return nil, err
	}
	name := filepath.Base(strings.TrimSpace(filename))
	row := models.GuidelineAsset{
		Base: models.Base{ID: id}, VersionID: versionID, Type: models.GuidelineAssetFigure,
		MIMEType: mimeType, Checksum: checksum, StorageKey: key, SizeBytes: int64(len(data)), OriginalFilename: &name,
		AlternativeText: cleanAssetText(in.AlternativeText), Caption: cleanAssetText(in.Caption), Source: cleanAssetText(in.Source),
		Attribution: cleanAssetText(in.Attribution), License: cleanAssetText(in.License), FigureNumber: in.FigureNumber,
		ClinicallySensitive: assetBoolValue(in.ClinicallySensitive), UploadedBy: &actorID,
		SourceFingerprint: "editor:" + id.String(), ReviewStatus: models.GuidelineBlockDraft,
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.asset.created", "guideline_asset", row.ID, ip, map[string]any{"version_id": versionID, "mime_type": mimeType})
	}); err != nil {
		_ = s.Store.Delete(ctx, key)
		return nil, err
	}
	return s.guidelineAssetDTO(ctx, row, false)
}

func (s GuidelineService) ListGuidelineAssets(ctx context.Context, versionID uuid.UUID) (*GuidelineAssetList, error) {
	if err := requireGuidelineVersion(s.DB, versionID); err != nil {
		return nil, err
	}
	var rows []models.GuidelineAsset
	if err := s.DB.Where("version_id = ?", versionID).Order("figure_number ASC NULLS LAST, created_at ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	references, err := s.currentGuidelineAssetReferences(ctx, versionID)
	if err != nil {
		return nil, err
	}
	known := map[string]bool{}
	result := &GuidelineAssetList{Items: make([]GuidelineAssetDTO, 0, len(rows)), BrokenReferences: []string{}}
	for _, row := range rows {
		known[row.ID.String()] = true
		item, err := s.guidelineAssetDTO(ctx, row, references[row.ID.String()])
		if err != nil {
			return nil, err
		}
		result.Items = append(result.Items, *item)
	}
	for id := range references {
		if !known[id] {
			result.BrokenReferences = append(result.BrokenReferences, id)
		}
	}
	return result, nil
}

func (s GuidelineService) GetGuidelineAsset(ctx context.Context, versionID, assetID uuid.UUID) (*GuidelineAssetDTO, error) {
	var row models.GuidelineAsset
	if err := s.DB.First(&row, "id = ? AND version_id = ?", assetID, versionID).Error; err != nil {
		return nil, err
	}
	references, err := s.currentGuidelineAssetReferences(ctx, versionID)
	if err != nil {
		return nil, err
	}
	return s.guidelineAssetDTO(ctx, row, references[assetID.String()])
}

func (s GuidelineService) UpdateGuidelineAsset(ctx context.Context, versionID, assetID, actorID uuid.UUID, in GuidelineAssetInput, ip string) (*GuidelineAssetDTO, error) {
	if err := validateGuidelineAssetMetadata(in); err != nil {
		return nil, err
	}
	var row models.GuidelineAsset
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if err := tx.First(&row, "id = ? AND version_id = ?", assetID, versionID).Error; err != nil {
			return err
		}
		updates := map[string]any{}
		assetStringUpdate(updates, "alternative_text", in.AlternativeText)
		assetStringUpdate(updates, "caption", in.Caption)
		assetStringUpdate(updates, "source", in.Source)
		assetStringUpdate(updates, "attribution", in.Attribution)
		assetStringUpdate(updates, "license", in.License)
		if in.FigureNumber != nil {
			updates["figure_number"] = *in.FigureNumber
		}
		if in.ClinicallySensitive != nil {
			updates["clinically_sensitive"] = *in.ClinicallySensitive
		}
		if len(updates) > 0 {
			updates["review_status"] = models.GuidelineBlockDraft
			updates["reviewed_by"] = nil
			updates["reviewed_at"] = nil
			if err := tx.Model(&row).Updates(updates).Error; err != nil {
				return err
			}
		}
		if err := writeGuidelineAudit(tx, actorID, "guideline.asset.updated", "guideline_asset", assetID, ip, map[string]any{"version_id": versionID}); err != nil {
			return err
		}
		return tx.First(&row, "id = ?", assetID).Error
	})
	if err != nil {
		return nil, err
	}
	references, err := s.currentGuidelineAssetReferences(ctx, versionID)
	if err != nil {
		return nil, err
	}
	return s.guidelineAssetDTO(ctx, row, references[assetID.String()])
}

func (s GuidelineService) DeleteGuidelineAsset(versionID, assetID, actorID uuid.UUID, ip string) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var row models.GuidelineAsset
		if err := tx.First(&row, "id = ? AND version_id = ?", assetID, versionID).Error; err != nil {
			return err
		}
		if err := tx.Delete(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.asset.deleted", "guideline_asset", assetID, ip, map[string]any{"version_id": versionID})
	})
}

func validateGuidelineImage(filename string, data []byte) (string, string, error) {
	if len(data) == 0 || len(data) > maxGuidelineImageBytes {
		return "", "", ErrGuidelineAssetInvalid
	}
	mimeType := http.DetectContentType(data)
	extensions := map[string]string{"image/png": ".png", "image/jpeg": ".jpg", "image/gif": ".gif", "image/webp": ".webp"}
	extension, ok := extensions[mimeType]
	if !ok || strings.EqualFold(filepath.Ext(filename), ".svg") {
		return "", "", fmt.Errorf("%w: only PNG, JPEG, GIF and WebP images are supported", ErrGuidelineAssetInvalid)
	}
	return mimeType, extension, nil
}

func validateGuidelineAssetMetadata(in GuidelineAssetInput) error {
	if in.FigureNumber != nil && *in.FigureNumber < 1 {
		return fmt.Errorf("%w: figure number must be positive", ErrGuidelineAssetInvalid)
	}
	for _, value := range []*string{in.AlternativeText, in.Caption, in.Source, in.Attribution, in.License} {
		if value != nil && len(strings.TrimSpace(*value)) > 2000 {
			return fmt.Errorf("%w: metadata value is too long", ErrGuidelineAssetInvalid)
		}
	}
	return nil
}

func (s GuidelineService) guidelineAssetDTO(ctx context.Context, row models.GuidelineAsset, referenced bool) (*GuidelineAssetDTO, error) {
	url, err := s.Store.PresignGet(ctx, row.StorageKey, guidelineAssetURLTTL)
	if err != nil {
		return nil, err
	}
	filename := ""
	if row.OriginalFilename != nil {
		filename = *row.OriginalFilename
	}
	return &GuidelineAssetDTO{ID: row.ID, VersionID: row.VersionID, Type: row.Type, MIMEType: row.MIMEType, Checksum: row.Checksum, SizeBytes: row.SizeBytes,
		OriginalFilename: filename, AlternativeText: row.AlternativeText, Caption: row.Caption, Source: row.Source, Attribution: row.Attribution,
		License: row.License, FigureNumber: row.FigureNumber, ClinicallySensitive: row.ClinicallySensitive, ReviewStatus: row.ReviewStatus,
		ReviewedBy: row.ReviewedBy, ReviewedAt: row.ReviewedAt, UploadedBy: row.UploadedBy, Reference: "guideline-asset://" + row.ID.String(),
		Referenced: referenced, URL: url.String(), URLExpiresAt: time.Now().UTC().Add(guidelineAssetURLTTL), CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}, nil
}

func (s GuidelineService) currentGuidelineAssetReferences(ctx context.Context, versionID uuid.UUID) (map[string]bool, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	key := version.MarkdownFileKey
	if version.CurrentMarkdownRevisionID != nil {
		var revision models.GuidelineMarkdownRevision
		if err := s.DB.First(&revision, "id = ? AND version_id = ?", *version.CurrentMarkdownRevisionID, versionID).Error; err != nil {
			return nil, err
		}
		key = revision.StorageKey
	}
	result := map[string]bool{}
	if strings.TrimSpace(key) == "" {
		return result, nil
	}
	reader, err := s.Store.Get(ctx, key)
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	data, err := io.ReadAll(io.LimitReader(reader, maxGuidelineAssetMarkdownBytes+1))
	if err != nil {
		return nil, err
	}
	if len(data) > maxGuidelineAssetMarkdownBytes {
		return nil, ErrGuidelineAssetInvalid
	}
	for _, match := range assetReferencePattern.FindAllStringSubmatch(string(data), -1) {
		result[strings.ToLower(match[1])] = true
	}
	return result, nil
}

func requireGuidelineVersion(db *gorm.DB, versionID uuid.UUID) error {
	var count int64
	if err := db.Model(&models.GuidelineVersion{}).Where("id = ?", versionID).Count(&count).Error; err != nil {
		return err
	}
	if count != 1 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
func cleanAssetText(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}
func assetBoolValue(value *bool) bool { return value != nil && *value }
func assetStringUpdate(updates map[string]any, key string, value *string) {
	if value != nil {
		updates[key] = strings.TrimSpace(*value)
	}
}
