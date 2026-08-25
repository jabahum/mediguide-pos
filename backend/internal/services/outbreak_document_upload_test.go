package services

import (
	"bytes"
	"context"
	"errors"
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
