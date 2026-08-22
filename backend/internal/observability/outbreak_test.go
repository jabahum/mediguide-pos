package observability

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestOutbreakHTTPUsesRouteTemplateNotResourceID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(OutbreakHTTP())
	router.GET("/api/public/outbreaks/:id", func(c *gin.Context) { c.Status(http.StatusOK) })
	id := "d7604104-719c-4be8-b516-ded6bab474f7"
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/api/public/outbreaks/"+id, nil))
	if response.Code != http.StatusOK { t.Fatalf("unexpected status %d", response.Code) }
	for key := range SnapshotOutbreak().Requests {
		if strings.Contains(key, id) { t.Fatalf("resource ID leaked into metric key %q", key) }
	}
}
