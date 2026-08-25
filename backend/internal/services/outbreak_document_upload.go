package services

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
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
	searchContent, renderedContent, contentFormat, extractionStatus := deriveOutbreakDocumentContent(metadata.Extension, data)
	extractedAt := time.Now().UTC()

	if current.StorageKey == key && current.ChecksumSHA256 == checksum && current.OriginalFilename == name {
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
		"search_content": searchContent, "rendered_content": renderedContent,
		"content_format": contentFormat, "extraction_status": extractionStatus,
		"extracted_at": extractedAt,
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
	search, rendered, format, status := deriveOutbreakDocumentContent(metadata.Extension, data)
	now := time.Now().UTC()
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.OutbreakResource{}).
			Where("id = ? AND outbreak_id = ? AND lock_version = ?", documentID, outbreakID, lockVersion).
			Updates(map[string]any{
				"search_content": search, "rendered_content": rendered,
				"content_format": format, "extraction_status": status,
				"extracted_at": now, "lock_version": gorm.Expr("lock_version + 1"),
			})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_document.content_reprocessed", "outbreak_document", documentID, map[string]any{
			"previous_status": current.ExtractionStatus, "extraction_status": status,
			"content_format": format, "checksum_sha256": current.ChecksumSHA256,
		})
	})
	if err != nil {
		return nil, err
	}
	return s.GetDocument(outbreakID, documentID)
}

var markdownSyntax = regexp.MustCompile(`(?m)(?:^#{1,6}\s+|[*_~` + "`" + `>\[\]()]|!\[[^]]*\]\([^)]*\)|\[[^]]+\]\([^)]*\))`)
var whitespaceRuns = regexp.MustCompile(`\s+`)
var xmlTags = regexp.MustCompile(`<[^>]+>`)

// deriveOutbreakDocumentContent deliberately supports only formats for which
// the API can produce deterministic, safe text without executing converters.
// PDF and spreadsheet extraction remain explicit "not_available" states until
// a sandboxed extraction worker is configured.
func deriveOutbreakDocumentContent(extension string, data []byte) (search, rendered, format, status string) {
	switch extension {
	case "md":
		rendered = strings.TrimSpace(string(data))
		search = strings.TrimSpace(whitespaceRuns.ReplaceAllString(markdownSyntax.ReplaceAllString(rendered, " "), " "))
		return search, rendered, "markdown", "ready"
	case "txt":
		rendered = strings.TrimSpace(string(data))
		search = strings.TrimSpace(whitespaceRuns.ReplaceAllString(rendered, " "))
		return search, rendered, "plain_text", "ready"
	case "docx":
		text, err := extractOfficeXMLText(data, "word/document.xml")
		if err == nil && text != "" {
			return text, text, "plain_text", "ready"
		}
		return "", "", "", "failed"
	default:
		return "", "", "", "not_available"
	}
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
