package handlers

import (
	"bytes"
	"net/http"
	"net/http/httptest"
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

func TestFirebaseDeviceHandlersEnforceOwnershipAndNeverExposeTokens(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.FirebaseDevice{}, &models.NotificationPreferenceSettings{}); err != nil {
		t.Fatal(err)
	}
	owner, other := uuid.New(), uuid.New()
	device := models.FirebaseDevice{UserID: other, InstallationID: "other-installation", RegistrationToken: "never-expose-this-token", Platform: "android", NotificationsEnabled: true, LastSeenAt: time.Now().UTC()}
	if err := db.Create(&device).Error; err != nil {
		t.Fatal(err)
	}
	handler := FirebaseHandler{Service: &services.FirebaseService{DB: db}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: owner})
		c.Next()
	})
	router.GET("/devices", handler.ListDevices)
	router.PATCH("/devices/:id", handler.UpdateDevice)

	listResponse := httptest.NewRecorder()
	router.ServeHTTP(listResponse, httptest.NewRequest(http.MethodGet, "/devices", nil))
	if listResponse.Code != http.StatusOK || strings.Contains(listResponse.Body.String(), "never-expose-this-token") || strings.Contains(listResponse.Body.String(), other.String()) {
		t.Fatalf("private device data leaked: status=%d body=%s", listResponse.Code, listResponse.Body.String())
	}

	updateResponse := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPatch, "/devices/"+device.ID.String(), bytes.NewBufferString(`{"notifications_enabled":false}`))
	request.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(updateResponse, request)
	if updateResponse.Code != http.StatusNotFound {
		t.Fatalf("another user's device was mutable: status=%d body=%s", updateResponse.Code, updateResponse.Body.String())
	}
}
