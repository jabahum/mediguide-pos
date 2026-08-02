package middleware

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/security"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
)

type RateLimitPolicy struct {
	Name   string
	Limit  int
	Window time.Duration
	Burst  int
}

type IdentityFunc func(*gin.Context) string

type RateLimiter struct {
	client      redis.UniversalClient
	prefix      string
	enabled     bool
	fallback    *localRateLimiter
	concurrency *localConcurrencyLimiter
}

type rateDecision struct {
	allowed    bool
	limit      int
	remaining  int
	retryAfter time.Duration
	resetAfter time.Duration
}

var tokenBucketScript = redis.NewScript(`
local now_parts = redis.call('TIME')
local now = (tonumber(now_parts[1]) * 1000) + math.floor(tonumber(now_parts[2]) / 1000)
local rate = tonumber(ARGV[1])
local capacity = tonumber(ARGV[2])
local requested = tonumber(ARGV[3])
local ttl = tonumber(ARGV[4])
local values = redis.call('HMGET', KEYS[1], 'tokens', 'updated')
local tokens = tonumber(values[1])
local updated = tonumber(values[2])
if tokens == nil or updated == nil then
  tokens = capacity
  updated = now
else
  local elapsed = math.max(0, now - updated)
  tokens = math.min(capacity, tokens + (elapsed * rate))
end
local allowed = 0
local retry_after = 0
if tokens >= requested then
  tokens = tokens - requested
  allowed = 1
else
  retry_after = math.ceil((requested - tokens) / rate)
end
local reset_after = math.ceil((capacity - tokens) / rate)
redis.call('HSET', KEYS[1], 'tokens', tokens, 'updated', now)
redis.call('PEXPIRE', KEYS[1], ttl)
return {allowed, math.floor(tokens), retry_after, reset_after}
`)

var acquireConcurrencyScript = redis.NewScript(`
local now_parts = redis.call('TIME')
local now = (tonumber(now_parts[1]) * 1000) + math.floor(tonumber(now_parts[2]) / 1000)
redis.call('ZREMRANGEBYSCORE', KEYS[1], '-inf', now)
local count = redis.call('ZCARD', KEYS[1])
if count >= tonumber(ARGV[1]) then
  local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
  local retry = 1000
  if first[2] ~= nil then retry = math.max(1, tonumber(first[2]) - now) end
  return {0, retry}
end
redis.call('ZADD', KEYS[1], now + tonumber(ARGV[2]), ARGV[3])
redis.call('PEXPIRE', KEYS[1], tonumber(ARGV[2]) + 1000)
return {1, 0}
`)

var releaseConcurrencyScript = redis.NewScript(`
redis.call('ZREM', KEYS[1], ARGV[1])
return 1
`)

func NewRateLimiter(client redis.UniversalClient, prefix string, enabled bool) *RateLimiter {
	return &RateLimiter{
		client: client, prefix: strings.TrimSuffix(prefix, ":"), enabled: enabled,
		fallback: newLocalRateLimiter(10_000), concurrency: newLocalConcurrencyLimiter(),
	}
}

func ByMethod(read, write gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Method == http.MethodGet || c.Request.Method == http.MethodHead {
			read(c)
			return
		}
		write(c)
	}
}

func Policy(name string, limit int, window time.Duration, burst int) RateLimitPolicy {
	key := "RATE_LIMIT_" + envPolicyName(name)
	if value, err := strconv.Atoi(os.Getenv(key + "_LIMIT")); err == nil && value > 0 {
		limit = value
	}
	if value, err := strconv.Atoi(os.Getenv(key + "_WINDOW_SECONDS")); err == nil && value > 0 {
		window = time.Duration(value) * time.Second
	}
	if value, err := strconv.Atoi(os.Getenv(key + "_BURST")); err == nil && value >= 0 {
		burst = value
	}
	return RateLimitPolicy{Name: name, Limit: limit, Window: window, Burst: burst}
}

func (l *RateLimiter) Limit(policy RateLimitPolicy, identity IdentityFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !l.enabled || c.Request.Method == http.MethodOptions || isProbe(c.Request.URL.Path) {
			c.Next()
			return
		}
		identityValue := strings.TrimSpace(identity(c))
		if identityValue == "" {
			identityValue = c.ClientIP()
		}
		key := l.prefix + ":rate-limit:" + hashValue(policy.Name) + ":" + hashValue(identityValue)
		decision, err := l.allow(c.Request.Context(), key, policy)
		fallback := false
		if err != nil {
			fallback = true
			decision = l.fallback.allow(key, policy, time.Now())
			log.Warn().Err(err).Str("rate_limit_policy", policy.Name).Msg("redis rate limiter unavailable; using local fallback")
		}
		setRateLimitHeaders(c, decision)
		route := c.FullPath()
		if route == "" {
			route = "unmatched"
		}
		if !decision.allowed {
			log.Warn().Str("rate_limit_policy", policy.Name).Bool("rate_limit_fallback", fallback).
				Str("route", route).Bool("rate_limit_allowed", false).Int("rate_limit_remaining", decision.remaining).
				Int("retry_after_seconds", secondsCeil(decision.retryAfter)).Msg("request rate limited")
			httpx.Error(c, http.StatusTooManyRequests, "rate limit exceeded")
			c.Abort()
			return
		}
		log.Debug().Str("rate_limit_policy", policy.Name).Str("route", route).
			Bool("rate_limit_allowed", true).Bool("rate_limit_fallback", fallback).
			Int("rate_limit_remaining", decision.remaining).Msg("rate limit evaluated")
		c.Next()
	}
}

