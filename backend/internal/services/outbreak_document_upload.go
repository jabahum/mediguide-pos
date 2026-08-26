package services

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"github.com/ledongthuc/pdf"
	"github.com/microcosm-cc/bluemonday"
	"gorm.io/gorm"
)

const defaultOutbreakDocumentMaxBytes int64 = 25 << 20

var pdfPageMarker = regexp.MustCompile(`/Type\s*/Page\b`)

type outbreakDocumentFile struct {
	MIMEType  string
	Extension string
	PageCount *int
}

func (s OutbreakAdminService) UploadDocument(ctx context.Context, actor OutbreakActor, outbreakID, documentID uuid.UUID, lockVersion int, file multipart.File, header *multipart.FileHeader, maxBytes int64) (*OutbreakDocumentAdminDTO, error) {
	if s.Store == nil {
		return nil, errors.New("outbreak document storage unavailable")
	}
	if lockVersion < 1 || file == nil || header == nil {
		return nil, ErrOutbreakInvalid
	}
	if maxBytes <= 0 {
		maxBytes = defaultOutbreakDocumentMaxBytes
	}
	if header.Size <= 0 || header.Size > maxBytes {
		return nil, ErrOutbreakInvalid
	}
	var current models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&current).Error; err != nil {
		return nil, err
	}
	if current.Status != "draft" {
		return nil, ErrOutbreakImmutable
	}
	if current.LockVersion != lockVersion {
		return nil, ErrOutbreakConflict
	}

	data, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil || len(data) == 0 || int64(len(data)) > maxBytes {
		return nil, ErrOutbreakInvalid
	}
	name, err := safeOutbreakDocumentFilename(header.Filename)
	if err != nil {
		return nil, err
	}
	metadata, err := validateOutbreakDocumentFile(name, data, maxBytes)
	if err != nil {
		return nil, err
	}
	digest := sha256.Sum256(data)
	checksum := hex.EncodeToString(digest[:])
	key := fmt.Sprintf("outbreaks/%s/documents/%s/%s.%s", outbreakID, documentID, checksum, metadata.Extension)
	derived := deriveOutbreakDocumentContent(metadata.Extension, data)
	extractedAt := time.Now().UTC()

	if current.StorageKey == key && current.ChecksumSHA256 == checksum && current.OriginalFilename == name && current.ExtractionSourceChecksum == checksum && current.SearchSchemaVersion == OutbreakDocumentSearchSchemaVersion {
		result := outbreakDocumentAdminDTO(current)
		return &result, nil
	}
	if err := s.Store.Put(ctx, key, bytes.NewReader(data), int64(len(data)), metadata.MIMEType); err != nil {
		return nil, err
	}
	updates := map[string]any{
		"storage_key": key, "original_filename": name, "mime_type": metadata.MIMEType,
		"file_size": int64(len(data)), "checksum_sha256": checksum, "page_count": metadata.PageCount,
		"asset_url": "", "lock_version": gorm.Expr("lock_version + 1"),
		"search_content": derived.Search, "search_headings": derived.Headings, "rendered_content": derived.Rendered,
		"content_format": derived.Format, "extraction_status": derived.Status,
		"extraction_error": derived.Error, "extraction_source_checksum": checksum,
		"derived_content_checksum": derived.Checksum, "content_sections": derived.SectionsJSON,
		"source_page_map": derived.PageMapJSON, "search_index_status": "pending_approval",
		"search_schema_version": OutbreakDocumentSearchSchemaVersion,
		"extracted_at":          extractedAt, "indexed_at": nil,
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.OutbreakResource{}).
			Where("id = ? AND outbreak_id = ? AND status = 'draft' AND lock_version = ?", documentID, outbreakID, lockVersion).
			Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_document.file_uploaded", "outbreak_document", documentID, map[string]any{
			"original_filename": name, "mime_type": metadata.MIMEType, "file_size": len(data), "checksum_sha256": checksum,
		})
	})
	if err != nil {
		_ = s.Store.Delete(ctx, key)
		return nil, err
	}
	if current.StorageKey != "" && current.StorageKey != key {
		s.deleteUnreferencedDocumentObject(ctx, current.StorageKey)
	}
	return s.GetDocument(outbreakID, documentID)
}

