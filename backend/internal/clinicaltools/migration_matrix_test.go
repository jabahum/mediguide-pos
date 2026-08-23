package clinicaltools

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"testing"
)

func TestEveryMigrationDefinitionPassesGoAuthorityFixtures(t *testing.T) {
	directory := filepath.Join("..", "..", "..", "clinical-tools", "migrations", "v1", "definitions")
	files, err := filepath.Glob(filepath.Join(directory, "*.json"))
	if err != nil {
		t.Fatal(err)
	}
	sort.Strings(files)
	if len(files) != 14 {
		t.Fatalf("expected the complete 14-tool matrix, got %d", len(files))
	}
	for _, path := range files {
		path := path
		t.Run(filepath.Base(path), func(t *testing.T) {
			raw, readErr := os.ReadFile(path)
			if readErr != nil {
				t.Fatal(readErr)
			}
			var envelope struct {
				Definition json.RawMessage `json:"definition"`
			}
			if unmarshalErr := json.Unmarshal(raw, &envelope); unmarshalErr != nil {
				t.Fatal(unmarshalErr)
			}
			definition, validation := ParseAndValidate(envelope.Definition)
			if !validation.Valid {
				t.Fatalf("definition validation failed: %#v", validation.Errors)
			}
			if len(definition.TestCases) == 0 {
				t.Fatal("publication candidate must contain saved fixtures")
			}
			report := ExecuteTestCases(definition)
			if !report.Passed {
				t.Fatalf("Go publication-authority fixtures failed: %#v", report.Cases)
			}
		})
	}
}
