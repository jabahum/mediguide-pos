package services

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"slices"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

const maxMarkdownDraftBytes = 100 << 20

var (
	ErrMarkdownRevisionConflict = errors.New("the Markdown draft was changed by another editor")
	ErrMarkdownRevisionMissing  = errors.New("Markdown draft revision not found")
	ErrMarkdownAlreadyCurrent   = errors.New("structured content is already current for this revision")
	ErrGuidelineVersionExists   = errors.New("a guideline version with this version number already exists")
)

type MarkdownDraftInput struct {
	Content          string     `json:"content"`
	ExpectedRevision string     `json:"expected_revision,omitempty"`
	CheckpointName   string     `json:"checkpoint_name,omitempty"`
	ChangeSummary    string     `json:"change_summary,omitempty"`
	SourceType       string     `json:"source_type,omitempty"`
	ParentRevisionID *uuid.UUID `json:"parent_revision_id,omitempty"`
}

type MarkdownDraft struct {
	Revision models.GuidelineMarkdownRevision `json:"revision"`
	Content  string                           `json:"content"`
	ETag     string                           `json:"etag"`
	Saved    bool                             `json:"saved"`
}

type MarkdownRevisionQuery struct {
	Page       PageInput
	SourceType string
	CreatedBy  *uuid.UUID
	From       *time.Time
	To         *time.Time
}

type MarkdownRegenerationInput struct {
	RevisionID     uuid.UUID `json:"revision_id"`
	IdempotencyKey string    `json:"idempotency_key,omitempty"`
	Operations     []string  `json:"operations,omitempty"`
}

type MarkdownRegenerationResult struct {
	Job        models.IngestionJob `json:"job"`
	RevisionID uuid.UUID           `json:"revision_id"`
	Operations []string            `json:"operations"`
	QueuedAt   time.Time           `json:"queued_at"`
}

type DuplicateMarkdownVersionInput struct {
	Version         string `json:"version"`
	PublicationDate string `json:"publication_date,omitempty"`
	ReviewDate      string `json:"review_date,omitempty"`
}

type DuplicatedGuidelineVersion struct {
	ID                        uuid.UUID  `json:"id"`
	DocumentID                uuid.UUID  `json:"document_id"`
	Version                   string     `json:"version"`
	PublicationDate           string     `json:"publication_date"`
	ReviewDate                string     `json:"review_date"`
	Status                    string     `json:"status"`
	CurrentMarkdownRevisionID *uuid.UUID `json:"current_markdown_revision_id"`
	StructuredContentStatus   string     `json:"structured_content_status"`
	CreatedAt                 time.Time  `json:"created_at"`
	UpdatedAt                 time.Time  `json:"updated_at"`
}

type DuplicatedMarkdownVersion struct {
	Version DuplicatedGuidelineVersion `json:"version"`
	Draft   MarkdownDraft              `json:"draft"`
}

func (s GuidelineService) GetMarkdownDraft(ctx context.Context, versionID uuid.UUID) (*MarkdownDraft, error) {
	revision, err := s.currentMarkdownRevision(versionID)
	if err != nil {
		return nil, err
	}
	content, err := s.readMarkdownObject(ctx, revision.StorageKey)
	if err != nil {
		return nil, err
	}
	return &MarkdownDraft{
		Revision: *revision,
		Content:  content,
		ETag:     markdownRevisionETag(revision),
		Saved:    true,
	}, nil
}

