package services

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

var (
	ErrCalculatorVersionConflict       = errors.New("calculator version was changed by another editor")
	ErrCalculatorVersionImmutable      = errors.New("published calculator versions are immutable")
	ErrCalculatorVersionInvalidState   = errors.New("calculator version state transition is invalid")
	ErrCalculatorVersionValidation     = errors.New("calculator definition validation failed")
	ErrCalculatorVersionTestsFailed    = errors.New("calculator definition tests have not passed")
	ErrCalculatorVersionAuthorApproval = errors.New("author cannot approve this clinically critical version")
	ErrCalculatorMigrationConflict     = errors.New("clinical tool migration conflicts with an existing version")
)

type CalculatorVersionService struct {
	DB  *gorm.DB
	Now func() time.Time
}

type CalculatorVersionDTO struct {
	ID                 uuid.UUID                `json:"id"`
	CalculatorID       uuid.UUID                `json:"calculator_id"`
	SemanticVersion    string                   `json:"semantic_version"`
	SchemaVersion      string                   `json:"schema_version"`
	Definition         clinicaltools.Definition `json:"definition"`
	DefinitionChecksum string                   `json:"definition_checksum"`
	Status             string                   `json:"status"`
	ChangeSummary      string                   `json:"change_summary"`
	CreatedBy          *uuid.UUID               `json:"created_by,omitempty"`
	ReviewedBy         *uuid.UUID               `json:"reviewed_by,omitempty"`
	ApprovedBy         *uuid.UUID               `json:"approved_by,omitempty"`
	PublishedBy        *uuid.UUID               `json:"published_by,omitempty"`
	ReviewedAt         *time.Time               `json:"reviewed_at,omitempty"`
	ApprovedAt         *time.Time               `json:"approved_at,omitempty"`
	PublishedAt        *time.Time               `json:"published_at,omitempty"`
	EffectiveAt        *time.Time               `json:"effective_at,omitempty"`
	ReviewAt           *time.Time               `json:"review_at,omitempty"`
	ValidationPassed   bool                     `json:"validation_passed"`
	TestsPassed        bool                     `json:"tests_passed"`
	LockVersion        int                      `json:"lock_version"`
	CreatedAt          time.Time                `json:"created_at"`
	UpdatedAt          time.Time                `json:"updated_at"`
}

type CreateCalculatorVersionInput struct {
	Definition    json.RawMessage `json:"definition" swaggertype:"object"`
	ChangeSummary string          `json:"change_summary"`
}
type UpdateCalculatorVersionInput struct {
	Definition    json.RawMessage `json:"definition" swaggertype:"object"`
	ChangeSummary string          `json:"change_summary"`
	LockVersion   int             `json:"lock_version"`
}

type DuplicateCalculatorVersionInput struct {
	SemanticVersion string `json:"semantic_version" binding:"required"`
	ChangeSummary   string `json:"change_summary"`
}

type CalculatorVersionReviewCommentInput struct {
	Comment string `json:"comment" binding:"required,max=4000"`
}

type CalculatorDefinitionDTO struct {
	CalculatorID       uuid.UUID                `json:"calculator_id"`
	VersionID          uuid.UUID                `json:"version_id"`
	RuntimeType        string                   `json:"runtime_type"`
	SemanticVersion    string                   `json:"semantic_version"`
	DefinitionChecksum string                   `json:"definition_checksum"`
	Definition         clinicaltools.Definition `json:"definition"`
}

type CalculatorVersionValidationDTO struct {
	Valid       bool                            `json:"valid"`
	Errors      []clinicaltools.ValidationError `json:"errors"`
	LockVersion int                             `json:"lock_version"`
}

type CalculatorVersionTestDTO struct {
	Report      clinicaltools.TestReport `json:"report"`
	LockVersion int                      `json:"lock_version"`
}