// ReprocessDocument rebuilds only server-owned search and preview projections
// from the immutable managed object. It verifies both the stored file shape and
// checksum before changing any database state.
func (s OutbreakAdminService) ReprocessDocument(ctx context.Context, actor OutbreakActor, outbreakID, documentID uuid.UUID, lockVersion int) (*OutbreakDocumentAdminDTO, error) {
	if s.Store == nil || lockVersion < 1 {
		return nil, ErrOutbreakInvalid
	}
	var current models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&current).Error; err != nil {
		return nil, err
	}
	if current.LockVersion != lockVersion {
		return nil, ErrOutbreakConflict
	}
	if current.StorageKey == "" || current.OriginalFilename == "" || !outbreakDocumentChecksum.MatchString(current.ChecksumSHA256) {
		return nil, ErrOutbreakInvalid
	}
	stream, err := s.Store.Get(ctx, current.StorageKey)
	if err != nil {
		return nil, err
	}
	data, readErr := io.ReadAll(io.LimitReader(stream, defaultOutbreakDocumentMaxBytes+1))
	closeErr := stream.Close()
	if readErr != nil || closeErr != nil || len(data) == 0 || int64(len(data)) > defaultOutbreakDocumentMaxBytes {
		return nil, ErrOutbreakInvalid
	}
	metadata, err := validateOutbreakDocumentFile(current.OriginalFilename, data, defaultOutbreakDocumentMaxBytes)
	if err != nil {
		return nil, err
	}
	digest := sha256.Sum256(data)
	if hex.EncodeToString(digest[:]) != current.ChecksumSHA256 {
		return nil, ErrOutbreakInvalid
	}
	derived := deriveOutbreakDocumentContent(metadata.Extension, data)
	if current.ExtractionSourceChecksum == current.ChecksumSHA256 && current.DerivedContentChecksum == derived.Checksum && current.SearchSchemaVersion == OutbreakDocumentSearchSchemaVersion && current.ExtractionStatus == derived.Status {
		result := outbreakDocumentAdminDTO(current)
		return &result, nil
	}
	now := time.Now().UTC()
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.OutbreakResource{}).
			Where("id = ? AND outbreak_id = ? AND lock_version = ?", documentID, outbreakID, lockVersion).
			Updates(map[string]any{
				"search_content": derived.Search, "search_headings": derived.Headings, "rendered_content": derived.Rendered,
				"content_format": derived.Format, "extraction_status": derived.Status,
				"extraction_error": derived.Error, "extraction_source_checksum": current.ChecksumSHA256,
				"derived_content_checksum": derived.Checksum, "content_sections": derived.SectionsJSON,
				"source_page_map": derived.PageMapJSON, "search_index_status": "pending_approval",
				"search_schema_version": OutbreakDocumentSearchSchemaVersion,
				"extracted_at":          now, "indexed_at": nil, "lock_version": gorm.Expr("lock_version + 1"),
			})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_document.content_reprocessed", "outbreak_document", documentID, map[string]any{
			"previous_status": current.ExtractionStatus, "extraction_status": derived.Status,
			"content_format": derived.Format, "checksum_sha256": current.ChecksumSHA256,
		})
	})
	if err != nil {
		return nil, err
	}
	return s.GetDocument(outbreakID, documentID)
}

// OutbreakDocumentSearchSchemaVersion identifies the deterministic derived
// projection format. Seed/import code must use the same value and derivation
// helper as runtime uploads so fresh environments do not start stale.
const OutbreakDocumentSearchSchemaVersion = 2

type OutbreakDocumentProjection struct {
	Search, Headings, Rendered, Format, Status, Error, Checksum string
	SectionsJSON, PageMapJSON                                   []byte
}

type outbreakDocumentSection struct {
	ID      string `json:"id"`
	Heading string `json:"heading"`
	Level   int    `json:"level"`
	Text    string `json:"text"`
	Page    *int   `json:"page,omitempty"`
}

type outbreakDocumentPageMap struct {
	Page      int    `json:"page"`
	SectionID string `json:"section_id"`
}

