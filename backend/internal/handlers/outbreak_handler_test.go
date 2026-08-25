package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

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
	router.GET("/api/public/outbreak-documents", handler.SearchDocuments)
	router.GET("/api/public/outbreak-documents/:documentId", handler.GetDocumentGlobal)
	router.GET("/api/public/outbreak-documents/:documentId/content", handler.DocumentContent)
	return router, db
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
	document := models.OutbreakResource{OutbreakID: parent.ID, Title: "Case management SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", PublishedAt: &now, SearchContent: "isolate the patient", RenderedContent: "# Isolation", ContentFormat: "markdown", ExtractionStatus: "ready", ChecksumSHA256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
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
	if content.Code != http.StatusOK || content.Header().Get("ETag") == "" || !strings.Contains(content.Body.String(), "Isolation") {
		t.Fatalf("content status=%d headers=%v body=%s", content.Code, content.Header(), content.Body.String())
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
