package services

import (
	"encoding/json"
	"errors"
	"testing"

	"mediguide/internal/models"
)

func TestValidateGuidelineBlockContent(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		blockType models.GuidelineBlockType
		content   string
		valid     bool
	}{
		{name: "paragraph", blockType: models.GuidelineBlockParagraph, content: `{"type":"paragraph","text":"Clinical guidance."}`, valid: true},
		{name: "table", blockType: models.GuidelineBlockTable, content: `{"type":"table","title":"Performance","columns":["Test","Sensitivity"],"rows":[["RDT","95%"]],"footnotes":[]}`, valid: true},
		{name: "figure", blockType: models.GuidelineBlockFigure, content: `{"type":"figure","asset_id":"29d50fa6-6fe7-4fb3-a2a2-4ca242740947","caption":"Flow","alternative_text":"A clinical flow diagram"}`, valid: true},
		{name: "callout", blockType: models.GuidelineBlockRecommendation, content: `{"type":"recommendation","title":"Recommendation","content":"Refer urgently.","severity":"critical"}`, valid: true},
		{name: "dosage callout", blockType: models.GuidelineBlockDosage, content: `{"type":"dosage","title":"Dose","content":"Use the reviewed regimen exactly as written.","severity":"high","evidence_grade":"A","source":"National guideline"}`, valid: true},
		{name: "empty contraindication", blockType: models.GuidelineBlockContraindication, content: `{"type":"contraindication","content":""}`, valid: false},
		{name: "algorithm", blockType: models.GuidelineBlockAlgorithm, content: `{"type":"algorithm","nodes":[{"id":"start","label":"Assess","kind":"start","next":["end"]},{"id":"end","label":"Refer","kind":"end"}]}`, valid: true},
		{name: "reject arbitrary html", blockType: models.GuidelineBlockParagraph, content: `{"type":"paragraph","text":"Clinical guidance.","html":"<script>alert(1)</script>"}`},
		{name: "reject mismatched discriminator", blockType: models.GuidelineBlockWarning, content: `{"type":"recommendation","content":"Warning","severity":"high"}`},
		{name: "reject ragged table", blockType: models.GuidelineBlockTable, content: `{"type":"table","columns":["A","B"],"rows":[["only one"]],"footnotes":[]}`},
		{name: "reject dangling algorithm edge", blockType: models.GuidelineBlockAlgorithm, content: `{"type":"algorithm","nodes":[{"id":"start","label":"Assess","kind":"start","next":["missing"]}]}`},
		{name: "reject unknown type", blockType: models.GuidelineBlockType("video"), content: `{"type":"video","text":"x"}`},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateGuidelineBlockContent(test.blockType, json.RawMessage(test.content))
			if test.valid && err != nil {
				t.Fatalf("expected valid block, got %v", err)
			}
			if !test.valid && !errors.Is(err, ErrInvalidGuidelineBlockContent) {
				t.Fatalf("expected invalid block error, got %v", err)
			}
		})
	}
}

func TestClinicalCalloutReviewRiskClassification(t *testing.T) {
	for _, blockType := range []models.GuidelineBlockType{
		models.GuidelineBlockRecommendation,
		models.GuidelineBlockWarning,
		models.GuidelineBlockCaution,
		models.GuidelineBlockContraindication,
		models.GuidelineBlockDosage,
		models.GuidelineBlockProcedure,
		models.GuidelineBlockAlgorithmReference,
		models.GuidelineBlockReferralCriteria,
	} {
		if !highRiskGuidelineBlock(blockType) {
			t.Errorf("expected %s to require clinical review", blockType)
		}
	}
	for _, blockType := range []models.GuidelineBlockType{
		models.GuidelineBlockDefinition,
		models.GuidelineBlockEvidence,
		models.GuidelineBlockClinicalNote,
	} {
		if highRiskGuidelineBlock(blockType) {
			t.Errorf("expected %s to use standard review", blockType)
		}
	}
}
