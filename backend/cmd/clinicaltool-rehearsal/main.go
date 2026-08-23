package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

const expectedToolCount = 14

type rehearsalToolReport struct {
	LegacyFile         string    `json:"legacy_file"`
	CalculatorID       uuid.UUID `json:"calculator_id"`
	VersionID          uuid.UUID `json:"version_id"`
	DefinitionChecksum string    `json:"definition_checksum"`
	Status             string    `json:"status"`
}

type rehearsalReport struct {
	Kind                   string                `json:"kind"`
	ClinicalApproval       bool                  `json:"clinical_approval"`
	SyntheticTestEvidence  bool                  `json:"synthetic_test_evidence"`
	ComposeProject         string                `json:"compose_project"`
	StartedAt              time.Time             `json:"started_at"`
	CompletedAt            *time.Time            `json:"completed_at,omitempty"`
	AuthorID               uuid.UUID             `json:"author_id"`
	ReviewerID             uuid.UUID             `json:"reviewer_id"`
	PublisherID            uuid.UUID             `json:"publisher_id"`
	Tools                  []rehearsalToolReport `json:"tools"`
	RetirementServiceReady bool                  `json:"retirement_service_ready"`
	RetirementBlockers     []string              `json:"retirement_blockers"`
	Error                  string                `json:"error,omitempty"`
}

func main() {
	var jsonPath, textPath string
	flag.StringVar(&jsonPath, "json-report", "", "machine-readable report path")
	flag.StringVar(&textPath, "text-report", "", "human-readable report path")
	flag.Parse()

	cfg := config.Load()
	project := strings.TrimSpace(os.Getenv("COMPOSE_PROJECT_NAME"))
	report := rehearsalReport{
		Kind:                  "clinical_tool_retirement_rehearsal",
		ClinicalApproval:      false,
		SyntheticTestEvidence: true,
		ComposeProject:        project,
		StartedAt:             time.Now().UTC(),
		Tools:                 []rehearsalToolReport{},
		RetirementBlockers:    []string{},
	}

	err := run(cfg.DatabaseURL, cfg.AppEnv, project, &report)
	completed := time.Now().UTC()
	report.CompletedAt = &completed
	if err != nil {
		report.Error = err.Error()
	}
	if writeErr := writeReports(report, jsonPath, textPath); writeErr != nil {
		fmt.Fprintln(os.Stderr, writeErr)
		os.Exit(1)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "BLOCKED synthetic retirement rehearsal:", err)
		os.Exit(1)
	}
	fmt.Printf("READY synthetic retirement rehearsal completed for %d tools; this is not clinical approval\n", len(report.Tools))
}

func run(databaseURL, environment, project string, report *rehearsalReport) error {
	if err := clinicaltools.ValidateRehearsalTarget(databaseURL, environment, project, os.Getenv("CLINICAL_TOOLS_REHEARSAL")); err != nil {
		return err
	}
	database, err := db.Connect(databaseURL)
	if err != nil {
		return err
	}
	author, err := rehearsalActor(database, "admin@mediguide.health.go.ug")
	if err != nil {
		return fmt.Errorf("synthetic author: %w", err)
	}
	reviewer, err := rehearsalActor(database, "clinician@mediguide.health.go.ug")
	if err != nil {
		return fmt.Errorf("synthetic reviewer: %w", err)
	}
	publisher, err := rehearsalActor(database, "assistant@mediguide.health.go.ug")
	if err != nil {
		return fmt.Errorf("synthetic publisher: %w", err)
	}
	if author == reviewer || author == publisher || reviewer == publisher {
		return errors.New("author, reviewer, and publisher must be separate synthetic actors")
	}
	report.AuthorID, report.ReviewerID, report.PublisherID = author, reviewer, publisher

	tools, err := canonicalTools(database)
	if err != nil {
		return err
	}
	versions := services.CalculatorVersionService{DB: database, SyntheticRehearsalEvidence: true}
	for _, tool := range tools {
		var drafts []models.CalculatorVersion
		if err = database.Where("calculator_id = ? AND status = ?", tool.calculator.ID, "draft").Order("created_at DESC, id DESC").Find(&drafts).Error; err != nil {
			return err
		}
		if len(drafts) != 1 {
			return fmt.Errorf("%s: expected exactly one imported draft, found %d", tool.file, len(drafts))
		}
		draft := drafts[0]
		submitted, err := versions.Submit(draft.ID, author, draft.LockVersion)
		if err != nil {
			return fmt.Errorf("%s submit: %w", tool.file, err)
		}
		approved, err := versions.Approve(draft.ID, reviewer, submitted.LockVersion)
		if err != nil {
			return fmt.Errorf("%s synthetic approve: %w", tool.file, err)
		}
		published, err := versions.Publish(draft.ID, publisher, approved.LockVersion)
		if err != nil {
			return fmt.Errorf("%s synthetic publish: %w", tool.file, err)
		}
		report.Tools = append(report.Tools, rehearsalToolReport{
			LegacyFile: tool.file, CalculatorID: tool.calculator.ID, VersionID: published.ID,
			DefinitionChecksum: published.DefinitionChecksum, Status: published.Status,
		})
	}

	blockers, err := (services.CalculatorMigrationService{DB: database}).SyntheticRuntimeReadiness()
	if err != nil {
		return err
	}
	report.RetirementBlockers = blockers
	report.RetirementServiceReady = len(blockers) == 0
	if len(blockers) != 0 {
		return fmt.Errorf("retirement readiness service returned %d blockers", len(blockers))
	}
	return nil
}

