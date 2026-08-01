package handlers

import (
	"net/http"
	"net/http/httptest"
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

func TestUsageAnalyticsRequiresPermission(t *testing.T) {
	h := testProgressUsageHandler(t)
	router := gin.New()
	router.Use(func(c *gin.Context) { c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New()}); c.Next() })
	router.GET("/api/v2/analytics/usage", middleware.RequireAnyPermission("admin.all", "analytics.read"), h.UsageAggregates)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/v2/analytics/usage", nil))
	if response.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", response.Code)
	}
}
func testProgressUsageHandler(t *testing.T) ProgressUsageHandler {
	t.Helper()
	db, e := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if e != nil {
		t.Fatal(e)
	}
	if e = db.AutoMigrate(&models.ReadingProgress{}, &models.GuidelineUsageLog{}, &models.AbbreviationUsageLog{}, &models.ConsultantUsageLog{}, &models.AIUsageLog{}); e != nil {
		t.Fatal(e)
	}
	return ProgressUsageHandler{Service: services.ProgressUsageService{DB: db}}
}