var markdownSyntax = regexp.MustCompile(`(?m)(?:^#{1,6}\s+|[*_~` + "`" + `>\[\]()]|!\[[^]]*\]\([^)]*\)|\[[^]]+\]\([^)]*\))`)
var markdownHeading = regexp.MustCompile(`^(#{1,6})\s+(.+?)\s*#*\s*$`)
var whitespaceRuns = regexp.MustCompile(`\s+`)
var xmlTags = regexp.MustCompile(`<[^>]+>`)
var spreadsheetCellText = regexp.MustCompile(`(?s)<(?:t|v)(?:\s[^>]*)?>(.*?)</(?:t|v)>`)
var nonSlug = regexp.MustCompile(`[^a-z0-9]+`)

// deriveOutbreakDocumentContent creates server-owned projections. The source
// object remains immutable and authoritative; these fields can always be
// discarded and deterministically rebuilt from its checksum-bound bytes.
func deriveOutbreakDocumentContent(extension string, data []byte) OutbreakDocumentProjection {
	var result OutbreakDocumentProjection
	var sections []outbreakDocumentSection
	var pages []outbreakDocumentPageMap
	switch extension {
	case "md":
		result.Rendered = sanitizeOutbreakMarkdown(string(data))
		sections = extractMarkdownSections(result.Rendered)
		result.Search = searchableSections(sections, result.Rendered)
		result.Format, result.Status = "markdown", "ready"
	case "txt":
		result.Rendered = strings.TrimSpace(string(data))
		sections = []outbreakDocumentSection{{ID: "document", Heading: "Document", Level: 1, Text: result.Rendered}}
		result.Search = normalizeSearchText(result.Rendered)
		result.Format, result.Status = "plain_text", "ready"
	case "docx":
		text, err := extractOfficeXMLText(data, "word/document.xml")
		if err == nil && text != "" {
			result.Search, result.Rendered = text, text
			sections = []outbreakDocumentSection{{ID: "document", Heading: "Document", Level: 1, Text: text}}
			result.Format, result.Status = "plain_text", "ready"
		} else {
			result.Status, result.Error = "failed", safeExtractionError(err, "DOCX contains no readable text")
		}
	case "pdf":
		var err error
		sections, pages, result.Search, err = extractPDFText(data)
		if err != nil || result.Search == "" {
			result.Status, result.Error = "failed", safeExtractionError(err, "PDF contains no extractable text; OCR may be required")
		} else {
			result.Format, result.Status = "pdf_text", "ready"
		}
	case "xlsx":
		text, err := extractSpreadsheetText(data)
		if err != nil || text == "" {
			result.Status, result.Error = "failed", safeExtractionError(err, "Spreadsheet contains no indexable text")
		} else {
			result.Search = text
			sections = []outbreakDocumentSection{{ID: "spreadsheet", Heading: "Spreadsheet", Level: 1, Text: text}}
			result.Format, result.Status = "spreadsheet_text", "ready"
		}
	default:
		result.Status = "not_available"
	}
	result.SectionsJSON, _ = json.Marshal(sections)
	result.PageMapJSON, _ = json.Marshal(pages)
	for _, section := range sections {
		result.Headings += " " + section.Heading
	}
	result.Headings = normalizeSearchText(result.Headings)
	digest := sha256.Sum256([]byte(result.Rendered + "\x00" + result.Search + "\x00" + string(result.SectionsJSON)))
	result.Checksum = hex.EncodeToString(digest[:])
	return result
}

// DeriveOutbreakDocumentProjection exposes the exact runtime projection to
// controlled seed/import commands. It does not publish or approve content.
func DeriveOutbreakDocumentProjection(extension string, data []byte) OutbreakDocumentProjection {
	return deriveOutbreakDocumentContent(strings.TrimPrefix(strings.ToLower(strings.TrimSpace(extension)), "."), data)
}

func sanitizeOutbreakMarkdown(value string) string {
	// StrictPolicy removes executable/raw HTML while leaving Markdown syntax,
	// tables, lists, callouts and fenced code as text for the Markdown renderer.
	return strings.TrimSpace(bluemonday.StrictPolicy().Sanitize(value))
}

