package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type fakePublicGuidelineReader struct {
	listResult     *services.PageResult[services.PublicGuideline]
	listErr        error
	detail         *services.PublicGuideline
	detailErr      error
	markdown       *services.PublicGuidelineMarkdown
	markdownErr    error
	receivedFilter services.PublicGuidelineFilter
}

type fakePublicGuidelineContent struct {
	PublicGuidelineContentReader
	download *services.PublicGuidelineAssetDownload
	err      error
}

func (f fakePublicGuidelineContent) AssetDownload(context.Context, uuid.UUID, uuid.UUID, string) (*services.PublicGuidelineAssetDownload, error) {
	return f.download, f.err
}

func (f *fakePublicGuidelineReader) List(_ context.Context, filter services.PublicGuidelineFilter) (*services.PageResult[services.PublicGuideline], error) {
	f.receivedFilter = filter
	return f.listResult, f.listErr
}

func (f *fakePublicGuidelineReader) Get(_ context.Context, _ uuid.UUID) (*services.PublicGuideline, error) {
	return f.detail, f.detailErr
}

func (f *fakePublicGuidelineReader) Markdown(_ context.Context, _ uuid.UUID) (*services.PublicGuidelineMarkdown, error) {
	return f.markdown, f.markdownErr
}

func TestPublicGuidelineListReturnsOnlyPublicProjectionAndFilters(t *testing.T) {
	gin.SetMode(gin.TestMode)
	id := uuid.New()
	fake := &fakePublicGuidelineReader{
		listResult: services.NewPageResult([]services.PublicGuideline{{
			ID: id, Slug: "malaria-care", Title: "Malaria care", Version: "2026",
		}}, services.PageInput{Page: 2, PerPage: 10}, 11),
	}
	router := gin.New()
	handler := PublicGuidelineHandler{Service: fake}
	router.GET("/api/public/guidelines", handler.List)

	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/public/guidelines?search=malaria&program_area=infectious&page=2&per_page=10", nil)
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", response.Code, response.Body.String())
	}
	if fake.receivedFilter.Search != "malaria" || fake.receivedFilter.ProgramArea != "infectious" {
		t.Fatalf("filters not forwarded: %#v", fake.receivedFilter)
	}
	var payload map[string]any
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatal(err)
	}
	body := response.Body.String()
	for _, privateField := range []string{"markdown_file_key", "approved_by", "current_version_id", "version_id"} {
		if strings.Contains(body, privateField) {
			t.Fatalf("public response exposed %q: %s", privateField, body)
		}
	}
}

func TestPublicGuidelineMarkdownHeadersAndConditionalRequest(t *testing.T) {
	gin.SetMode(gin.TestMode)
	id := uuid.New()
	modified := time.Date(2026, 7, 30, 9, 10, 11, 0, time.UTC)
	fake := &fakePublicGuidelineReader{markdown: &services.PublicGuidelineMarkdown{
		Content: []byte("# Care"), ETag: `"sha256-test"`, LastModified: modified, Filename: "care.md",
	}}
	router := gin.New()
	handler := PublicGuidelineHandler{Service: fake}
	router.GET("/api/public/guidelines/:id/markdown", handler.Markdown)

	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+id.String()+"/markdown", nil)
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK || response.Body.String() != "# Care" {
		t.Fatalf("unexpected response %d: %s", response.Code, response.Body.String())
	}
	if got := response.Header().Get("Content-Type"); got != "text/markdown; charset=utf-8" {
		t.Fatalf("unexpected content type %q", got)
	}
	if got := response.Header().Get("Content-Disposition"); !strings.HasPrefix(got, "inline;") {
		t.Fatalf("expected inline disposition, got %q", got)
	}
	if response.Header().Get("ETag") != `"sha256-test"` {
		t.Fatal("missing ETag")
	}

	notModified := httptest.NewRecorder()
	conditional := httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+id.String()+"/markdown", nil)
	conditional.Header.Set("If-None-Match", `W/"sha256-test"`)
	router.ServeHTTP(notModified, conditional)
	if notModified.Code != http.StatusNotModified || notModified.Body.Len() != 0 {
		t.Fatalf("expected empty 304, got %d: %s", notModified.Code, notModified.Body.String())
	}
}

