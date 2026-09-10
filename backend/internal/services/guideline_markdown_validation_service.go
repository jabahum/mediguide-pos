package services

import (
	"context"
	"fmt"
	"net/url"
	"path"
	"regexp"
	"sort"
	"strings"
	"unicode/utf8"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

type MarkdownValidationIssue struct {
	Severity  string `json:"severity"`
	Code      string `json:"code"`
	Message   string `json:"message"`
	Line      int    `json:"line"`
	Column    int    `json:"column"`
	EndLine   int    `json:"end_line"`
	EndColumn int    `json:"end_column"`
}

type MarkdownValidationResult struct {
	RevisionID uuid.UUID                 `json:"revision_id"`
	Valid      bool                      `json:"valid"`
	Issues     []MarkdownValidationIssue `json:"issues"`
	Errors     int                       `json:"errors"`
	Warnings   int                       `json:"warnings"`
	Info       int                       `json:"info"`
}

var (
	mdHeadingRE      = regexp.MustCompile(`^(#{1,6})\s+(.+?)\s*#*\s*$`)
	mdLinkRE         = regexp.MustCompile(`!?\[([^]]*)\]\(([^)\s]+)(?:\s+(?:"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'))?\)`)
	mdHTMLRE         = regexp.MustCompile(`(?i)<\s*/?\s*([a-z][a-z0-9-]*)\b[^>]*>`)
	mdUnsafeRE       = regexp.MustCompile(`(?i)<\s*(script|iframe|object|embed)\b|\bon[a-z]+\s*=|javascript\s*:`)
	mdReferenceUseRE = regexp.MustCompile(`\[[^]]+\]\[([^]]+)\]`)
	mdReferenceDefRE = regexp.MustCompile(`^\s*\[([^]]+)\]:\s*\S+`)
	mdDoseRE         = regexp.MustCompile(`(?i)\b\d+(?:\.\d+)?\s*(mg|mcg|µg|g|ml|mL|units?|iu)\b`)
)

func (s GuidelineService) ValidateMarkdownRevision(ctx context.Context, versionID, revisionID uuid.UUID) (*MarkdownValidationResult, error) {
	var revision models.GuidelineMarkdownRevision
	if err := s.DB.First(&revision, "id = ? AND version_id = ?", revisionID, versionID).Error; err != nil {
		return nil, err
	}
	content, err := s.readMarkdownObject(ctx, revision.StorageKey)
	if err != nil {
		return nil, err
	}
	var document models.GuidelineDocument
	if err := s.DB.Table("guideline_documents d").Joins("JOIN guideline_versions v ON v.document_id=d.id").Where("v.id = ?", versionID).First(&document).Error; err != nil {
		return nil, err
	}
	var assets []models.GuidelineAsset
	if err := s.DB.Where("version_id = ?", versionID).Find(&assets).Error; err != nil {
		return nil, err
	}
	return validateMarkdownDocument(revisionID, content, document, assets), nil
}

func validateMarkdownDocument(revisionID uuid.UUID, content string, document models.GuidelineDocument, assets []models.GuidelineAsset) *MarkdownValidationResult {
	result := &MarkdownValidationResult{RevisionID: revisionID, Issues: []MarkdownValidationIssue{}}
	add := func(severity, code, message string, line, column, endColumn int) {
		if line < 1 {
			line = 1
		}
		if column < 1 {
			column = 1
		}
		if endColumn < column {
			endColumn = column
		}
		result.Issues = append(result.Issues, MarkdownValidationIssue{Severity: severity, Code: code, Message: message, Line: line, Column: column, EndLine: line, EndColumn: endColumn})
	}
	if strings.TrimSpace(content) == "" {
		add("error", "empty_document", "The document is empty.", 1, 1, 1)
	}
	if len(content) > maxMarkdownDraftBytes {
		add("error", "document_too_large", "The document exceeds the 100 MB authoring limit.", 1, 1, 1)
	} else if len(content) > 5<<20 {
		add("warning", "large_document", "Large Markdown documents may be slow to review and regenerate.", 1, 1, 1)
	}
	if strings.TrimSpace(document.SourceOrg) == "" {
		add("warning", "missing_source_metadata", "The guideline source organization is missing.", 1, 1, 1)
	}

	lines := strings.Split(strings.ReplaceAll(content, "\r\n", "\n"), "\n")
	headings := map[string]int{}
	previousLevel := 0
	h1 := 0
	anchors := map[string]bool{}
	definitions := map[string]bool{}
	uses := map[string]int{}
	assetIDs := map[string]bool{}
	assetNames := map[string]bool{}
	assetBaseNameCounts := map[string]int{}
	for _, asset := range assets {
		assetIDs[asset.ID.String()] = true
		if asset.OriginalFilename != nil {
			name := strings.TrimSpace(*asset.OriginalFilename)
			assetNames[name] = true
			assetBaseNameCounts[path.Base(strings.ReplaceAll(name, "\\", "/"))]++
		}
	}
	frontMatter := false
	if len(lines) > 0 && strings.TrimSpace(lines[0]) == "---" {
		frontMatter = true
	}
	frontMatterClosed := !frontMatter
	calloutLine := 0
	calloutHasContent := false
	calloutType := ""
	fenceLine := 0
	allowedHTML := map[string]bool{"br": true, "sub": true, "sup": true, "kbd": true, "mark": true, "details": true, "summary": true}
	for index, line := range lines {
		lineNo := index + 1
		if frontMatter && index > 0 && strings.TrimSpace(line) == "---" {
			frontMatterClosed = true
			frontMatter = false
			continue
		}
		if frontMatter && strings.TrimSpace(line) != "" && !strings.HasPrefix(strings.TrimSpace(line), "#") && !strings.Contains(line, ":") {
			add("error", "invalid_front_matter", "Front matter entries must use key: value syntax.", lineNo, 1, utf8.RuneCountInString(line)+1)
		}
		if match := mdHeadingRE.FindStringSubmatch(line); match != nil {
			level := len(match[1])
			headingTitle := strings.TrimSpace(match[2])
			if level == 1 {
				h1++
				if strings.TrimSpace(document.Title) != "" && !guidelineTitlesCompatible(document.Title, headingTitle) {
					add("warning", "document_title_mismatch", fmt.Sprintf("The H1 title %q does not match guideline metadata %q; publication will be blocked until they are aligned.", headingTitle, document.Title), lineNo, 1, len(line)+1)
				}
			}
			if _, placeholder := guidelineTemplateTitles[strings.ToLower(headingTitle)]; placeholder {
				add("error", "template_placeholder", fmt.Sprintf("Replace the unchanged template heading %q.", headingTitle), lineNo, 1, len(line)+1)
			}
			slug := markdownAnchor(headingTitle)
			anchors[slug] = true
			if first, exists := headings[slug]; exists {
				add("error", "duplicate_heading_anchor", fmt.Sprintf("Heading anchor %q duplicates line %d.", slug, first), lineNo, 1, len(line)+1)
			} else {
				headings[slug] = lineNo
			}
			if previousLevel > 0 && level > previousLevel+1 {
				add("warning", "skipped_heading_level", fmt.Sprintf("Heading level jumps from H%d to H%d.", previousLevel, level), lineNo, 1, level+1)
			}
			previousLevel = level
		}
		if mdUnsafeRE.MatchString(line) {
			add("error", "unsafe_html", "Scripts, embeds, event handlers, and JavaScript URLs are not allowed.", lineNo, 1, len(line)+1)
		}
		for _, match := range mdHTMLRE.FindAllStringSubmatch(line, -1) {
			if !allowedHTML[strings.ToLower(match[1])] {
				add("warning", "unsupported_raw_html", fmt.Sprintf("Raw HTML element <%s> is not supported and will be sanitized.", match[1]), lineNo, 1, len(line)+1)
			}
		}
		if strings.Contains(line, "![ ](") || regexp.MustCompile(`!\[\s*\]\(`).MatchString(line) {
			add("error", "missing_image_alt", "Images require meaningful alternative text.", lineNo, 1, len(line)+1)
		}
		for _, match := range mdLinkRE.FindAllStringSubmatch(line, -1) {
			target := strings.TrimSpace(match[2])
			image := strings.HasPrefix(match[0], "!")
			if strings.HasPrefix(target, "#") {
				if !anchors[strings.TrimPrefix(target, "#")] {
					uses["anchor:"+strings.TrimPrefix(target, "#")] = lineNo
				}
				continue
			}
			if image && (strings.HasPrefix(target, "guideline-asset://") || strings.HasPrefix(target, "asset:") || strings.HasPrefix(target, "/api/v2/guideline-assets/")) {
				id := strings.TrimPrefix(strings.TrimPrefix(strings.TrimPrefix(target, "guideline-asset://"), "asset:"), "/api/v2/guideline-assets/")
				id = strings.Split(id, "/")[0]
				if !assetIDs[id] {
					add("error", "broken_asset_reference", "The image references an asset that does not belong to this guideline version.", lineNo, 1, len(line)+1)
				}
				continue
			}
			assetBaseName := path.Base(strings.ReplaceAll(target, "\\", "/"))
			assetResolved := assetNames[target] || assetBaseNameCounts[assetBaseName] == 1
			if image && !strings.HasPrefix(target, "http://") && !strings.HasPrefix(target, "https://") && !assetResolved {
				add("warning", "unresolved_asset_reference", "The local image reference cannot be resolved to a version asset.", lineNo, 1, len(line)+1)
			}
			if strings.HasPrefix(target, "http://") || strings.HasPrefix(target, "https://") {
				if _, err := url.ParseRequestURI(target); err != nil {
					add("error", "broken_external_link_syntax", "External link syntax is invalid.", lineNo, 1, len(line)+1)
				}
			}
		}
		if match := mdReferenceDefRE.FindStringSubmatch(line); match != nil {
			definitions[strings.ToLower(match[1])] = true
		}
		for _, match := range mdReferenceUseRE.FindAllStringSubmatch(line, -1) {
			uses["ref:"+strings.ToLower(match[1])] = lineNo
		}
		trimmed := strings.TrimSpace(line)
		if strings.Contains(strings.ToLower(trimmed), guidelineTemplatePlaceholder) {
			add("error", "template_placeholder", "Replace this template placeholder with reviewed clinical content.", lineNo, 1, len(line)+1)
		}
		if strings.HasPrefix(trimmed, "```") {
			if fenceLine == 0 {
				fenceLine = lineNo
				language := strings.ToLower(strings.TrimSpace(strings.TrimPrefix(trimmed, "```")))
				allowed := map[string]bool{"": true, "text": true, "json": true, "yaml": true, "yml": true, "bash": true, "sh": true, "mermaid": true}
				if !allowed[language] {
					add("warning", "unsupported_fenced_block", fmt.Sprintf("Fenced block language %q may not render.", language), lineNo, 1, len(line)+1)
				}
			} else {
				fenceLine = 0
			}
		}
		if strings.HasPrefix(trimmed, ":::") {
			if trimmed == ":::" {
				if calloutLine == 0 {
					add("error", "unexpected_callout_end", "Callout closing marker has no opening marker.", lineNo, 1, 4)
				} else if !calloutHasContent {
					add("error", "empty_callout", "Clinical callout requires content.", calloutLine, 1, 4)
				}
				calloutLine = 0
				calloutHasContent = false
				calloutType = ""
			} else if calloutLine != 0 {
				add("error", "nested_callout", "Nested clinical callouts are not supported.", lineNo, 1, len(line)+1)
			} else {
				calloutLine = lineNo
				fields := strings.Fields(strings.TrimPrefix(trimmed, ":::"))
				if len(fields) > 0 {
					calloutType = strings.ToLower(fields[0])
				}
				allowed := map[string]bool{"recommendation": true, "warning": true, "caution": true, "key-point": true, "contraindication": true, "dosage": true, "evidence": true, "definition": true, "procedure": true, "algorithm-reference": true, "clinical-note": true, "referral-criteria": true}
				if !allowed[calloutType] {
					add("error", "unsupported_callout", fmt.Sprintf("Clinical callout type %q is unsupported.", calloutType), lineNo, 1, len(line)+1)
				}
				if map[string]bool{"recommendation": true, "warning": true, "caution": true, "contraindication": true, "dosage": true, "procedure": true, "algorithm-reference": true, "referral-criteria": true}[calloutType] {
					add("warning", "high_risk_review_required", "This clinical callout requires explicit publisher review after regeneration.", lineNo, 1, len(line)+1)
				}
			}
		} else if calloutLine != 0 && trimmed != "" {
			calloutHasContent = true
		}
		if strings.Count(line, "](") > len(mdLinkRE.FindAllString(line, -1)) {
			add("error", "malformed_link", "A Markdown link or image is not closed correctly.", lineNo, 1, len(line)+1)
		}
		if strings.Contains(line, "|") && index+1 < len(lines) && regexp.MustCompile(`^\s*\|?\s*:?-+`).MatchString(lines[index+1]) {
			expected := len(markdownTableCells(line))
			separator := len(markdownTableCells(lines[index+1]))
			if expected != separator {
				add("error", "malformed_table", "Table header and separator have different column counts.", lineNo, 1, len(line)+1)
			}
			for rowIndex := index + 2; rowIndex < len(lines) && strings.Contains(lines[rowIndex], "|"); rowIndex++ {
				columns := len(markdownTableCells(lines[rowIndex]))
				if columns != expected {
					add("error", "malformed_table", fmt.Sprintf("Table row has %d columns; expected %d.", columns, expected), rowIndex+1, 1, len(lines[rowIndex])+1)
				}
			}
			label := markdownTableLabel(lines, index)
			add("warning", "high_risk_table_review_required", fmt.Sprintf("Clinical table %q requires explicit publisher review after regeneration.", label), lineNo, 1, len(line)+1)
		}
		if mdDoseRE.MatchString(line) && !regexp.MustCompile(`(?i)\b(per|every|daily|once|twice|hour|day|week|kg|dose|route|oral|iv|im|sc)\b`).MatchString(line) {
			add("warning", "ambiguous_dosage_or_unit", "Review this dosage or unit for an explicit route, frequency, and patient basis.", lineNo, 1, len(line)+1)
		}
	}
	if !frontMatterClosed {
		add("error", "invalid_front_matter", "Front matter is not closed with ---.", 1, 1, 4)
	}
	if h1 == 0 {
		add("warning", "missing_h1", "Add one level-one document title.", 1, 1, 1)
	}
	if h1 > 1 {
		add("warning", "multiple_h1", "Use only one level-one document title.", 1, 1, 1)
	}
	if calloutLine != 0 {
		add("error", "unclosed_callout", "Clinical callout is not closed.", calloutLine, 1, 4)
	}
	if fenceLine != 0 {
		add("error", "unclosed_fenced_block", "Fenced code block is not closed.", fenceLine, 1, 4)
	}
	for key, line := range uses {
		if strings.HasPrefix(key, "anchor:") && !anchors[strings.TrimPrefix(key, "anchor:")] {
			add("error", "broken_internal_link", "Internal link target does not exist.", line, 1, 1)
		}
		if strings.HasPrefix(key, "ref:") && !definitions[strings.TrimPrefix(key, "ref:")] {
			add("error", "missing_reference_definition", "Reference-style link has no definition.", line, 1, 1)
		}
	}
	sort.SliceStable(result.Issues, func(i, j int) bool {
		if result.Issues[i].Line == result.Issues[j].Line {
			return result.Issues[i].Severity < result.Issues[j].Severity
		}
		return result.Issues[i].Line < result.Issues[j].Line
	})
	for _, issue := range result.Issues {
		switch issue.Severity {
		case "error":
			result.Errors++
		case "warning":
			result.Warnings++
		default:
			result.Info++
		}
	}
	result.Valid = result.Errors == 0
	return result
}

func markdownTableLabel(lines []string, headerIndex int) string {
	for index := headerIndex - 1; index >= 0; index-- {
		candidate := strings.TrimSpace(lines[index])
		if candidate == "" {
			continue
		}
		candidate = strings.TrimSpace(strings.Trim(candidate, "*_`"))
		if matches := mdHeadingRE.FindStringSubmatch(candidate); len(matches) == 3 {
			candidate = strings.TrimSpace(matches[2])
		}
		if candidate != "" {
			return candidate
		}
	}
	return fmt.Sprintf("starting on line %d", headerIndex+1)
}

// markdownTableCells counts Markdown table cells without discarding meaningful
// empty cells at either edge. It also keeps escaped pipes and pipes inside
// inline-code spans in their containing cell.
func markdownTableCells(line string) []string {
	line = strings.TrimSpace(line)
	if strings.HasPrefix(line, "|") {
		line = strings.TrimPrefix(line, "|")
	}
	if strings.HasSuffix(line, "|") && !isEscapedMarkdownByte(line, len(line)-1) {
		line = strings.TrimSuffix(line, "|")
	}

	cells := make([]string, 0, strings.Count(line, "|")+1)
	start := 0
	inCode := false
	for index := 0; index < len(line); index++ {
		switch line[index] {
		case '`':
			if !isEscapedMarkdownByte(line, index) {
				inCode = !inCode
			}
		case '|':
			if !inCode && !isEscapedMarkdownByte(line, index) {
				cells = append(cells, line[start:index])
				start = index + 1
			}
		}
	}
	cells = append(cells, line[start:])
	return cells
}

func isEscapedMarkdownByte(value string, index int) bool {
	backslashes := 0
	for index--; index >= 0 && value[index] == '\\'; index-- {
		backslashes++
	}
	return backslashes%2 == 1
}

func markdownAnchor(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = regexp.MustCompile(`[^a-z0-9\s-]`).ReplaceAllString(value, "")
	value = regexp.MustCompile(`[\s-]+`).ReplaceAllString(value, "-")
	return strings.Trim(value, "-")
}
