package httpx

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Response struct {
	Success bool   `json:"success"`
	Data    any    `json:"data,omitempty"`
	Error   string `json:"error,omitempty"`
	Meta    any    `json:"meta,omitempty"`
}

type RateLimitMetadata struct {
	Limit             int `json:"limit"`
	Remaining         int `json:"remaining"`
	RetryAfterSeconds int `json:"retry_after_seconds"`
	ResetAfterSeconds int `json:"reset_after_seconds"`
}

func OK(c *gin.Context, data any) { c.JSON(http.StatusOK, Response{Success: true, Data: data}) }
func Created(c *gin.Context, data any) {
	c.JSON(http.StatusCreated, Response{Success: true, Data: data})
}
func Error(c *gin.Context, code int, msg string) { c.JSON(code, Response{Success: false, Error: msg}) }

func TooManyRequests(c *gin.Context, metadata RateLimitMetadata) {
	c.JSON(http.StatusTooManyRequests, Response{Success: false, Error: "rate limit exceeded", Meta: metadata})
}
