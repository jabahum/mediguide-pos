package services

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

const maxLegacyCalculatorArtifactBytes = 256 << 10

const legacyCalculatorCSP = "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data:; connect-src 'none'; font-src 'none'; media-src 'none'; object-src 'none'; frame-src 'none'; child-src 'none'; worker-src 'none'; form-action 'none'; base-uri 'none'"

func LegacyCalculatorContentSecurityPolicy() string { return legacyCalculatorCSP }

var reviewedLegacyCalculatorChecksums = map[string]string{
	"apgar-score-calculator.html":        "4b4ba682704ce5a95e745117e459b8a76a9bb6bce0e960cee57ff7d72106a677",
	"blood-pressure-assessment.html":     "7a3ca6bb79e40c2ca14124287f025c375ba10809134a7c63f794a9102b0c4e2a",
	"bmi-calculator.html":                "5317c90a25a1e1f00df9f3bfdb934e5f91c1e5944e8bde266497640804d98391",
	"cardiac-risk-assessment.html":       "3f801e2205c368fdda49af1b428a6fc00bd9235cf3e59e62564fc4bf6e1e9f6a",
	"dehydration-assessment.html":        "1e007a6d5908a4f25739e73a7424df0c44b14b81216258c800f6ec161e4d9597",
	"emergency-triage-assessment.html":   "086efb599f8c535faa94f589d19b477e0bef3afd635ca0a0ccb7ee3c061c7420",
	"fluid-balance-calculator.html":      "6aaf110ccee6d2032c0ada4a16e60c7247641372317e69f7bead65cb9269f090",
	"glasgow-coma-scale.html":            "5f2ac864c148997e5f126b4691dda1226780e8ca61322637fa57af9de32e99d4",
	"immunization-schedule-checker.html": "6a5bf25184ccc0c9df9b666d1a50346851ff36d755cff146180536a7dac54030",
	"medication-dosage-calculator.html":  "0b97e86b8cf06fb99e090afa852dc824b6f19e296d032ce24516c178974850bb",
	"pain-assessment-scale.html":         "6f4231a0c9e348aa4479511328d683f81db3c6fc3b066322a076a47578dc7db5",
	"pediatric-fever-management.html":    "db1ae667c44ebe12a1cd6227e9faa033e2cd04e07d56b1d02f96cdf7f244e39d",
	"pregnancy-due-date-calculator.html": "4298a2ee251e8d9f0a6ec74d748cb37c1c694dae78aedc67c1ecf490fa4d4e5a",
	"wound-assessment-tool.html":         "5fa5f696c90a583d61e8363068b914e1e1d5fadc57af7b7389a2609aff511675",
}

var legacyRemoteDependencyRE = regexp.MustCompile(`(?is)(<(script|img|iframe|link|audio|video|source|embed)\b[^>]*(src|href)\s*=\s*["']\s*(https?:|//)|@import\s+|url\s*\(\s*["']?\s*(https?:|//)|\b(fetch|XMLHttpRequest|WebSocket|EventSource)\s*\()`)

func reviewedLegacyCalculatorChecksum(filename string) (string, bool) {
	checksum, ok := reviewedLegacyCalculatorChecksums[filepath.Base(strings.TrimSpace(filename))]
	return checksum, ok
}

// ReviewedLegacyCalculatorChecksum exposes the checksum pin to trusted seed and
// migration tooling without making arbitrary artifacts executable.
func ReviewedLegacyCalculatorChecksum(filename string) (string, bool) {
	return reviewedLegacyCalculatorChecksum(filename)
}

// ReviewedLegacyCalculatorFiles returns a sorted copy of the immutable legacy
// artifact allowlist. Callers cannot mutate the publication safety map.
func ReviewedLegacyCalculatorFiles() []string {
	files := make([]string, 0, len(reviewedLegacyCalculatorChecksums))
	for filename := range reviewedLegacyCalculatorChecksums {
		files = append(files, filename)
	}
	sort.Strings(files)
	return files
}

func validateCalculatorArtifactMetadata(raw json.RawMessage) bool {
	if len(bytes.TrimSpace(raw)) == 0 || !json.Valid(raw) {
		return false
	}
	var metadata calculatorArtifactMetadata
	if err := json.Unmarshal(raw, &metadata); err != nil {
		return false
	}
	if strings.TrimSpace(metadata.HTML) != "" {
		return false
	}
	path := strings.TrimSpace(metadata.Path)
	if path == "" {
		path = strings.TrimSpace(metadata.Name)
	}
	if path == "" {
		// A base calculator may exist as a non-executable draft before its first
		// schema version is published.
		return true
	}
	clean := filepath.Clean(path)
	if filepath.IsAbs(clean) || filepath.Base(clean) != clean {
		return false
	}
	expected, ok := reviewedLegacyCalculatorChecksum(clean)
	if !ok {
		return false
	}
	return metadata.SHA256 == "" || strings.EqualFold(metadata.SHA256, expected)
}

func verifyLegacyCalculatorArtifact(filename string, content []byte) (string, error) {
	expected, ok := reviewedLegacyCalculatorChecksum(filename)
	if !ok {
		return "", ErrCalculatorArtifactUnsafe
	}
	if len(content) == 0 || len(content) > maxLegacyCalculatorArtifactBytes {
		return "", ErrCalculatorArtifactUnsafe
	}
	digest := sha256.Sum256(content)
	actual := hex.EncodeToString(digest[:])
	if !strings.EqualFold(actual, expected) {
		return "", ErrCalculatorArtifactChecksum
	}
	if legacyRemoteDependencyRE.Match(content) {
		return "", ErrCalculatorArtifactDependency
	}
	return actual, nil
}

func containLegacyCalculatorHTML(content []byte) ([]byte, error) {
	if !bytes.Contains(bytes.ToLower(content), []byte("<html")) {
		return nil, ErrCalculatorArtifactUnsafe
	}
	meta := []byte(`<meta http-equiv="Content-Security-Policy" content="` + legacyCalculatorCSP + `">`)
	lower := bytes.ToLower(content)
	if index := bytes.Index(lower, []byte("<head>")); index >= 0 {
		result := make([]byte, 0, len(content)+len(meta))
		result = append(result, content[:index+len("<head>")]...)
		result = append(result, meta...)
		result = append(result, content[index+len("<head>"):]...)
		return result, nil
	}
	return nil, errors.New("reviewed legacy calculator is missing a head element")
}
