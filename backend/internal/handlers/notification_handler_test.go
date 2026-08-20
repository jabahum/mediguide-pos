package handlers

import (
	"bytes"
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

func TestNotificationAdministrativeHandlersRequireFocusedPermissions(t *testing.T) {
	gin.SetMode(gin.TestMode)
	notificationHandler := NotificationHandler{}
	firebaseHandler := FirebaseHandler{}
	tests := []struct {
		name       string
		method     string
		path       string
		permission string
		handler    gin.HandlerFunc
	}{
		{name: "publish notification", method: http.MethodPost, path: "/api/v2/notifications", permission: "notification.publish", handler: notificationHandler.Create},
		{name: "firebase status", method: http.MethodGet, path: "/api/v2/firebase/status", permission: "firebase.status.read", handler: firebaseHandler.Status},
		{name: "firebase test push", method: http.MethodPost, path: "/api/v2/firebase/push/test", permission: "firebase.push.test", handler: firebaseHandler.SendTestPush},
		{name: "get remote config", method: http.MethodGet, path: "/api/v2/firebase/remote-config", permission: "firebase.config.manage", handler: firebaseHandler.GetRemoteConfig},
		{name: "put remote config", method: http.MethodPut, path: "/api/v2/firebase/remote-config", permission: "firebase.config.manage", handler: firebaseHandler.PutRemoteConfig},
		{name: "list templates", method: http.MethodGet, path: "/api/v2/notification-templates", permission: "notification.template.read", handler: notificationHandler.ListTemplates},
		{name: "get template", method: http.MethodGet, path: "/api/v2/notification-templates/:id", permission: "notification.template.read", handler: notificationHandler.GetTemplate},
		{name: "create template", method: http.MethodPost, path: "/api/v2/notification-templates", permission: "notification.template.manage", handler: notificationHandler.CreateTemplate},
		{name: "update template", method: http.MethodPatch, path: "/api/v2/notification-templates/:id", permission: "notification.template.manage", handler: notificationHandler.UpdateTemplate},
		{name: "update template status", method: http.MethodPatch, path: "/api/v2/notification-templates/:id/status", permission: "notification.template.manage", handler: notificationHandler.UpdateTemplateStatus},
		{name: "list template versions", method: http.MethodGet, path: "/api/v2/notification-templates/:id/versions", permission: "notification.template.read", handler: notificationHandler.ListTemplateVersions},
		{name: "preview template version", method: http.MethodPost, path: "/api/v2/notification-template-versions/:id/preview", permission: "notification.template.read", handler: notificationHandler.PreviewTemplateVersion},
		{name: "delete template", method: http.MethodDelete, path: "/api/v2/notification-templates/:id", permission: "notification.template.manage", handler: notificationHandler.DeleteTemplate},
		{name: "list campaigns", method: http.MethodGet, path: "/api/v2/notification-campaigns", permission: "notification.campaign.read", handler: notificationHandler.ListCampaigns},
		{name: "estimate audience", method: http.MethodPost, path: "/api/v2/notification-campaigns/audience-estimate", permission: "notification.campaign.manage", handler: notificationHandler.EstimateAudience},
		{name: "get campaign", method: http.MethodGet, path: "/api/v2/notification-campaigns/:id", permission: "notification.campaign.read", handler: notificationHandler.GetCampaign},
		{name: "create campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns", permission: "notification.campaign.manage", handler: notificationHandler.CreateCampaign},
		{name: "update campaign", method: http.MethodPatch, path: "/api/v2/notification-campaigns/:id", permission: "notification.campaign.manage", handler: notificationHandler.UpdateCampaign},
		{name: "submit campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns/:id/submit", permission: "notification.campaign.manage", handler: notificationHandler.TransitionCampaign},
		{name: "approve campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns/:id/approve", permission: "notification.campaign.approve", handler: notificationHandler.TransitionCampaign},
		{name: "reject campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns/:id/reject", permission: "notification.campaign.approve", handler: notificationHandler.TransitionCampaign},
		{name: "schedule campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns/:id/schedule", permission: "notification.campaign.manage", handler: notificationHandler.TransitionCampaign},
		{name: "cancel campaign", method: http.MethodPost, path: "/api/v2/notification-campaigns/:id/cancel", permission: "notification.campaign.manage", handler: notificationHandler.TransitionCampaign},
		{name: "delete campaign", method: http.MethodDelete, path: "/api/v2/notification-campaigns/:id", permission: "notification.campaign.manage", handler: notificationHandler.DeleteCampaign},
		{name: "list delivery jobs", method: http.MethodGet, path: "/api/v2/notification-delivery-jobs", permission: "notification.analytics.read", handler: notificationHandler.ListDeliveryJobs},
		{name: "requeue delivery job", method: http.MethodPost, path: "/api/v2/notification-delivery-jobs/:id/requeue", permission: "notification.campaign.manage", handler: notificationHandler.RequeueDeliveryJob},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := gin.New()
			router.Use(func(c *gin.Context) {
				c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: []string{"notification.read"}})
				c.Next()
			})
			router.Handle(tt.method, tt.path, middleware.RequirePermission(tt.permission), tt.handler)

			path := strings.ReplaceAll(tt.path, ":id", uuid.NewString())
			response := httptest.NewRecorder()
			request := httptest.NewRequest(tt.method, path, bytes.NewBufferString(`{}`))
			request.Header.Set("Content-Type", "application/json")
			router.ServeHTTP(response, request)
			if response.Code != http.StatusForbidden {
				t.Fatalf("%s %s returned %d, want 403", tt.method, path, response.Code)
			}
		})
	}
}

func TestNotificationAudienceSensitiveFiltersRequireAnalyticsPermission(t *testing.T) {
	gin.SetMode(gin.TestMode)
	handler := NotificationHandler{Service: services.NotificationService{}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: []string{"notification.campaign.manage"}})
		c.Next()
	})
	router.POST("/estimate", handler.EstimateAudience)

	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPost, "/estimate", bytes.NewBufferString(`{"audience":{"all_eligible":false,"facility_ids":["`+uuid.NewString()+`"]}}`))
	request.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("sensitive audience status=%d body=%s", response.Code, response.Body.String())
	}
}

func TestNotificationCampaignReadRedactsSensitiveAudienceWithoutAnalyticsPermission(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.NotificationCampaign{}); err != nil {
		t.Fatal(err)
	}
	campaign := models.NotificationCampaign{Name: "Facility alert", Type: "update", Status: "draft", RenderedTitle: "Title", RenderedBody: "Body", ActionSnapshotJSON: datatypes.JSON(`{"type":"none","parameters":{}}`), AudienceDefinitionJSON: datatypes.JSON(`{"all_eligible":false,"facility_ids":["` + uuid.NewString() + `"]}`), RequestedChannelsJSON: datatypes.JSON(`["in-app"]`), Priority: "normal", Timezone: "UTC", IdempotencyKey: "redacted-audience", DispatchSnapshotJSON: datatypes.JSON(`{"recipient_ids":["private"]}`)}
	if err := db.Create(&campaign).Error; err != nil {
		t.Fatal(err)
	}
	handler := NotificationHandler{Service: services.NotificationService{DB: db}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(middleware.ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: []string{"notification.campaign.read"}})
		c.Next()
	})
	router.GET("/campaigns/:id", handler.GetCampaign)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/campaigns/"+campaign.ID.String(), nil))
	if response.Code != http.StatusOK || strings.Contains(response.Body.String(), "facility_ids") || strings.Contains(response.Body.String(), "private") {
		t.Fatalf("sensitive audience was exposed: status=%d body=%s", response.Code, response.Body.String())
	}
}