type CalculatorVersionAuditDTO struct {
	ID                  uuid.UUID      `json:"id"`
	CalculatorID        uuid.UUID      `json:"calculator_id"`
	CalculatorVersionID *uuid.UUID     `json:"calculator_version_id,omitempty"`
	ActorID             *uuid.UUID     `json:"actor_id,omitempty"`
	Action              string         `json:"action"`
	FromStatus          *string        `json:"from_status,omitempty"`
	ToStatus            *string        `json:"to_status,omitempty"`
	Metadata            map[string]any `json:"metadata"`
	CreatedAt           time.Time      `json:"created_at"`
}

func (s CalculatorVersionService) Definition(calculatorID uuid.UUID) (*CalculatorDefinitionDTO, error) {
	var tool models.Calculator
	if err := s.DB.First(&tool, "id = ?", calculatorID).Error; err != nil {
		return nil, err
	}
	if tool.RuntimeType != "schema_v1" || tool.CurrentVersionID == nil {
		return nil, ErrCalculatorVersionInvalidState
	}
	var version models.CalculatorVersion
	if err := s.DB.First(&version, "id = ? AND calculator_id = ? AND status = 'published'", *tool.CurrentVersionID, tool.ID).Error; err != nil {
		return nil, err
	}
	definition, validation := clinicaltools.ParseAndValidate(version.DefinitionJSON)
	if !validation.Valid {
		return nil, ErrCalculatorVersionValidation
	}
	return &CalculatorDefinitionDTO{CalculatorID: tool.ID, VersionID: version.ID, RuntimeType: tool.RuntimeType, SemanticVersion: version.SemanticVersion, DefinitionChecksum: version.DefinitionChecksum, Definition: *definition}, nil
}

func (s CalculatorVersionService) List(calculatorID uuid.UUID) ([]CalculatorVersionDTO, error) {
	var rows []models.CalculatorVersion
	if err := s.DB.Where("calculator_id = ?", calculatorID).Order("created_at DESC, id DESC").Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]CalculatorVersionDTO, 0, len(rows))
	for _, row := range rows {
		item, err := calculatorVersionDTO(row)
		if err != nil {
			return nil, err
		}
		items = append(items, *item)
	}
	return items, nil
}

func (s CalculatorVersionService) Get(versionID uuid.UUID) (*CalculatorVersionDTO, error) {
	var row models.CalculatorVersion
	if err := s.DB.First(&row, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	return calculatorVersionDTO(row)
}

func (s CalculatorVersionService) Duplicate(versionID, actorID uuid.UUID, in DuplicateCalculatorVersionInput) (*CalculatorVersionDTO, clinicaltools.ValidationResult, error) {
	var source models.CalculatorVersion
	if err := s.DB.First(&source, "id = ?", versionID).Error; err != nil {
		return nil, clinicaltools.ValidationResult{}, err
	}
	definition, validation := clinicaltools.ParseAndValidate(source.DefinitionJSON)
	if !validation.Valid {
		return nil, validation, ErrCalculatorVersionValidation
	}
	definition.Version = strings.TrimSpace(in.SemanticVersion)
	raw, err := json.Marshal(definition)
	if err != nil {
		return nil, validation, err
	}
	return s.CreateDraft(source.CalculatorID, actorID, CreateCalculatorVersionInput{Definition: raw, ChangeSummary: in.ChangeSummary})
}

func (s CalculatorVersionService) ValidateVersion(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionValidationDTO, error) {
	var response CalculatorVersionValidationDTO
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status != "draft" {
			return ErrCalculatorVersionImmutable
		}
		_, validation := clinicaltools.ParseAndValidate(row.DefinitionJSON)
		result := tx.Model(&models.CalculatorVersion{}).Where("id = ? AND status = 'draft' AND lock_version = ?", row.ID, lockVersion).Updates(map[string]any{"validation_passed": validation.Valid, "tests_passed": false, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": s.now()})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.validated", calculatorStringPointer("draft"), calculatorStringPointer("draft"), map[string]any{"valid": validation.Valid, "error_count": len(validation.Errors)}); err != nil {
			return err
		}
		response = CalculatorVersionValidationDTO{Valid: validation.Valid, Errors: validation.Errors, LockVersion: lockVersion + 1}
		return nil
	})
	return &response, err
}

