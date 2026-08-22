package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/alicebob/miniredis/v2"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestRateLimiterLocalFallbackReturnsHeadersAnd429(t *testing.T) {
	gin.SetMode(gin.TestMode)
	limiter := NewRateLimiter(nil, "test", true)
	router := gin.New()
	router.POST("/login", limiter.Limit(RateLimitPolicy{Name: "login", Limit: 1, Window: time.Minute}, IPAndJSONFieldIdentity("email")), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	first := performJSONRequest(router, `{"email":"person@example.org"}`)
	if first.Code != http.StatusNoContent || first.Header().Get("RateLimit-Remaining") != "0" {
		t.Fatalf("unexpected first response: %d, %#v", first.Code, first.Header())
	}
	second := performJSONRequest(router, `{"email":"person@example.org"}`)
	if second.Code != http.StatusTooManyRequests || second.Header().Get("Retry-After") == "" {
		t.Fatalf("unexpected limited response: %d, %#v", second.Code, second.Header())
	}
	if !strings.Contains(second.Body.String(), `"retry_after_seconds"`) || !strings.Contains(second.Body.String(), `"reset_after_seconds"`) {
		t.Fatalf("429 response does not include retry metadata: %s", second.Body.String())
	}
	for key := range limiter.fallback.entries {
		if strings.Contains(key, "person@example.org") {
			t.Fatal("raw identity leaked into limiter key")
		}
	}
}

func TestRateLimiterAuditsDeniedAuthenticatedAttemptWithoutSensitiveIdentity(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database, err := gorm.Open(sqlite.Open("file:rate-limit-audit?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.AuditLog{}); err != nil {
		t.Fatal(err)
	}
	userID := uuid.New()
	limiter := NewRateLimiter(nil, "test", true).WithAuditDB(database)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set(ClaimsKey, &security.Claims{UserID: userID, Email: "private@example.org"})
		c.Next()
	})
	router.POST("/publish", limiter.Limit(RateLimitPolicy{Name: "notification-publication", Limit: 1, Window: time.Hour}, UserIdentity), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	request := func() *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodPost, "/publish", strings.NewReader(`{"message":"private clinical content"}`))
		req.Header.Set("Content-Type", "application/json")
		response := httptest.NewRecorder()
		router.ServeHTTP(response, req)
		return response
	}
	if request().Code != http.StatusNoContent || request().Code != http.StatusTooManyRequests {
		t.Fatal("expected the second publication attempt to be denied")
	}
	var audit models.AuditLog
	if err := database.Where("action = ?", "rate_limit.denied").Take(&audit).Error; err != nil {
		t.Fatal(err)
	}
	if audit.ActorID != userID.String() || audit.EntityType != "rate_limit_policy" {
		t.Fatalf("unexpected audit identity: %#v", audit)
	}
	if strings.Contains(audit.MetadataJSON, "private@example.org") || strings.Contains(audit.MetadataJSON, "private clinical content") {
		t.Fatalf("sensitive request data leaked into audit: %s", audit.MetadataJSON)
	}
}

func TestLimitWhenAppliesStrongerUrgentPolicyAndPreservesBody(t *testing.T) {
	gin.SetMode(gin.TestMode)
	limiter := NewRateLimiter(nil, "test", true)
	router := gin.New()
	router.POST("/campaigns", limiter.LimitWhen(
		RateLimitPolicy{Name: "urgent", Limit: 1, Window: time.Hour},
		IPIdentity,
		JSONFieldEquals("priority", "urgent"),
	), func(c *gin.Context) {
		var payload map[string]string
		if err := c.ShouldBindJSON(&payload); err != nil || payload["name"] != "Emergency" {
			c.Status(http.StatusBadRequest)
			return
		}
		c.Status(http.StatusNoContent)
	})

	perform := func(priority string) *httptest.ResponseRecorder {
		request := httptest.NewRequest(http.MethodPost, "/campaigns", strings.NewReader(`{"name":"Emergency","priority":"`+priority+`"}`))
		request.Header.Set("Content-Type", "application/json")
		request.RemoteAddr = "192.0.2.10:1234"
		response := httptest.NewRecorder()
		router.ServeHTTP(response, request)
		return response
	}
	if response := perform("normal"); response.Code != http.StatusNoContent {
		t.Fatalf("normal campaign was unexpectedly limited: %d", response.Code)
	}
	if response := perform("urgent"); response.Code != http.StatusNoContent {
		t.Fatalf("first urgent campaign should pass: %d", response.Code)
	}
	if response := perform("urgent"); response.Code != http.StatusTooManyRequests {
		t.Fatalf("second urgent campaign should hit stronger limit: %d", response.Code)
	}
}

