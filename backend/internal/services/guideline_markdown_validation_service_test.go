package services

import (
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func TestValidateMarkdownDocumentReportsUnsafeAndStructuralIssues(t *testing.T) {
	result := validateMarkdownDocument(uuid.New(), "# Care\n### Jump\n\n<script>alert(1)</script>\n\n![](asset:missing)\n\n[bad](https://example.test\n", models.GuidelineDocument{}, nil)
	want := map[string]bool{"skipped_heading_level": false, "unsafe_html": false, "missing_image_alt": false, "broken_asset_reference": false, "malformed_link": false, "missing_source_metadata": false}
	for _, issue := range result.Issues {
		if _, ok := want[issue.Code]; ok {
			want[issue.Code] = true
		}
		if issue.Line < 1 || issue.Column < 1 {
			t.Fatalf("issue lacks source range: %#v", issue)
		}
	}
	for code, found := range want {
		if !found {
			t.Errorf("missing issue %s: %#v", code, result.Issues)
		}
	}
	if result.Valid {
		t.Fatal("unsafe Markdown must not validate")
	}
}

func TestValidateMarkdownDocumentFlagsHighRiskReviewWithoutChangingClinicalText(t *testing.T) {
	content := "# Dose\n\n:::dosage title=Adult\nGive 5 mg orally daily.\n:::\n\n| Drug | Dose |\n| --- | --- |\n| A | 5 mg |"
	result := validateMarkdownDocument(uuid.New(), content, models.GuidelineDocument{SourceOrg: "Ministry"}, nil)
	for _, issue := range result.Issues {
		if issue.Severity == "error" {
			t.Fatalf("valid clinical Markdown was rejected: %#v", result.Issues)
		}
	}
	if !result.Valid {
		t.Fatal("expected valid Markdown")
	}
	found := false
	for _, issue := range result.Issues {
		if issue.Code == "high_risk_review_required" {
			found = true
		}
	}
	if !found {
		t.Fatal("expected high-risk review warning")
	}
}

func TestValidateMarkdownDocumentRejectsEmptyCalloutAndMissingReference(t *testing.T) {
	result := validateMarkdownDocument(uuid.New(), "# Care\n\n:::warning\n:::\n\nSee [source][missing].", models.GuidelineDocument{SourceOrg: "Ministry"}, nil)
	want := map[string]bool{"empty_callout": false, "missing_reference_definition": false}
	for _, issue := range result.Issues {
		if _, ok := want[issue.Code]; ok {
			want[issue.Code] = true
		}
	}
	for code, found := range want {
		if !found {
			t.Errorf("missing %s", code)
		}
	}
}