func (s CalculatorVersionService) RunTests(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionTestDTO, error) {
	var response CalculatorVersionTestDTO
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status != "draft" {
			return ErrCalculatorVersionImmutable
		}
		definition, validation := clinicaltools.ParseAndValidate(row.DefinitionJSON)
		if !validation.Valid {
			return ErrCalculatorVersionValidation
		}
		report := clinicaltools.ExecuteTestCases(definition)
		if err := persistCalculatorTestReport(tx, row.ID, report, s.now()); err != nil {
			return err
		}
		result := tx.Model(&models.CalculatorVersion{}).
			Where("id = ? AND status = 'draft' AND lock_version = ?", row.ID, lockVersion).
			Updates(map[string]any{"validation_passed": true, "tests_passed": report.Passed, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": s.now()})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.tests_run", calculatorStringPointer("draft"), calculatorStringPointer("draft"), map[string]any{"passed": report.Passed, "case_count": len(report.Cases)}); err != nil {
			return err
		}
		response = CalculatorVersionTestDTO{Report: report, LockVersion: lockVersion + 1}
		return nil
	})
	return &response, err
}

func (s CalculatorVersionService) Audit(versionID uuid.UUID) ([]CalculatorVersionAuditDTO, error) {
	var rows []models.CalculatorVersionAudit
	if err := s.DB.Where("calculator_version_id = ?", versionID).Order("created_at ASC, id ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]CalculatorVersionAuditDTO, 0, len(rows))
	for _, row := range rows {
		metadata := map[string]any{}
		_ = json.Unmarshal(row.MetadataJSON, &metadata)
		items = append(items, CalculatorVersionAuditDTO{ID: row.ID, CalculatorID: row.CalculatorID, CalculatorVersionID: row.CalculatorVersionID, ActorID: row.ActorID, Action: row.Action, FromStatus: row.FromStatus, ToStatus: row.ToStatus, Metadata: metadata, CreatedAt: row.CreatedAt})
	}
	return items, nil
}

func (s CalculatorVersionService) AddReviewComment(versionID, actorID uuid.UUID, input CalculatorVersionReviewCommentInput) error {
	comment := strings.TrimSpace(input.Comment)
	if comment == "" || len(comment) > 4000 {
		return ErrCalculatorVersionValidation
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status == "withdrawn" {
			return ErrCalculatorVersionInvalidState
		}
		return writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.review_commented", calculatorStringPointer(row.Status), calculatorStringPointer(row.Status), map[string]any{"comment": comment})
	})
}

func (s CalculatorVersionService) CreateDraft(calculatorID, actorID uuid.UUID, in CreateCalculatorVersionInput) (*CalculatorVersionDTO, clinicaltools.ValidationResult, error) {
	definition, validation := clinicaltools.ParseAndValidate(in.Definition)
	if !validation.Valid {
		return nil, validation, ErrCalculatorVersionValidation
	}
	var tool models.Calculator
	if err := s.DB.First(&tool, "id = ?", calculatorID).Error; err != nil {
		return nil, validation, err
	}
	if tool.Type != definition.ToolType {
		return nil, clinicaltools.ValidationResult{Valid: false, Errors: []clinicaltools.ValidationError{{Path: "$.tool_type", Code: "type_mismatch", Message: "definition type does not match calculator"}}}, ErrCalculatorVersionValidation
	}
	canonical, _ := json.Marshal(definition)
	row := models.CalculatorVersion{CalculatorID: calculatorID, SemanticVersion: definition.Version, SchemaVersion: definition.SchemaVersion, DefinitionJSON: datatypes.JSON(canonical), DefinitionChecksum: definitionChecksum(canonical), Status: "draft", ChangeSummary: strings.TrimSpace(in.ChangeSummary), CreatedBy: &actorID, EffectiveAt: definition.EffectiveAt, ReviewAt: definition.ReviewAt, LockVersion: 1}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		if err := replaceCalculatorVersionChildren(tx, &row, *definition); err != nil {
			return err
		}
		return writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.created", nil, calculatorStringPointer("draft"), map[string]any{"semantic_version": row.SemanticVersion, "checksum": row.DefinitionChecksum})
	})
	if err != nil {
		return nil, validation, err
	}
	dto, err := calculatorVersionDTO(row)
	return dto, validation, err
}

