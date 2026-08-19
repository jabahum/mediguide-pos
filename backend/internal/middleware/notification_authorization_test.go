package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"mediguide/internal/security"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func TestFocusedNotificationPermissionMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	tests := []struct {
		name       string
		required   string
		granted    []string
		wantStatus int
	}{
		{name: "inbox reader", required: "notification.read", granted: []string{"notification.read"}, wantStatus: http.StatusNoContent},
		{name: "template reader cannot manage", required: "notification.template.manage", granted: []string{"notification.template.read"}, wantStatus: http.StatusForbidden},
		{name: "campaign author cannot approve", required: "notification.campaign.approve", granted: []string{"notification.campaign.manage"}, wantStatus: http.StatusForbidden},
		{name: "firebase observer cannot publish config", required: "firebase.config.manage", granted: []string{"firebase.status.read"}, wantStatus: http.StatusForbidden},
		{name: "administrator wildcard", required: "firebase.push.test", granted: []string{"admin.all"}, wantStatus: http.StatusNoContent},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := gin.New()
			router.Use(func(c *gin.Context) {
				c.Set(ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: tt.granted})
				c.Next()
			})
			router.POST("/operation", RequirePermission(tt.required), func(c *gin.Context) { c.Status(http.StatusNoContent) })

			response := httptest.NewRecorder()
			router.ServeHTTP(response, httptest.NewRequest(http.MethodPost, "/operation", nil))
			if response.Code != tt.wantStatus {
				t.Fatalf("status=%d body=%s, want %d", response.Code, response.Body.String(), tt.wantStatus)
			}
		})
	}
}
