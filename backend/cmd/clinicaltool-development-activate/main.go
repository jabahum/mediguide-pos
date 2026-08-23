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

type activationItem struct {
	LegacyID     string    `json:"legacy_id"`
	LegacyFile   string    `json:"legacy_file"`
	CalculatorID uuid.UUID `json:"calculator_id"`
	VersionID    uuid.UUID `json:"version_id"`
	Status       string    `json:"status"`
	Changed      bool      `json:"changed"`
}

type activationReport struct {
	Kind                  string           `json:"kind"`
	Environment           string           `json:"environment"`
	ClinicalApproval      bool             `json:"clinical_approval"`
	SyntheticTestEvidence bool             `json:"synthetic_test_evidence"`
	ActivatedAt           time.Time        `json:"activated_at"`
	Tools                 []activationItem `json:"tools"`
	TechnicalBlockers     []string         `json:"technical_blockers"`
	ProductionGateBlocked bool             `json:"production_gate_blocked"`
}

func main() {
	var sourceDir, definitionDir, authorEmail, reviewerEmail, publisherEmail, reportPath string
	flag.StringVar(&sourceDir, "source-dir", firstExisting("/app/legacy-tools", "../dashboard/samples"), "characterized legacy HTML source directory")
	flag.StringVar(&definitionDir, "definition-dir", firstExisting("/app/clinical-tools/migrations/v1/definitions", "../clinical-tools/migrations/v1/definitions"), "schema migration envelope directory")
	flag.StringVar(&authorEmail, "author-email", "admin@mediguide.health.go.ug", "synthetic development author email")
	flag.StringVar(&reviewerEmail, "reviewer-email", "clinician@mediguide.health.go.ug", "synthetic development reviewer email")
	flag.StringVar(&publisherEmail, "publisher-email", "assistant@mediguide.health.go.ug", "synthetic development publisher email")
	flag.StringVar(&reportPath, "json-report", "", "optional machine-readable report path")
	flag.Parse()

	cfg := config.Load()
	if err := clinicaltools.ValidateDevelopmentActivationTarget(cfg.DatabaseURL, cfg.AppEnv, os.Getenv("CLINICAL_TOOLS_DEVELOPMENT_ACTIVATION")); err != nil {
		fatal(err)
	}
	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		fatal(err)
	}

	author, err := actor(database, authorEmail)
	if err != nil {
		fatal(fmt.Errorf("synthetic author %q: %w; run the development seed first or supply --author-email", authorEmail, err))
	}
	reviewer, err := actor(database, reviewerEmail)
	if err != nil {
		fatal(fmt.Errorf("synthetic reviewer %q: %w; run the development seed first or supply --reviewer-email", reviewerEmail, err))
	}
	publisher, err := actor(database, publisherEmail)
	if err != nil {
		fatal(fmt.Errorf("synthetic publisher %q: %w; run the development seed first or supply --publisher-email", publisherEmail, err))
	}
	if author == reviewer || author == publisher || reviewer == publisher {
		fatal(errors.New("development author, reviewer, and publisher must be separate users"))
	}

	envelopes, err := loadEnvelopes(definitionDir, sourceDir)
	if err != nil {
		fatal(err)
	}
	versions := services.CalculatorVersionService{DB: database, SyntheticRehearsalEvidence: true}
	migration := services.CalculatorMigrationService{DB: database, Versions: versions}
	report := activationReport{
		Kind:                  "clinical_tool_development_activation",
		Environment:           "development",
		ClinicalApproval:      false,
		SyntheticTestEvidence: true,
		ActivatedAt:           time.Now().UTC(),
		Tools:                 make([]activationItem, 0, len(envelopes)),
		TechnicalBlockers:     []string{},
		ProductionGateBlocked: true,
	}
	for _, envelope := range envelopes {
		item, activateErr := activate(database, migration, versions, envelope, author, reviewer, publisher)
		if activateErr != nil {
			fatal(fmt.Errorf("%s: %w", envelope.LegacyFile, activateErr))
		}
		report.Tools = append(report.Tools, item)
		state := "unchanged"
		if item.Changed {
			state = "activated"
		}
		fmt.Printf("%s tool=%s version=%s evidence=synthetic_non_clinical\n", strings.ToUpper(state), envelope.LegacyID, item.VersionID)
	}

	blockers, err := migration.SyntheticRuntimeReadiness()
	if err != nil {
		fatal(err)
	}
	report.TechnicalBlockers = blockers
	if len(blockers) != 0 {
		fatal(fmt.Errorf("schema runtime activation has %d technical blockers: %s", len(blockers), strings.Join(blockers, " | ")))
	}
	productionBlockers, err := migration.RetirementReadiness()
	if err != nil {
		fatal(err)
	}
	report.ProductionGateBlocked = len(productionBlockers) != 0
	if !report.ProductionGateBlocked {
		fatal(errors.New("safety invariant failed: synthetic development activation unexpectedly satisfied the production retirement gate"))
	}
	if reportPath != "" {
		raw, marshalErr := json.MarshalIndent(report, "", "  ")
		if marshalErr != nil {
			fatal(marshalErr)
		}
		if err = os.MkdirAll(filepath.Dir(reportPath), 0o750); err != nil {
			fatal(err)
		}
		if err = os.WriteFile(reportPath, append(raw, '\n'), 0o600); err != nil {
			fatal(err)
		}
	}
	fmt.Printf("READY development schema runtime active for %d tools; production retirement remains BLOCKED pending genuine clinician approval\n", len(report.Tools))
}