func extractMarkdownSections(markdown string) []outbreakDocumentSection {
	lines := strings.Split(markdown, "\n")
	sections := make([]outbreakDocumentSection, 0)
	used := map[string]int{}
	current := outbreakDocumentSection{ID: "document", Heading: "Document", Level: 1}
	flush := func() {
		current.Text = strings.TrimSpace(current.Text)
		if current.Text != "" || current.ID != "document" {
			sections = append(sections, current)
		}
	}
	for _, line := range lines {
		match := markdownHeading.FindStringSubmatch(strings.TrimSpace(line))
		if len(match) == 3 {
			flush()
			heading := strings.TrimSpace(markdownSyntax.ReplaceAllString(match[2], ""))
			base := stableSectionID(heading)
			used[base]++
			id := base
			if used[base] > 1 {
				id = fmt.Sprintf("%s-%d", base, used[base])
			}
			current = outbreakDocumentSection{ID: id, Heading: heading, Level: len(match[1])}
			continue
		}
		current.Text += line + "\n"
	}
	flush()
	return sections
}

func stableSectionID(value string) string {
	id := strings.Trim(nonSlug.ReplaceAllString(strings.ToLower(value), "-"), "-")
	if id == "" {
		return "section"
	}
	return id
}

func searchableSections(sections []outbreakDocumentSection, fallback string) string {
	parts := make([]string, 0, len(sections)*2)
	for _, section := range sections {
		parts = append(parts, section.Heading, section.Text)
	}
	if len(parts) == 0 {
		parts = append(parts, fallback)
	}
	return normalizeSearchText(markdownSyntax.ReplaceAllString(strings.Join(parts, " "), " "))
}

func normalizeSearchText(value string) string {
	return strings.TrimSpace(whitespaceRuns.ReplaceAllString(value, " "))
}

func safeExtractionError(err error, fallback string) string {
	if err == nil {
		return fallback
	}
	message := strings.TrimSpace(err.Error())
	if len(message) > 500 {
		message = message[:500]
	}
	return message
}

func extractPDFText(data []byte) ([]outbreakDocumentSection, []outbreakDocumentPageMap, string, error) {
	reader, err := pdf.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return nil, nil, "", err
	}
	sections := make([]outbreakDocumentSection, 0, reader.NumPage())
	pageMap := make([]outbreakDocumentPageMap, 0, reader.NumPage())
	parts := make([]string, 0, reader.NumPage())
	for pageNumber := 1; pageNumber <= reader.NumPage(); pageNumber++ {
		text, pageErr := reader.Page(pageNumber).GetPlainText(nil)
		if pageErr != nil {
			return nil, nil, "", fmt.Errorf("extract PDF page %d: %w", pageNumber, pageErr)
		}
		text = normalizeSearchText(text)
		if text == "" {
			continue
		}
		page := pageNumber
		id := fmt.Sprintf("page-%d", pageNumber)
		sections = append(sections, outbreakDocumentSection{ID: id, Heading: fmt.Sprintf("Page %d", pageNumber), Level: 1, Text: text, Page: &page})
		pageMap = append(pageMap, outbreakDocumentPageMap{Page: pageNumber, SectionID: id})
		parts = append(parts, text)
	}
	return sections, pageMap, normalizeSearchText(strings.Join(parts, " ")), nil
}

func extractSpreadsheetText(data []byte) (string, error) {
	reader, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return "", err
	}
	parts := make([]string, 0)
	for _, file := range reader.File {
		name := filepath.ToSlash(filepath.Clean(file.Name))
		if name != "xl/sharedStrings.xml" && !strings.HasPrefix(name, "xl/worksheets/sheet") {
			continue
		}
		stream, openErr := file.Open()
		if openErr != nil {
			return "", openErr
		}
		contents, readErr := io.ReadAll(io.LimitReader(stream, defaultOutbreakDocumentMaxBytes))
		closeErr := stream.Close()
		if readErr != nil {
			return "", readErr
		}
		if closeErr != nil {
			return "", closeErr
		}
		for _, match := range spreadsheetCellText.FindAllSubmatch(contents, -1) {
			if len(match) == 2 {
				parts = append(parts, string(match[1]))
			}
		}
	}
	text := strings.NewReplacer("&amp;", "&", "&lt;", "<", "&gt;", ">", "&quot;", `"`, "&apos;", "'").Replace(strings.Join(parts, " "))
	return normalizeSearchText(text), nil
}

