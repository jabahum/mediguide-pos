package main

import (
	"encoding/json"
	"strings"
	"testing"

	"mediguide/internal/models"
	"mediguide/internal/services"
)

func TestDemoGuidelinesProvideValidChapterHierarchies(t *testing.T) {
	guidelines := demoGuidelines()
	if len(guidelines) < 3 {
		t.Fatalf("expected at least three demo guidelines, got %d", len(guidelines))
	}

	for _, guideline := range guidelines {
		t.Run(guideline.Key, func(t *testing.T) {
			if len(guideline.Sections) < 8 {
				t.Fatalf("expected a rich chapter fixture, got %d sections", len(guideline.Sections))
			}

			seen := map[string]demoSection{}
			nested := 0
			blockTypes := map[string]bool{}
			for _, section := range guideline.Sections {
				if section.Slug == "" || section.Title == "" {
					t.Fatal("section title and slug are required")
				}
				if _, duplicate := seen[section.Slug]; duplicate {
					t.Fatalf("duplicate section slug %q", section.Slug)
				}
				if section.ParentSlug != "" {
					parent, exists := seen[section.ParentSlug]
					if !exists {
						t.Fatalf("parent %q must precede child %q", section.ParentSlug, section.Slug)
					}
					if section.Level != parent.Level+1 {
						t.Fatalf("child %q level %d must follow parent level %d", section.Slug, section.Level, parent.Level)
					}
					nested++
				}
				seen[section.Slug] = section

				for _, block := range section.Blocks {
					payload, err := json.Marshal(block.Payload)
					if err != nil {
						t.Fatalf("marshal %s block: %v", block.Type, err)
					}
					if err := services.ValidateGuidelineBlockContent(models.GuidelineBlockType(block.Type), payload); err != nil {
						t.Fatalf("invalid %s block in %q: %v", block.Type, section.Slug, err)
					}
					blockTypes[block.Type] = true
				}
			}

			if nested < 2 {
				t.Fatalf("expected nested subsections, got %d", nested)
			}
			if !blockTypes[string(models.GuidelineBlockKeyPoint)] {
				t.Fatal("expected at least one key point")
			}
			if !blockTypes[string(models.GuidelineBlockTable)] {
				t.Fatal("expected at least one clinical table")
			}
		})
	}
}

func TestDemoGuidelineMarkdownIncludesNestedAndStructuredContent(t *testing.T) {
	malaria := demoGuidelines()[0]
	markdown := string(demoMarkdown(malaria))
	for _, expected := range []string{
		"## 2. Diagnosis and assessment",
		"### 2.1 Clinical assessment",
		"| Test | Typical setting | Result |",
		"> **Danger signs:**",
		"1. Confirm clinical improvement",
	} {
		if !strings.Contains(markdown, expected) {
			t.Fatalf("expected generated Markdown to contain %q", expected)
		}
	}
}