func (l *RateLimiter) Concurrency(name string, limit int, ttl time.Duration, identity IdentityFunc) gin.HandlerFunc {
	keyName := "RATE_LIMIT_" + envPolicyName(name) + "_CONCURRENCY"
	if value, err := strconv.Atoi(os.Getenv(keyName)); err == nil && value > 0 {
		limit = value
	}
	return func(c *gin.Context) {
		if !l.enabled || c.Request.Method == http.MethodOptions {
			c.Next()
			return
		}
		identityValue := strings.TrimSpace(identity(c))
		if identityValue == "" {
			identityValue = IPIdentity(c)
		}
		key := l.prefix + ":concurrency:" + hashValue(name) + ":" + hashValue(identityValue)
		token := randomToken()
		acquired, retryAfter, err := l.acquire(c.Request.Context(), key, token, limit, ttl)
		fallback := false
		if err != nil {
			fallback = true
			acquired = l.concurrency.acquire(key, limit)
			retryAfter = time.Second
		}
		if !acquired {
			retrySeconds := max(secondsCeil(retryAfter), 1)
			c.Header("Retry-After", strconv.Itoa(retrySeconds))
			c.Header("RateLimit-Limit", strconv.Itoa(limit))
			c.Header("RateLimit-Remaining", "0")
			c.Header("RateLimit-Reset", strconv.FormatInt(time.Now().Add(time.Duration(retrySeconds)*time.Second).Unix(), 10))
			log.Warn().Str("rate_limit_policy", name).Bool("rate_limit_fallback", fallback).Msg("request concurrency limited")
			httpx.Error(c, http.StatusTooManyRequests, "too many concurrent requests")
			c.Abort()
			return
		}
		defer func() {
			if fallback {
				l.concurrency.release(key)
				return
			}
			_ = releaseConcurrencyScript.Run(context.Background(), l.client, []string{key}, token).Err()
		}()
		c.Next()
	}
}

func (l *RateLimiter) acquire(ctx context.Context, key, token string, limit int, ttl time.Duration) (bool, time.Duration, error) {
	if l.client == nil {
		return false, 0, fmt.Errorf("redis client unavailable")
	}
	result, err := acquireConcurrencyScript.Run(ctx, l.client, []string{key}, limit, ttl.Milliseconds(), token).Slice()
	if err != nil {
		return false, 0, err
	}
	if len(result) != 2 {
		return false, 0, fmt.Errorf("unexpected concurrency limiter response")
	}
	return asInt64(result[0]) == 1, time.Duration(asInt64(result[1])) * time.Millisecond, nil
}

func (l *RateLimiter) allow(ctx context.Context, key string, policy RateLimitPolicy) (rateDecision, error) {
	if l.client == nil {
		return rateDecision{}, fmt.Errorf("redis client unavailable")
	}
	if policy.Limit < 1 || policy.Window <= 0 {
		return rateDecision{allowed: true}, nil
	}
	capacity := policy.Limit + max(policy.Burst, 0)
	ratePerMS := float64(policy.Limit) / float64(policy.Window.Milliseconds())
	ttlMS := int64(math.Ceil(float64(capacity)/ratePerMS)) * 2
	result, err := tokenBucketScript.Run(ctx, l.client, []string{key}, ratePerMS, capacity, 1, ttlMS).Slice()
	if err != nil {
		return rateDecision{}, err
	}
	if len(result) != 4 {
		return rateDecision{}, fmt.Errorf("unexpected rate limiter response")
	}
	return rateDecision{
		allowed:    asInt64(result[0]) == 1,
		limit:      capacity,
		remaining:  int(asInt64(result[1])),
		retryAfter: time.Duration(asInt64(result[2])) * time.Millisecond,
		resetAfter: time.Duration(asInt64(result[3])) * time.Millisecond,
	}, nil
}

func IPIdentity(c *gin.Context) string { return "ip:" + c.ClientIP() }

func UserIdentity(c *gin.Context) string {
	if value, ok := c.Get(ClaimsKey); ok {
		if claims, valid := value.(*security.Claims); valid && claims.UserID.String() != "" {
			return "user:" + claims.UserID.String()
		}
	}
	return IPIdentity(c)
}

