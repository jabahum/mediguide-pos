package handlers

import (
	"net/http"
	"net/http/httptest"
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
