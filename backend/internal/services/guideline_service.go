package services

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	cachepkg "mediguide/internal/cache"
	"mediguide/internal/models"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"
	"gorm.io/gorm"
)

type GuidelineService struct {
	DB    *gorm.DB
	Store storage.ObjectStore
	Cache *cachepkg.Store
}

type CreateGuidelineInput struct {
	Title       string `json:"title"`
	Country     string `json:"country"`
	SourceOrg   string `json:"source_org"`
	ProgramArea string `json:"program_area"`
	Language    string `json:"language"`
	Description string `json:"description"`
}

type UpdateGuidelineInput = CreateGuidelineInput

type CreateVersionInput struct {
	Version         string `json:"version"`
	PublicationDate string `json:"publication_date"`
	ReviewDate      string `json:"review_date"`
}

type ExtractedAsset struct {
	Reader      io.ReadCloser
	Filename    string
	ContentType string
}

var (
	ErrGuidelineIngestionIncomplete = errors.New("guideline ingestion is not complete")
	ErrGuidelineIngestionFailed     = errors.New("guideline ingestion failed")
	ErrGuidelineAssetMissing        = errors.New("extracted guideline asset is missing")
	ErrUnsupportedGuidelineAsset    = errors.New("unsupported extracted guideline asset format")
	ErrPublishedMarkdownImmutable   = errors.New("published guideline markdown cannot be edited")
	ErrPublishedVersionImmutable    = errors.New("published guideline version cannot be re-ingested")
)