func (s CalculatorVersionService) UpdateDraft(versionID, actorID uuid.UUID, in UpdateCalculatorVersionInput) (*CalculatorVersionDTO, clinicaltools.ValidationResult, error) {
	definition, validation := clinicaltools.ParseAndValidate(in.Definition)
	if !validation.Valid {
		return nil, validation, ErrCalculatorVersionValidation
	}
	canonical, _ := json.Marshal(definition)
	var updated models.CalculatorVersion
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var current models.CalculatorVersion
		if err := tx.First(&current, "id = ?", versionID).Error; err != nil {
			return err
		}
		if current.Status != "draft" {
			return ErrCalculatorVersionImmutable
		}
		if current.SemanticVersion != definition.Version {
			return ErrCalculatorVersionInvalidState
		}
		result := tx.Model(&models.CalculatorVersion{}).Where("id = ? AND status = 'draft' AND lock_version = ?", versionID, in.LockVersion).Updates(map[string]any{"definition_json": datatypes.JSON(canonical), "definition_checksum": definitionChecksum(canonical), "change_summary": strings.TrimSpace(in.ChangeSummary), "effective_at": definition.EffectiveAt, "review_at": definition.ReviewAt, "validation_passed": false, "tests_passed": false, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": s.now()})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := replaceCalculatorVersionChildren(tx, &current, *definition); err != nil {
			return err
		}
		if err := writeCalculatorVersionAudit(tx, current.CalculatorID, &current.ID, actorID, "calculator.version.updated", calculatorStringPointer("draft"), calculatorStringPointer("draft"), map[string]any{"lock_version": in.LockVersion + 1}); err != nil {
			return err
		}
		return tx.First(&updated, "id = ?", versionID).Error
	})
	if err != nil {
		return nil, validation, err
	}
	dto, err := calculatorVersionDTO(updated)
	return dto, validation, err
}

func (s CalculatorVersionService) Submit(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionDTO, error) {
	return s.transition(versionID, actorID, lockVersion, "draft", "pending_review", "calculator.version.submitted", nil)
}
func (s CalculatorVersionService) Approve(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionDTO, error) {
	var row models.CalculatorVersion
	if err := s.DB.First(&row, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	definition, validation := clinicaltools.ParseAndValidate(row.DefinitionJSON)
	if !validation.Valid {
		return nil, ErrCalculatorVersionValidation
	}
	if report := clinicaltools.ExecuteTestCases(definition); !report.Passed {
		return nil, ErrCalculatorVersionTestsFailed
	}
	if !row.ValidationPassed || !row.TestsPassed {
		return nil, ErrCalculatorVersionTestsFailed
	}
	if row.CreatedBy != nil && *row.CreatedBy == actorID {
		var tool models.Calculator
		if err := s.DB.First(&tool, "id = ?", row.CalculatorID).Error; err != nil {
			return nil, err
		}
		if clinicallyCriticalTool(tool) {
			return nil, ErrCalculatorVersionAuthorApproval
		}
	}
	now := s.now()
	return s.transition(versionID, actorID, lockVersion, "pending_review", "approved", "calculator.version.approved", map[string]any{"reviewed_by": actorID, "reviewed_at": now, "approved_by": actorID, "approved_at": now})
}

func (s CalculatorVersionService) Publish(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionDTO, error) {
	var published models.CalculatorVersion
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status != "approved" {
			return ErrCalculatorVersionInvalidState
		}
		if !row.ValidationPassed {
			return ErrCalculatorVersionValidation
		}
		if !row.TestsPassed {
			return ErrCalculatorVersionTestsFailed
		}
		definition, validation := clinicaltools.ParseAndValidate(row.DefinitionJSON)
		if !validation.Valid {
			return ErrCalculatorVersionValidation
		}
		testReport := clinicaltools.ExecuteTestCases(definition)
		if !testReport.Passed {
			return ErrCalculatorVersionTestsFailed
		}
		now := s.now()
		if err := persistCalculatorTestReport(tx, row.ID, testReport, now); err != nil {
			return err
		}
		if err := supersedeCurrentCalculatorVersion(tx, row.CalculatorID, actorID, now); err != nil {
			return err
		}
		result := tx.Model(&models.CalculatorVersion{}).Where("id = ? AND status = 'approved' AND lock_version = ?", versionID, lockVersion).Updates(map[string]any{"status": "published", "published_by": actorID, "published_at": now, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": now})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := tx.Model(&models.Calculator{}).Where("id = ?", row.CalculatorID).Updates(map[string]any{"current_version_id": row.ID, "runtime_type": "schema_v1", "version": row.SemanticVersion, "updated_at": now}).Error; err != nil {
			return err
		}
		if err := writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.published", calculatorStringPointer("approved"), calculatorStringPointer("published"), map[string]any{"checksum": row.DefinitionChecksum}); err != nil {
			return err
		}
		return tx.First(&published, "id = ?", row.ID).Error
	})
	if err != nil {
		return nil, err
	}
	return calculatorVersionDTO(published)
}