func activate(database *gorm.DB, migration services.CalculatorMigrationService, versions services.CalculatorVersionService, envelope services.CalculatorMigrationEnvelope, author, reviewer, publisher uuid.UUID) (activationItem, error) {
	result, err := migration.ImportDraft(envelope, author)
	if errors.Is(err, services.ErrCalculatorMigrationConflict) {
		result, err = migration.ReconcileSyntheticDevelopmentDraft(envelope, author, true)
	}
	if err != nil {
		return activationItem{}, err
	}
	if result.CalculatorID == nil || result.VersionID == nil {
		return activationItem{}, errors.New("draft import did not return calculator and version IDs")
	}
	item := activationItem{LegacyID: envelope.LegacyID, LegacyFile: envelope.LegacyFile, CalculatorID: *result.CalculatorID, VersionID: *result.VersionID}
	for transitions := 0; transitions < 4; transitions++ {
		var version models.CalculatorVersion
		if err = database.First(&version, "id = ?", *result.VersionID).Error; err != nil {
			return item, err
		}
		item.Status = version.Status
		switch version.Status {
		case "draft":
			if _, err = versions.Submit(version.ID, author, version.LockVersion); err != nil {
				return item, err
			}
			item.Changed = true
		case "pending_review":
			if _, err = versions.Approve(version.ID, reviewer, version.LockVersion); err != nil {
				return item, err
			}
			item.Changed = true
		case "approved":
			if _, err = versions.Publish(version.ID, publisher, version.LockVersion); err != nil {
				return item, err
			}
			item.Changed = true
		case "superseded":
			if err = versions.SelectPublished(*result.CalculatorID, version.ID, publisher, version.LockVersion); err != nil {
				return item, err
			}
			item.Changed = true
		case "published":
			var tool models.Calculator
			if err = database.First(&tool, "id = ?", *result.CalculatorID).Error; err != nil {
				return item, err
			}
			if tool.RuntimeType != "schema_v1" || tool.CurrentVersionID == nil || *tool.CurrentVersionID != version.ID {
				return item, errors.New("published version is not the active schema runtime")
			}
			item.Status = "published"
			return item, nil
		default:
			return item, fmt.Errorf("unsupported version state %q", version.Status)
		}
	}
	return item, errors.New("version did not reach published state")
}

func loadEnvelopes(definitionDir, sourceDir string) ([]services.CalculatorMigrationEnvelope, error) {
	entries, err := os.ReadDir(definitionDir)
	if err != nil {
		return nil, err
	}
	allowed := map[string]bool{}
	for _, file := range services.ReviewedLegacyCalculatorFiles() {
		allowed[file] = true
	}
	items := make([]services.CalculatorMigrationEnvelope, 0, expectedToolCount)
	seen := map[string]bool{}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		raw, readErr := os.ReadFile(filepath.Join(definitionDir, entry.Name()))
		if readErr != nil {
			return nil, readErr
		}
		envelope, parseErr := services.ParseCalculatorMigrationEnvelope(raw)
		if parseErr != nil {
			return nil, fmt.Errorf("%s: %w", entry.Name(), parseErr)
		}
		if !allowed[envelope.LegacyFile] || seen[envelope.LegacyFile] {
			return nil, fmt.Errorf("%s references an unknown or duplicate legacy file %q", entry.Name(), envelope.LegacyFile)
		}
		source, readErr := os.ReadFile(filepath.Join(sourceDir, envelope.LegacyFile))
		if readErr != nil {
			return nil, readErr
		}
		if verifyErr := services.VerifyCalculatorMigrationSource(*envelope, source); verifyErr != nil {
			return nil, fmt.Errorf("%s: %w", envelope.LegacyFile, verifyErr)
		}
		seen[envelope.LegacyFile] = true
		items = append(items, *envelope)
	}
	if len(items) != expectedToolCount || len(allowed) != expectedToolCount {
		return nil, fmt.Errorf("expected %d canonical migration envelopes, found %d", expectedToolCount, len(items))
	}
	sort.Slice(items, func(i, j int) bool { return items[i].LegacyFile < items[j].LegacyFile })
	return items, nil
}

func actor(database *gorm.DB, email string) (uuid.UUID, error) {
	var user models.User
	if err := database.Select("id").Where("LOWER(email) = ?", strings.ToLower(strings.TrimSpace(email))).First(&user).Error; err != nil {
		return uuid.Nil, err
	}
	return user.ID, nil
}

func firstExisting(paths ...string) string {
	for _, path := range paths {
		if info, err := os.Stat(path); err == nil && info.IsDir() {
			return path
		}
	}
	return paths[0]
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "BLOCKED development schema activation:", err)
	os.Exit(1)
}