func (s GuidelineService) CreateDocument(in CreateGuidelineInput) (*models.GuidelineDocument, error) {
	d := models.GuidelineDocument{Title: in.Title, Country: in.Country, SourceOrg: in.SourceOrg, ProgramArea: in.ProgramArea, Language: in.Language, Description: in.Description}
	if d.Language == "" {
		d.Language = "en"
	}
	return &d, s.DB.Create(&d).Error
}
func (s GuidelineService) ListDocuments(programArea string, page PageInput) (*PageResult[models.GuidelineDocument], error) {
	var docs []models.GuidelineDocument
	normalized := page.Normalize(20, 100)
	q := s.DB.Model(&models.GuidelineDocument{})
	if programArea != "" {
		q = q.Where("program_area = ?", programArea)
	}

	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	if err := q.Session(&gorm.Session{}).Preload("Versions").Order("created_at desc").Limit(normalized.PerPage).Offset(normalized.Offset()).Find(&docs).Error; err != nil {
		return nil, err
	}
	return NewPageResult(docs, normalized, total), nil
}
func (s GuidelineService) GetDocument(id uuid.UUID) (*models.GuidelineDocument, error) {
	var d models.GuidelineDocument
	return &d, s.DB.Preload("Versions").First(&d, "id = ?", id).Error
}
func (s GuidelineService) UpdateDocument(id uuid.UUID, in UpdateGuidelineInput) (*models.GuidelineDocument, error) {
	var document models.GuidelineDocument
	if err := s.DB.First(&document, "id = ?", id).Error; err != nil {
		return nil, err
	}
	language := strings.TrimSpace(in.Language)
	if language == "" {
		language = "en"
	}
	if err := s.DB.Model(&document).Updates(map[string]any{
		"title":        strings.TrimSpace(in.Title),
		"country":      strings.TrimSpace(in.Country),
		"source_org":   strings.TrimSpace(in.SourceOrg),
		"program_area": strings.TrimSpace(in.ProgramArea),
		"language":     language,
		"description":  strings.TrimSpace(in.Description),
	}).Error; err != nil {
		return nil, err
	}
	result, err := s.GetDocument(id)
	if err == nil {
		s.invalidatePublishedCaches(context.Background())
	}
	return result, err
}
func (s GuidelineService) CreateVersion(docID uuid.UUID, in CreateVersionInput) (*models.GuidelineVersion, error) {
	v := models.GuidelineVersion{DocumentID: docID, Version: in.Version, PublicationDate: in.PublicationDate, ReviewDate: in.ReviewDate, Status: "draft"}
	return &v, s.DB.Create(&v).Error
}
func (s GuidelineService) UploadPDF(ctx context.Context, versionID uuid.UUID, file multipart.File, header *multipart.FileHeader) (*models.IngestionJob, error) {
	var target models.GuidelineVersion
	if err := s.DB.First(&target, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	if err := validateVersionAllowsIngestion(&target); err != nil {
		return nil, err
	}
	key := fmt.Sprintf("guidelines/%s/original/%d_%s", versionID.String(), time.Now().Unix(), filepath.Base(header.Filename))
	if err := s.Store.Put(ctx, key, file, header.Size, header.Header.Get("Content-Type")); err != nil {
		return nil, err
	}
	var job models.IngestionJob
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&models.GuidelineVersion{}).Where("id = ?", versionID).Update("original_file_key", key).Error; err != nil {
			return err
		}

		version, document, err := s.loadVersionDocument(tx, versionID)
		if err != nil {
			return err
		}
		if err := ensureDraftProtocol(tx, document, version); err != nil {
			return err
		}

		job = models.IngestionJob{VersionID: versionID, JobType: "pdf_ingestion", Status: "queued", PayloadJSON: fmt.Sprintf(`{"file_key":"%s"}`, key)}
		return tx.Create(&job).Error
	})
	if err != nil {
		return nil, err
	}
	return &job, nil
}
func (s GuidelineService) PublishVersion(versionID uuid.UUID, userID uuid.UUID) error {
	publishedAt := time.Now().UTC()
	now := publishedAt.Format(time.RFC3339)
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var v models.GuidelineVersion
		if err := tx.First(&v, "id = ?", versionID).Error; err != nil {
			return err
		}
		if err := ensureVersionReadyForPublish(tx, &v); err != nil {
			return err
		}
		if err := tx.Model(&v).Updates(map[string]any{"status": "published", "approved_by": userID, "approved_at": now}).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ?", versionID).Update("review_status", "approved").Error; err != nil {
			return err
		}
		if _, err := generateGuidelineVersionManifest(tx, versionID, publishedAt); err != nil {
			return err
		}
		return tx.Model(&models.GuidelineDocument{}).Where("id = ?", v.DocumentID).Update("current_version_id", versionID).Error
	})
	if err == nil {
		s.invalidatePublishedCaches(context.Background())
	}
	return err
}
func (s GuidelineService) Sections(versionID uuid.UUID, page PageInput) (*PageResult[models.GuidelineSection], error) {
	var rows []models.GuidelineSection
	normalized := page.Normalize(100, 500)
	q := s.DB.Model(&models.GuidelineSection{}).Where("version_id = ?", versionID)

	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	if err := q.Session(&gorm.Session{}).Order("sort_order asc").Limit(normalized.PerPage).Offset(normalized.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	return NewPageResult(rows, normalized, total), nil
}
func (s GuidelineService) Chunks(versionID uuid.UUID, page PageInput) (*PageResult[models.GuidelineChunk], error) {
	var rows []models.GuidelineChunk
	normalized := page.Normalize(100, 500)
	q := s.DB.Model(&models.GuidelineChunk{}).Where("version_id = ?", versionID)

	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	if err := q.Session(&gorm.Session{}).Order("created_at asc").Limit(normalized.PerPage).Offset(normalized.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	return NewPageResult(rows, normalized, total), nil
}

func (s GuidelineService) ExtractedAsset(ctx context.Context, versionID uuid.UUID, format string) (*ExtractedAsset, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}

	key, extension, contentType, err := guidelineAssetDetails(&version, format)
	if err != nil {
		return nil, err
	}

	reader, err := s.Store.Get(ctx, key)
	if err != nil {
		return nil, err
	}
	return &ExtractedAsset{
		Reader:      reader,
		Filename:    fmt.Sprintf("guideline-%s.%s", versionID, extension),
		ContentType: contentType,
	}, nil
}

func guidelineAssetDetails(version *models.GuidelineVersion, format string) (key, extension, contentType string, err error) {
	switch strings.ToLower(strings.TrimPrefix(strings.TrimSpace(format), ".")) {
	case "md", "markdown":
		key = version.MarkdownFileKey
		extension = "md"
		contentType = "text/markdown; charset=utf-8"
	case "html":
		key = version.HTMLFileKey
		extension = "html"
		contentType = "text/html; charset=utf-8"
	default:
		return "", "", "", ErrUnsupportedGuidelineAsset
	}
	if strings.TrimSpace(key) == "" {
		return "", "", "", ErrGuidelineAssetMissing
	}
	return key, extension, contentType, nil
}

func (s GuidelineService) UpdateMarkdown(ctx context.Context, versionID uuid.UUID, content []byte) error {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return err
	}
	if err := validateMarkdownUpdate(&version, content); err != nil {
		return err
	}
	if err := s.Store.Put(
		ctx,
		version.MarkdownFileKey,
		bytes.NewReader(content),
		int64(len(content)),
		"text/markdown; charset=utf-8",
	); err != nil {
		return err
	}
	err := s.DB.Model(&version).Update("updated_at", time.Now()).Error
	if err == nil {
		s.invalidatePublishedCaches(ctx)
	}
	return err
}

