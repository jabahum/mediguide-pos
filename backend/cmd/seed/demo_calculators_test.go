package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/services"
)

func TestSeededCalculatorSamplesCoverReviewedLegacyArtifactsExactlyOnce(t *testing.T) {
	samples := seededCalculatorSamples()
	if len(samples) != 14 {
		t.Fatalf("expected 14 reviewed legacy calculator samples, got %d", len(samples))
	}

	seenIDs := make(map[string]string, len(samples))
	seenFiles := make(map[string]bool, len(samples))
	for _, sample := range samples {
		if sample.ID == [16]byte{} {
			t.Fatalf("%q has no deterministic ID", sample.FileName)
		}
		if previous, duplicate := seenIDs[sample.ID.String()]; duplicate {
			t.Fatalf("%q and %q share calculator ID %s", previous, sample.FileName, sample.ID)
		}
		seenIDs[sample.ID.String()] = sample.FileName
		if seenFiles[sample.FileName] {
			t.Fatalf("legacy artifact %q is seeded more than once", sample.FileName)
		}
		seenFiles[sample.FileName] = true
		if _, reviewed := services.ReviewedLegacyCalculatorChecksum(sample.FileName); !reviewed {
			t.Fatalf("%q is not in the reviewed legacy inventory", sample.FileName)
		}

		definitionPath := filepath.Join("..", "..", "..", "clinical-tools", "migrations", "v1", "definitions", strings.TrimSuffix(sample.FileName, ".html")+".json")
		raw, err := os.ReadFile(definitionPath)
		if err != nil {
			t.Fatalf("read %q migration envelope: %v", sample.FileName, err)
		}
		var envelope struct {
			Definition clinicaltools.Definition `json:"definition"`
		}
		if err = json.Unmarshal(raw, &envelope); err != nil {
			t.Fatalf("decode %q migration envelope: %v", sample.FileName, err)
		}
		if sample.Type != envelope.Definition.ToolType {
			t.Fatalf("%q seed type %q differs from reviewed definition type %q", sample.FileName, sample.Type, envelope.Definition.ToolType)
		}
	}

	for _, sample := range samples {
		if expected := sampleCalculatorUUID(sample.FileName); sample.ID != expected && sample.FileName != "medication-dosage-calculator.html" {
			t.Fatalf("%q ID is not derived from its artifact: got %s want %s", sample.FileName, sample.ID, expected)
		}
	}
}
