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

func TestGuidelineContentWriteRequiresPermission(t *testing.T) {
	handler := testGuidelineContentHandler(t)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: []string{"guideline.read"}})
		c.Next()
	})
	router.POST("/api/v2/guideline-categories", middleware.RequirePermission("guideline.write"), handler.CreateCategory)

	request := httptest.NewRequest(http.MethodPost, "/api/v2/guideline-categories", strings.NewReader(`{"name":"Emergency"}`))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d: %s", response.Code, response.Body.String())
	}
}

func TestGuidelineContentWriterCanCreateCategory(t *testing.T) {
	handler := testGuidelineContentHandler(t)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: []string{"guideline.write"}})
		c.Next()
	})
	router.POST("/api/v2/guideline-categories", middleware.RequirePermission("guideline.write"), handler.CreateCategory)

	request := httptest.NewRequest(http.MethodPost, "/api/v2/guideline-categories", strings.NewReader(`{"name":"Emergency"}`))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", response.Code, response.Body.String())
	}
}

func testGuidelineContentHandler(t *testing.T) GuidelineContentHandler {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.GuidelineCategory{}, &models.GuidelineTag{}, &models.Abbreviation{}, &models.GuidelineIndexEntry{}, &models.MedicalGuideline{}); err != nil {
		t.Fatal(err)
	}
	return GuidelineContentHandler{Service: services.GuidelineContentService{DB: database}}
}
