package handlers

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"mediguide/internal/middleware"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type outbreakDownloadHandlerStore struct{ objects map[string][]byte }

func (s outbreakDownloadHandlerStore) Put(context.Context, string, io.Reader, int64, string) error {
	return nil
}
func (s outbreakDownloadHandlerStore) Get(_ context.Context, key string) (io.ReadCloser, error) {
	return io.NopCloser(bytes.NewReader(s.objects[key])), nil
}
func (s outbreakDownloadHandlerStore) Delete(context.Context, string) error { return nil }
func (s outbreakDownloadHandlerStore) PresignGet(context.Context, string, time.Duration) (*url.URL, error) {
	return url.Parse("http://minio:9000/private-object")
}

func publicOutbreakTestRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
	t.Helper()
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.Outbreak{}, &models.OutbreakUpdate{}, &models.OutbreakResource{}, &models.SituationReport{}); err != nil {
		t.Fatal(err)
	}
	handler := OutbreakHandler{Service: services.OutbreakService{DB: db}}
	router := gin.New()
	router.GET("/api/public/outbreaks", handler.List)
	router.GET("/api/public/outbreak-resources", handler.ListResources)
	router.GET("/api/public/outbreak-documents", handler.SearchDocuments)
	router.GET("/api/public/outbreak-documents/:documentId", handler.GetDocumentGlobal)
	router.GET("/api/public/outbreak-documents/:documentId/content", handler.DocumentContent)
	return router, db
}

func TestPublicOutbreakQuickResourceDiscovery(t *testing.T) {
	router, db := publicOutbreakTestRouter(t)
	now := time.Now().UTC().Add(-time.Minute)
	parent := models.Outbreak{Title: "Ebola response", SourceOrganization: "Ministry of Health", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := db.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	resource := models.OutbreakResource{OutbreakID: parent.ID, Title: "Official response statement", Description: "Verified response announcement", ResourceType: "official_statement", URL: "https://health.go.ug/response", Status: "published", PublishedAt: &now}
	if err := db.Create(&resource).Error; err != nil {
		t.Fatal(err)
	}
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/public/outbreak-resources?search=verified&target_type=external_url", nil))
	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), `"target_type":"external_url"`) || !strings.Contains(response.Body.String(), `"reader_capability":"external_browser"`) || !strings.Contains(response.Body.String(), parent.Title) {
		t.Fatalf("quick resource response=%d body=%s", response.Code, response.Body.String())
	}
}

func TestPublicOutbreakHandlerSupportsETagAndNotModified(t *testing.T) {
	router, db := publicOutbreakTestRouter(t)
	now := time.Now().UTC().Add(-time.Minute)
	item := models.Outbreak{Title: "Ebola response", DiseaseType: "Ebola", Status: "active", GeographicArea: "Uganda", PublishedAt: &now, LastUpdate: now, VisualTone: "critical"}
	if err := db.Create(&item).Error; err != nil {
		t.Fatal(err)
	}
	first := httptest.NewRecorder()
	router.ServeHTTP(first, httptest.NewRequest(http.MethodGet, "/api/public/outbreaks?disease=Ebola", nil))
	if first.Code != http.StatusOK || first.Header().Get("ETag") == "" || first.Header().Get("Last-Modified") == "" || first.Header().Get("Cache-Control") == "" {
		t.Fatalf("conditional headers missing: status=%d headers=%v body=%s", first.Code, first.Header(), first.Body.String())
	}
	second := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/public/outbreaks?disease=Ebola", nil)
	request.Header.Set("If-None-Match", first.Header().Get("ETag"))
	router.ServeHTTP(second, request)
	if second.Code != http.StatusNotModified || second.Body.Len() != 0 {
		t.Fatalf("etag request status=%d body=%s", second.Code, second.Body.String())
	}
}

