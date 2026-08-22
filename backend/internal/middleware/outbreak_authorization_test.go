package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"mediguide/internal/security"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func TestOutbreakPermissionsRemainSeparated(t *testing.T) {
	gin.SetMode(gin.TestMode)
	cases := []struct {
		name, required string
		granted        []string
		want           int
	}{
		{"author can manage", "outbreak.manage", []string{"outbreak.manage"}, http.StatusNoContent},
		{"author cannot approve", "outbreak.review", []string{"outbreak.manage"}, http.StatusForbidden},
		{"reviewer cannot publish", "outbreak.publish", []string{"outbreak.review"}, http.StatusForbidden},
		{"report author cannot approve", "situation_report.review", []string{"situation_report.manage"}, http.StatusForbidden},
		{"publisher can publish report", "situation_report.publish", []string{"situation_report.publish"}, http.StatusNoContent},
		{"publisher cannot withdraw report", "situation_report.withdraw", []string{"situation_report.publish"}, http.StatusForbidden},
		{"report withdrawer can withdraw", "situation_report.withdraw", []string{"situation_report.withdraw"}, http.StatusNoContent},
	}
	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			r := gin.New()
			r.POST("/operation", func(c *gin.Context) {
				c.Set(ClaimsKey, &security.Claims{UserID: uuid.New(), Perms: tt.granted})
				c.Next()
			}, RequirePermission(tt.required), func(c *gin.Context) { c.Status(http.StatusNoContent) })
			w := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodPost, "/operation", nil)
			r.ServeHTTP(w, req)
			if w.Code != tt.want {
				t.Fatalf("status=%d want=%d body=%s", w.Code, tt.want, w.Body.String())
			}
		})
	}
}