func (s GuidelineService) SaveMarkdownDraft(
	ctx context.Context,
	versionID uuid.UUID,
	actorID uuid.UUID,
	input MarkdownDraftInput,
) (*MarkdownDraft, error) {
	content := strings.ReplaceAll(strings.ReplaceAll(input.Content, "\r\n", "\n"), "\r", "\n")
	if strings.TrimSpace(content) == "" {
		return nil, errors.New("markdown content is required")
	}
	if len([]byte(content)) > maxMarkdownDraftBytes {
		return nil, errors.New("markdown exceeds maximum allowed size")
	}

	var target models.GuidelineVersion
	if err := s.DB.First(&target, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	if err := validateVersionAllowsIngestion(&target); err != nil {
		return nil, err
	}

	revisionID := uuid.New()
	data := []byte(content)
	checksum := markdownContentChecksum(data)
	key := fmt.Sprintf("guidelines/%s/revisions/%s.md", versionID, revisionID)
	if err := s.Store.Put(ctx, key, bytes.NewReader(data), int64(len(data)), "text/markdown; charset=utf-8"); err != nil {
		return nil, err
	}

	sourceType := strings.TrimSpace(input.SourceType)
	if sourceType == "" {
		sourceType = "manual_edit"
	}
	if !validMarkdownRevisionSource(sourceType) {
		_ = s.Store.Delete(ctx, key)
		return nil, errors.New("invalid Markdown revision source type")
	}

	var revision models.GuidelineMarkdownRevision
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var version models.GuidelineVersion
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&version, "id = ?", versionID).Error; err != nil {
			return err
		}
		if err := validateVersionAllowsIngestion(&version); err != nil {
			return err
		}

		var current *models.GuidelineMarkdownRevision
		if version.CurrentMarkdownRevisionID != nil {
			var found models.GuidelineMarkdownRevision
			if err := tx.First(&found, "id = ? AND version_id = ?", *version.CurrentMarkdownRevisionID, versionID).Error; err != nil {
				return err
			}
			current = &found
		}
		expected := strings.TrimSpace(input.ExpectedRevision)
		if expected != "" {
			if current == nil || !etagMatches(expected, markdownRevisionETag(current)) {
				return ErrMarkdownRevisionConflict
			}
		}

		var revisionNumber int
		if err := tx.Model(&models.GuidelineMarkdownRevision{}).
			Where("version_id = ?", versionID).
			Select("COALESCE(MAX(revision_number), 0)").
			Scan(&revisionNumber).Error; err != nil {
			return err
		}
		revisionNumber++
		parentID := input.ParentRevisionID
		if parentID == nil && current != nil {
			value := current.ID
			parentID = &value
		}
		if current != nil {
			if err := tx.Model(current).Update("is_current", false).Error; err != nil {
				return err
			}
		}
		actor := actorID
		revision = models.GuidelineMarkdownRevision{
			Base:                    models.Base{ID: revisionID},
			DocumentID:              version.DocumentID,
			VersionID:               versionID,
			RevisionNumber:          revisionNumber,
			StorageKey:              key,
			Checksum:                checksum,
			SizeBytes:               int64(len(data)),
			SourceType:              sourceType,
			ParentRevisionID:        parentID,
			CheckpointName:          strings.TrimSpace(input.CheckpointName),
			ChangeSummary:           strings.TrimSpace(input.ChangeSummary),
			CreatedBy:               &actor,
			IsCurrent:               true,
			StructuredContentStatus: "outdated",
			ReviewState:             "draft",
			PublicationState:        "draft",
		}
		if err := tx.Create(&revision).Error; err != nil {
			return err
		}
		return tx.Model(&version).Updates(map[string]any{
			"current_markdown_revision_id": revision.ID,
			"markdown_file_key":            key,
			"structured_content_status":    "outdated",
			"updated_at":                   time.Now().UTC(),
		}).Error
	})
	if err != nil {
		_ = s.Store.Delete(ctx, key)
		return nil, err
	}

	s.invalidatePublishedCaches(ctx)
	return &MarkdownDraft{
		Revision: revision,
		Content:  content,
		ETag:     markdownRevisionETag(&revision),
		Saved:    true,
	}, nil
}

func (s GuidelineService) ListMarkdownRevisions(
	versionID uuid.UUID,
	query MarkdownRevisionQuery,
) (*PageResult[models.GuidelineMarkdownRevision], error) {
	page := query.Page.Normalize(20, 100)
	db := s.DB.Model(&models.GuidelineMarkdownRevision{}).Where("version_id = ?", versionID)
	if value := strings.TrimSpace(query.SourceType); value != "" {
		if !validMarkdownRevisionSource(value) {
			return nil, errors.New("invalid Markdown revision source type")
		}
		db = db.Where("source_type = ?", value)
	}
	if query.CreatedBy != nil {
		db = db.Where("created_by = ?", *query.CreatedBy)
	}
	if query.From != nil {
		db = db.Where("created_at >= ?", *query.From)
	}
	if query.To != nil {
		db = db.Where("created_at <= ?", *query.To)
	}
	var total int64
	if err := db.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	var revisions []models.GuidelineMarkdownRevision
	if err := db.Session(&gorm.Session{}).
		Order("revision_number DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&revisions).Error; err != nil {
		return nil, err
	}
	return NewPageResult(revisions, page, total), nil
}

