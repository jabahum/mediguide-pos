package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/services"

	"github.com/google/uuid"
)

type catalog struct {
	CatalogVersion string        `json:"catalog_version"`
	SourceManifest string        `json:"source_manifest"`
	Tools          []catalogTool `json:"tools"`
}

type catalogTool struct {
	LegacyID       string `json:"legacy_id"`
	LegacyFile     string `json:"legacy_file"`
	SourceChecksum string `json:"source_checksum"`
	Wave           int    `json:"wave"`
	Status         string `json:"status"`
	ClinicalGate   string `json:"clinical_gate"`
}

type parityReport struct {
	LegacyID       string   `json:"legacy_id"`
	LegacyFile     string   `json:"legacy_file"`
	Status         string   `json:"status"`
	ReviewerID     *string  `json:"reviewer_id"`
	ReviewedAt     *string  `json:"reviewed_at"`
	CasesTested    int      `json:"cases_tested"`
	ExactMatches   int      `json:"exact_matches"`
	ToleranceMatch int      `json:"tolerance_matches"`
	Presentation   []string `json:"presentation_differences"`
	Logic          []string `json:"logic_differences"`
	Ambiguities    []string `json:"unresolved_clinical_ambiguities"`
	Decision       string   `json:"reviewer_decision"`
}

func main() {
	var catalogPath, sourceDir, definitionDir, parityDir, actorText string
	var apply, requireAll, retirementCheck bool
	flag.StringVar(&catalogPath, "catalog", firstExisting("/app/clinical-tools/migrations/v1/catalog.json", "../clinical-tools/migrations/v1/catalog.json"), "migration catalog path")
	flag.StringVar(&sourceDir, "source-dir", firstExisting("/app/legacy-tools", "../dashboard/samples"), "legacy HTML source directory")
	flag.StringVar(&definitionDir, "definition-dir", firstExisting("/app/clinical-tools/migrations/v1/definitions", "../clinical-tools/migrations/v1/definitions"), "migration envelope directory")
	flag.StringVar(&parityDir, "parity-dir", firstExisting("/app/clinical-tools/migrations/v1/parity", "../clinical-tools/migrations/v1/parity"), "approved parity-report directory")
	flag.StringVar(&actorText, "actor", "", "author UUID required with --apply")
	flag.BoolVar(&apply, "apply", false, "import validated conversions as drafts")
	flag.BoolVar(&requireAll, "require-all", false, "fail when a catalog tool has no conversion envelope")
	flag.BoolVar(&retirementCheck, "retirement-check", false, "require approved parity evidence and published schema replacements for all tools")
	flag.Parse()
	if retirementCheck {
		requireAll = true
	}

	items, err := loadCatalog(catalogPath)
	if err != nil {
		fatal(err)
	}
	envelopes, err := loadEnvelopes(definitionDir)
	if err != nil {
		fatal(err)
	}
	parityReports, err := loadParityReports(parityDir)
	if err != nil {
		fatal(err)
	}
	catalogIDs := map[string]bool{}
	for _, item := range items.Tools {
		catalogIDs[item.LegacyID] = true
	}
	for legacyID := range parityReports {
		if !catalogIDs[legacyID] {
			fatal(fmt.Errorf("parity report references unknown legacy tool %q", legacyID))
		}
	}

	var migration services.CalculatorMigrationService
	var actor uuid.UUID
	if apply || retirementCheck {
		if apply {
			actor, err = uuid.Parse(strings.TrimSpace(actorText))
			if err != nil {
				fatal(errors.New("--actor must be a valid UUID with --apply"))
			}
		}
		cfg := config.Load()
		database, connectErr := db.Connect(cfg.DatabaseURL)
		if connectErr != nil {
			fatal(connectErr)
		}
		migration = services.CalculatorMigrationService{DB: database, Versions: services.CalculatorVersionService{DB: database}}
	}
	failed := false
	for _, item := range items.Tools {
		source, readErr := os.ReadFile(filepath.Join(sourceDir, item.LegacyFile))
		if readErr != nil || checksum(source) != item.SourceChecksum {
			fmt.Printf("BLOCKED wave=%d tool=%s reason=legacy_source_drift\n", item.Wave, item.LegacyID)
			failed = true
			continue
		}
		envelope, found := envelopes[item.LegacyID]
		if !found {
			fmt.Printf("BLOCKED wave=%d tool=%s status=%s gate=%q\n", item.Wave, item.LegacyID, item.Status, item.ClinicalGate)
			failed = failed || requireAll
			continue
		}
		report, hasReport := parityReports[item.LegacyID]
		if hasReport && report.LegacyFile != item.LegacyFile {
			fmt.Printf("BLOCKED wave=%d tool=%s reason=parity_catalog_mismatch\n", item.Wave, item.LegacyID)
			failed = true
			continue
		}
		if retirementCheck && (!hasReport || !report.approved()) {
			fmt.Printf("BLOCKED wave=%d tool=%s reason=approved_parity_report_missing\n", item.Wave, item.LegacyID)
			failed = true
		}
		if envelope.LegacyFile != item.LegacyFile || envelope.SourceChecksum != item.SourceChecksum {
			fmt.Printf("BLOCKED wave=%d tool=%s reason=envelope_catalog_mismatch\n", item.Wave, item.LegacyID)
			failed = true
			continue
		}
		if err = services.VerifyCalculatorMigrationSource(envelope, source); err != nil {
			fmt.Printf("BLOCKED wave=%d tool=%s reason=%q\n", item.Wave, item.LegacyID, err.Error())
			failed = true
			continue
		}
		if apply {
			result, importErr := migration.ImportDraft(envelope, actor)
			if importErr != nil {
				fmt.Printf("%s wave=%d tool=%s version=%s reason=%q\n", strings.ToUpper(result.Status), item.Wave, item.LegacyID, envelope.Definition.Version, importErr.Error())
			} else {
				fmt.Printf("%s wave=%d tool=%s version=%s\n", strings.ToUpper(result.Status), item.Wave, item.LegacyID, envelope.Definition.Version)
			}
			failed = failed || importErr != nil
		} else {
			result := (services.CalculatorMigrationService{}).Plan(envelope)
			fmt.Printf("%s wave=%d tool=%s version=%s\n", strings.ToUpper(result.Status), item.Wave, item.LegacyID, envelope.Definition.Version)
			failed = failed || result.Status != "ready_for_draft_import"
		}
	}
	if retirementCheck {
		blockers, readinessErr := migration.RetirementReadiness()
		if readinessErr != nil {
			fatal(readinessErr)
		}
		for _, blocker := range blockers {
			fmt.Printf("BLOCKED retirement=%q\n", blocker)
		}
		failed = failed || len(blockers) > 0
		if !failed {
			fmt.Println("READY legacy_html production execution may be removed")
		}
	}
	if failed {
		os.Exit(1)
	}
}

