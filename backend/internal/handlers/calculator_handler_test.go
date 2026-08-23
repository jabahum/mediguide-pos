package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"mediguide/internal/middleware"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestCalculatorHandlerListContract(t *testing.T) {
	handler, database := testCalculatorHandler(t)
	calculator := models.Calculator{
		AddedByUserID: uuid.New(),
		Name:          "Emergency Triage",
		AppFileJSON:   datatypes.JSON([]byte(`{"path":"triage.html"}`)),
		Version:       "1",
		Type:          "decision_tool",
		Status:        "active",
	}
	if err := database.Create(&calculator).Error; err != nil {
		t.Fatal(err)
	}

	router := gin.New()
	router.GET("/api/v2/calculators", handler.List)
	request := httptest.NewRequest(http.MethodGet, "/api/v2/calculators?status=active&type=decision_tool&page=1&per_page=10", nil)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("unexpected status %d: %s", response.Code, response.Body.String())
	}
	var envelope struct {
		Success bool `json:"success"`
		Data    struct {
			Items      []models.Calculator `json:"items"`
			TotalItems int                 `json:"total_items"`
		} `json:"data"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if !envelope.Success || envelope.Data.TotalItems != 1 || envelope.Data.Items[0].ID != calculator.ID {
		t.Fatalf("unexpected response: %#v", envelope)
	}
}

func TestCalculatorHandlerContentContract(t *testing.T) {
	handler, database := testCalculatorHandler(t)
	root := handler.Service.LegacyClinicalToolsDir
	content, err := os.ReadFile(filepath.Join("..", "..", "..", "dashboard", "samples", "bmi-calculator.html"))
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "bmi-calculator.html"), content, 0o600); err != nil {
		t.Fatal(err)
	}
	calculator := models.Calculator{
		AddedByUserID: uuid.New(),
		Name:          "Emergency Triage",
		AppFileJSON:   datatypes.JSON([]byte(`{"path":"bmi-calculator.html"}`)),
		Version:       "1",
		Type:          "decision_tool",
		Status:        "active",
	}
	if err := database.Create(&calculator).Error; err != nil {
		t.Fatal(err)
	}

	router := gin.New()
	router.GET("/api/v2/calculators/:id/content", handler.Content)
	request := httptest.NewRequest(http.MethodGet, "/api/v2/calculators/"+calculator.ID.String()+"/content", nil)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), "Content-Security-Policy") {
		t.Fatalf("unexpected content response %d: %s", response.Code, response.Body.String())
	}
	if got := response.Header().Get("Content-Type"); got != "text/html; charset=utf-8" {
		t.Fatalf("unexpected content type: %s", got)
	}
	if response.Header().Get("X-Clinical-Tool-Checksum") == "" || response.Header().Get("Permissions-Policy") == "" || response.Header().Get("Content-Security-Policy") == "" {
		t.Fatalf("legacy containment headers are incomplete: %#v", response.Header())
	}
}

func TestCalculatorHandlerCreateUsesAuthenticatedUser(t *testing.T) {
	handler, _ := testCalculatorHandler(t)
	userID := uuid.New()
	router := gin.New()
	router.POST("/api/v2/calculators", func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: userID})
		handler.Create(c)
	})
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v2/calculators",
		strings.NewReader(`{"name":"BMI","version":"1","type":"calculator","status":"draft","app_file_json":{"path":"bmi-calculator.html"}}`),
	)
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusCreated {
		t.Fatalf("unexpected status %d: %s", response.Code, response.Body.String())
	}
	var envelope struct {
		Data models.Calculator `json:"data"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if envelope.Data.AddedByUserID != userID {
		t.Fatalf("calculator owner mismatch: %s", envelope.Data.AddedByUserID)
	}
}

func testCalculatorHandler(t *testing.T) (CalculatorHandler, *gorm.DB) {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.Calculator{}, &models.CalculatorUsageLog{}); err != nil {
		t.Fatal(err)
	}
	return CalculatorHandler{
		Service: services.CalculatorService{DB: database, LegacyClinicalToolsDir: t.TempDir()},
	}, database
}