func (s GuidelineService) GetMarkdownRevision(
	ctx context.Context,
	versionID uuid.UUID,
	revisionID uuid.UUID,
) (*MarkdownDraft, error) {
	var revision models.GuidelineMarkdownRevision
	if err := s.DB.First(&revision, "id = ? AND version_id = ?", revisionID, versionID).Error; err != nil {
		return nil, err
	}
	content, err := s.readMarkdownObject(ctx, revision.StorageKey)
	if err != nil {
		return nil, err
	}
	return &MarkdownDraft{
		Revision: revision,
		Content:  content,
		ETag:     markdownRevisionETag(&revision),
		Saved:    true,
	}, nil
}

func (s GuidelineService) RestoreMarkdownRevision(
	ctx context.Context,
	versionID uuid.UUID,
	revisionID uuid.UUID,
	actorID uuid.UUID,
	expected string,
) (*MarkdownDraft, error) {
	source, err := s.GetMarkdownRevision(ctx, versionID, revisionID)
	if err != nil {
		return nil, err
	}
	parent := source.Revision.ID
	return s.SaveMarkdownDraft(ctx, versionID, actorID, MarkdownDraftInput{
		Content:          source.Content,
		ExpectedRevision: expected,
		CheckpointName:   fmt.Sprintf("Restored revision %d", source.Revision.RevisionNumber),
		ChangeSummary:    "Restored from revision history",
		SourceType:       "restored",
		ParentRevisionID: &parent,
	})
}

// DuplicateMarkdownVersion creates a new draft version from one exact immutable
// source revision. Published versions branch from their published revision;
// drafts branch from the revision that was current when this request began.
func (s GuidelineService) DuplicateMarkdownVersion(
	ctx context.Context,
	sourceVersionID uuid.UUID,
	actorID uuid.UUID,
	input DuplicateMarkdownVersionInput,
) (*DuplicatedMarkdownVersion, error) {
	input.Version = strings.TrimSpace(input.Version)
	if input.Version == "" {
		return nil, errors.New("version is required")
	}

	var sourceVersion models.GuidelineVersion
	if err := s.DB.First(&sourceVersion, "id = ?", sourceVersionID).Error; err != nil {
		return nil, err
	}
	sourceRevisionID := sourceVersion.CurrentMarkdownRevisionID
	if strings.EqualFold(sourceVersion.Status, "published") && sourceVersion.PublishedMarkdownRevisionID != nil {
		sourceRevisionID = sourceVersion.PublishedMarkdownRevisionID
	}
	if sourceRevisionID == nil {
		return nil, ErrMarkdownRevisionMissing
	}

	var sourceRevision models.GuidelineMarkdownRevision
	if err := s.DB.First(&sourceRevision, "id = ? AND version_id = ?", *sourceRevisionID, sourceVersionID).Error; err != nil {
		return nil, err
	}
	content, err := s.readMarkdownObject(ctx, sourceRevision.StorageKey)
	if err != nil {
		return nil, err
	}

	versionID := uuid.New()
	revisionID := uuid.New()
	data := []byte(content)
	key := fmt.Sprintf("guidelines/%s/revisions/%s.md", versionID, revisionID)
	if err := s.Store.Put(ctx, key, bytes.NewReader(data), int64(len(data)), "text/markdown; charset=utf-8"); err != nil {
		return nil, err
	}

	result := DuplicatedMarkdownVersion{}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		var lockedSource models.GuidelineVersion
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&lockedSource, "id = ?", sourceVersionID).Error; err != nil {
			return err
		}
		lockedRevisionID := lockedSource.CurrentMarkdownRevisionID
		if strings.EqualFold(lockedSource.Status, "published") && lockedSource.PublishedMarkdownRevisionID != nil {
			lockedRevisionID = lockedSource.PublishedMarkdownRevisionID
		}
		if lockedRevisionID == nil || *lockedRevisionID != sourceRevision.ID {
			return ErrMarkdownRevisionConflict
		}

		var duplicateCount int64
		if err := tx.Model(&models.GuidelineVersion{}).
			Where("document_id = ? AND lower(version) = lower(?)", lockedSource.DocumentID, input.Version).
			Count(&duplicateCount).Error; err != nil {
			return err
		}
		if duplicateCount > 0 {
			return ErrGuidelineVersionExists
		}

		version := models.GuidelineVersion{
			Base:                    models.Base{ID: versionID},
			DocumentID:              lockedSource.DocumentID,
			Version:                 input.Version,
			PublicationDate:         strings.TrimSpace(input.PublicationDate),
			ReviewDate:              strings.TrimSpace(input.ReviewDate),
			Status:                  "draft",
			OriginalFileKey:         lockedSource.OriginalFileKey,
			MarkdownFileKey:         key,
			Checksum:                sourceRevision.Checksum,
			StructuredContentStatus: "outdated",
		}
		if err := tx.Create(&version).Error; err != nil {
			return err
		}
		parentID := sourceRevision.ID
		actor := actorID
		revision := models.GuidelineMarkdownRevision{
			Base:                    models.Base{ID: revisionID},
			DocumentID:              lockedSource.DocumentID,
			VersionID:               version.ID,
			RevisionNumber:          1,
			StorageKey:              key,
			Checksum:                markdownContentChecksum(data),
			SizeBytes:               int64(len(data)),
			SourceType:              "duplicated",
			ParentRevisionID:        &parentID,
			CheckpointName:          fmt.Sprintf("Duplicated from version %s", lockedSource.Version),
			ChangeSummary:           "Created as a new draft from an immutable Markdown revision",
			CreatedBy:               &actor,
			IsCurrent:               true,
			StructuredContentStatus: "outdated",
			ReviewState:             "draft",
			PublicationState:        "draft",
		}
		if err := tx.Create(&revision).Error; err != nil {
			return err
		}
		if err := tx.Model(&version).Updates(map[string]any{
			"current_markdown_revision_id": revision.ID,
			"markdown_file_key":            key,
			"checksum":                     revision.Checksum,
		}).Error; err != nil {
			return err
		}
		version.CurrentMarkdownRevisionID = &revision.ID
		result.Version = DuplicatedGuidelineVersion{
			ID:                        version.ID,
			DocumentID:                version.DocumentID,
			Version:                   version.Version,
			PublicationDate:           version.PublicationDate,
			ReviewDate:                version.ReviewDate,
			Status:                    version.Status,
			CurrentMarkdownRevisionID: version.CurrentMarkdownRevisionID,
			StructuredContentStatus:   version.StructuredContentStatus,
			CreatedAt:                 version.CreatedAt,
			UpdatedAt:                 version.UpdatedAt,
		}
		result.Draft = MarkdownDraft{
			Revision: revision,
			Content:  content,
			ETag:     markdownRevisionETag(&revision),
			Saved:    true,
		}
		return nil
	})
	if err != nil {
		_ = s.Store.Delete(ctx, key)
		return nil, err
	}

	s.invalidatePublishedCaches(ctx)
	return &result, nil
}