func TestCampaignIsUrgentUsesPersistedCampaignState(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:rate-limit-campaign?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.NotificationCampaign{}); err != nil {
		t.Fatal(err)
	}
	urgent := models.NotificationCampaign{Name: "Urgent", Type: "update", Priority: "urgent", Status: "pending_review", Timezone: "UTC", IdempotencyKey: uuid.NewString()}
	normal := models.NotificationCampaign{Name: "Normal", Type: "update", Priority: "normal", Status: "pending_review", Timezone: "UTC", IdempotencyKey: uuid.NewString()}
	if err := database.Create(&urgent).Error; err != nil {
		t.Fatal(err)
	}
	if err := database.Create(&normal).Error; err != nil {
		t.Fatal(err)
	}
	predicate := CampaignIsUrgent(database)
	for _, test := range []struct {
		id   uuid.UUID
		want bool
	}{{urgent.ID, true}, {normal.ID, false}} {
		context, _ := gin.CreateTestContext(httptest.NewRecorder())
		context.Params = gin.Params{{Key: "id", Value: test.id.String()}}
		if got := predicate(context); got != test.want {
			t.Fatalf("unexpected urgency for %s: got %t want %t", test.id, got, test.want)
		}
	}
}

func TestJSONIdentityPreservesRequestBody(t *testing.T) {
	gin.SetMode(gin.TestMode)
	limiter := NewRateLimiter(nil, "test", true)
	router := gin.New()
	router.POST("/login", limiter.Limit(RateLimitPolicy{Name: "login", Limit: 2, Window: time.Minute}, IPAndJSONFieldIdentity("email")), func(c *gin.Context) {
		var body map[string]string
		if err := c.ShouldBindJSON(&body); err != nil || body["password"] != "secret" {
			c.Status(http.StatusBadRequest)
			return
		}
		c.Status(http.StatusNoContent)
	})

	response := performJSONRequest(router, `{"email":"person@example.org","password":"secret"}`)
	if response.Code != http.StatusNoContent {
		t.Fatalf("middleware consumed request body: %d", response.Code)
	}
}

func TestRedisQuotaIsSharedAcrossInstancesAndExpires(t *testing.T) {
	gin.SetMode(gin.TestMode)
	server := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: server.Addr()})
	t.Cleanup(func() { _ = client.Close() })
	policy := RateLimitPolicy{Name: "shared", Limit: 2, Window: time.Minute}

	newRouter := func() *gin.Engine {
		router := gin.New()
		limiter := NewRateLimiter(client, "test", true)
		router.GET("/resource", limiter.Limit(policy, IPIdentity), func(c *gin.Context) {
			c.Status(http.StatusNoContent)
		})
		return router
	}
	firstInstance, secondInstance := newRouter(), newRouter()
	if performRequest(firstInstance).Code != http.StatusNoContent || performRequest(firstInstance).Code != http.StatusNoContent {
		t.Fatal("requests below the distributed limit should be allowed")
	}
	if response := performRequest(secondInstance); response.Code != http.StatusTooManyRequests {
		t.Fatalf("second API instance did not share quota: %d", response.Code)
	}
	if size := client.DBSize(context.Background()).Val(); size == 0 {
		t.Fatal("expected an expiring Redis limiter key")
	}
	server.FastForward(5 * time.Minute)
	if size := client.DBSize(context.Background()).Val(); size != 0 {
		t.Fatalf("limiter keys did not expire: %d remain", size)
	}
}

func TestUntrustedForwardedForDoesNotChangeIdentity(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	if err := router.SetTrustedProxies([]string{}); err != nil {
		t.Fatal(err)
	}
	limiter := NewRateLimiter(nil, "test", true)
	router.GET("/resource", limiter.Limit(RateLimitPolicy{Name: "ip", Limit: 1, Window: time.Minute}, IPIdentity), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	if performForwardedRequest(router, "198.51.100.1").Code != http.StatusNoContent {
		t.Fatal("first request should be allowed")
	}
	if response := performForwardedRequest(router, "198.51.100.2"); response.Code != http.StatusTooManyRequests {
		t.Fatalf("untrusted forwarded address bypassed quota: %d", response.Code)
	}
}

func performJSONRequest(router http.Handler, body string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(http.MethodPost, "/login", strings.NewReader(body))
	request.Header.Set("Content-Type", "application/json")
	request.RemoteAddr = "192.0.2.10:1234"
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	return response
}

func performRequest(router http.Handler) *httptest.ResponseRecorder {
	request := httptest.NewRequest(http.MethodGet, "/resource", nil)
	request.RemoteAddr = "192.0.2.10:1234"
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	return response
}

func performForwardedRequest(router http.Handler, forwardedFor string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(http.MethodGet, "/resource", nil)
	request.RemoteAddr = "192.0.2.10:1234"
	request.Header.Set("X-Forwarded-For", forwardedFor)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	return response
}
