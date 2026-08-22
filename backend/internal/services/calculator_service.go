package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"mime"
	"os"
	"path/filepath"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

var (
	ErrCalculatorInvalidPayload  = errors.New("invalid calculator payload")
	ErrCalculatorArtifactMissing = errors.New("calculator artifact is missing")
	ErrCalculatorArtifactUnsafe  = errors.New("calculator artifact path is unsafe")
	ErrCalculatorUsageForbidden  = errors.New("calculator usage session is not owned by the user")
)

type CalculatorService struct {
	DB               *gorm.DB
	StaticSamplesDir string
}

type CalculatorListInput struct {
	Page     PageInput
	Search   string
	Type     string
	Status   string
	Featured *bool
	Sort     string
	Order    string
}

type CreateCalculatorInput struct {
	Name            string          `json:"name"`
	Description     string          `json:"description"`
	Icon            string          `json:"icon"`
	Color           string          `json:"color"`
	BackgroundColor string          `json:"background_color"`
	AppFileJSON     json.RawMessage `json:"app_file_json" swaggertype:"object"`
	Version         string          `json:"version"`
	Type            string          `json:"type"`
	Status          string          `json:"status"`
	Featured        bool            `json:"featured"`
}

type UpdateCalculatorInput struct {
	Name            *string          `json:"name"`
	Description     *string          `json:"description"`
	Icon            *string          `json:"icon"`
	Color           *string          `json:"color"`
	BackgroundColor *string          `json:"background_color"`
	AppFileJSON     *json.RawMessage `json:"app_file_json" swaggertype:"object"`
	Version         *string          `json:"version"`
	Type            *string          `json:"type"`
	Status          *string          `json:"status"`
	Featured        *bool            `json:"featured"`
}

type StartCalculatorUsageInput struct {
	SessionStart   string `json:"session_start"`
	CalculatorType string `json:"calculator_type"`
}

type FinishCalculatorUsageInput struct {
	SessionEnd string `json:"session_end"`
}

type CalculatorArtifact struct {
	Content     []byte
	ContentType string
	Filename    string
}

type calculatorArtifactMetadata struct {
	Name string `json:"name"`
	Path string `json:"path"`
	HTML string `json:"html"`
}

