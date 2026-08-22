package handlers

import (
	"context"
	"fmt"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	cachepkg "mediguide/internal/cache"
	"mediguide/internal/observability"
	"mediguide/internal/storage"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type OperationsHandler struct {
	DB    *gorm.DB
	Cache *cachepkg.Store
	Store storage.ObjectStore
}

func (h OperationsHandler) Metrics(c *gin.Context) {
	var output strings.Builder
	write := func(name string, labels map[string]string, value any) {
		output.WriteString(name)
		if len(labels) > 0 {
			keys := make([]string, 0, len(labels))
			for key := range labels {
				keys = append(keys, key)
			}
			sort.Strings(keys)
			output.WriteByte('{')
			for i, key := range keys {
				if i > 0 {
					output.WriteByte(',')
				}
				output.WriteString(key + "=" + strconv.Quote(labels[key]))
			}
			output.WriteByte('}')
		}
		fmt.Fprintln(&output, value)
	}
	snapshot := observability.SnapshotOutbreak()
	for key, metric := range snapshot.Requests {
		parts := strings.SplitN(key, "|", 2)
		labels := map[string]string{"route": parts[0], "status": parts[1]}
		write("mediguide_outbreak_public_requests_total", labels, metric.Count)
		write("mediguide_outbreak_public_request_errors_total", labels, metric.Errors)
		write("mediguide_outbreak_public_request_duration_seconds_sum", labels, metric.Duration.Seconds())
	}
	write("mediguide_outbreak_report_asset_failures_total", nil, snapshot.ReportAssetFailures)
	write("mediguide_outbreak_malformed_actions_total", nil, snapshot.MalformedActions)
	cache := h.Cache.Metrics()
	write("mediguide_cache_hits_total", map[string]string{"domain": "platform"}, cache.Hits)
	write("mediguide_cache_misses_total", map[string]string{"domain": "platform"}, cache.Misses)
	write("mediguide_cache_errors_total", map[string]string{"domain": "platform"}, cache.Errors)
	h.writeDatabaseMetrics(write)
	ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Second)
	defer cancel()
	healthy := 0
	if checker, ok := h.Store.(interface{ Health(context.Context) error }); ok && checker.Health(ctx) == nil {
		healthy = 1
	}
	write("mediguide_managed_report_storage_healthy", nil, healthy)
	c.Data(http.StatusOK, "text/plain; version=0.0.4; charset=utf-8", []byte(output.String()))
}

func (h OperationsHandler) writeDatabaseMetrics(write func(string, map[string]string, any)) {
	if h.DB == nil {
		return
	}
	type verification struct {
		ID             string
		Status         string
		LastVerifiedAt *time.Time
	}
	var rows []verification
	if h.DB.Table("outbreaks").Select("CAST(id AS TEXT) AS id, status, last_verified_at").Where("deleted_at IS NULL AND published_at IS NOT NULL AND withdrawn_at IS NULL AND status IN ?", []string{"active", "monitoring"}).Scan(&rows).Error == nil {
		for _, row := range rows {
			age := -1.0
			if row.LastVerifiedAt != nil {
				age = time.Since(row.LastVerifiedAt.UTC()).Hours()
			}
			write("mediguide_outbreak_verification_age_hours", map[string]string{"outbreak_id": row.ID, "status": row.Status}, age)
		}
	}
	count := func(table, where string, args ...any) int64 {
		var value int64
		if h.DB.Table(table).Where(where, args...).Count(&value).Error != nil {
			return 0
		}
		return value
	}
	write("mediguide_outbreak_publications_total", map[string]string{"state": "published"}, count("audit_logs", "action IN ?", []string{"outbreak.published", "situation_report.published"}))
	write("mediguide_outbreak_publications_total", map[string]string{"state": "withdrawn"}, count("audit_logs", "action IN ?", []string{"outbreak.withdrawn", "situation_report.withdrawn"}))
	write("mediguide_notification_campaigns_total", nil, count("notification_campaigns", "deleted_at IS NULL"))
	for _, state := range []string{"queued", "attempted", "accepted", "rejected", "expired", "opened", "clicked"} {
		write("mediguide_notification_deliveries_total", map[string]string{"state": state}, count("notification_deliveries", "deleted_at IS NULL AND state = ?", state))
	}
}
