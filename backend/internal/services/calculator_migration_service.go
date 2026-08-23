package services

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// CalculatorMigrationEnvelope is the source-controlled handoff between the
// legacy characterization suite and the normal clinical review workflow.
// SourceChecksum binds the draft to the exact HTML file that was reviewed.
type CalculatorMigrationEnvelope struct {
	LegacyID       string                   `json:"legacy_id"`
	LegacyFile     string                   `json:"legacy_file"`
	SourceChecksum string                   `json:"source_checksum"`
	ChangeSummary  string                   `json:"change_summary"`
	Definition     clinicaltools.Definition `json:"definition"`
}

type CalculatorMigrationResult struct {
	LegacyID        string     `json:"legacy_id"`
	LegacyFile      string     `json:"legacy_file"`
	CalculatorID    *uuid.UUID `json:"calculator_id,omitempty"`
	VersionID       *uuid.UUID `json:"version_id,omitempty"`
	Status          string     `json:"status"`
	DefinitionValid bool       `json:"definition_valid"`
	FixturesPassed  bool       `json:"fixtures_passed"`
	Message         string     `json:"message,omitempty"`
}

type CalculatorMigrationService struct {
	DB       *gorm.DB
	Versions CalculatorVersionService
}

// RetirementReadiness proves that every reviewed legacy artifact has an active,
// immutable schema replacement. It is deliberately strict: an empty blocker
// list is required before production HTML execution may be removed.
func (s CalculatorMigrationService) RetirementReadiness() ([]string, error) {
	return s.runtimeReadiness(false)
}

// SyntheticRuntimeReadiness verifies that schema tools are technically active
// while deliberately allowing synthetic development/rehearsal evidence. It is
// never an authorization to remove the production legacy runtime.
func (s CalculatorMigrationService) SyntheticRuntimeReadiness() ([]string, error) {
	return s.runtimeReadiness(true)
}

func (s CalculatorMigrationService) runtimeReadiness(allowSynthetic bool) ([]string, error) {
	var tools []models.Calculator
	if err := s.DB.Find(&tools).Error; err != nil {
		return nil, err
	}
	byFile := make(map[string][]models.Calculator)
	for _, tool := range tools {
		var artifact calculatorArtifactMetadata
		if json.Unmarshal(tool.AppFileJSON, &artifact) == nil && strings.TrimSpace(artifact.Path) != "" {
			byFile[strings.TrimSpace(artifact.Path)] = append(byFile[strings.TrimSpace(artifact.Path)], tool)
		}
	}
	files := make([]string, 0, len(reviewedLegacyCalculatorChecksums))
	for file := range reviewedLegacyCalculatorChecksums {
		files = append(files, file)
	}
	sort.Strings(files)
	blockers := make([]string, 0)
	for _, file := range files {
		matches := byFile[file]
		if len(matches) != 1 {
			blockers = append(blockers, fmt.Sprintf("%s: expected exactly one calculator, found %d", file, len(matches)))
			continue
		}
		tool := matches[0]
		if tool.RuntimeType != "schema_v1" || tool.CurrentVersionID == nil {
			blockers = append(blockers, fmt.Sprintf("%s: schema_v1 is not active", file))
			continue
		}
		var version models.CalculatorVersion
		if err := s.DB.First(&version, "id = ? AND calculator_id = ?", *tool.CurrentVersionID, tool.ID).Error; err != nil {
			blockers = append(blockers, fmt.Sprintf("%s: active version is unavailable", file))
			continue
		}
		issues := make([]string, 0, 8)
		definition, validation := clinicaltools.ParseAndValidate(version.DefinitionJSON)
		canonicalDefinition, marshalErr := json.Marshal(definition)
		checksumMatches := validation.Valid && marshalErr == nil && strings.EqualFold(version.DefinitionChecksum, definitionChecksum(canonicalDefinition))
		if version.Status != "published" {
			issues = append(issues, "status is not published")
		}
		if !version.ValidationPassed {
			issues = append(issues, "validation did not pass")
		}
		if !version.TestsPassed {
			issues = append(issues, "fixtures did not pass")
		}
		if version.ApprovedBy == nil {
			issues = append(issues, "approved_by is missing")
		}
		if version.ApprovedAt == nil {
			issues = append(issues, "approved_at is missing")
		}
		if version.PublishedBy == nil {
			issues = append(issues, "published_by is missing")
		}
		if version.PublishedAt == nil {
			issues = append(issues, "published_at is missing")
		}
		if !checksumMatches {
			issues = append(issues, "definition checksum does not match canonical persisted definition")
		}
		if !allowSynthetic {
			synthetic, err := s.versionHasSyntheticEvidence(version.ID)
			if err != nil {
				return nil, err
			}
			if synthetic {
				issues = append(issues, "approval or publication uses synthetic non-clinical evidence")
			}
		}
		if len(issues) > 0 {
			blockers = append(blockers, fmt.Sprintf("%s: %s", file, strings.Join(issues, "; ")))
		}
	}
	return blockers, nil
}