func (s CalculatorVersionService) SelectPublished(calculatorID, versionID, actorID uuid.UUID, lockVersion int) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ? AND calculator_id = ?", versionID, calculatorID).Error; err != nil {
			return err
		}
		if row.Status != "superseded" {
			return ErrCalculatorVersionInvalidState
		}
		now := s.now()
		if err := supersedeCurrentCalculatorVersion(tx, calculatorID, actorID, now); err != nil {
			return err
		}
		result := tx.Model(&models.CalculatorVersion{}).
			Where("id = ? AND status = 'superseded' AND lock_version = ?", versionID, lockVersion).
			Updates(map[string]any{"status": "published", "lock_version": gorm.Expr("lock_version + 1"), "updated_at": now})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := tx.Model(&models.Calculator{}).Where("id = ?", calculatorID).Updates(map[string]any{"current_version_id": versionID, "runtime_type": "schema_v1", "version": row.SemanticVersion, "updated_at": now}).Error; err != nil {
			return err
		}
		return writeCalculatorVersionAudit(tx, calculatorID, &versionID, actorID, "calculator.version.selected", nil, calculatorStringPointer("published"), map[string]any{"semantic_version": row.SemanticVersion})
	})
}

// SelectLegacyRuntime is the emergency rollback path for a migrated tool. It
// deliberately keeps every immutable schema version and its audit history, but
// removes the active schema pointer so clients return to the characterized HTML
// artifact. A later rollout must go through review and SelectPublished/Publish
// again; this method never promotes a draft or bypasses lifecycle checks.
func (s CalculatorVersionService) SelectLegacyRuntime(calculatorID, actorID uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var tool models.Calculator
		if err := tx.First(&tool, "id = ?", calculatorID).Error; err != nil {
			return err
		}
		if tool.RuntimeType == "legacy_html" && tool.CurrentVersionID == nil {
			return nil
		}
		now := s.now()
		if tool.CurrentVersionID != nil {
			var current models.CalculatorVersion
			if err := tx.First(&current, "id = ? AND calculator_id = ?", *tool.CurrentVersionID, tool.ID).Error; err != nil {
				return err
			}
			if current.Status != "published" {
				return ErrCalculatorVersionInvalidState
			}
			result := tx.Model(&models.CalculatorVersion{}).
				Where("id = ? AND status = 'published' AND lock_version = ?", current.ID, current.LockVersion).
				Updates(map[string]any{"status": "superseded", "lock_version": gorm.Expr("lock_version + 1"), "updated_at": now})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected == 0 {
				return ErrCalculatorVersionConflict
			}
			if err := writeCalculatorVersionAudit(tx, tool.ID, &current.ID, actorID, "calculator.version.superseded_for_legacy_rollback", calculatorStringPointer("published"), calculatorStringPointer("superseded"), nil); err != nil {
				return err
			}
		}
		if err := tx.Model(&models.Calculator{}).Where("id = ?", tool.ID).Updates(map[string]any{
			"runtime_type":       "legacy_html",
			"current_version_id": nil,
			"updated_at":         now,
		}).Error; err != nil {
			return err
		}
		return writeCalculatorVersionAudit(tx, tool.ID, nil, actorID, "calculator.runtime.legacy_selected", calculatorStringPointer("schema_v1"), calculatorStringPointer("legacy_html"), nil)
	})
}