func SessionIdentity(c *gin.Context) string {
	if value, ok := c.Get(ClaimsKey); ok {
		if claims, valid := value.(*security.Claims); valid && claims.SessionID != "" {
			return "session:" + claims.SessionID
		}
	}
	return IPIdentity(c)
}

func StaticIdentity(value string) IdentityFunc {
	return func(_ *gin.Context) string { return "static:" + value }
}

func IPAndJSONFieldIdentity(field string) IdentityFunc {
	return func(c *gin.Context) string {
		value := normalizedJSONField(c, field)
		if value == "" {
			return IPIdentity(c)
		}
		return IPIdentity(c) + ":field:" + value
	}
}

func normalizedJSONField(c *gin.Context, field string) string {
	if c.Request.Body == nil {
		return ""
	}
	const maximum = 64 * 1024
	original := c.Request.Body
	data, err := io.ReadAll(io.LimitReader(original, maximum+1))
	if err != nil {
		return ""
	}
	if len(data) > maximum {
		c.Request.Body = io.NopCloser(io.MultiReader(bytes.NewReader(data), original))
		return ""
	}
	c.Request.Body = io.NopCloser(bytes.NewReader(data))
	var payload map[string]any
	if json.Unmarshal(data, &payload) != nil {
		return ""
	}
	value, _ := payload[field].(string)
	return strings.ToLower(strings.TrimSpace(value))
}

func setRateLimitHeaders(c *gin.Context, decision rateDecision) {
	c.Header("RateLimit-Limit", strconv.Itoa(decision.limit))
	c.Header("RateLimit-Remaining", strconv.Itoa(max(decision.remaining, 0)))
	c.Header("RateLimit-Reset", strconv.Itoa(secondsCeil(decision.resetAfter)))
	if !decision.allowed {
		c.Header("Retry-After", strconv.Itoa(max(secondsCeil(decision.retryAfter), 1)))
	}
}

func hashValue(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func randomToken() string {
	value := make([]byte, 16)
	if _, err := rand.Read(value); err != nil {
		return strconv.FormatInt(time.Now().UnixNano(), 10)
	}
	return hex.EncodeToString(value)
}

func envPolicyName(value string) string {
	return strings.ToUpper(strings.NewReplacer("-", "_", ".", "_", "/", "_").Replace(value))
}

func isProbe(path string) bool { return path == "/api/healthz" || path == "/api/readyz" }

func secondsCeil(value time.Duration) int {
	if value <= 0 {
		return 0
	}
	return int(math.Ceil(value.Seconds()))
}

func asInt64(value any) int64 {
	switch converted := value.(type) {
	case int64:
		return converted
	case string:
		parsed, _ := strconv.ParseInt(converted, 10, 64)
		return parsed
	default:
		parsed, _ := strconv.ParseInt(fmt.Sprint(value), 10, 64)
		return parsed
	}
}

type localWindow struct {
	started time.Time
	count   int
}

type localRateLimiter struct {
	mu         sync.Mutex
	entries    map[string]localWindow
	maxEntries int
}

type localConcurrencyLimiter struct {
	mu     sync.Mutex
	counts map[string]int
}

func newLocalConcurrencyLimiter() *localConcurrencyLimiter {
	return &localConcurrencyLimiter{counts: make(map[string]int)}
}

func (l *localConcurrencyLimiter) acquire(key string, limit int) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.counts[key] >= limit {
		return false
	}
	l.counts[key]++
	return true
}

func (l *localConcurrencyLimiter) release(key string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.counts[key] <= 1 {
		delete(l.counts, key)
		return
	}
	l.counts[key]--
}

func newLocalRateLimiter(maxEntries int) *localRateLimiter {
	return &localRateLimiter{entries: make(map[string]localWindow), maxEntries: maxEntries}
}

func (l *localRateLimiter) allow(key string, policy RateLimitPolicy, now time.Time) rateDecision {
	l.mu.Lock()
	defer l.mu.Unlock()
	if len(l.entries) >= l.maxEntries {
		for entryKey, entry := range l.entries {
			if now.Sub(entry.started) >= policy.Window {
				delete(l.entries, entryKey)
			}
		}
		if len(l.entries) >= l.maxEntries {
			for entryKey := range l.entries {
				delete(l.entries, entryKey)
				break
			}
		}
	}
	entry := l.entries[key]
	if entry.started.IsZero() || now.Sub(entry.started) >= policy.Window {
		entry = localWindow{started: now}
	}
	entry.count++
	l.entries[key] = entry
	limit := policy.Limit + max(policy.Burst, 0)
	remaining := max(limit-entry.count, 0)
	resetAfter := policy.Window - now.Sub(entry.started)
	return rateDecision{
		allowed: entry.count <= limit, limit: limit, remaining: remaining,
		retryAfter: resetAfter, resetAfter: resetAfter,
	}
}
