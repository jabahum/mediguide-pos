package observability

import (
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type RequestMetric struct {
	Count    uint64
	Errors   uint64
	Duration time.Duration
}

type outbreakRegistry struct {
	mu                  sync.RWMutex
	requests            map[string]RequestMetric
	reportAssetFailures uint64
	malformedActions    uint64
}

var Outbreak = &outbreakRegistry{requests: map[string]RequestMetric{}}

// OutbreakHTTP records only bounded route/status dimensions. Resource IDs are
// emitted in structured logs for correlation and are deliberately not metric
// labels, avoiding unbounded cardinality and accidental user-data exposure.
func OutbreakHTTP() gin.HandlerFunc {
	return func(c *gin.Context) {
		path := c.Request.URL.Path
		relevant := strings.HasPrefix(path, "/api/public/outbreaks") ||
			strings.HasPrefix(path, "/api/public/situation-reports") ||
			strings.Contains(path, "/outbreaks") || strings.Contains(path, "/situation-reports")
		if !relevant {
			c.Next()
			return
		}
		started := time.Now()
		c.Next()
		status := c.Writer.Status()
		route := c.FullPath()
		if route == "" {
			route = "unmatched"
		}
		key := route + "|" + strconv.Itoa(status)
		Outbreak.mu.Lock()
		metric := Outbreak.requests[key]
		metric.Count++
		metric.Duration += time.Since(started)
		if status >= 400 {
			metric.Errors++
		}
		Outbreak.requests[key] = metric
		if strings.HasSuffix(path, "/asset") && status >= 400 {
			Outbreak.reportAssetFailures++
		}
		if status == 400 {
			Outbreak.malformedActions++
		}
		Outbreak.mu.Unlock()
		event := log.Info().Str("route", route).Int("status", status).Dur("duration", time.Since(started))
		if strings.Contains(route, "situation-reports") {
			event = event.Str("report_id", c.Param("id"))
		} else {
			event = event.Str("outbreak_id", c.Param("id"))
		}
		event.Msg("outbreak_request_completed")
	}
}

type OutbreakSnapshot struct {
	Requests            map[string]RequestMetric
	ReportAssetFailures uint64
	MalformedActions    uint64
}

func SnapshotOutbreak() OutbreakSnapshot {
	Outbreak.mu.RLock()
	defer Outbreak.mu.RUnlock()
	requests := make(map[string]RequestMetric, len(Outbreak.requests))
	for key, value := range Outbreak.requests {
		requests[key] = value
	}
	return OutbreakSnapshot{requests, Outbreak.reportAssetFailures, Outbreak.malformedActions}
}