func (s GuidelineService) RegenerateMarkdown(
	versionID uuid.UUID,
	actorID uuid.UUID,
	input MarkdownRegenerationInput,
) (*MarkdownRegenerationResult, error) {
	operations, err := normalizeRegenerationOperations(input.Operations)
	if err != nil {
		return nil, err
	}
	var result MarkdownRegenerationResult
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		var version models.GuidelineVersion
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&version, "id = ?", versionID).Error; err != nil {
			return err
		}
		if err := validateVersionAllowsIngestion(&version); err != nil {
			return err
		}
		if version.CurrentMarkdownRevisionID == nil || *version.CurrentMarkdownRevisionID != input.RevisionID {
			return ErrMarkdownRevisionConflict
		}
		var revision models.GuidelineMarkdownRevision
		if err := tx.First(&revision, "id = ? AND version_id = ?", input.RevisionID, versionID).Error; err != nil {
			return err
		}
		if revision.StructuredContentStatus == "queued" || revision.StructuredContentStatus == "processing" {
			if revision.RegenerationJobID != nil && strings.TrimSpace(input.IdempotencyKey) != "" {
				var existing models.IngestionJob
				if err := tx.First(&existing, "id = ?", *revision.RegenerationJobID).Error; err == nil {
					existingKey, existingOperations := markdownJobRequest(existing.PayloadJSON)
					if existingKey == strings.TrimSpace(input.IdempotencyKey) && !slices.Equal(existingOperations, operations) {
						return ErrMarkdownRevisionConflict
					}
					if existingKey != strings.TrimSpace(input.IdempotencyKey) {
						return ErrMarkdownAlreadyCurrent
					}
					result = MarkdownRegenerationResult{
						Job:        existing,
						RevisionID: revision.ID,
						Operations: existingOperations,
						QueuedAt:   existing.CreatedAt,
					}
					return nil
				}
			}
			return ErrMarkdownAlreadyCurrent
		}
		payload, err := json.Marshal(map[string]any{
			"file_key":        revision.StorageKey,
			"source_format":   "markdown",
			"source":          "manual_regeneration",
			"revision_id":     revision.ID,
			"requested_by":    actorID,
			"idempotency_key": strings.TrimSpace(input.IdempotencyKey),
			"operations":      operations,
		})
		if err != nil {
			return err
		}
		job := models.IngestionJob{
			VersionID:   versionID,
			JobType:     "markdown_ingestion",
			Status:      "queued",
			PayloadJSON: string(payload),
		}
		if err := tx.Create(&job).Error; err != nil {
			return err
		}
		if err := tx.Model(&revision).Updates(map[string]any{
			"regeneration_job_id":       job.ID,
			"structured_content_status": "queued",
			"review_state":              "draft",
		}).Error; err != nil {
			return err
		}
		if err := tx.Model(&version).Updates(map[string]any{
			"structured_content_status": "queued",
			"status":                    "draft",
		}).Error; err != nil {
			return err
		}
		result = MarkdownRegenerationResult{
			Job:        job,
			RevisionID: revision.ID,
			Operations: operations,
			QueuedAt:   job.CreatedAt,
		}
		return nil
	})
	return &result, err
}