type canonicalTool struct {
	file       string
	calculator models.Calculator
}

func canonicalTools(database *gorm.DB) ([]canonicalTool, error) {
	allowed := map[string]bool{}
	for _, filename := range services.ReviewedLegacyCalculatorFiles() {
		allowed[filename] = true
	}
	var calculators []models.Calculator
	if err := database.Where("status = ?", "active").Find(&calculators).Error; err != nil {
		return nil, err
	}
	byFile := map[string][]models.Calculator{}
	for _, calculator := range calculators {
		var artifact struct {
			Path string `json:"path"`
		}
		if json.Unmarshal(calculator.AppFileJSON, &artifact) == nil && allowed[strings.TrimSpace(artifact.Path)] {
			file := strings.TrimSpace(artifact.Path)
			byFile[file] = append(byFile[file], calculator)
		}
	}
	if len(byFile) != expectedToolCount || len(allowed) != expectedToolCount {
		return nil, fmt.Errorf("expected %d active canonical artifacts, found %d", expectedToolCount, len(byFile))
	}
	items := make([]canonicalTool, 0, expectedToolCount)
	for file := range allowed {
		matches := byFile[file]
		if len(matches) != 1 {
			return nil, fmt.Errorf("%s: expected exactly one active canonical calculator, found %d", file, len(matches))
		}
		items = append(items, canonicalTool{file: file, calculator: matches[0]})
	}
	sort.Slice(items, func(i, j int) bool { return items[i].file < items[j].file })
	return items, nil
}

func rehearsalActor(database *gorm.DB, email string) (uuid.UUID, error) {
	var user models.User
	if err := database.Select("id").Where("email = ?", email).First(&user).Error; err != nil {
		return uuid.Nil, err
	}
	return user.ID, nil
}

func writeReports(report rehearsalReport, jsonPath, textPath string) error {
	raw, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}
	if jsonPath != "" {
		if err = writeFile(jsonPath, append(raw, '\n')); err != nil {
			return err
		}
	}
	text := fmt.Sprintf("Clinical-tool retirement rehearsal\nProject: %s\nSynthetic evidence: yes\nClinical approval: no\nTools published: %d/%d\nRetirement service ready: %t\n", report.ComposeProject, len(report.Tools), expectedToolCount, report.RetirementServiceReady)
	if report.Error != "" {
		text += "Error: " + report.Error + "\n"
	}
	for _, blocker := range report.RetirementBlockers {
		text += "BLOCKED: " + blocker + "\n"
	}
	if textPath != "" {
		return writeFile(textPath, []byte(text))
	}
	return nil
}

func writeFile(path string, content []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		return err
	}
	return os.WriteFile(path, content, 0o600)
}
