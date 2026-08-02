package services

import (
	"fmt"
	"time"
)

// Overview aggregates dashboard metrics across all major tables.
func (s LegacyAPIService) overviewUncached() (OverviewResult, error) {
	now := time.Now().UTC().Format(time.RFC3339)
	metrics := map[string]int64{}
	pipeline := map[string]int64{}
	engagement := map[string]int64{}
	contentHealth := map[string]int64{}
	support := map[string]int64{}
	taxonomy := map[string]int64{}
	coverage := map[string]int64{}

	var err error
	if metrics["totalUsers"], err = s.count("users", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if metrics["activeUsers"], err = s.count("users", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	metrics["healthcareProviders"], err = s.countHealthcareProviders()
	if err != nil {
		return OverviewResult{}, err
	}
	if metrics["totalDrugs"], err = s.count("drugs", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if metrics["activeDrugs"], err = s.count("drugs", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	if metrics["totalFacilities"], err = s.count("health_facilities", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if metrics["totalConsultants"], err = s.count("consultants", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if metrics["activeConsultants"], err = s.count("consultants", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}

	if pipeline["usersPendingActivation"], err = s.count("users", "deleted_at IS NULL AND status IN ?", []string{"pending_activation", "pendingActivation"}); err != nil {
		return OverviewResult{}, err
	}
	if pipeline["drugsUnderReview"], err = s.count("drugs", "deleted_at IS NULL AND status = ?", "under_review"); err != nil {
		return OverviewResult{}, err
	}
	if pipeline["drugsPendingReview"], err = s.count("drugs", "deleted_at IS NULL AND review_status = ?", "pending"); err != nil {
		return OverviewResult{}, err
	}
	if pipeline["drugsInactive"], err = s.count("drugs", "deleted_at IS NULL AND status = ?", "inactive"); err != nil {
		return OverviewResult{}, err
	}
	if pipeline["consultantsPendingApproval"], err = s.count("consultants", "deleted_at IS NULL AND status IN ?", []string{"pending_approval", "pendingApproval"}); err != nil {
		return OverviewResult{}, err
	}
	if pipeline["consultantsVerified"], err = s.count("consultants", "deleted_at IS NULL AND is_verified = ?", true); err != nil {
		return OverviewResult{}, err
	}

	engagement["aiUsage7d"], err = s.countRecent("ai_usage_logs", 6)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["aiUsage30d"], err = s.countRecent("ai_usage_logs", 29)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["calculatorUsage7d"], err = s.countRecent("calculator_usage_logs", 6)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["calculatorUsage30d"], err = s.countRecent("calculator_usage_logs", 29)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["guidelineUsage7d"], err = s.countRecent("guideline_usage_logs", 6)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["guidelineUsage30d"], err = s.countRecent("guideline_usage_logs", 29)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["drugUsage7d"], err = s.countRecent("drug_usage_logs", 6)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["drugUsage30d"], err = s.countRecent("drug_usage_logs", 29)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["facilityUsage7d"], err = s.countRecent("facility_usage_logs", 6)
	if err != nil {
		return OverviewResult{}, err
	}
	engagement["facilityUsage30d"], err = s.countRecent("facility_usage_logs", 29)
	if err != nil {
		return OverviewResult{}, err
	}

	if contentHealth["medicalGuidelinesTotal"], err = s.count("medical_guidelines", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["medicalGuidelinesPublished"], err = s.count("medical_guidelines", "deleted_at IS NULL AND (is_published = ? OR status = ?)", true, "published"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["medicalGuidelinesDraft"], err = s.count("medical_guidelines", "deleted_at IS NULL AND status = ?", "draft"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["faqsTotal"], err = s.count("faqs", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["faqsPublished"], err = s.count("faqs", "deleted_at IS NULL AND status = ?", "published"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["faqsDraft"], err = s.count("faqs", "deleted_at IS NULL AND status = ?", "draft"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["documentationTotal"], err = s.count("documentation", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["documentationPublished"], err = s.count("documentation", "deleted_at IS NULL AND status = ?", "published"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["genericPagesTotal"], err = s.count("generic_pages", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["abbreviationsTotal"], err = s.count("abbreviations", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["calculatorsTotal"], err = s.count("calculators", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["calculatorsActive"], err = s.count("calculators", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	if contentHealth["guidelineCategoriesActive"], err = s.count("guideline_categories", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}

	if support["ticketsOpen"], err = s.count("support_tickets", "deleted_at IS NULL AND status = ?", "open"); err != nil {
		return OverviewResult{}, err
	}
	if support["ticketsInProgress"], err = s.count("support_tickets", "deleted_at IS NULL AND status = ?", "in_progress"); err != nil {
		return OverviewResult{}, err
	}
	if support["ticketsResolved"], err = s.count("support_tickets", "deleted_at IS NULL AND status = ?", "resolved"); err != nil {
		return OverviewResult{}, err
	}
	if support["ticketsClosed"], err = s.count("support_tickets", "deleted_at IS NULL AND status = ?", "closed"); err != nil {
		return OverviewResult{}, err
	}
	if support["ticketsUrgent"], err = s.count("support_tickets", "deleted_at IS NULL AND priority = ?", "urgent"); err != nil {
		return OverviewResult{}, err
	}
	if support["notifications7d"], err = s.countRecent("notifications", 6); err != nil {
		return OverviewResult{}, err
	}
	if support["notifications30d"], err = s.countRecent("notifications", 29); err != nil {
		return OverviewResult{}, err
	}

	if taxonomy["activeDrugCategories"], err = s.count("drug_categories", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	if taxonomy["activeDrugClasses"], err = s.count("drug_classes", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	if taxonomy["activeTherapeuticCategories"], err = s.count("therapeutic_categories", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}
	if taxonomy["activeDrugTags"], err = s.count("drug_tags", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return OverviewResult{}, err
	}

	if coverage["regions"], err = s.count("regions", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if coverage["districts"], err = s.count("districts", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if coverage["subcounties"], err = s.count("subcounties", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}
	if coverage["parishes"], err = s.count("parishes", "deleted_at IS NULL"); err != nil {
		return OverviewResult{}, err
	}

	usersByDay, err := s.seriesCount("users")
	if err != nil {
		return OverviewResult{}, err
	}
	drugsByDay, err := s.seriesCount("drugs")
	if err != nil {
		return OverviewResult{}, err
	}
	facilitiesByDay, err := s.seriesCount("health_facilities")
	if err != nil {
		return OverviewResult{}, err
	}

	return OverviewResult{
		Success:       true,
		CachedAt:      now,
		Metrics:       metrics,
		Pipeline:      pipeline,
		Engagement:    engagement,
		ContentHealth: contentHealth,
		Support:       support,
		Taxonomy:      taxonomy,
		Coverage:      coverage,
		Series: map[string]any{
			"usersByDay":      usersByDay,
			"drugsByDay":      drugsByDay,
			"facilitiesByDay": facilitiesByDay,
		},
	}, nil
}

// Stats returns mobile-home-screen counters, optionally enriched with user-specific message data.
func (s LegacyAPIService) statsUncached(userID string) (StatsResult, error) {
	now := time.Now().UTC().Format(time.RFC3339)
	res := StatsResult{Success: true, CachedAt: now}
	var err error

	if res.MedicalGuidelines, err = s.count("medical_guidelines", "deleted_at IS NULL AND status = ?", "published"); err != nil {
		return StatsResult{}, err
	}
	if res.Drugs, err = s.count("drugs", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return StatsResult{}, err
	}
	if res.Calculators, err = s.count("calculators", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return StatsResult{}, err
	}
	if res.Abbreviations, err = s.count("abbreviations", "deleted_at IS NULL"); err != nil {
		return StatsResult{}, err
	}
	if res.HealthFacilities, err = s.count("health_facilities", "deleted_at IS NULL"); err != nil {
		return StatsResult{}, err
	}
	if res.Consultants, err = s.count("consultants", "deleted_at IS NULL AND status = ?", "active"); err != nil {
		return StatsResult{}, err
	}
	if res.TotalUsers, err = s.count("users", "deleted_at IS NULL"); err != nil {
		return StatsResult{}, err
	}
	if res.MinistryDirectory, err = s.count("ministry_directory", "deleted_at IS NULL"); err != nil {
		return StatsResult{}, err
	}
	if res.FAQs, err = s.count("faqs", "deleted_at IS NULL AND status = ?", "published"); err != nil {
		return StatsResult{}, err
	}

	if userID != "" {
		if res.UnreadMessagesCount, err = s.unreadMessagesCount(userID); err != nil {
			return StatsResult{}, err
		}
		if res.UserConversationsCount, err = s.userConversationsCount(userID); err != nil {
			return StatsResult{}, err
		}
	}
	return res, nil
}

// count returns the number of rows in table matching the where clause.
func (s LegacyAPIService) count(table string, where string, args ...any) (int64, error) {
	var total int64
	err := s.DB.Table(table).Where(where, args...).Count(&total).Error
	return total, err
}

// countRecent counts rows created within the last daysBack days.
func (s LegacyAPIService) countRecent(table string, daysBack int) (int64, error) {
	var total int64
	sql := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE deleted_at IS NULL AND created_at::date >= CURRENT_DATE - ?::int", table)
	err := s.DB.Raw(sql, daysBack).Scan(&total).Error
	return total, err
}

// countHealthcareProviders counts users whose role is healthcare_provider.
func (s LegacyAPIService) countHealthcareProviders() (int64, error) {
	var total int64
	err := s.DB.Raw(`
		SELECT COUNT(DISTINCT u.id)
		FROM users u
		JOIN user_roles ur ON ur.user_id = u.id
		JOIN roles r ON r.id = ur.role_id
		WHERE u.deleted_at IS NULL
		  AND (
		    lower(coalesce(r.role_key, '')) IN ('healthcare_provider', 'healthcareprovider')
		    OR lower(r.name) IN ('healthcare provider', 'healthcare_provider', 'healthcareprovider')
		  )
	`).Scan(&total).Error
	return total, err
}

// unreadMessagesCount returns the number of unread messages for a user.
func (s LegacyAPIService) unreadMessagesCount(userID string) (int64, error) {
	var total int64
	err := s.DB.Raw(`
		SELECT COUNT(*)
		FROM messages m
		WHERE m.deleted_at IS NULL
		  AND m.sender_user_id::text <> ?
		  AND (
		    m.read_by_json IS NULL
		    OR m.read_by_json = '[]'::jsonb
		    OR NOT (m.read_by_json @> to_jsonb(ARRAY[?::text]))
		  )
	`, userID, userID).Scan(&total).Error
	return total, err
}

// userConversationsCount returns how many conversations the user participates in.
func (s LegacyAPIService) userConversationsCount(userID string) (int64, error) {
	var total int64
	err := s.DB.Raw(`
		SELECT COUNT(*)
		FROM conversations
		WHERE deleted_at IS NULL
		  AND (participant1_user_id::text = ? OR participant2_user_id::text = ?)
	`, userID, userID).Scan(&total).Error
	return total, err
}

// seriesCount returns a daily count for the last 30 days for the given table.
func (s LegacyAPIService) seriesCount(table string) ([]DayTotal, error) {
	var rows []DayTotal
	sql := fmt.Sprintf(`
		WITH days AS (
			SELECT generate_series(CURRENT_DATE - INTERVAL '29 day', CURRENT_DATE, INTERVAL '1 day')::date AS day
		)
		SELECT to_char(days.day, 'YYYY-MM-DD') AS day, COUNT(t.id) AS total
		FROM days
		LEFT JOIN %s t
		  ON t.deleted_at IS NULL
		 AND t.created_at::date = days.day
		GROUP BY days.day
		ORDER BY days.day
	`, table)
	err := s.DB.Raw(sql).Scan(&rows).Error
	return rows, err
}