func (s CalculatorService) List(in CalculatorListInput) (*PageResult[models.Calculator], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.Calculator{})

	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		query = query.Where("LOWER(name) LIKE LOWER(?) OR LOWER(COALESCE(description, '')) LIKE LOWER(?)", like, like)
	}
	if toolTypes := splitCalculatorFilter(in.Type); len(toolTypes) > 0 {
		if !allCalculatorValuesValid(toolTypes, validCalculatorType) {
			return nil, ErrCalculatorInvalidPayload
		}
		query = query.Where("type IN ?", toolTypes)
	}
	if statuses := splitCalculatorFilter(in.Status); len(statuses) > 0 {
		if !allCalculatorValuesValid(statuses, validCalculatorStatus) {
			return nil, ErrCalculatorInvalidPayload
		}
		query = query.Where("status IN ?", statuses)
	}
	if in.Featured != nil {
		query = query.Where("featured = ?", *in.Featured)
	}

	var total int64
	if err := query.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}

	items := []models.Calculator{}
	if err := query.Session(&gorm.Session{}).
		Order(calculatorSort(in.Sort, in.Order)).
		Limit(page.PerPage).
		Offset(page.Offset()).
		Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s CalculatorService) Get(id uuid.UUID) (*models.Calculator, error) {
	var calculator models.Calculator
	if err := s.DB.First(&calculator, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &calculator, nil
}

func (s CalculatorService) Create(userID uuid.UUID, in CreateCalculatorInput) (*models.Calculator, error) {
	if err := validateCalculatorInput(in.Name, in.Version, in.Type, in.Status, in.AppFileJSON); err != nil {
		return nil, err
	}
	status := strings.TrimSpace(in.Status)
	if status == "" {
		status = "draft"
	}
	calculator := models.Calculator{
		AddedByUserID:   userID,
		Name:            strings.TrimSpace(in.Name),
		Description:     strings.TrimSpace(in.Description),
		Icon:            strings.TrimSpace(in.Icon),
		Color:           strings.TrimSpace(in.Color),
		BackgroundColor: strings.TrimSpace(in.BackgroundColor),
		AppFileJSON:     datatypes.JSON(bytes.Clone(in.AppFileJSON)),
		Version:         strings.TrimSpace(in.Version),
		Type:            strings.TrimSpace(in.Type),
		Status:          status,
		Featured:        in.Featured,
	}
	if err := s.DB.Create(&calculator).Error; err != nil {
		return nil, err
	}
	return &calculator, nil
}

func (s CalculatorService) Update(id uuid.UUID, in UpdateCalculatorInput) (*models.Calculator, error) {
	updates := map[string]any{}
	copyCalculatorString(updates, "name", in.Name)
	copyCalculatorString(updates, "description", in.Description)
	copyCalculatorString(updates, "icon", in.Icon)
	copyCalculatorString(updates, "color", in.Color)
	copyCalculatorString(updates, "background_color", in.BackgroundColor)
	copyCalculatorString(updates, "version", in.Version)
	if in.Type != nil {
		value := strings.TrimSpace(*in.Type)
		if !validCalculatorType(value) {
			return nil, ErrCalculatorInvalidPayload
		}
		updates["type"] = value
	}
	if in.Status != nil {
		value := strings.TrimSpace(*in.Status)
		if !validCalculatorStatus(value) {
			return nil, ErrCalculatorInvalidPayload
		}
		updates["status"] = value
	}
	if in.Featured != nil {
		updates["featured"] = *in.Featured
	}
	if in.AppFileJSON != nil {
		if !validCalculatorArtifact(*in.AppFileJSON) {
			return nil, ErrCalculatorInvalidPayload
		}
		updates["app_file_json"] = datatypes.JSON(bytes.Clone(*in.AppFileJSON))
	}
	if name, ok := updates["name"].(string); ok && name == "" {
		return nil, ErrCalculatorInvalidPayload
	}
	if version, ok := updates["version"].(string); ok && version == "" {
		return nil, ErrCalculatorInvalidPayload
	}
	if len(updates) > 0 {
		updates["updated_at"] = time.Now().UTC()
		result := s.DB.Model(&models.Calculator{}).Where("id = ?", id).Updates(updates)
		if result.Error != nil {
			return nil, result.Error
		}
		if result.RowsAffected == 0 {
			return nil, gorm.ErrRecordNotFound
		}
	}
	return s.Get(id)
}

func (s CalculatorService) Delete(id uuid.UUID) error {
	result := s.DB.Delete(&models.Calculator{}, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s CalculatorService) Artifact(id uuid.UUID) (*CalculatorArtifact, error) {
	calculator, err := s.Get(id)
	if err != nil {
		return nil, err
	}
	return resolveCalculatorArtifact(calculator.AppFileJSON, s.StaticSamplesDir)
}

func (s CalculatorService) StartUsage(userID, calculatorID uuid.UUID, in StartCalculatorUsageInput) (*models.CalculatorUsageLog, error) {
	if strings.TrimSpace(in.SessionStart) == "" || !validCalculatorType(in.CalculatorType) {
		return nil, ErrCalculatorInvalidPayload
	}
	calculator, err := s.Get(calculatorID)
	if err != nil {
		return nil, err
	}
	log := models.CalculatorUsageLog{
		UserID:              userID,
		CalculatorID:        calculatorID,
		SessionStart:        strings.TrimSpace(in.SessionStart),
		CalculatorType:      strings.TrimSpace(in.CalculatorType),
		CalculatorVersionID: calculator.CurrentVersionID,
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&log).Error; err != nil {
			return err
		}
		return tx.Model(&models.Calculator{}).
			Where("id = ?", calculatorID).
			UpdateColumn("usage_count", gorm.Expr("usage_count + 1")).Error
	})
	if err != nil {
		return nil, err
	}
	return &log, nil
}

func (s CalculatorService) FinishUsage(userID, usageID uuid.UUID, in FinishCalculatorUsageInput) (*models.CalculatorUsageLog, error) {
	sessionEnd := strings.TrimSpace(in.SessionEnd)
	if sessionEnd == "" {
		return nil, ErrCalculatorInvalidPayload
	}
	result := s.DB.Model(&models.CalculatorUsageLog{}).
		Where("id = ? AND user_id = ?", usageID, userID).
		Updates(map[string]any{"session_end": sessionEnd, "updated_at": time.Now().UTC()})
	if result.Error != nil {
		return nil, result.Error
	}
	if result.RowsAffected == 0 {
		return nil, ErrCalculatorUsageForbidden
	}
	var log models.CalculatorUsageLog
	if err := s.DB.First(&log, "id = ? AND user_id = ?", usageID, userID).Error; err != nil {
		return nil, err
	}
	return &log, nil
}

