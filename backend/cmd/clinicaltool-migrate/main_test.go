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