func TestPublicOutbreakDocumentDiscoveryAndContentVisibility(t *testing.T) {
	router, db := publicOutbreakTestRouter(t)
	now := time.Now().UTC().Add(-time.Minute)
	parent := models.Outbreak{Title: "Ebola response", DiseaseType: "EVD", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := db.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	document := models.OutbreakResource{OutbreakID: parent.ID, Title: "Case management SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", MIMEType: "text/markdown", StorageKey: "outbreaks/case.md", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &now, SearchContent: "isolate the patient", RenderedContent: "# Isolation", ContentFormat: "markdown", ExtractionStatus: "ready", ContentSections: []byte(`[{"id":"isolation","heading":"Isolation","level":1,"text":"Isolate the patient."}]`), ChecksumSHA256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", DerivedContentChecksum: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}

	search := httptest.NewRecorder()
	router.ServeHTTP(search, httptest.NewRequest(http.MethodGet, "/api/public/outbreak-documents?search=isolate", nil))
	if search.Code != http.StatusOK || !strings.Contains(search.Body.String(), document.ID.String()) || !strings.Contains(search.Body.String(), "Ebola response") {
		t.Fatalf("discovery status=%d body=%s", search.Code, search.Body.String())
	}
	content := httptest.NewRecorder()
	router.ServeHTTP(content, httptest.NewRequest(http.MethodGet, "/api/public/outbreak-documents/"+document.ID.String()+"/content", nil))
	if content.Code != http.StatusOK || content.Header().Get("ETag") != `"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"` || content.Header().Get("Cache-Control") == "" || content.Header().Get("X-Content-Type-Options") != "nosniff" || !strings.Contains(content.Body.String(), `"document_id"`) || !strings.Contains(content.Body.String(), `"can_read_inline":true`) || !strings.Contains(content.Body.String(), `"sections"`) || !strings.Contains(content.Body.String(), "Isolation") {
		t.Fatalf("content status=%d headers=%v body=%s", content.Code, content.Header(), content.Body.String())
	}
	notModified := httptest.NewRecorder()
	conditional := httptest.NewRequest(http.MethodGet, "/api/public/outbreak-documents/"+document.ID.String()+"/content", nil)
	conditional.Header.Set("If-None-Match", `W/"ignored", W/`+content.Header().Get("ETag"))
	router.ServeHTTP(notModified, conditional)
	if notModified.Code != http.StatusNotModified || notModified.Body.Len() != 0 || notModified.Header().Get("ETag") == "" || notModified.Header().Get("Cache-Control") == "" {
		t.Fatalf("conditional content status=%d headers=%v body=%s", notModified.Code, notModified.Header(), notModified.Body.String())
	}

	pdf := models.OutbreakResource{OutbreakID: parent.ID, Title: "Case definition PDF", ResourceType: "managed_document", DocumentKind: "case_definition", Language: "en", MIMEType: "application/pdf", StorageKey: "outbreaks/case.pdf", Status: "published", ApprovedAt: &now, PublishedAt: &now, SearchContent: "case definition", ContentFormat: "pdf_text", ExtractionStatus: "ready", ChecksumSHA256: strings.Repeat("c", 64), DerivedContentChecksum: strings.Repeat("d", 64)}
	if err := db.Create(&pdf).Error; err != nil {
		t.Fatal(err)
	}
	unsupported := httptest.NewRecorder()
	router.ServeHTTP(unsupported, httptest.NewRequest(http.MethodGet, "/api/public/outbreak-documents/"+pdf.ID.String()+"/content", nil))
	if unsupported.Code != http.StatusUnsupportedMediaType || unsupported.Header().Get("Cache-Control") != "no-store" || !strings.Contains(unsupported.Body.String(), `"code":"inline_reading_unsupported"`) || !strings.Contains(unsupported.Body.String(), `"can_read_inline":false`) || !strings.Contains(unsupported.Body.String(), pdf.ID.String()) {
		t.Fatalf("unsupported inline status=%d headers=%v body=%s", unsupported.Code, unsupported.Header(), unsupported.Body.String())
	}
}

func TestPublicOutbreakDocumentDownloadStreamsManagedObjectThroughAPI(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.Outbreak{}, &models.OutbreakResource{}); err != nil {
		t.Fatal(err)
	}
	contents := []byte("%PDF-1.7\nmanaged content")
	store := outbreakDownloadHandlerStore{objects: map[string][]byte{"outbreaks/report.pdf": contents}}
	handler := OutbreakHandler{Service: services.OutbreakService{DB: db, Store: store}}
	router := gin.New()
	router.GET("/api/public/outbreaks/:id/documents/:documentId/download", handler.DocumentDownload)

	now := time.Now().UTC().Add(-time.Minute)
	parent := models.Outbreak{Title: "Ebola response", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := db.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	document := models.OutbreakResource{
		OutbreakID: parent.ID, Title: "Case management", ResourceType: "managed_document",
		DocumentKind: "sop", Status: "published", ApprovedAt: &now, PublishedAt: &now,
		StorageKey: "outbreaks/report.pdf", OriginalFilename: "case management.pdf",
		MIMEType: "application/pdf", FileSize: int64(len(contents)), ChecksumSHA256: strings.Repeat("a", 64),
	}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}

	response := httptest.NewRecorder()
	path := "/api/public/outbreaks/" + parent.ID.String() + "/documents/" + document.ID.String() + "/download"
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, path, nil))
	if response.Code != http.StatusOK || !bytes.Equal(response.Body.Bytes(), contents) {
		t.Fatalf("managed download status=%d body=%q", response.Code, response.Body.Bytes())
	}
	if response.Header().Get("Content-Type") != "application/pdf" || !strings.Contains(response.Header().Get("Content-Disposition"), "case management.pdf") {
		t.Fatalf("download headers missing: %v", response.Header())
	}
	if response.Header().Get("Location") != "" || strings.Contains(response.Body.String(), "minio") {
		t.Fatalf("internal object-storage address leaked: headers=%v body=%q", response.Header(), response.Body.String())
	}
}

