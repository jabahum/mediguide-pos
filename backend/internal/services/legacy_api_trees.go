package services

import (
	"encoding/json"
	"fmt"
	"strings"
)

// ConsultantsTree groups consultants by region → city → specialty.
func (s LegacyAPIService) consultantsTreeUncached(level int, filters map[string]string) (TreeResult, error) {
	var rows []treeRow
	query := s.DB.Table("consultants").
		Where("deleted_at IS NULL").
		Where("status IN ?", []string{"active", "pendingApproval", "pending_approval"})

	if value := filters["region"]; value != "" {
		query = query.Where("coalesce(nullif(region, ''), 'Unknown Region') = ?", value)
	}
	if value := filters["city"]; value != "" {
		query = query.Where("coalesce(nullif(city, ''), 'Unknown City') = ?", value)
	}
	if value := filters["specialty"]; value != "" {
		query = query.Where("coalesce(nullif(specialty, ''), 'Other') = ?", value)
	}
	if value := filters["status"]; value != "" {
		query = query.Where("status = ?", value)
	}
	if value, ok := parseBoolFilter(filters["verified"]); ok {
		query = query.Where("is_verified = ?", value)
	}

	switch level {
	case 0:
		err := query.
			Select("coalesce(nullif(region, ''), 'Unknown Region') AS id, coalesce(nullif(region, ''), 'Unknown Region') AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return map[string]string{"region": r.ID}
		}), err
	case 1:
		err := query.
			Select("coalesce(nullif(city, ''), 'Unknown City') AS id, coalesce(nullif(city, ''), 'Unknown City') AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return map[string]string{"region": filters["region"], "city": r.ID}
		}), err
	default:
		err := query.
			Select("coalesce(nullif(specialty, ''), 'Other') AS id, coalesce(nullif(specialty, ''), 'Other') AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, false, func(r treeRow) map[string]string {
			return map[string]string{"region": filters["region"], "city": filters["city"], "specialty": r.ID}
		}), err
	}
}

// HealthFacilitiesTree groups facilities by region → district → facility level.
func (s LegacyAPIService) healthFacilitiesTreeUncached(level int, filters map[string]string) (TreeResult, error) {
	var rows []treeRow

	query := s.DB.Table("health_facilities hf").
		Joins("LEFT JOIN regions r ON r.id = hf.region_id").
		Joins("LEFT JOIN districts d ON d.id = hf.district_id").
		Joins("LEFT JOIN facility_levels fl ON fl.id = hf.facility_level_id").
		Where("hf.deleted_at IS NULL")

	if value := filters["region"]; value != "" {
		query = query.Where("hf.region_id::text = ?", value)
	}
	if value := filters["district"]; value != "" {
		query = query.Where("hf.district_id::text = ?", value)
	}
	if value := filters["facility_level"]; value != "" {
		query = query.Where("hf.facility_level_id::text = ?", value)
	}

	switch level {
	case 0:
		err := query.Select("hf.region_id::text AS id, coalesce(r.name, 'Unknown Region') AS title, count(*) AS count").
			Group("hf.region_id, r.name").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return map[string]string{"region": r.ID}
		}), err
	case 1:
		err := query.Select("hf.district_id::text AS id, coalesce(d.name, 'Unknown District') AS title, count(*) AS count").
			Group("hf.district_id, d.name").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return map[string]string{"region": filters["region"], "district": r.ID}
		}), err
	default:
		err := query.Select("hf.facility_level_id::text AS id, coalesce(fl.name, 'Unknown Facility Level') AS title, count(*) AS count").
			Group("hf.facility_level_id, fl.name").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, false, func(r treeRow) map[string]string {
			return map[string]string{"region": filters["region"], "district": filters["district"], "facility_level": r.ID}
		}), err
	}
}

