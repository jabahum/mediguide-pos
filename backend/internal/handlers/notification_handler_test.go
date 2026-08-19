package handlers

import (
	"bytes"
	"net/http"
	"net/http/httptest"
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

func TestCampaignTransitionHandlerMapsApprovalAndConcurrencyErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.NotificationCampaign{}, &models.AuditLog{}); err != nil {
		t.Fatal(err)
	}
	actor := uuid.New()
	base := models.NotificationCampaign{
		Name: "National emergency", Type: "emergency", Status: "pending_review", RenderedTitle: "Alert", RenderedBody: "Body",
		ActionSnapshotJSON: datatypes.JSON(`{"type":"none","parameters":{}}`), AudienceDefinitionJSON: datatypes.JSON(`{"all_eligible":true}`),
		RequestedChannelsJSON: datatypes.JSON(`["push"]`), ChannelsJSON: datatypes.JSON(`["push"]`), Priority: "urgent", Timezone: "UTC",
		IdempotencyKey: "handler-approval", LockVersion: 1, CreatedBy: &actor,
	}
	if err := db.Create(&base).Error; err != nil {
		t.Fatal(err)
	}
	handler := NotificationHandler{Service: services.NotificationService{DB: db}}
	router := gin.New()
	router.Use(func(c *gin.Context) { c.Set(middleware.ClaimsKey, &security.Claims{UserID: actor}); c.Next() })
	router.POST("/api/v2/notification-campaigns/:id/:action", handler.TransitionCampaign)

	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPost, "/api/v2/notification-campaigns/"+base.ID.String()+"/approve", bytes.NewBufferString(`{"lock_version":1}`))
	request.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("self approval status=%d body=%s", response.Code, response.Body.String())
	}

	base.Status = "draft"
	base.IdempotencyKey = "handler-conflict"
	base.LockVersion = 4
	base.ID = uuid.Nil
	if err := db.Create(&base).Error; err != nil {
		t.Fatal(err)
	}
	response = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodPost, "/api/v2/notification-campaigns/"+base.ID.String()+"/submit", bytes.NewBufferString(`{"lock_version":3}`))
	request.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(response, request)
	if response.Code != http.StatusConflict {
		t.Fatalf("stale transition status=%d body=%s", response.Code, response.Body.String())
	}
}
