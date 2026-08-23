package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestMigrationCatalogCoversEveryCharacterizedLegacyToolAndPinsSource(t *testing.T) {
	repositoryRoot := filepath.Clean(filepath.Join("..", "..", ".."))
	value, err := loadCatalog(filepath.Join(repositoryRoot, "clinical-tools", "migrations", "v1", "catalog.json"))
	if err != nil {
		t.Fatal(err)
	}
	if len(value.Tools) != 14 {
		t.Fatalf("expected all 14 characterized tools, got %d", len(value.Tools))
	}
	manifestRaw, err := os.ReadFile(filepath.Join(repositoryRoot, "dashboard", "samples", "manifests", "legacy-tool-behaviors.json"))
	if err != nil {
		t.Fatal(err)
	}
	var manifest struct {
		Tools []struct {
			ID   string `json:"id"`
			File string `json:"file"`
		} `json:"tools"`
	}
	if err = json.Unmarshal(manifestRaw, &manifest); err != nil {
		t.Fatal(err)
	}
	characterized := map[string]string{}
	for _, item := range manifest.Tools {
		characterized[item.ID] = item.File
	}
	if len(characterized) != len(value.Tools) {
		t.Fatalf("catalog/characterization count differs: catalog=%d manifest=%d", len(value.Tools), len(characterized))
	}
	for _, item := range value.Tools {
		if characterized[item.LegacyID] != item.LegacyFile {
			t.Fatalf("%s does not match characterization manifest", item.LegacyID)
		}
		raw, readErr := os.ReadFile(filepath.Join(repositoryRoot, "dashboard", "samples", item.LegacyFile))
		if readErr != nil {
			t.Fatalf("%s: %v", item.LegacyID, readErr)
		}
		if actual := checksum(raw); actual != item.SourceChecksum {
			t.Fatalf("%s source drift: catalog=%s actual=%s", item.LegacyID, item.SourceChecksum, actual)
		}
	}
}

func TestLoadEnvelopesTreatsMissingDirectoryAsNoReadyConversions(t *testing.T) {
	values, err := loadEnvelopes(filepath.Join(t.TempDir(), "missing"))
	if err != nil {
		t.Fatal(err)
	}
	if len(values) != 0 {
		t.Fatalf("unexpected envelopes: %#v", values)
	}
}

func TestLoadParityReportsAcceptsUnsignedReviewDraft(t *testing.T) {
	directory := t.TempDir()
	raw := `{
  "legacy_id":"bmi-calculator",
  "legacy_file":"bmi-calculator.html",
  "status":"changes_required",
  "reviewer_id":null,
  "reviewed_at":null,
  "cases_tested":4,
  "exact_matches":3,
  "tolerance_matches":1,
  "presentation_differences":[],
  "logic_differences":["invalid inputs are rejected"],
  "unresolved_clinical_ambiguities":["clinician review required"],
  "reviewer_decision":"Pending independent clinician approval."
}`
	if err := os.WriteFile(filepath.Join(directory, "bmi-calculator.json"), []byte(raw), 0o600); err != nil {
		t.Fatal(err)
	}
	reports, err := loadParityReports(directory)
	if err != nil {
		t.Fatalf("expected valid review draft: %v", err)
	}
	if reports["bmi-calculator"].approved() {
		t.Fatal("unsigned review draft must not count as approved")
	}
}

func TestLoadParityReportsRejectsFakeApprovalAndUnknownFields(t *testing.T) {
	tests := map[string]string{
		"missing reviewer": `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"approved",
  "reviewer_id":null,"reviewed_at":null,"cases_tested":1,"exact_matches":1,
  "tolerance_matches":0,"presentation_differences":[],"logic_differences":[],
  "unresolved_clinical_ambiguities":[],"reviewer_decision":"Approved"
}`,
		"unresolved ambiguity": `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"approved",
  "reviewer_id":"11111111-1111-4111-8111-111111111111","reviewed_at":"2026-08-23T10:00:00Z",
  "cases_tested":1,"exact_matches":1,"tolerance_matches":0,
  "presentation_differences":[],"logic_differences":[],
  "unresolved_clinical_ambiguities":["still unresolved"],"reviewer_decision":"Approved"
}`,
		"unknown field": `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"changes_required",
  "reviewer_id":null,"reviewed_at":null,"cases_tested":1,"exact_matches":1,
  "tolerance_matches":0,"presentation_differences":[],"logic_differences":[],
  "unresolved_clinical_ambiguities":[],"reviewer_decision":"Changes required","approved_by_system":true
}`,
		"synthetic decision": `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"approved",
  "reviewer_id":"11111111-1111-4111-8111-111111111111","reviewed_at":"2026-08-23T10:00:00Z",
  "cases_tested":1,"exact_matches":1,"tolerance_matches":0,
  "presentation_differences":[],"logic_differences":[],
  "unresolved_clinical_ambiguities":[],"reviewer_decision":"TEST ONLY synthetic approval"
}`,
		"unaccounted cases": `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"approved",
  "reviewer_id":"11111111-1111-4111-8111-111111111111","reviewed_at":"2026-08-23T10:00:00Z",
  "cases_tested":2,"exact_matches":1,"tolerance_matches":0,
  "presentation_differences":[],"logic_differences":[],
  "unresolved_clinical_ambiguities":[],"reviewer_decision":"Clinically reviewed and approved."
}`,
	}
	for name, raw := range tests {
		t.Run(name, func(t *testing.T) {
			directory := t.TempDir()
			if err := os.WriteFile(filepath.Join(directory, "tool.json"), []byte(raw), 0o600); err != nil {
				t.Fatal(err)
			}
			if _, err := loadParityReports(directory); err == nil {
				t.Fatal("expected parity report rejection")
			}
		})
	}
}

func TestLoadParityReportsAcceptsCompleteAuthenticApproval(t *testing.T) {
	directory := t.TempDir()
	raw := `{
  "legacy_id":"tool","legacy_file":"tool.html","status":"approved",
  "reviewer_id":"11111111-1111-4111-8111-111111111111","reviewed_at":"2026-08-23T10:00:00Z",
  "cases_tested":2,"exact_matches":1,"tolerance_matches":1,
  "presentation_differences":["Native spacing differs"],"logic_differences":[],
  "unresolved_clinical_ambiguities":[],
  "reviewer_decision":"Reviewed the declared behavior, clinical language, thresholds, and safety messages; approved for publication."
}`
	if err := os.WriteFile(filepath.Join(directory, "tool.json"), []byte(raw), 0o600); err != nil {
		t.Fatal(err)
	}
	reports, err := loadParityReports(directory)
	if err != nil {
		t.Fatalf("expected complete approval to load: %v", err)
	}
	if !reports["tool"].approved() {
		t.Fatal("complete approval must be recognized")
	}
}