func (s GuidelineService) invalidatePublishedCaches(ctx context.Context) {
	if s.Cache == nil {
		return
	}
	_ = s.Cache.InvalidateNamespace(ctx, "public-guidelines")
	_ = s.Cache.InvalidateNamespace(ctx, "guideline-search")
}

func validateMarkdownUpdate(version *models.GuidelineVersion, content []byte) error {
	if len(bytes.TrimSpace(content)) == 0 {
		return errors.New("markdown content is required")
	}
	if strings.EqualFold(strings.TrimSpace(version.Status), "published") {
		return ErrPublishedMarkdownImmutable
	}
	if strings.TrimSpace(version.MarkdownFileKey) == "" {
		return ErrGuidelineAssetMissing
	}
	return nil
}

func validateVersionAllowsIngestion(version *models.GuidelineVersion) error {
	if strings.EqualFold(strings.TrimSpace(version.Status), "published") {
		return ErrPublishedVersionImmutable
	}
	return nil
}

func (s GuidelineService) loadVersionDocument(tx *gorm.DB, versionID uuid.UUID) (*models.GuidelineVersion, *models.GuidelineDocument, error) {
	var version models.GuidelineVersion
	if err := tx.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, nil, err
	}
	var document models.GuidelineDocument
	if err := tx.First(&document, "id = ?", version.DocumentID).Error; err != nil {
		return nil, nil, err
	}
	return &version, &document, nil
}

