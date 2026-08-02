package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/alicebob/miniredis/v2"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
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
	for key := range limiter.fallback.entries {
		if strings.Contains(key, "person@example.org") {
			t.Fatal("raw identity leaked into limiter key")
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
