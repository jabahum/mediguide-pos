package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"mediguide/internal/middleware"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestContentReferencePageWriteRequiresPermission(t *testing.T) {
	h := testContentReferenceHandler(t)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New()})
		c.Next()
	})
	router.POST("/api/v2/pages", middleware.RequireAnyPermission("content.write", "guideline.write"), h.CreatePage)
	request := httptest.NewRequest(http.MethodPost, "/api/v2/pages", strings.NewReader(`{"title":"About","key":"about"}`))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d: %s", response.Code, response.Body.String())
	}
}

func TestContentReferenceInvalidLanguageQuery(t *testing.T) {
	h := testContentReferenceHandler(t)
	router := gin.New()
	router.GET("/api/v2/languages", h.ListLanguages)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/v2/languages?is_active=maybe", nil))
	if response.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", response.Code, response.Body.String())
	}
}

func testContentReferenceHandler(t *testing.T) ContentReferenceHandler {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.GenericPage{}, &models.MinistryDirectoryEntry{}, &models.District{}, &models.Region{}, &models.Language{}); err != nil {
		t.Fatal(err)
	}
	return ContentReferenceHandler{Service: services.ContentReferenceService{DB: db}}
}