func extractOfficeXMLText(data []byte, part string) (string, error) {
	reader, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return "", err
	}
	for _, file := range reader.File {
		if filepath.ToSlash(filepath.Clean(file.Name)) != part {
			continue
		}
		stream, err := file.Open()
		if err != nil {
			return "", err
		}
		contents, readErr := io.ReadAll(io.LimitReader(stream, defaultOutbreakDocumentMaxBytes))
		closeErr := stream.Close()
		if readErr != nil {
			return "", readErr
		}
		if closeErr != nil {
			return "", closeErr
		}
		plain := strings.ReplaceAll(strings.ReplaceAll(string(contents), "</w:p>", "\n"), "</w:tab>", "\t")
		plain = xmlTags.ReplaceAllString(plain, " ")
		plain = strings.NewReplacer("&amp;", "&", "&lt;", "<", "&gt;", ">", "&quot;", `"`, "&apos;", "'").Replace(plain)
		return strings.TrimSpace(whitespaceRuns.ReplaceAllString(plain, " ")), nil
	}
	return "", ErrOutbreakInvalid
}

func (s OutbreakAdminService) deleteUnreferencedDocumentObject(ctx context.Context, key string) {
	if s.Store == nil || strings.TrimSpace(key) == "" {
		return
	}
	var references int64
	if err := s.DB.Model(&models.OutbreakResource{}).Where("storage_key = ?", key).Count(&references).Error; err == nil && references == 0 {
		_ = s.Store.Delete(ctx, key)
	}
}

func safeOutbreakDocumentFilename(value string) (string, error) {
	// Browsers normally send a basename, but some clients still send a Windows
	// path. Normalize both separator styles before retaining display metadata.
	name := strings.TrimSpace(filepath.Base(strings.ReplaceAll(value, `\`, "/")))
	if name == "" || name == "." || len(name) > 255 || strings.ContainsAny(name, "\x00\r\n") {
		return "", ErrOutbreakInvalid
	}
	return name, nil
}

func validateOutbreakDocumentFile(filename string, data []byte, maxBytes int64) (outbreakDocumentFile, error) {
	extension := strings.ToLower(strings.TrimPrefix(filepath.Ext(filename), "."))
	switch extension {
	case "pdf":
		if !bytes.HasPrefix(data, []byte("%PDF-")) || !bytes.Contains(data[max(0, len(data)-2048):], []byte("%%EOF")) {
			return outbreakDocumentFile{}, ErrOutbreakInvalid
		}
		pages := len(pdfPageMarker.FindAll(data, -1))
		var pageCount *int
		if pages > 0 {
			pageCount = &pages
		}
		return outbreakDocumentFile{MIMEType: "application/pdf", Extension: extension, PageCount: pageCount}, nil
	case "docx":
		if err := validateOfficeOpenXML(data, maxBytes, "word/document.xml"); err != nil {
			return outbreakDocumentFile{}, err
		}
		return outbreakDocumentFile{MIMEType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document", Extension: extension}, nil
	case "xlsx":
		if err := validateOfficeOpenXML(data, maxBytes, "xl/workbook.xml"); err != nil {
			return outbreakDocumentFile{}, err
		}
		return outbreakDocumentFile{MIMEType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", Extension: extension}, nil
	case "md", "txt":
		if !utf8.Valid(data) || bytes.IndexByte(data, 0) >= 0 {
			return outbreakDocumentFile{}, ErrOutbreakInvalid
		}
		mimeType := "text/plain; charset=utf-8"
		if extension == "md" {
			mimeType = "text/markdown; charset=utf-8"
		}
		return outbreakDocumentFile{MIMEType: mimeType, Extension: extension}, nil
	default:
		return outbreakDocumentFile{}, ErrOutbreakInvalid
	}
}

func validateOfficeOpenXML(data []byte, maxBytes int64, requiredPart string) error {
	reader, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return ErrOutbreakInvalid
	}
	foundTypes, foundPart := false, false
	var expanded uint64
	limit := uint64(maxBytes * 10)
	for _, file := range reader.File {
		clean := filepath.ToSlash(filepath.Clean(file.Name))
		if strings.HasPrefix(clean, "../") || strings.HasPrefix(clean, "/") || strings.Contains(clean, ":") {
			return ErrOutbreakInvalid
		}
		expanded += file.UncompressedSize64
		if expanded > limit {
			return ErrOutbreakInvalid
		}
		foundTypes = foundTypes || clean == "[Content_Types].xml"
		foundPart = foundPart || clean == requiredPart
	}
	if !foundTypes || !foundPart {
		return ErrOutbreakInvalid
	}
	return nil
}
