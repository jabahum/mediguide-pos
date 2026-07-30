package middleware

import (
	"net/http"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/httpx"
	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

const ClaimsKey = "claims"

func AuthRequired(cfg config.Config, database *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			httpx.Error(c, http.StatusUnauthorized, "missing bearer token")
			c.Abort()
			return
		}
		claims, err := security.ParseJWT(cfg.JWTSecret, strings.TrimPrefix(header, "Bearer "))
		if err != nil {
			httpx.Error(c, http.StatusUnauthorized, "invalid token")
			c.Abort()
			return
		}
		if claims.SessionID == "" {
			httpx.Error(c, http.StatusUnauthorized, "invalid session")
			c.Abort()
			return
		}
		var count int64
		if err := database.Model(&models.AuthSession{}).
			Where("id = ? AND revoked_at IS NULL AND expires_at > ?", claims.SessionID, time.Now()).
			Count(&count).Error; err != nil || count == 0 {
			httpx.Error(c, http.StatusUnauthorized, "invalid session")
			c.Abort()
			return
		}
		c.Set(ClaimsKey, claims)
		c.Next()
	}
}

func RequirePermission(permission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		v, exists := c.Get(ClaimsKey)
		if !exists {
			httpx.Error(c, http.StatusUnauthorized, "not authenticated")
			c.Abort()
			return
		}
		claims := v.(*security.Claims)
		if !security.HasPerm(claims, permission) {
			httpx.Error(c, http.StatusForbidden, "forbidden")
			c.Abort()
			return
		}
		c.Next()
	}
}

func RequireAnyPermission(permissions ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		v, exists := c.Get(ClaimsKey)
		if !exists {
			httpx.Error(c, http.StatusUnauthorized, "not authenticated")
			c.Abort()
			return
		}
		claims := v.(*security.Claims)
		for _, permission := range permissions {
			if security.HasPerm(claims, permission) {
				c.Next()
				return
			}
		}
		httpx.Error(c, http.StatusForbidden, "forbidden")
		c.Abort()
	}
}