func TestPublicOutbreakHandlerRejectsInvalidTypedFilters(t *testing.T) {
	router, _ := publicOutbreakTestRouter(t)
	for _, path := range []string{
		"/api/public/outbreaks?region_id=not-a-uuid",
		"/api/public/outbreaks?effective_from=2026-08-02&effective_to=2026-08-01",
		"/api/public/outbreaks?updated_from=not-a-date",
		"/api/public/outbreaks?sort=deleted_at",
		"/api/public/outbreaks?order=random",
	} {
		response := httptest.NewRecorder()
		router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, path, nil))
		if response.Code != http.StatusBadRequest {
			t.Fatalf("path=%s status=%d body=%s", path, response.Code, response.Body.String())
		}
	}
}

func TestOutbreakDocumentReprocessRequiresManagePermission(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.Outbreak{}, &models.OutbreakResource{}, &models.AuditLog{}); err != nil {
		t.Fatal(err)
	}
	handler := OutbreakAdminHandler{Service: services.OutbreakAdminService{DB: db}}
	outbreakID, documentID := uuid.New(), uuid.New()
	path := "/api/v2/outbreaks/" + outbreakID.String() + "/documents/" + documentID.String() + "/reprocess"

	for name, testCase := range map[string]struct {
		permissions []string
		expected    int
	}{
		"unauthenticated":  {nil, http.StatusUnauthorized},
		"wrong permission": {[]string{"outbreak.read"}, http.StatusForbidden},
		// The manager reaches the service. With no object store configured the
		// fixture is rejected as an invalid operation, rather than by auth.
		"outbreak manager": {[]string{"outbreak.manage"}, http.StatusBadRequest},
	} {
		t.Run(name, func(t *testing.T) {
			router := gin.New()
			if testCase.permissions != nil {
				router.Use(func(c *gin.Context) {
					c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: testCase.permissions})
					c.Next()
				})
			}
			router.POST("/api/v2/outbreaks/:id/documents/:documentId/reprocess", middleware.RequirePermission("outbreak.manage"), handler.ReprocessDocument)
			response := httptest.NewRecorder()
			request := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{"lock_version":1}`))
			request.Header.Set("Content-Type", "application/json")
			router.ServeHTTP(response, request)
			if response.Code != testCase.expected {
				t.Fatalf("status=%d want=%d body=%s", response.Code, testCase.expected, response.Body.String())
			}
		})
	}
}
