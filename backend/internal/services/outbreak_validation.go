package services

import (
	"encoding/json"
	"math"
	"net/url"
	"regexp"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

const (
	maxOutbreakMetrics    = 40
	maxReportHighlights   = 20
	maxHighlightLength    = 500
	maxSourceReferenceLen = 500
)

var (
	outbreakMetricKey        = regexp.MustCompile(`^[a-z][a-z0-9_]{1,63}$`)
	diseaseName              = regexp.MustCompile(`^[\pL\pN][\pL\pN .,'()/-]{1,119}$`)
	managedOutbreakAssetPath = regexp.MustCompile(`^/api/public/situation-reports/[0-9a-fA-F-]{36}/asset$`)
)

// OutbreakMetric is the only supported outbreak/report metric transport shape.
// NumericValue is optional because some public-health metrics are categorical.
type OutbreakMetric struct {
	Key             string    `json:"key"`
	Label           string    `json:"label"`
	Value           string    `json:"value,omitempty"`
	NumericValue    *float64  `json:"numeric_value,omitempty"`
	Unit            string    `json:"unit,omitempty"`
	AsOf            time.Time `json:"as_of"`
	SourceReference string    `json:"source_reference"`
	SortOrder       int       `json:"sort_order"`
}

func validateOutbreakMetrics(metrics []OutbreakMetric) error {
	if len(metrics) > maxOutbreakMetrics {
		return ErrOutbreakInvalid
	}
	seen := make(map[string]struct{}, len(metrics))
	orders := make(map[int]struct{}, len(metrics))
	for i := range metrics {
		metric := &metrics[i]
		metric.Key = strings.ToLower(strings.TrimSpace(metric.Key))
		metric.Label = strings.TrimSpace(metric.Label)
		metric.Value = strings.TrimSpace(metric.Value)
		metric.Unit = strings.TrimSpace(metric.Unit)
		metric.SourceReference = strings.TrimSpace(metric.SourceReference)
		if !outbreakMetricKey.MatchString(metric.Key) || metric.Label == "" || len(metric.Label) > 120 || len(metric.Value) > 120 || len(metric.Unit) > 40 || metric.AsOf.IsZero() || metric.AsOf.After(time.Now().UTC().Add(5*time.Minute)) || metric.SourceReference == "" || len(metric.SourceReference) > maxSourceReferenceLen || metric.SortOrder < 0 || metric.SortOrder > 10_000 {
			return ErrOutbreakInvalid
		}
		if metric.Value == "" && metric.NumericValue == nil {
			return ErrOutbreakInvalid
		}
		if metric.NumericValue != nil && (math.IsNaN(*metric.NumericValue) || math.IsInf(*metric.NumericValue, 0)) {
			return ErrOutbreakInvalid
		}
		if _, exists := seen[metric.Key]; exists {
			return ErrOutbreakInvalid
		}
		if _, exists := orders[metric.SortOrder]; exists {
			return ErrOutbreakInvalid
		}
		seen[metric.Key] = struct{}{}
		orders[metric.SortOrder] = struct{}{}
	}
	return nil
}

func validateHighlights(values []string) error {
	if len(values) > maxReportHighlights {
		return ErrOutbreakInvalid
	}
	seen := make(map[string]struct{}, len(values))
	for i := range values {
		values[i] = strings.TrimSpace(values[i])
		key := strings.ToLower(values[i])
		if values[i] == "" || len(values[i]) > maxHighlightLength {
			return ErrOutbreakInvalid
		}
		if _, exists := seen[key]; exists {
			return ErrOutbreakInvalid
		}
		seen[key] = struct{}{}
	}
	return nil
}

func encodeMetrics(values []OutbreakMetric) ([]byte, error) {
	if values == nil {
		values = []OutbreakMetric{}
	}
	if err := validateOutbreakMetrics(values); err != nil {
		return nil, err
	}
	return json.Marshal(values)
}

func decodeMetrics(value []byte) []OutbreakMetric {
	result := []OutbreakMetric{}
	if len(value) == 0 || json.Unmarshal(value, &result) != nil {
		return []OutbreakMetric{}
	}
	return result
}

func encodeHighlights(values []string) ([]byte, error) {
	if values == nil {
		values = []string{}
	}
	if err := validateHighlights(values); err != nil {
		return nil, err
	}
	return json.Marshal(values)
}

func decodeHighlights(value []byte) []string {
	result := []string{}
	if len(value) == 0 || json.Unmarshal(value, &result) != nil {
		return []string{}
	}
	return result
}

func (s OutbreakAdminService) validateGeography(regionID, districtID *uuid.UUID) error {
	if districtID != nil {
		var district models.District
		if err := s.DB.Select("id", "region_id").First(&district, "id = ?", *districtID).Error; err != nil {
			return ErrOutbreakInvalid
		}
		if regionID != nil && district.RegionID != *regionID {
			return ErrOutbreakInvalid
		}
		return nil
	}
	if regionID != nil {
		var count int64
		if err := s.DB.Model(&models.Region{}).Where("id = ?", *regionID).Count(&count).Error; err != nil || count != 1 {
			return ErrOutbreakInvalid
		}
	}
	return nil
}

func validateSourceURL(value string, allowedHosts []string) error {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	if !validApprovedHTTPSURL(value, allowedHosts, true) {
		return ErrOutbreakInvalid
	}
	return nil
}

func (s OutbreakAdminService) validateResource(row models.OutbreakResource) error {
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || row.SortOrder < 0 || row.SortOrder > 10_000 {
		return ErrOutbreakInvalid
	}
	kind := strings.TrimSpace(row.ResourceType)
	switch kind {
	case "guideline":
		parsed, err := url.ParseRequestURI(strings.TrimSpace(row.URL))
		parts := []string{}
		if err == nil && !parsed.IsAbs() && parsed.Host == "" && parsed.RawQuery == "" && parsed.Fragment == "" {
			parts = strings.Split(strings.Trim(parsed.Path, "/"), "/")
		}
		if len(parts) != 3 || parts[0] != "public" || parts[1] != "guidelines" {
			return ErrOutbreakInvalid
		}
		if _, err := uuid.Parse(parts[2]); err != nil {
			return ErrOutbreakInvalid
		}
	case "situation_report":
		parsed, err := url.ParseRequestURI(strings.TrimSpace(row.URL))
		parts := []string{}
		if err == nil && !parsed.IsAbs() && parsed.Host == "" && parsed.RawQuery == "" && parsed.Fragment == "" {
			parts = strings.Split(strings.Trim(parsed.Path, "/"), "/")
		}
		if len(parts) != 2 || parts[0] != "situation-reports" {
			return ErrOutbreakInvalid
		}
		if _, err := uuid.Parse(parts[1]); err != nil {
			return ErrOutbreakInvalid
		}
	case "internal_route":
		if !validNotificationInternalRoute(strings.TrimSpace(row.URL)) {
			return ErrOutbreakInvalid
		}
	case "approved_external_url", "official_statement", "official_update", "link":
		if validateSourceURL(row.URL, s.AllowedExternalHosts) != nil {
			return ErrOutbreakInvalid
		}
	case "managed_document", "downloadable_asset":
		if strings.TrimSpace(row.AssetURL) == "" || strings.TrimSpace(row.URL) != "" {
			return ErrOutbreakInvalid
		}
		asset := strings.TrimSpace(row.AssetURL)
		if !managedOutbreakAssetPath.MatchString(asset) && validateSourceURL(asset, s.AllowedExternalHosts) != nil {
			return ErrOutbreakInvalid
		}
	default:
		return ErrOutbreakInvalid
	}
	return nil
}

func (s OutbreakAdminService) validateOutbreakFields(row models.Outbreak, publishing bool) error {
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || strings.TrimSpace(row.DiseaseType) == "" || !diseaseName.MatchString(strings.TrimSpace(row.DiseaseType)) || len(row.GeographicArea) > 240 || len(row.Summary) > 10_000 || len(row.SourceOrganization) > 240 || len(row.SourceReference) > maxSourceReferenceLen || !validOutbreakValue(row.VisualTone, "info", "warning", "critical", "success", "neutral") {
		return ErrOutbreakInvalid
	}
	if err := s.validateGeography(row.RegionID, row.DistrictID); err != nil {
		return err
	}
	if err := validateSourceURL(row.SourceURL, s.AllowedExternalHosts); err != nil {
		return err
	}
	if err := validateOutbreakMetrics(decodeMetrics(row.Metrics)); err != nil {
		return err
	}
	if row.StartDate != nil && row.LastUpdate.Before(*row.StartDate) || row.DataAsOf != nil && row.StartDate != nil && row.DataAsOf.Before(*row.StartDate) || row.EffectiveAt != nil && row.StartDate != nil && row.EffectiveAt.Before(*row.StartDate) || row.LastVerifiedAt != nil && row.LastVerifiedAt.After(time.Now().UTC().Add(5*time.Minute)) || row.DataAsOf != nil && row.LastVerifiedAt != nil && row.LastVerifiedAt.Before(*row.DataAsOf) {
		return ErrOutbreakInvalid
	}
	if publishing && (strings.TrimSpace(row.GeographicArea) == "" || strings.TrimSpace(row.SourceOrganization) == "" || strings.TrimSpace(row.SourceReference) == "" || row.EffectiveAt == nil || row.LastVerifiedAt == nil) {
		return ErrOutbreakInvalid
	}
	return nil
}

func (s OutbreakAdminService) validateReportFields(row models.SituationReport, publishing bool) error {
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || len(row.GeographicArea) > 240 || len(row.Summary) > 10_000 || len(row.SourceOrganization) > 240 || len(row.SourceReference) > maxSourceReferenceLen {
		return ErrOutbreakInvalid
	}
	if err := s.validateGeography(row.RegionID, row.DistrictID); err != nil {
		return err
	}
	if err := validateSourceURL(row.SourceURL, s.AllowedExternalHosts); err != nil {
		return err
	}
	if err := validateHighlights(decodeHighlights(row.KeyHighlights)); err != nil {
		return err
	}
	if err := validateOutbreakMetrics(decodeMetrics(row.Metrics)); err != nil {
		return err
	}
	if row.OutbreakID == nil && !row.StandaloneAllowed {
		return ErrOutbreakInvalid
	}
	if row.OutbreakID != nil {
		var count int64
		if err := s.DB.Model(&models.Outbreak{}).Where("id = ?", *row.OutbreakID).Count(&count).Error; err != nil || count != 1 {
			return ErrOutbreakInvalid
		}
	}
	if !row.PublicationDate.IsZero() && row.EffectiveAt != nil && row.PublicationDate.Before(*row.EffectiveAt) || row.DataAsOf != nil && row.LastVerifiedAt != nil && row.LastVerifiedAt.Before(*row.DataAsOf) || row.LastVerifiedAt != nil && row.LastVerifiedAt.After(time.Now().UTC().Add(5*time.Minute)) {
		return ErrOutbreakInvalid
	}
	if publishing && (row.PublicationDate.IsZero() || row.PublicationDate.After(time.Now().UTC().Add(24*time.Hour)) || strings.TrimSpace(row.GeographicArea) == "" || strings.TrimSpace(row.SourceOrganization) == "" || strings.TrimSpace(row.SourceReference) == "" || row.EffectiveAt == nil || row.LastVerifiedAt == nil || row.ReportAssetID == nil && strings.TrimSpace(row.ReportAssetURL) == "") {
		return ErrOutbreakInvalid
	}
	return nil
}