func ensureDraftProtocol(tx *gorm.DB, document *models.GuidelineDocument, version *models.GuidelineVersion) error {
	code := protocolCode(document, version)
	var existing models.ClinicalProtocol
	err := tx.Where("code = ?", code).First(&existing).Error
	if err == nil {
		return nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	definition := generatedProtocolDefinition(document, version)
	definitionYAMLBytes, err := yaml.Marshal(definition)
	if err != nil {
		return err
	}
	definitionJSONBytes, err := json.Marshal(definition)
	if err != nil {
		return err
	}
	protocol := models.ClinicalProtocol{
		Code:           code,
		Title:          protocolTitle(document),
		ProgramArea:    protocolProgramArea(document),
		Version:        version.Version,
		Language:       protocolLanguage(document),
		Status:         "draft",
		DefinitionYAML: strings.TrimSpace(string(definitionYAMLBytes)),
		DefinitionJSON: string(definitionJSONBytes),
	}
	return tx.Create(&protocol).Error
}

func ensureVersionReadyForPublish(tx *gorm.DB, version *models.GuidelineVersion) error {
	if strings.EqualFold(strings.TrimSpace(version.Status), "review_required") {
		return fmt.Errorf("%w: structured extraction requires editorial review", ErrGuidelineIngestionIncomplete)
	}
	if strings.TrimSpace(version.OriginalFileKey) == "" {
		return fmt.Errorf("%w: no PDF has been uploaded for this version", ErrGuidelineIngestionIncomplete)
	}
	if strings.TrimSpace(version.HTMLFileKey) == "" || strings.TrimSpace(version.MarkdownFileKey) == "" {
		return fmt.Errorf("%w: extracted HTML/Markdown assets are missing", ErrGuidelineIngestionIncomplete)
	}

	var latestJob models.IngestionJob
	jobErr := tx.Where("version_id = ? AND deleted_at IS NULL", version.ID).Order("created_at desc").First(&latestJob).Error
	if jobErr == nil {
		switch strings.ToLower(strings.TrimSpace(latestJob.Status)) {
		case "completed":
		case "failed":
			msg := strings.TrimSpace(latestJob.Error)
			if msg == "" {
				msg = "the ingestion worker reported a failure"
			}
			return fmt.Errorf("%w: %s", ErrGuidelineIngestionFailed, msg)
		default:
			return fmt.Errorf("%w: latest ingestion job status is %s", ErrGuidelineIngestionIncomplete, latestJob.Status)
		}
	} else if !errors.Is(jobErr, gorm.ErrRecordNotFound) {
		return jobErr
	}

	var sectionCount int64
	if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ?", version.ID).Count(&sectionCount).Error; err != nil {
		return err
	}
	if sectionCount == 0 {
		return fmt.Errorf("%w: no extracted sections were generated from the uploaded PDF", ErrGuidelineIngestionIncomplete)
	}

	var chunkCount int64
	if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ?", version.ID).Count(&chunkCount).Error; err != nil {
		return err
	}
	if chunkCount == 0 {
		return fmt.Errorf("%w: no vectorized chunks were generated from the uploaded PDF", ErrGuidelineIngestionIncomplete)
	}

	return nil
}

func protocolCode(document *models.GuidelineDocument, version *models.GuidelineVersion) string {
	base := slug(protocolProgramArea(document))
	if base == "" {
		base = slug(document.Title)
	}
	if base == "" {
		base = "guideline"
	}
	return fmt.Sprintf("%s-%s", base, slug(version.Version))
}

func protocolTitle(document *models.GuidelineDocument) string {
	disease := protocolProgramArea(document)
	if disease == "" {
		disease = document.Title
	}
	if disease == "" {
		disease = "Guideline"
	}
	return fmt.Sprintf("%s Protocol", disease)
}

func protocolProgramArea(document *models.GuidelineDocument) string {
	if strings.TrimSpace(document.ProgramArea) != "" {
		return strings.TrimSpace(document.ProgramArea)
	}
	return strings.TrimSpace(document.Title)
}

func protocolLanguage(document *models.GuidelineDocument) string {
	if strings.TrimSpace(document.Language) != "" {
		return document.Language
	}
	return "en"
}

func generatedProtocolDefinition(document *models.GuidelineDocument, version *models.GuidelineVersion) ProtocolDefinition {
	disease := protocolProgramArea(document)
	if disease == "" {
		disease = "disease"
	}
	source := document.SourceOrg
	if strings.TrimSpace(source) == "" {
		source = document.Title
	}
	stepID := slug(disease)
	if stepID == "" {
		stepID = "guideline"
	}

	return ProtocolDefinition{
		ID:      protocolCode(document, version),
		Title:   protocolTitle(document),
		Source:  source,
		Version: version.Version,
		Steps: []ProtocolStep{
			{
				ID:      stepID + "_assessment",
				Type:    "recommendation",
				Message: fmt.Sprintf("Use the uploaded %s guideline to assess and manage %s. Review the extracted guideline sections before finalizing this protocol.", disease, disease),
				Citation: map[string]string{
					"document": document.Title,
					"section":  "Initial assessment",
				},
			},
		},
	}
}

var nonSlugPattern = regexp.MustCompile(`[^a-z0-9]+`)

func slug(value string) string {
	s := strings.ToLower(strings.TrimSpace(value))
	s = nonSlugPattern.ReplaceAllString(s, "-")
	s = strings.Trim(s, "-")
	if s == "" {
		return ""
	}
	return s
}