// MinistryDirectoryTree groups directory entries by region → district → ministry.
func (s LegacyAPIService) ministryDirectoryTreeUncached(level int, filters map[string]string) (TreeResult, error) {
	var rows []treeRow

	query := s.DB.Table("ministry_directory md").
		Joins("LEFT JOIN districts d ON d.id = md.district_id").
		Joins("LEFT JOIN regions reg_direct ON reg_direct.id = md.region_id").
		Joins("LEFT JOIN regions reg_district ON reg_district.id = d.region_id").
		Where("md.deleted_at IS NULL")

	if value := filters["region"]; value != "" {
		query = query.Where("coalesce(reg_direct.name, reg_district.name, 'Unknown Region') = ?", value)
	}
	if value := filters["district"]; value != "" {
		query = query.Where("coalesce(d.name, 'Unknown District') = ?", value)
	}
	if value := filters["ministry"]; value != "" {
		query = query.Where("md.ministry = ?", value)
	}
	if value := filters["department"]; value != "" {
		query = query.Where("coalesce(nullif(md.department, ''), 'Unspecified') = ?", value)
	}
	if value := filters["status"]; value != "" {
		query = query.Where("md.status = ?", value)
	}

	switch level {
	case 0:
		err := query.Select("coalesce(reg_direct.name, reg_district.name, 'Unknown Region') AS id, coalesce(reg_direct.name, reg_district.name, 'Unknown Region') AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return compactFilterMap(map[string]string{"region": r.ID, "status": filters["status"]})
		}), err
	case 1:
		err := query.Select("coalesce(d.name, 'Unknown District') AS id, coalesce(d.name, 'Unknown District') AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, true, func(r treeRow) map[string]string {
			return compactFilterMap(map[string]string{"region": filters["region"], "district": r.ID, "status": filters["status"]})
		}), err
	default:
		err := query.Select("md.ministry AS id, md.ministry AS title, count(*) AS count").
			Group("1,2").Order("2").
			Scan(&rows).Error
		return buildTreeResult(level, rows, false, func(r treeRow) map[string]string {
			return compactFilterMap(map[string]string{"region": filters["region"], "district": filters["district"], "ministry": r.ID, "status": filters["status"]})
		}), err
	}
}

// buildTreeResult converts raw DB rows into a TreeResult with node metadata.
func buildTreeResult(level int, rows []treeRow, hasChildren bool, filterFn func(treeRow) map[string]string) TreeResult {
	nodes := make([]TreeNode, 0, len(rows))
	for _, row := range rows {
		nodes = append(nodes, TreeNode{
			ID:          row.ID,
			Title:       row.Title,
			Subtitle:    "",
			Level:       level,
			Count:       row.Count,
			HasChildren: hasChildren,
			Filters:     filterFn(row),
		})
	}
	return TreeResult{Success: true, Level: level, Data: nodes}
}

// parseLevel parses and clamps the level query parameter.
func parseLevel(raw string, maxLevel int) (int, error) {
	if raw == "" {
		return 0, nil
	}
	var level int
	_, err := fmt.Sscanf(raw, "%d", &level)
	if err != nil {
		return 0, err
	}
	if level < 0 {
		level = 0
	}
	if level > maxLevel {
		level = maxLevel
	}
	return level, nil
}

// parseFilterMap decodes a JSON filter string, retaining only allowed keys.
func parseFilterMap(raw string, allowedKeys []string) map[string]string {
	if raw == "" {
		return map[string]string{}
	}
	var parsed map[string]any
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil {
		return map[string]string{}
	}
	allowed := map[string]bool{}
	for _, key := range allowedKeys {
		allowed[key] = true
	}
	out := map[string]string{}
	for key, value := range parsed {
		if len(allowed) > 0 && !allowed[key] {
			continue
		}
		if value == nil {
			continue
		}
		str := strings.TrimSpace(fmt.Sprint(value))
		if str == "" || len(str) > 120 {
			continue
		}
		out[key] = str
	}
	return out
}

// parseBoolFilter converts "true"/"false"/etc. strings to bool.
func parseBoolFilter(raw string) (bool, bool) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "true", "1", "yes":
		return true, true
	case "false", "0", "no":
		return false, true
	default:
		return false, false
	}
}

// compactFilterMap removes empty string values from a filter map.
func compactFilterMap(in map[string]string) map[string]string {
	out := map[string]string{}
	for k, v := range in {
		if strings.TrimSpace(v) != "" {
			out[k] = v
		}
	}
	return out
}
