package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"mediguide/internal/config"
	"mediguide/internal/models"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestAuthHandlerLoginUsesV2Contract(t *testing.T) {
	handler := testAuthHandler(t)
	if _, err := handler.Service.Register(services.RegisterInput{
		Name:     "Admin",
		Email:    "admin@mediguide.local",
		Password: "secret",
	}); err != nil {
		t.Fatal(err)
	}

	router := gin.New()
	router.POST("/api/v2/auth/login", handler.Login)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v2/auth/login",
		strings.NewReader(`{"email":"admin@mediguide.local","password":"secret"}`),
	)
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("unexpected status %d: %s", response.Code, response.Body.String())
	}
	var envelope struct {
		Success bool `json:"success"`
		Data    struct {
			Token        string      `json:"token"`
			RefreshToken string      `json:"refresh_token"`
			SessionID    string      `json:"session_id"`
			User         models.User `json:"user"`
		} `json:"data"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if !envelope.Success || envelope.Data.Token == "" || envelope.Data.RefreshToken == "" || envelope.Data.SessionID == "" {
		t.Fatalf("incomplete login response: %#v", envelope)
	}
	if envelope.Data.User.Email != "admin@mediguide.local" {
		t.Fatalf("unexpected login user: %#v", envelope.Data.User)
	}
}

func testAuthHandler(t *testing.T) AuthHandler {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.User{},
		&models.Role{},
		&models.Permission{},
		&models.AuthSession{},
	); err != nil {
		t.Fatal(err)
	}
	return AuthHandler{Service: services.AuthService{
		DB: database,
		Cfg: config.Config{
			JWTSecret:            "test-secret-that-is-long-enough-for-hmac",
			JWTIssuer:            "mediguide-test",
			JWTTTLMinutes:        15,
			JWTRefreshTTLMinutes: 60,
		},
	}}
}