func loadParityReports(directory string) (map[string]parityReport, error) {
	reports := map[string]parityReport{}
	entries, err := os.ReadDir(directory)
	if errors.Is(err, os.ErrNotExist) {
		return reports, nil
	}
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		raw, readErr := os.ReadFile(filepath.Join(directory, entry.Name()))
		if readErr != nil {
			return nil, readErr
		}
		var report parityReport
		var fields map[string]json.RawMessage
		if err := json.Unmarshal(raw, &fields); err != nil {
			return nil, fmt.Errorf("%s: %w", entry.Name(), err)
		}
		for _, required := range []string{"legacy_id", "legacy_file", "status", "reviewer_id", "reviewed_at", "cases_tested", "exact_matches", "tolerance_matches", "presentation_differences", "logic_differences", "unresolved_clinical_ambiguities", "reviewer_decision"} {
			if _, found := fields[required]; !found {
				return nil, fmt.Errorf("%s: required field %q is missing", entry.Name(), required)
			}
		}
		decoder := json.NewDecoder(strings.NewReader(string(raw)))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&report); err != nil {
			return nil, fmt.Errorf("%s: %w", entry.Name(), err)
		}
		if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
			return nil, fmt.Errorf("%s: trailing JSON data is not allowed", entry.Name())
		}
		if err := validateParityReport(report, entry.Name()); err != nil {
			return nil, err
		}
		if _, exists := reports[report.LegacyID]; exists {
			return nil, fmt.Errorf("duplicate parity report %q", report.LegacyID)
		}
		reports[report.LegacyID] = report
	}
	return reports, nil
}

