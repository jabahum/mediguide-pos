package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CalculatorReviewQueueInput struct {
	Page          PageInput
	Search        string
	Status        string
	ToolType      string
	AuthorID      *uuid.UUID
	ReviewerID    *uuid.UUID
	ClinicalOwner string
	CreatedFrom   *time.Time
	CreatedTo     *time.Time
	Sort          string
	Order         string
}

type CalculatorReviewQueueItem struct {
	VersionID           uuid.UUID  `json:"version_id"`
	CalculatorID        uuid.UUID  `json:"calculator_id"`
	ToolName            string     `json:"tool_name"`
	ToolType            string     `json:"tool_type"`
	ToolStatus          string     `json:"tool_status"`
	SemanticVersion     string     `json:"semantic_version"`
	VersionStatus       string     `json:"version_status"`
	AuthorID            *uuid.UUID `json:"author_id,omitempty"`
	ReviewerID          *uuid.UUID `json:"reviewer_id,omitempty"`
	ClinicalOwner       string     `json:"clinical_owner,omitempty"`
	ClinicalReviewer    string     `json:"clinical_reviewer,omitempty"`
	ValidationPassed    bool       `json:"validation_passed"`
	TestsPassed         bool       `json:"tests_passed"`
	FixtureCount        int        `json:"fixture_count"`
	FixturePassedCount  int        `json:"fixture_passed_count"`
	ReviewEvidenceState string     `json:"review_evidence_status"`
	LastAuditAction     string     `json:"last_audit_action,omitempty"`
	LastAuditAt         *time.Time `json:"last_audit_at,omitempty"`
	DefinitionChecksum  string     `json:"definition_checksum"`
	LockVersion         int        `json:"lock_version"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

type CalculatorFixtureReviewDTO struct {
	Key              string         `json:"key"`
	Description      string         `json:"description"`
	Input            map[string]any `json:"input"`
	Expected         map[string]any `json:"expected"`
	LastResult       map[string]any `json:"last_result,omitempty"`
	LastPassed       *bool          `json:"last_passed,omitempty"`
	LastRunAt        *time.Time     `json:"last_run_at,omitempty"`
	NumericTolerance *float64       `json:"numeric_tolerance,omitempty"`
}

type CalculatorVersionPreviewDTO struct {
	Version              CalculatorVersionDTO         `json:"version"`
	ToolName             string                       `json:"tool_name"`
	ToolType             string                       `json:"tool_type"`
	ToolStatus           string                       `json:"tool_status"`
	RuntimeType          string                       `json:"runtime_type"`
	Fixtures             []CalculatorFixtureReviewDTO `json:"fixtures"`
	ReviewEvidenceStatus string                       `json:"review_evidence_status"`
	Audit                []CalculatorVersionAuditDTO  `json:"audit"`
}

func (s CalculatorVersionService) ReviewQueue(input CalculatorReviewQueueInput) (*PageResult[CalculatorReviewQueueItem], error) {
	page := input.Page.Normalize(20, 100)
	query := s.DB.Table("calculator_versions AS cv").
		Joins("JOIN calculators AS c ON c.id = cv.calculator_id AND c.deleted_at IS NULL").
		Where("cv.deleted_at IS NULL")
	if search := strings.ToLower(strings.TrimSpace(input.Search)); search != "" {
		like := "%" + search + "%"
		query = query.Where("LOWER(c.name) LIKE ? OR LOWER(cv.semantic_version) LIKE ?", like, like)
	}
	if values := reviewFilterValues(input.Status, map[string]bool{"draft": true, "pending_review": true, "approved": true, "published": true, "superseded": true, "withdrawn": true}); len(values) > 0 {
		query = query.Where("cv.status IN ?", values)
	}
	if values := reviewFilterValues(input.ToolType, map[string]bool{"calculator": true, "decision_tool": true, "checklist": true}); len(values) > 0 {
		query = query.Where("c.type IN ?", values)
	}
	if input.AuthorID != nil {
		query = query.Where("cv.created_by = ?", *input.AuthorID)
	}
	if input.ReviewerID != nil {
		query = query.Where("cv.reviewed_by = ?", *input.ReviewerID)
	}
	if owner := strings.TrimSpace(input.ClinicalOwner); owner != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("LOWER(cv.definition_json ->> 'clinical_owner') = ?", strings.ToLower(owner))
		} else {
			query = query.Where("LOWER(json_extract(cv.definition_json, '$.clinical_owner')) = ?", strings.ToLower(owner))
		}
	}
	if input.CreatedFrom != nil {
		query = query.Where("cv.created_at >= ?", *input.CreatedFrom)
	}
	if input.CreatedTo != nil {
		query = query.Where("cv.created_at <= ?", *input.CreatedTo)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	sortColumns := map[string]string{"created_at": "cv.created_at", "updated_at": "cv.updated_at", "status": "cv.status", "semantic_version": "cv.semantic_version", "tool_name": "c.name"}
	sortColumn := sortColumns[strings.TrimSpace(input.Sort)]
	if sortColumn == "" {
		sortColumn = "cv.created_at"
	}
	order := "DESC"
	if strings.EqualFold(strings.TrimSpace(input.Order), "asc") {
		order = "ASC"
	}
	type joinedRow struct {
		ID                 uuid.UUID `gorm:"column:id"`
		CalculatorID       uuid.UUID `gorm:"column:calculator_id"`
		SemanticVersion    string
		DefinitionJSON     []byte
		DefinitionChecksum string
		Status             string
		CreatedBy          *uuid.UUID
		ReviewedBy         *uuid.UUID
		ValidationPassed   bool
		TestsPassed        bool
		LockVersion        int
		CreatedAt          time.Time
		UpdatedAt          time.Time
		ToolName           string
		ToolType           string
		ToolStatus         string
	}
	var rows []joinedRow
	err := query.Select("cv.id,cv.calculator_id,cv.semantic_version,cv.definition_json,cv.definition_checksum,cv.status,cv.created_by,cv.reviewed_by,cv.validation_passed,cv.tests_passed,cv.lock_version,cv.created_at,cv.updated_at,c.name AS tool_name,c.type AS tool_type,c.status AS tool_status").
		Order(fmt.Sprintf("%s %s, cv.id DESC", sortColumn, order)).Offset(page.Offset()).Limit(page.PerPage).Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	items := make([]CalculatorReviewQueueItem, 0, len(rows))
	for _, row := range rows {
		var definition clinicaltools.Definition
		if err = json.Unmarshal(row.DefinitionJSON, &definition); err != nil {
			return nil, ErrCalculatorVersionValidation
		}
		var fixtureCount, fixturePassed int64
		if err = s.DB.Model(&models.CalculatorTestCase{}).Where("calculator_version_id = ?", row.ID).Count(&fixtureCount).Error; err != nil {
			return nil, err
		}
		if err = s.DB.Model(&models.CalculatorTestCase{}).Where("calculator_version_id = ? AND last_passed = ?", row.ID, true).Count(&fixturePassed).Error; err != nil {
			return nil, err
		}
		var audit models.CalculatorVersionAudit
		auditErr := s.DB.Where("calculator_version_id = ?", row.ID).Order("created_at DESC, id DESC").First(&audit).Error
		if auditErr != nil && !errors.Is(auditErr, gorm.ErrRecordNotFound) {
			return nil, auditErr
		}
		item := CalculatorReviewQueueItem{VersionID: row.ID, CalculatorID: row.CalculatorID, ToolName: row.ToolName, ToolType: row.ToolType, ToolStatus: row.ToolStatus, SemanticVersion: row.SemanticVersion, VersionStatus: row.Status, AuthorID: row.CreatedBy, ReviewerID: row.ReviewedBy, ClinicalOwner: definition.ClinicalOwner, ClinicalReviewer: definition.ClinicalReviewer, ValidationPassed: row.ValidationPassed, TestsPassed: row.TestsPassed, FixtureCount: int(fixtureCount), FixturePassedCount: int(fixturePassed), ReviewEvidenceState: "source_controlled_review_required", DefinitionChecksum: row.DefinitionChecksum, LockVersion: row.LockVersion, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}
		if auditErr == nil {
			item.LastAuditAction = audit.Action
			item.LastAuditAt = &audit.CreatedAt
		}
		items = append(items, item)
	}
	return NewPageResult(items, page, total), nil
}

func (s CalculatorVersionService) Preview(versionID uuid.UUID) (*CalculatorVersionPreviewDTO, error) {
	version, err := s.Get(versionID)
	if err != nil {
		return nil, err
	}
	var tool models.Calculator
	if err = s.DB.First(&tool, "id = ?", version.CalculatorID).Error; err != nil {
		return nil, err
	}
	var rows []models.CalculatorTestCase
	if err = s.DB.Where("calculator_version_id = ?", versionID).Order("created_at ASC, id ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	fixtures := make([]CalculatorFixtureReviewDTO, 0, len(rows))
	for _, row := range rows {
		item := CalculatorFixtureReviewDTO{Key: row.TestKey, Description: row.Description, Input: map[string]any{}, Expected: map[string]any{}, LastResult: map[string]any{}, LastPassed: row.LastPassed, LastRunAt: row.LastRunAt, NumericTolerance: row.NumericTolerance}
		_ = json.Unmarshal(row.InputJSON, &item.Input)
		_ = json.Unmarshal(row.ExpectedJSON, &item.Expected)
		_ = json.Unmarshal(row.LastResultJSON, &item.LastResult)
		fixtures = append(fixtures, item)
	}
	audit, err := s.Audit(versionID)
	if err != nil {
		return nil, err
	}
	return &CalculatorVersionPreviewDTO{Version: *version, ToolName: tool.Name, ToolType: tool.Type, ToolStatus: tool.Status, RuntimeType: tool.RuntimeType, Fixtures: fixtures, ReviewEvidenceStatus: "source_controlled_review_required", Audit: audit}, nil
}

func reviewFilterValues(raw string, allowed map[string]bool) []string {
	values := []string{}
	seen := map[string]bool{}
	for _, value := range strings.Split(raw, ",") {
		value = strings.ToLower(strings.TrimSpace(value))
		if allowed[value] && !seen[value] {
			seen[value] = true
			values = append(values, value)
		}
	}
	return values
}