func TestPublicGuidelineMarkdownHidesPrivateAndMissingRecords(t *testing.T) {
	gin.SetMode(gin.TestMode)
	fake := &fakePublicGuidelineReader{markdownErr: services.ErrPublicGuidelineNotFound}
	router := gin.New()
	handler := PublicGuidelineHandler{Service: fake}
	router.GET("/api/public/guidelines/:id/markdown", handler.Markdown)

	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+uuid.NewString()+"/markdown", nil)
	router.ServeHTTP(response, request)

	if response.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", response.Code)
	}
	var payload httpx.Response
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatal(err)
	}
	if payload.Error != "guideline not found" {
		t.Fatalf("unexpected error %q", payload.Error)
	}

	fake.markdownErr = errors.New("storage credentials rejected")
	internal := httptest.NewRecorder()
	router.ServeHTTP(internal, request)
	if strings.Contains(internal.Body.String(), "credentials") {
		t.Fatalf("internal error leaked: %s", internal.Body.String())
	}
}

func TestPublicGuidelineInvalidIDReturnsNotFoundWithoutServiceLookup(t *testing.T) {
	gin.SetMode(gin.TestMode)
	fake := &fakePublicGuidelineReader{}
	router := gin.New()
	handler := PublicGuidelineHandler{Service: fake}
	router.GET("/api/public/guidelines/:id", handler.Get)

	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/public/guidelines/not-a-uuid", nil))
	if response.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", response.Code)
	}
}

func TestPublicGuidelineDetailSupportsConditionalRequests(t *testing.T) {
	gin.SetMode(gin.TestMode)
	id := uuid.New()
	fake := &fakePublicGuidelineReader{detail: &services.PublicGuideline{ID: id, Title: "Care", LastUpdated: time.Now().UTC()}}
	router := gin.New()
	handler := PublicGuidelineHandler{Service: fake}
	router.GET("/api/public/guidelines/:id", handler.Get)
	first := httptest.NewRecorder()
	router.ServeHTTP(first, httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+id.String(), nil))
	if first.Code != http.StatusOK || first.Header().Get("ETag") == "" {
		t.Fatalf("missing public ETag: %d %#v", first.Code, first.Header())
	}
	second := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+id.String(), nil)
	request.Header.Set("If-None-Match", first.Header().Get("ETag"))
	router.ServeHTTP(second, request)
	if second.Code != http.StatusNotModified || second.Body.Len() != 0 {
		t.Fatalf("expected empty 304, got %d %s", second.Code, second.Body.String())
	}
}

func TestPublicGuidelineAssetDownloadStreamsWithoutInternalStorageRedirect(t *testing.T) {
	gin.SetMode(gin.TestMode)
	id := uuid.New()
	handler := PublicGuidelineHandler{Content: fakePublicGuidelineContent{download: &services.PublicGuidelineAssetDownload{
		Body: io.NopCloser(strings.NewReader("verified-package")), Filename: "malaria-offline.zip",
		MIMEType: "application/zip", SizeBytes: int64(len("verified-package")), Checksum: strings.Repeat("a", 64),
	}}}
	router := gin.New()
	router.GET("/api/public/guidelines/:id/offline-package/download", handler.OfflinePackageDownload)

	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/public/guidelines/"+id.String()+"/offline-package/download", nil))

	if response.Code != http.StatusOK || response.Body.String() != "verified-package" {
		t.Fatalf("unexpected download response %d: %q", response.Code, response.Body.String())
	}
	if response.Header().Get("Location") != "" || strings.Contains(response.Body.String(), "minio") {
		t.Fatalf("internal storage address leaked: headers=%v body=%q", response.Header(), response.Body.String())
	}
	if response.Header().Get("Content-Type") != "application/zip" || !strings.Contains(response.Header().Get("Content-Disposition"), "malaria-offline.zip") {
		t.Fatalf("download headers missing: %v", response.Header())
	}
}
