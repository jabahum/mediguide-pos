package services

import (
	"testing"

	"mediguide/internal/models"
)

func TestRecommendedGuidelineReaderMode(t *testing.T) {
	tests := []struct {
		name     string
		manifest models.GuidelineVersionManifest
		want     string
	}{
		{name: "reviewed", manifest: models.GuidelineVersionManifest{ExtractionQuality: models.GuidelineExtractionReviewed}, want: "structured"},
		{name: "partial", manifest: models.GuidelineVersionManifest{ExtractionQuality: models.GuidelineExtractionPartiallyReviewed}, want: "partial"},
		{name: "markdown with sections", manifest: models.GuidelineVersionManifest{ExtractionQuality: models.GuidelineExtractionMarkdownFallback, SectionCount: 2}, want: "partial"},
		{name: "unreviewed", manifest: models.GuidelineVersionManifest{ExtractionQuality: models.GuidelineExtractionUnreviewed}, want: "original_document"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := recommendedGuidelineReaderMode(&test.manifest); got != test.want {
				t.Fatalf("recommended mode = %q, want %q", got, test.want)
			}
		})
	}
}