func supersedeCurrentCalculatorVersion(tx *gorm.DB, calculatorID, actorID uuid.UUID, now time.Time) error {
	var current []models.CalculatorVersion
	if err := tx.Where("calculator_id = ? AND status = 'published'", calculatorID).Find(&current).Error; err != nil {
		return err
	}
	for _, version := range current {
		result := tx.Model(&models.CalculatorVersion{}).
			Where("id = ? AND status = 'published' AND lock_version = ?", version.ID, version.LockVersion).
			Updates(map[string]any{"status": "superseded", "lock_version": gorm.Expr("lock_version + 1"), "updated_at": now})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := writeCalculatorVersionAudit(tx, calculatorID, &version.ID, actorID, "calculator.version.superseded", calculatorStringPointer("published"), calculatorStringPointer("superseded"), nil); err != nil {
			return err
		}
	}
	return nil
}

// Withdraw marks a non-current immutable version as unavailable for future
// selection. The active version must be rolled back first so a schema_v1 tool
// can never point at a non-published definition.
func (s CalculatorVersionService) Withdraw(versionID, actorID uuid.UUID, lockVersion int) (*CalculatorVersionDTO, error) {
	var row models.CalculatorVersion
	if err := s.DB.First(&row, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	if row.Status != "superseded" {
		return nil, ErrCalculatorVersionInvalidState
	}
	return s.transition(versionID, actorID, lockVersion, "superseded", "withdrawn", "calculator.version.withdrawn", nil)
}

func (s CalculatorVersionService) DeleteDraft(versionID, actorID uuid.UUID, lockVersion int) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status != "draft" {
			return ErrCalculatorVersionImmutable
		}
		result := tx.Where("id = ? AND lock_version = ?", versionID, lockVersion).Delete(&models.CalculatorVersion{})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		return writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, "calculator.version.deleted", calculatorStringPointer("draft"), nil, nil)
	})
}

