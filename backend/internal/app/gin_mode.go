package app

import (
	"strings"

	"github.com/gin-gonic/gin"
)

// ginModeForEnvironment keeps APP_ENV as the runtime source of truth. Unknown
// deployment names fail closed to release mode so a typo cannot enable Gin's
// verbose debug output in a hosted environment.
func ginModeForEnvironment(environment string) string {
	switch strings.ToLower(strings.TrimSpace(environment)) {
	case "development", "dev", "local":
		return gin.DebugMode
	case "test", "testing":
		return gin.TestMode
	default:
		return gin.ReleaseMode
	}
}

func configureGinMode(environment string) string {
	mode := ginModeForEnvironment(environment)
	gin.SetMode(mode)
	return mode
}