func validateParityReport(report parityReport, filename string) error {
	if report.LegacyID == "" || report.LegacyFile == "" || filepath.Base(report.LegacyFile) != report.LegacyFile || filepath.Ext(report.LegacyFile) != ".html" {
		return fmt.Errorf("%s: invalid legacy identity", filename)
	}
	if filename != report.LegacyID+".json" {
		return fmt.Errorf("%s: filename must match legacy_id", filename)
	}
	if report.Status != "draft" && report.Status != "changes_required" && report.Status != "approved" {
		return fmt.Errorf("%s: invalid parity status %q", filename, report.Status)
	}
	if report.CasesTested < 1 || report.ExactMatches < 0 || report.ToleranceMatch < 0 || report.ExactMatches+report.ToleranceMatch > report.CasesTested {
		return fmt.Errorf("%s: invalid parity case counts", filename)
	}
	if strings.TrimSpace(report.Decision) == "" {
		return fmt.Errorf("%s: reviewer_decision is required", filename)
	}
	if (report.ReviewerID == nil) != (report.ReviewedAt == nil) {
		return fmt.Errorf("%s: reviewer_id and reviewed_at must both be null or both be set", filename)
	}
	if report.ReviewerID != nil {
		if _, err := uuid.Parse(strings.TrimSpace(*report.ReviewerID)); err != nil {
			return fmt.Errorf("%s: reviewer_id must be a valid UUID", filename)
		}
		if _, err := time.Parse(time.RFC3339, strings.TrimSpace(*report.ReviewedAt)); err != nil {
			return fmt.Errorf("%s: reviewed_at must be RFC 3339", filename)
		}
	}
	if report.Status == "approved" && !report.approved() {
		return fmt.Errorf("%s: approved reports require a reviewer, review timestamp, and no unresolved ambiguities", filename)
	}
	if report.Status == "approved" && report.ExactMatches+report.ToleranceMatch != report.CasesTested {
		return fmt.Errorf("%s: approved reports must account for every tested case", filename)
	}
	if report.Status == "approved" && invalidApprovalDecision(report.Decision) {
		return fmt.Errorf("%s: approved reports require a genuine, non-placeholder reviewer decision", filename)
	}
	return nil
}

func invalidApprovalDecision(value string) bool {
	decision := strings.ToLower(strings.TrimSpace(value))
	if decision == "" {
		return true
	}
	for _, blocked := range []string{
		"test only",
		"synthetic",
		"placeholder",
		"pending approval",
		"pending independent",
		"do not approve",
		"not approved",
	} {
		if strings.Contains(decision, blocked) {
			return true
		}
	}
	return false
}

func (report parityReport) approved() bool {
	return report.Status == "approved" && report.ReviewerID != nil && report.ReviewedAt != nil && len(report.Ambiguities) == 0
}

func firstExisting(paths ...string) string {
	for _, path := range paths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return paths[len(paths)-1]
}

func loadCatalog(path string) (*catalog, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var value catalog
	if err = json.Unmarshal(raw, &value); err != nil {
		return nil, err
	}
	if value.CatalogVersion != "1.0" || len(value.Tools) == 0 {
		return nil, errors.New("unsupported or empty migration catalog")
	}
	seenID, seenFile := map[string]bool{}, map[string]bool{}
	for _, item := range value.Tools {
		validStatus := item.Status == "review_draft_ready" || item.Status == "approved"
		if item.LegacyID == "" || item.LegacyFile == "" || item.Wave < 1 || len(item.SourceChecksum) != 64 || item.ClinicalGate == "" || !validStatus || seenID[item.LegacyID] || seenFile[item.LegacyFile] {
			return nil, fmt.Errorf("invalid or duplicate catalog entry %q", item.LegacyID)
		}
		seenID[item.LegacyID], seenFile[item.LegacyFile] = true, true
	}
	sort.Slice(value.Tools, func(i, j int) bool {
		if value.Tools[i].Wave == value.Tools[j].Wave {
			return value.Tools[i].LegacyID < value.Tools[j].LegacyID
		}
		return value.Tools[i].Wave < value.Tools[j].Wave
	})
	return &value, nil
}

func loadEnvelopes(directory string) (map[string]services.CalculatorMigrationEnvelope, error) {
	values := map[string]services.CalculatorMigrationEnvelope{}
	entries, err := os.ReadDir(directory)
	if errors.Is(err, os.ErrNotExist) {
		return values, nil
	}
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		raw, readErr := os.ReadFile(filepath.Join(directory, entry.Name()))
		if readErr != nil {
			return nil, readErr
		}
		envelope, parseErr := services.ParseCalculatorMigrationEnvelope(raw)
		if parseErr != nil {
			return nil, fmt.Errorf("%s: %w", entry.Name(), parseErr)
		}
		if _, exists := values[envelope.LegacyID]; exists {
			return nil, fmt.Errorf("duplicate migration envelope %q", envelope.LegacyID)
		}
		values[envelope.LegacyID] = *envelope
	}
	return values, nil
}

func checksum(raw []byte) string {
	digest := sha256.Sum256(raw)
	return hex.EncodeToString(digest[:])
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