func (s CalculatorMigrationService) versionHasSyntheticEvidence(versionID uuid.UUID) (bool, error) {
	if !s.DB.Migrator().HasTable(&models.CalculatorVersionAudit{}) {
		return false, nil
	}
	var rows []models.CalculatorVersionAudit
	if err := s.DB.Where("calculator_version_id = ? AND action IN ?", versionID, []string{"calculator.version.submitted", "calculator.version.approved", "calculator.version.published"}).Find(&rows).Error; err != nil {
		return false, err
	}
	for _, row := range rows {
		var metadata map[string]any
		if json.Unmarshal(row.MetadataJSON, &metadata) == nil && metadata["synthetic_test_evidence"] == true {
			return true, nil
		}
	}
	return false, nil
}

func ParseCalculatorMigrationEnvelope(raw []byte) (*CalculatorMigrationEnvelope, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var envelope CalculatorMigrationEnvelope
	if err := decoder.Decode(&envelope); err != nil {
		return nil, err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return nil, errors.New("migration envelope must contain one JSON object")
	}
	envelope.LegacyID = strings.TrimSpace(envelope.LegacyID)
	envelope.LegacyFile = strings.TrimSpace(envelope.LegacyFile)
	envelope.SourceChecksum = strings.ToLower(strings.TrimSpace(envelope.SourceChecksum))
	if envelope.LegacyID == "" || envelope.LegacyFile == "" || len(envelope.SourceChecksum) != 64 {
		return nil, errors.New("legacy_id, legacy_file, and a SHA-256 source_checksum are required")
	}
	definitionRaw, err := json.Marshal(envelope.Definition)
	if err != nil {
		return nil, err
	}
	if _, validation := clinicaltools.ParseAndValidate(definitionRaw); !validation.Valid {
		return nil, fmt.Errorf("definition validation failed: %v", validation.Errors)
	}
	return &envelope, nil
}

func VerifyCalculatorMigrationSource(envelope CalculatorMigrationEnvelope, source []byte) error {
	digest := sha256.Sum256(source)
	if !strings.EqualFold(envelope.SourceChecksum, hex.EncodeToString(digest[:])) {
		return errors.New("legacy HTML checksum differs from the reviewed migration source")
	}
	return nil
}

// Plan validates a conversion without requiring a database. It is the CI gate
// for generated definitions and intentionally executes every saved fixture.
func (s CalculatorMigrationService) Plan(envelope CalculatorMigrationEnvelope) CalculatorMigrationResult {
	result := CalculatorMigrationResult{LegacyID: envelope.LegacyID, LegacyFile: envelope.LegacyFile, Status: "invalid"}
	raw, err := json.Marshal(envelope.Definition)
	if err != nil {
		result.Message = err.Error()
		return result
	}
	definition, validation := clinicaltools.ParseAndValidate(raw)
	result.DefinitionValid = validation.Valid
	if !validation.Valid {
		result.Message = fmt.Sprintf("definition validation failed: %v", validation.Errors)
		return result
	}
	report := clinicaltools.ExecuteTestCases(definition)
	result.FixturesPassed = report.Passed
	if !report.Passed {
		result.Message = "one or more migration fixtures failed"
		return result
	}
	result.Status = "ready_for_draft_import"
	return result
}

// ImportDraft is idempotent by calculator and semantic version. It never
// submits, approves, or publishes the version.
func (s CalculatorMigrationService) ImportDraft(envelope CalculatorMigrationEnvelope, actorID uuid.UUID) (CalculatorMigrationResult, error) {
	result := s.Plan(envelope)
	if result.Status != "ready_for_draft_import" {
		return result, errors.New(result.Message)
	}
	tool, err := s.findLegacyTool(envelope.LegacyFile)
	if err != nil {
		result.Message = err.Error()
		return result, err
	}
	result.CalculatorID = &tool.ID
	if tool.Type != envelope.Definition.ToolType {
		err = fmt.Errorf("legacy type %q does not match definition type %q", tool.Type, envelope.Definition.ToolType)
		result.Message = err.Error()
		return result, err
	}

	var existing models.CalculatorVersion
	err = s.DB.Where("calculator_id = ? AND semantic_version = ?", tool.ID, envelope.Definition.Version).First(&existing).Error
	if err == nil {
		raw, _ := json.Marshal(envelope.Definition)
		if existing.DefinitionChecksum != definitionChecksum(raw) {
			result.Message = ErrCalculatorMigrationConflict.Error()
			return result, ErrCalculatorMigrationConflict
		}
		result.VersionID = &existing.ID
		result.Status = "already_imported"
		return result, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return result, err
	}

	raw, _ := json.Marshal(envelope.Definition)
	draft, _, err := s.Versions.CreateDraft(tool.ID, actorID, CreateCalculatorVersionInput{
		Definition:    raw,
		ChangeSummary: strings.TrimSpace(envelope.ChangeSummary) + " [legacy_sha256:" + envelope.SourceChecksum + "]",
	})
	if err != nil {
		result.Message = err.Error()
		return result, err
	}
	validated, err := s.Versions.ValidateVersion(draft.ID, actorID, draft.LockVersion)
	if err != nil {
		return result, err
	}
	tested, err := s.Versions.RunTests(draft.ID, actorID, validated.LockVersion)
	if err != nil || !tested.Report.Passed {
		if err == nil {
			err = ErrCalculatorVersionTestsFailed
		}
		return result, err
	}
	result.VersionID = &draft.ID
	result.Status = "draft_imported"
	return result, nil
}

