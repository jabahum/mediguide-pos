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

func TestConsultantWriteRequiresPermission(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.Consultant{}); err != nil {
		t.Fatal(err)
	}
	h := ConsultantHandler{Service: services.ConsultantService{DB: db}}
	router := gin.New()
	router.Use(func(c *gin.Context) { c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New()}); c.Next() })
	router.POST("/api/v2/consultants", middleware.RequireAnyPermission("admin.all", "content.write", "consultant.write"), h.Create)
	req := httptest.NewRequest(http.MethodPost, "/api/v2/consultants", strings.NewReader(`{"name":"Amina","email":"a@example.com","phone":"+256","specialty":"Cardiology","country":"Uganda"}`))
	req.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, req)
	if response.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d: %s", response.Code, response.Body.String())
	}
}

func TestConsultantInvalidVerifiedFilter(t *testing.T) {
	h := ConsultantHandler{}
	router := gin.New()
	router.Use(func(c *gin.Context) { c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New()}); c.Next() })
	router.GET("/api/v2/consultants", h.List)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/v2/consultants?verified=maybe", nil))
	if response.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", response.Code)
	}
}
