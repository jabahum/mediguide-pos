package app

import (
	"testing"

	"github.com/gin-gonic/gin"
)

func TestGinModeForEnvironment(t *testing.T) {
	tests := []struct {
		name        string
		environment string
		want        string
	}{
		{name: "development", environment: "development", want: gin.DebugMode},
		{name: "development alias", environment: " DEV ", want: gin.DebugMode},
		{name: "local", environment: "local", want: gin.DebugMode},
		{name: "test", environment: "test", want: gin.TestMode},
		{name: "testing alias", environment: "TESTING", want: gin.TestMode},
		{name: "production", environment: "production", want: gin.ReleaseMode},
		{name: "staging", environment: "staging", want: gin.ReleaseMode},
		{name: "empty fails closed", environment: "", want: gin.ReleaseMode},
		{name: "unknown fails closed", environment: "developmnt", want: gin.ReleaseMode},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ginModeForEnvironment(tt.environment); got != tt.want {
				t.Fatalf("ginModeForEnvironment(%q) = %q, want %q", tt.environment, got, tt.want)
			}
		})
	}
}

func TestConfigureGinModeUpdatesGin(t *testing.T) {
	previous := gin.Mode()
	t.Cleanup(func() { gin.SetMode(previous) })

	if got := configureGinMode("production"); got != gin.ReleaseMode || gin.Mode() != gin.ReleaseMode {
		t.Fatalf("production did not configure release mode: returned=%q active=%q", got, gin.Mode())
	}
	if got := configureGinMode("development"); got != gin.DebugMode || gin.Mode() != gin.DebugMode {
		t.Fatalf("development did not configure debug mode: returned=%q active=%q", got, gin.Mode())
	}
}