// ReconcileSyntheticDevelopmentDraft replaces only an unapproved, unpublished
// development candidate whose semantic version predates the current canonical
// envelope. It preserves the audit trail and is deliberately unavailable unless
// the guarded caller supplies the explicit synthetic-development marker.
func (s CalculatorMigrationService) ReconcileSyntheticDevelopmentDraft(envelope CalculatorMigrationEnvelope, actorID uuid.UUID, enabled bool) (CalculatorMigrationResult, error) {
	result := s.Plan(envelope)
	if !enabled {
		return result, errors.New("synthetic development reconciliation is not enabled")
	}
	if result.Status != "ready_for_draft_import" {
		return result, errors.New(result.Message)
	}
	tool, err := s.findLegacyTool(envelope.LegacyFile)
	if err != nil {
		return result, err
	}
	result.CalculatorID = &tool.ID
	var existing models.CalculatorVersion
	if err = s.DB.Where("calculator_id = ? AND semantic_version = ?", tool.ID, envelope.Definition.Version).First(&existing).Error; err != nil {
		return result, err
	}
	if existing.Status != "draft" && existing.Status != "pending_review" {
		return result, ErrCalculatorMigrationConflict
	}
	if existing.ApprovedBy != nil || existing.ApprovedAt != nil || existing.PublishedBy != nil || existing.PublishedAt != nil {
		return result, ErrCalculatorMigrationConflict
	}
	if existing.Status == "pending_review" {
		err = s.DB.Transaction(func(tx *gorm.DB) error {
			update := tx.Model(&models.CalculatorVersion{}).
				Where("id = ? AND status = ? AND lock_version = ?", existing.ID, "pending_review", existing.LockVersion).
				Updates(map[string]any{"status": "draft", "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()})
			if update.Error != nil {
				return update.Error
			}
			if update.RowsAffected != 1 {
				return ErrCalculatorVersionConflict
			}
			return writeCalculatorVersionAudit(tx, tool.ID, &existing.ID, actorID, "calculator.version.synthetic_development_reopened", calculatorStringPointer("pending_review"), calculatorStringPointer("draft"), map[string]any{"synthetic_test_evidence": true, "clinical_approval": false})
		})
		if err != nil {
			return result, err
		}
		if err = s.DB.First(&existing, "id = ?", existing.ID).Error; err != nil {
			return result, err
		}
	}
	raw, _ := json.Marshal(envelope.Definition)
	updated, _, err := s.Versions.UpdateDraft(existing.ID, actorID, UpdateCalculatorVersionInput{
		Definition:    raw,
		ChangeSummary: strings.TrimSpace(envelope.ChangeSummary) + " [synthetic development reconciliation] [legacy_sha256:" + envelope.SourceChecksum + "]",
		LockVersion:   existing.LockVersion,
	})
	if err != nil {
		return result, err
	}
	validated, err := s.Versions.ValidateVersion(updated.ID, actorID, updated.LockVersion)
	if err != nil {
		return result, err
	}
	tested, err := s.Versions.RunTests(updated.ID, actorID, validated.LockVersion)
	if err != nil || !tested.Report.Passed {
		if err == nil {
			err = ErrCalculatorVersionTestsFailed
		}
		return result, err
	}
	result.VersionID = &existing.ID
	result.Status = "development_draft_reconciled"
	return result, nil
}

func (s CalculatorMigrationService) findLegacyTool(file string) (*models.Calculator, error) {
	var tools []models.Calculator
	if err := s.DB.Find(&tools).Error; err != nil {
		return nil, err
	}
	matches := make([]models.Calculator, 0, 1)
	for _, tool := range tools {
		var artifact struct {
			Path string `json:"path"`
		}
		if json.Unmarshal(tool.AppFileJSON, &artifact) == nil && strings.TrimSpace(artifact.Path) == file {
			matches = append(matches, tool)
		}
	}
	if len(matches) == 0 {
		return nil, gorm.ErrRecordNotFound
	}
	if len(matches) > 1 {
		sort.Slice(matches, func(i, j int) bool { return matches[i].ID.String() < matches[j].ID.String() })
		return nil, errors.New("multiple calculators reference the same legacy file")
	}
	return &matches[0], nil
}