func (s CalculatorVersionService) transition(versionID, actorID uuid.UUID, lockVersion int, from, to, action string, extra map[string]any) (*CalculatorVersionDTO, error) {
	var updated models.CalculatorVersion
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var row models.CalculatorVersion
		if err := tx.First(&row, "id = ?", versionID).Error; err != nil {
			return err
		}
		if row.Status != from {
			return ErrCalculatorVersionInvalidState
		}
		updates := map[string]any{"status": to, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": s.now()}
		for key, value := range extra {
			updates[key] = value
		}
		result := tx.Model(&models.CalculatorVersion{}).Where("id = ? AND status = ? AND lock_version = ?", versionID, from, lockVersion).Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrCalculatorVersionConflict
		}
		if err := writeCalculatorVersionAudit(tx, row.CalculatorID, &row.ID, actorID, action, calculatorStringPointer(from), calculatorStringPointer(to), nil); err != nil {
			return err
		}
		return tx.First(&updated, "id = ?", versionID).Error
	})
	if err != nil {
		return nil, err
	}
	return calculatorVersionDTO(updated)
}
func (s CalculatorVersionService) now() time.Time {
	if s.Now != nil {
		return s.Now().UTC()
	}
	return time.Now().UTC()
}
func definitionChecksum(value []byte) string {
	sum := sha256.Sum256(value)
	return hex.EncodeToString(sum[:])
}
func clinicallyCriticalTool(tool models.Calculator) bool {
	name := strings.ToLower(tool.Name)
	return tool.Type == "decision_tool" || strings.Contains(name, "dose") || strings.Contains(name, "medication") || strings.Contains(name, "triage") || strings.Contains(name, "emergency")
}
func calculatorStringPointer(value string) *string { return &value }
func writeCalculatorVersionAudit(tx *gorm.DB, calculatorID uuid.UUID, versionID *uuid.UUID, actorID uuid.UUID, action string, from, to *string, metadata any) error {
	raw := []byte("{}")
	if metadata != nil {
		raw, _ = json.Marshal(metadata)
	}
	return tx.Create(&models.CalculatorVersionAudit{CalculatorID: calculatorID, CalculatorVersionID: versionID, ActorID: &actorID, Action: action, FromStatus: from, ToStatus: to, MetadataJSON: datatypes.JSON(raw)}).Error
}
func replaceCalculatorVersionChildren(tx *gorm.DB, row *models.CalculatorVersion, definition clinicaltools.Definition) error {
	if err := tx.Unscoped().Where("calculator_version_id = ?", row.ID).Delete(&models.CalculatorTestCase{}).Error; err != nil {
		return err
	}
	if err := tx.Unscoped().Where("calculator_version_id = ?", row.ID).Delete(&models.CalculatorCitation{}).Error; err != nil {
		return err
	}
	for _, test := range definition.TestCases {
		input, _ := json.Marshal(test.Inputs)
		expected, _ := json.Marshal(test.Expected)
		child := models.CalculatorTestCase{CalculatorVersionID: row.ID, TestKey: test.Key, Description: test.Description, FixedNow: test.FixedNow, InputJSON: datatypes.JSON(input), ExpectedJSON: datatypes.JSON(expected), NumericTolerance: test.NumericTolerance}
		if err := tx.Create(&child).Error; err != nil {
			return err
		}
	}
	for index, citation := range definition.Citations {
		var published, accessed *time.Time
		if citation.PublishedAt != "" {
			value, err := time.Parse("2006-01-02", citation.PublishedAt)
			if err != nil {
				return err
			}
			published = &value
		}
		if citation.AccessedAt != "" {
			value, err := time.Parse("2006-01-02", citation.AccessedAt)
			if err != nil {
				return err
			}
			accessed = &value
		}
		child := models.CalculatorCitation{CalculatorVersionID: row.ID, CitationKey: citation.Key, Title: citation.Title, Organization: citation.Organization, URL: citation.URL, PublishedAt: published, AccessedAt: accessed, SortOrder: index}
		if err := tx.Create(&child).Error; err != nil {
			return err
		}
	}
	return nil
}

func persistCalculatorTestReport(tx *gorm.DB, versionID uuid.UUID, report clinicaltools.TestReport, now time.Time) error {
	for _, test := range report.Cases {
		actual, err := json.Marshal(test.Actual)
		if err != nil {
			return err
		}
		result := tx.Model(&models.CalculatorTestCase{}).
			Where("calculator_version_id = ? AND test_key = ?", versionID, test.Key).
			Updates(map[string]any{"last_result_json": datatypes.JSON(actual), "last_passed": test.Passed, "last_run_at": now, "updated_at": now})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return gorm.ErrRecordNotFound
		}
	}
	return nil
}
func calculatorVersionDTO(row models.CalculatorVersion) (*CalculatorVersionDTO, error) {
	var definition clinicaltools.Definition
	if err := json.Unmarshal(row.DefinitionJSON, &definition); err != nil {
		return nil, err
	}
	return &CalculatorVersionDTO{ID: row.ID, CalculatorID: row.CalculatorID, SemanticVersion: row.SemanticVersion, SchemaVersion: row.SchemaVersion, Definition: definition, DefinitionChecksum: row.DefinitionChecksum, Status: row.Status, ChangeSummary: row.ChangeSummary, CreatedBy: row.CreatedBy, ReviewedBy: row.ReviewedBy, ApprovedBy: row.ApprovedBy, PublishedBy: row.PublishedBy, ReviewedAt: row.ReviewedAt, ApprovedAt: row.ApprovedAt, PublishedAt: row.PublishedAt, EffectiveAt: row.EffectiveAt, ReviewAt: row.ReviewAt, ValidationPassed: row.ValidationPassed, TestsPassed: row.TestsPassed, LockVersion: row.LockVersion, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}, nil
}
