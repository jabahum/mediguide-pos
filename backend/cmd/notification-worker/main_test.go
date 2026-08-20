package main

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestWorkerHealthAndReadiness(t *testing.T) {
	handler := workerHealthHandler(func(context.Context) error { return nil }, func() bool { return true })
	health := httptest.NewRecorder()
	handler.ServeHTTP(health, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if health.Code != http.StatusOK || !strings.Contains(health.Body.String(), `"service":"notification-worker"`) {
		t.Fatalf("unexpected liveness response: %d %s", health.Code, health.Body.String())
	}
	ready := httptest.NewRecorder()
	handler.ServeHTTP(ready, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if ready.Code != http.StatusOK || !strings.Contains(ready.Body.String(), `"firebase_configured":true`) {
		t.Fatalf("unexpected readiness response: %d %s", ready.Code, ready.Body.String())
	}
}

func TestWorkerReadinessFailsWhenDatabaseIsUnavailable(t *testing.T) {
	handler := workerHealthHandler(func(context.Context) error { return errors.New("database unavailable") }, func() bool { return true })
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if response.Code != http.StatusServiceUnavailable || !strings.Contains(response.Body.String(), "db_unavailable") {
		t.Fatalf("unexpected readiness failure: %d %s", response.Code, response.Body.String())
	}
}