func validateCalculatorInput(name, version, toolType, status string, artifact json.RawMessage) error {
	if strings.TrimSpace(name) == "" || strings.TrimSpace(version) == "" || !validCalculatorType(toolType) {
		return ErrCalculatorInvalidPayload
	}
	if strings.TrimSpace(status) != "" && !validCalculatorStatus(status) {
		return ErrCalculatorInvalidPayload
	}
	if !validCalculatorArtifact(artifact) {
		return ErrCalculatorInvalidPayload
	}
	return nil
}

func validCalculatorArtifact(raw json.RawMessage) bool {
	if len(bytes.TrimSpace(raw)) == 0 || !json.Valid(raw) {
		return false
	}
	var value any
	if err := json.Unmarshal(raw, &value); err != nil {
		return false
	}
	return value != nil
}

func validCalculatorType(value string) bool {
	switch strings.TrimSpace(value) {
	case "calculator", "decision_tool", "checklist":
		return true
	default:
		return false
	}
}

func validCalculatorStatus(value string) bool {
	switch strings.TrimSpace(value) {
	case "active", "draft", "archived":
		return true
	default:
		return false
	}
}

func splitCalculatorFilter(value string) []string {
	result := []string{}
	for _, item := range strings.Split(value, ",") {
		if trimmed := strings.TrimSpace(item); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func allCalculatorValuesValid(values []string, validate func(string) bool) bool {
	for _, value := range values {
		if !validate(value) {
			return false
		}
	}
	return true
}

func calculatorSort(field, order string) string {
	columns := map[string]string{
		"name": "name", "created_at": "created_at", "updated_at": "updated_at", "usage_count": "usage_count",
	}
	column := columns[strings.TrimSpace(field)]
	if column == "" {
		column = "name"
	}
	direction := "ASC"
	if strings.EqualFold(strings.TrimSpace(order), "desc") {
		direction = "DESC"
	}
	return column + " " + direction
}

func copyCalculatorString(updates map[string]any, column string, value *string) {
	if value != nil {
		updates[column] = strings.TrimSpace(*value)
	}
}

func resolveCalculatorArtifact(raw []byte, root string) (*CalculatorArtifact, error) {
	var metadata calculatorArtifactMetadata
	if err := json.Unmarshal(raw, &metadata); err != nil {
		var path string
		if stringErr := json.Unmarshal(raw, &path); stringErr != nil {
			return nil, ErrCalculatorArtifactMissing
		}
		metadata.Path = path
	}
	if html := strings.TrimSpace(metadata.HTML); html != "" {
		return &CalculatorArtifact{
			Content:     []byte(html),
			ContentType: "text/html; charset=utf-8",
			Filename:    safeCalculatorFilename(metadata.Name, "calculator.html"),
		}, nil
	}

	path := strings.TrimSpace(metadata.Path)
	if path == "" {
		path = strings.TrimSpace(metadata.Name)
	}
	if path == "" {
		return nil, ErrCalculatorArtifactMissing
	}
	clean := filepath.Clean(path)
	if filepath.IsAbs(clean) || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) || filepath.Base(clean) != clean {
		return nil, ErrCalculatorArtifactUnsafe
	}
	content, err := os.ReadFile(filepath.Join(root, clean))
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrCalculatorArtifactMissing
	}
	if err != nil {
		return nil, err
	}
	contentType := mime.TypeByExtension(filepath.Ext(clean))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	return &CalculatorArtifact{Content: content, ContentType: contentType, Filename: clean}, nil
}

func safeCalculatorFilename(value, fallback string) string {
	name := filepath.Base(strings.TrimSpace(value))
	if name == "." || name == "" {
		return fallback
	}
	return name
}

func CalculatorErrorMessage(err error) string {
	switch {
	case errors.Is(err, ErrCalculatorInvalidPayload):
		return "invalid calculator payload"
	case errors.Is(err, ErrCalculatorArtifactMissing):
		return "calculator content is unavailable"
	case errors.Is(err, ErrCalculatorArtifactUnsafe):
		return "calculator content path is invalid"
	case errors.Is(err, ErrCalculatorUsageForbidden):
		return "calculator usage session is not accessible"
	default:
		return fmt.Sprintf("calculator operation failed: %v", err)
	}
}