func markdownJobRequest(payload string) (string, []string) {
	var value struct {
		IdempotencyKey string   `json:"idempotency_key"`
		Operations     []string `json:"operations"`
	}
	if json.Unmarshal([]byte(payload), &value) != nil {
		return "", nil
	}
	return strings.TrimSpace(value.IdempotencyKey), value.Operations
}

func (s GuidelineService) currentMarkdownRevision(versionID uuid.UUID) (*models.GuidelineMarkdownRevision, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	if version.CurrentMarkdownRevisionID == nil {
		return nil, ErrMarkdownRevisionMissing
	}
	var revision models.GuidelineMarkdownRevision
	if err := s.DB.First(&revision, "id = ? AND version_id = ?", *version.CurrentMarkdownRevisionID, versionID).Error; err != nil {
		return nil, err
	}
	return &revision, nil
}

func (s GuidelineService) readMarkdownObject(ctx context.Context, key string) (string, error) {
	reader, err := s.Store.Get(ctx, key)
	if err != nil {
		return "", err
	}
	defer reader.Close()
	data, err := io.ReadAll(io.LimitReader(reader, maxMarkdownDraftBytes+1))
	if err != nil {
		return "", err
	}
	if len(data) > maxMarkdownDraftBytes {
		return "", errors.New("markdown exceeds maximum allowed size")
	}
	return string(data), nil
}

func markdownRevisionETag(revision *models.GuidelineMarkdownRevision) string {
	return fmt.Sprintf("\"md-%s-%s\"", revision.ID, revision.Checksum)
}

func markdownContentChecksum(content []byte) string {
	digest := sha256.Sum256(content)
	return hex.EncodeToString(digest[:])
}

func etagMatches(value string, current string) bool {
	for _, candidate := range strings.Split(value, ",") {
		candidate = strings.TrimSpace(candidate)
		if candidate == "*" || candidate == current || strings.TrimPrefix(candidate, "W/") == current {
			return true
		}
	}
	return false
}

func validMarkdownRevisionSource(value string) bool {
	switch value {
	case "blank", "template", "uploaded_markdown", "pdf_generated", "manual_edit", "restored", "duplicated":
		return true
	default:
		return false
	}
}

func normalizeRegenerationOperations(values []string) ([]string, error) {
	allowed := map[string]bool{
		"structure":  true,
		"html":       true,
		"chunks":     true,
		"embeddings": true,
		"manifest":   true,
		"assets":     true,
	}
	if len(values) == 0 {
		return []string{"structure", "html", "chunks", "embeddings", "manifest", "assets"}, nil
	}
	seen := map[string]bool{}
	result := make([]string, 0, len(values))
	for _, item := range values {
		item = strings.TrimSpace(strings.ToLower(item))
		if !allowed[item] {
			return nil, fmt.Errorf("unsupported regeneration operation: %s", item)
		}
		if !seen[item] {
			seen[item] = true
			result = append(result, item)
		}
	}
	return result, nil
}
