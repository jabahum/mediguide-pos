package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

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

func main() {
	var catalogPath, sourceDir, definitionDir, actorText string
	var apply, requireAll bool
	flag.StringVar(&catalogPath, "catalog", "../clinical-tools/migrations/v1/catalog.json", "migration catalog path")
	flag.StringVar(&sourceDir, "source-dir", "../dashboard/samples", "legacy HTML source directory")
	flag.StringVar(&definitionDir, "definition-dir", "../clinical-tools/migrations/v1/definitions", "migration envelope directory")
	flag.StringVar(&actorText, "actor", "", "author UUID required with --apply")
	flag.BoolVar(&apply, "apply", false, "import validated conversions as drafts")
	flag.BoolVar(&requireAll, "require-all", false, "fail when a catalog tool has no conversion envelope")
	flag.Parse()

	items, err := loadCatalog(catalogPath)
	if err != nil {
		fatal(err)
	}
	envelopes, err := loadEnvelopes(definitionDir)
	if err != nil {
		fatal(err)
	}

	var migration services.CalculatorMigrationService
	var actor uuid.UUID
	if apply {
		actor, err = uuid.Parse(strings.TrimSpace(actorText))
		if err != nil {
			fatal(errors.New("--actor must be a valid UUID with --apply"))
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
			fmt.Printf("%s wave=%d tool=%s version=%s\n", strings.ToUpper(result.Status), item.Wave, item.LegacyID, envelope.Definition.Version)
			failed = failed || importErr != nil
		} else {
			result := (services.CalculatorMigrationService{}).Plan(envelope)
			fmt.Printf("%s wave=%d tool=%s version=%s\n", strings.ToUpper(result.Status), item.Wave, item.LegacyID, envelope.Definition.Version)
			failed = failed || result.Status != "ready_for_draft_import"
		}
	}
	if failed {
		os.Exit(1)
	}
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
		if item.LegacyID == "" || item.LegacyFile == "" || item.Wave < 1 || len(item.SourceChecksum) != 64 || item.ClinicalGate == "" || seenID[item.LegacyID] || seenFile[item.LegacyFile] {
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
