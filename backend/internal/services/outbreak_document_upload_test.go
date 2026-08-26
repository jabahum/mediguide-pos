package services

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/url"
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

type outbreakDocumentTestFile struct{ *bytes.Reader }

func (outbreakDocumentTestFile) Close() error { return nil }

type outbreakDocumentTestStore struct {
	objects map[string][]byte
	deleted []string
}

func (s *outbreakDocumentTestStore) Put(_ context.Context, key string, reader io.Reader, _ int64, _ string) error {
	data, err := io.ReadAll(reader)
	if err != nil {
		return err
	}
	s.objects[key] = data
	return nil
}
func (s *outbreakDocumentTestStore) Get(_ context.Context, key string) (io.ReadCloser, error) {
	return io.NopCloser(bytes.NewReader(s.objects[key])), nil
}
func (s *outbreakDocumentTestStore) Delete(_ context.Context, key string) error {
	delete(s.objects, key)
	s.deleted = append(s.deleted, key)
	return nil
}
func (s *outbreakDocumentTestStore) PresignGet(_ context.Context, key string, _ time.Duration) (*url.URL, error) {
	return url.Parse("https://objects.example.test/" + key)
}

func TestOutbreakDocumentUploadValidatesAndReplacesManagedFiles(t *testing.T) {
	service := outbreakAdminTestService(t)
	store := &outbreakDocumentTestStore{objects: map[string][]byte{}}
	service.Store = store
	parent := models.Outbreak{Title: "Ebola response", Status: "draft", LastUpdate: time.Now(), LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	author := OutbreakActor{ID: uuid.New()}
	document, err := service.CreateDocument(author, parent.ID, OutbreakDocumentInput{
		Title: ptr("Case-management SOP"), DocumentKind: ptr("sop"), IssuingAuthority: ptr("Ministry of Health"), Version: ptr("1.0"),
	})
	if err != nil {
		t.Fatal(err)
	}
	pdf := []byte("%PDF-1.7\n1 0 obj <</Type /Page>> endobj\n%%EOF")
	header := &multipart.FileHeader{Filename: "Ebola SOP.pdf", Size: int64(len(pdf))}
	uploaded, err := service.UploadDocument(context.Background(), author, parent.ID, document.ID, 1, outbreakDocumentTestFile{bytes.NewReader(pdf)}, header, 1024)
	if err != nil {
		t.Fatal(err)
	}
	if uploaded.MIMEType != "application/pdf" || uploaded.ChecksumSHA256 == "" || uploaded.FileSize != int64(len(pdf)) || uploaded.PageCount == nil || *uploaded.PageCount != 1 || uploaded.LockVersion != 2 {
		t.Fatalf("unexpected uploaded metadata: %#v", uploaded)
	}
	if !strings.HasPrefix(uploaded.OriginalFilename, "Ebola SOP") || len(store.objects) != 1 {
		t.Fatalf("file was not stored safely: %#v objects=%d", uploaded, len(store.objects))
	}

	badHeader := &multipart.FileHeader{Filename: "malware.exe", Size: int64(len(pdf))}
	if _, err := service.UploadDocument(context.Background(), author, parent.ID, document.ID, 2, outbreakDocumentTestFile{bytes.NewReader(pdf)}, badHeader, 1024); err != ErrOutbreakInvalid {
		t.Fatalf("disallowed extension accepted: %v", err)
	}

	markdown := []byte("# Case management\n\nUse approved PPE.\n")
	markdownHeader := &multipart.FileHeader{Filename: "case-management.md", Size: int64(len(markdown))}
	replaced, err := service.UploadDocument(context.Background(), author, parent.ID, document.ID, 2, outbreakDocumentTestFile{bytes.NewReader(markdown)}, markdownHeader, 1024)
	if err != nil {
		t.Fatal(err)
	}
	if replaced.MIMEType != "text/markdown; charset=utf-8" || replaced.LockVersion != 3 || len(store.objects) != 1 || len(store.deleted) != 1 {
		t.Fatalf("replacement did not clean old object: %#v stored=%d deleted=%#v", replaced, len(store.objects), store.deleted)
	}
	var derived models.OutbreakResource
	if err := service.DB.First(&derived, "id = ?", document.ID).Error; err != nil {
		t.Fatal(err)
	}
	if derived.ExtractionStatus != "ready" || derived.ContentFormat != "markdown" || !strings.Contains(derived.SearchContent, "approved PPE") || derived.RenderedContent != strings.TrimSpace(string(markdown)) {
		t.Fatalf("markdown discovery content was not derived safely: %#v", derived)
	}
}

func TestOutbreakDocumentUploadRejectsSignatureMismatchAndStaleLock(t *testing.T) {
	service := outbreakAdminTestService(t)
	service.Store = &outbreakDocumentTestStore{objects: map[string][]byte{}}
	parent := models.Outbreak{Title: "Response", Status: "draft", LastUpdate: time.Now(), LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	document, err := service.CreateDocument(OutbreakActor{ID: uuid.New()}, parent.ID, OutbreakDocumentInput{Title: ptr("Protocol")})
	if err != nil {
		t.Fatal(err)
	}
	content := []byte("this is not a PDF")
	header := &multipart.FileHeader{Filename: "protocol.pdf", Size: int64(len(content))}
	if _, err := service.UploadDocument(context.Background(), OutbreakActor{ID: uuid.New()}, parent.ID, document.ID, 1, outbreakDocumentTestFile{bytes.NewReader(content)}, header, 1024); err != ErrOutbreakInvalid {
		t.Fatalf("signature mismatch accepted: %v", err)
	}
	valid := []byte("%PDF-1.7\n%%EOF")
	header = &multipart.FileHeader{Filename: "protocol.pdf", Size: int64(len(valid))}
	if _, err := service.UploadDocument(context.Background(), OutbreakActor{ID: uuid.New()}, parent.ID, document.ID, 2, outbreakDocumentTestFile{bytes.NewReader(valid)}, header, 1024); err != ErrOutbreakConflict {
		t.Fatalf("stale lock accepted: %v", err)
	}
}

func TestOutbreakDocumentReprocessVerifiesObjectAndRebuildsDerivedContent(t *testing.T) {
	service := outbreakAdminTestService(t)
	store := &outbreakDocumentTestStore{objects: map[string][]byte{}}
	service.Store = store
	parent := models.Outbreak{Title: "Response", Status: "draft", LastUpdate: time.Now(), LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	actor := OutbreakActor{ID: uuid.New()}
	document, err := service.CreateDocument(actor, parent.ID, OutbreakDocumentInput{Title: ptr("IPC SOP")})
	if err != nil {
		t.Fatal(err)
	}
	markdown := []byte("# IPC SOP\n\nWear approved PPE and isolate the patient.\n")
	uploaded, err := service.UploadDocument(context.Background(), actor, parent.ID, document.ID, 1, outbreakDocumentTestFile{bytes.NewReader(markdown)}, &multipart.FileHeader{Filename: "ipc.md", Size: int64(len(markdown))}, 1024)
	if err != nil {
		t.Fatal(err)
	}
	if uploaded.ExtractionStatus != "ready" || !uploaded.SupportsPreview {
		t.Fatalf("upload did not expose extraction state: %#v", uploaded)
	}
	if err := service.DB.Model(&models.OutbreakResource{}).Where("id = ?", document.ID).Updates(map[string]any{
		"search_content": "", "rendered_content": "", "content_format": "", "extraction_status": "failed", "extracted_at": nil,
	}).Error; err != nil {
		t.Fatal(err)
	}
	reprocessed, err := service.ReprocessDocument(context.Background(), actor, parent.ID, document.ID, uploaded.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if reprocessed.ExtractionStatus != "ready" || reprocessed.ContentFormat != "markdown" || !reprocessed.SupportsPreview || reprocessed.ExtractedAt == nil || reprocessed.LockVersion != uploaded.LockVersion+1 {
		t.Fatalf("unexpected reprocess result: %#v", reprocessed)
	}
	preview, err := service.DocumentContent(parent.ID, document.ID)
	if err != nil || !strings.Contains(preview.Content, "approved PPE") {
		t.Fatalf("derived preview unavailable: %#v %v", preview, err)
	}
	var audit models.AuditLog
	if err := service.DB.Where("entity_id = ? AND action = ?", document.ID, "outbreak_document.content_reprocessed").First(&audit).Error; err != nil {
		t.Fatalf("reprocess was not audited: %v", err)
	}

	var row models.OutbreakResource
	if err := service.DB.First(&row, "id = ?", document.ID).Error; err != nil {
		t.Fatal(err)
	}
	store.objects[row.StorageKey] = []byte("tampered")
	if _, err := service.ReprocessDocument(context.Background(), actor, parent.ID, document.ID, reprocessed.LockVersion); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("tampered object was reprocessed: %v", err)
	}
}

func TestOutbreakDocumentDerivationSanitizesMarkdownAndBuildsStableSections(t *testing.T) {
	derived := deriveOutbreakDocumentContent("md", []byte("# Immediate Action\n\n<script>alert('x')</script>Use PPE.\n\n## Triage\n\nAssess the patient.\n\n## Triage\n\nEscalate."))
	if derived.Status != "ready" || derived.Format != "markdown" || derived.Checksum == "" || strings.Contains(strings.ToLower(derived.Rendered), "<script") || strings.Contains(derived.Search, "alert") {
		t.Fatalf("unsafe or incomplete Markdown projection: %#v", derived)
	}
	var sections []outbreakDocumentSection
	if err := json.Unmarshal(derived.SectionsJSON, &sections); err != nil {
		t.Fatal(err)
	}
	if len(sections) != 3 || sections[0].ID != "immediate-action" || sections[1].ID != "triage" || sections[2].ID != "triage-2" || !strings.Contains(derived.Headings, "Immediate Action") {
		t.Fatalf("unexpected section projection: %#v", sections)
	}
}

func TestOutbreakDocumentDerivationExtractsSpreadsheetCells(t *testing.T) {
	var payload bytes.Buffer
	writer := zip.NewWriter(&payload)
	for name, contents := range map[string]string{
		"xl/sharedStrings.xml":     `<sst><si><t>Isolation ward</t></si><si><t>Daily checklist</t></si></sst>`,
		"xl/worksheets/sheet1.xml": `<worksheet><sheetData><row><c t="inlineStr"><is><t>PPE stock</t></is></c></row></sheetData></worksheet>`,
	} {
		entry, err := writer.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := entry.Write([]byte(contents)); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	derived := deriveOutbreakDocumentContent("xlsx", payload.Bytes())
	if derived.Status != "ready" || derived.Format != "spreadsheet_text" || !strings.Contains(derived.Search, "Isolation ward") || !strings.Contains(derived.Search, "PPE stock") || derived.Rendered != "" {
		t.Fatalf("unexpected spreadsheet projection: %#v", derived)
	}
}

func TestOutbreakDocumentDerivationExtractsPDFPages(t *testing.T) {
	derived := deriveOutbreakDocumentContent("pdf", minimalTextPDF("Isolation protocol"))
	if derived.Status != "ready" || derived.Format != "pdf_text" || !strings.Contains(derived.Search, "Isolation protocol") {
		t.Fatalf("unexpected PDF projection: status=%s error=%s search=%q", derived.Status, derived.Error, derived.Search)
	}
	var sections []outbreakDocumentSection
	if err := json.Unmarshal(derived.SectionsJSON, &sections); err != nil {
		t.Fatal(err)
	}
	if len(sections) != 1 || sections[0].Page == nil || *sections[0].Page != 1 || sections[0].ID != "page-1" {
		t.Fatalf("missing PDF page mapping: %#v", sections)
	}
}

func minimalTextPDF(text string) []byte {
	objects := []string{
		`<< /Type /Catalog /Pages 2 0 R >>`,
		`<< /Type /Pages /Kids [3 0 R] /Count 1 >>`,
		`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>`,
		`<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>`,
	}
	stream := fmt.Sprintf("BT /F1 12 Tf 72 720 Td (%s) Tj ET", strings.ReplaceAll(text, ")", `\)`))
	objects = append(objects, fmt.Sprintf("<< /Length %d >>\nstream\n%s\nendstream", len(stream), stream))
	var output bytes.Buffer
	output.WriteString("%PDF-1.4\n")
	offsets := []int{0}
	for index, object := range objects {
		offsets = append(offsets, output.Len())
		fmt.Fprintf(&output, "%d 0 obj\n%s\nendobj\n", index+1, object)
	}
	xref := output.Len()
	fmt.Fprintf(&output, "xref\n0 %d\n0000000000 65535 f \n", len(objects)+1)
	for _, offset := range offsets[1:] {
		fmt.Fprintf(&output, "%010d 00000 n \n", offset)
	}
	fmt.Fprintf(&output, "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF", len(objects)+1, xref)
	return output.Bytes()
}
