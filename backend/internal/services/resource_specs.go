package services

import "gorm.io/gorm"

// resourceSpecs defines the query configuration for each transitional resource.
// Each entry maps a resource name to its table, access mode, joins, filters, and scopes.
var resourceSpecs = map[string]resourceSpec{
	"medical_guidelines": {
		Table:        "medical_guidelines mg",
		IDColumn:     "mg.id",
		Select:       "mg.*, gi.title AS index_item_title",
		DefaultOrder: "mg.updated_at DESC",
		SearchColumns: []string{
			"mg.condition_name", "coalesce(mg.icd10_code, '')", "coalesce(mg.target_population, '')",
		},
		FilterColumns: map[string]string{
			"priority": "mg.priority",
			"status":   "mg.status",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN guideline_index gi ON gi.id = mg.index_item_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("mg.deleted_at IS NULL").Where("(mg.is_published = ? OR mg.status = ?)", true, "published")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("mg.deleted_at IS NULL")
		},
	},
	"abbreviations": {
		Table:        "abbreviations a",
		IDColumn:     "a.id",
		Select:       "a.*",
		DefaultOrder: "a.abbreviation ASC",
		SearchColumns: []string{
			"a.abbreviation", "a.meaning", "coalesce(a.description, '')",
		},
		FilterColumns: map[string]string{
			"common_usage": "a.common_usage::text",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("a.deleted_at IS NULL")
		},
	},
	"emergency_protocols": {
		Table:        "emergency_protocols ep",
		IDColumn:     "ep.id",
		Select:       "ep.*",
		DefaultOrder: "ep.priority ASC, ep.title ASC",
		SearchColumns: []string{
			"ep.title", "coalesce(ep.description, '')", "ep.category",
		},
		FilterColumns: map[string]string{
			"status":   "ep.status",
			"category": "ep.category",
			"priority": "ep.priority",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("ep.deleted_at IS NULL").Where("ep.status = ?", "active")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("ep.deleted_at IS NULL")
		},
	},
	"generic_pages": {
		Table:        "generic_pages gp",
		IDColumn:     "gp.id",
		Select:       "gp.*",
		DefaultOrder: "gp.title ASC",
		SearchColumns: []string{
			"gp.title", "coalesce(gp.description, '')", "gp.key",
		},
		FilterColumns: map[string]string{
			"key": "gp.key",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("gp.deleted_at IS NULL")
		},
	},
	"guideline_categories": {
		Table:        "guideline_categories gc",
		IDColumn:     "gc.id",
		Select:       "gc.*",
		DefaultOrder: "coalesce(gc.sort_order, 999999), gc.name ASC",
		SearchColumns: []string{
			"gc.name", "coalesce(gc.slug, '')", "coalesce(gc.description, '')",
		},
		FilterColumns: map[string]string{
			"status":             "gc.status",
			"parent_category_id": "gc.parent_category_id::text",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("gc.deleted_at IS NULL").Where("gc.status = ?", "active")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("gc.deleted_at IS NULL")
		},
	},
	"guideline_tags": {
		Table:        "guideline_tags gt",
		IDColumn:     "gt.id",
		Select:       "gt.*",
		DefaultOrder: "gt.name ASC",
		SearchColumns: []string{
			"gt.name", "coalesce(gt.description, '')",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("gt.deleted_at IS NULL")
		},
	},
	"guideline_index": {
		Table:        "guideline_index gi",
		IDColumn:     "gi.id",
		Select:       "gi.*",
		DefaultOrder: "gi.level ASC, coalesce(gi.sort_order, 999999), gi.title ASC",
		SearchColumns: []string{
			"gi.title", "coalesce(gi.description, '')",
		},
		FilterColumns: map[string]string{
			"parent_id":    "gi.parent_id::text",
			"has_children": "gi.has_children::text",
			"level":        "gi.level::text",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("gi.deleted_at IS NULL")
		},
	},
	"consultants": {
		Table:        "consultants c",
		IDColumn:     "c.id",
		Select:       "c.*, u.id::text AS user_expand_id, u.name AS user_expand_name, u.email AS user_expand_email, u.avatar AS user_expand_avatar, u.verified AS user_expand_verified",
		DefaultOrder: "c.name ASC",
		SearchColumns: []string{
			"c.name", "c.email", "c.phone", "c.specialty", "coalesce(c.organization, '')", "coalesce(c.region, '')", "coalesce(c.city, '')",
		},
		FilterColumns: map[string]string{
			"status":      "c.status",
			"specialty":   "c.specialty",
			"region":      "c.region",
			"city":        "c.city",
			"is_verified": "c.is_verified::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN users u ON u.id = c.user_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("c.deleted_at IS NULL").Where("c.status = ?", "active")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("c.deleted_at IS NULL")
		},
	},
	"ministry_directory": {
		Table:        "ministry_directory md",
		IDColumn:     "md.id",
		Select:       "md.*, d.name AS district_name, r.name AS region_name",
		DefaultOrder: "md.priority_level ASC, md.name ASC",
		SearchColumns: []string{
			"md.name", "md.title", "md.ministry", "coalesce(md.department, '')", "md.phone", "coalesce(md.email, '')",
		},
		FilterColumns: map[string]string{
			"status":      "md.status",
			"district_id": "md.district_id::text",
			"region_id":   "md.region_id::text",
			"ministry":    "md.ministry",
			"department":  "md.department",
		},
		Access: resourceAccessPublic,
		Joins: []string{
			"LEFT JOIN districts d ON d.id = md.district_id",
			"LEFT JOIN regions r ON r.id = md.region_id",
		},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("md.deleted_at IS NULL").Where("md.status = ?", "active")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("md.deleted_at IS NULL")
		},
	},
	"languages": {
		Table:        "languages l",
		IDColumn:     "l.id",
		Select:       "l.*",
		DefaultOrder: "l.name ASC",
		SearchColumns: []string{
			"l.code", "l.name", "l.native_name",
		},
		FilterColumns: map[string]string{
			"status":     "l.status",
			"is_active":  "l.is_active::text",
			"is_default": "l.is_default::text",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("l.deleted_at IS NULL").Where("l.is_active = ?", true)
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("l.deleted_at IS NULL")
		},
	},
	"conversations": {
		Table:        "conversations c",
		IDColumn:     "c.id",
		Select:       "c.*, p1.id::text AS participant1_expand_id, p1.name AS participant1_expand_name, p1.email AS participant1_expand_email, p1.avatar AS participant1_expand_avatar, p1.verified AS participant1_expand_verified, p2.id::text AS participant2_expand_id, p2.name AS participant2_expand_name, p2.email AS participant2_expand_email, p2.avatar AS participant2_expand_avatar, p2.verified AS participant2_expand_verified, lm.id::text AS last_message_id, lm.content AS last_message",
		DefaultOrder: "c.updated_at DESC",
		FilterColumns: map[string]string{
			"participant1_user_id": "c.participant1_user_id::text",
			"participant2_user_id": "c.participant2_user_id::text",
		},
		Access: resourceAccessUser,
		Joins: []string{
			"LEFT JOIN users p1 ON p1.id = c.participant1_user_id",
			"LEFT JOIN users p2 ON p2.id = c.participant2_user_id",
			"LEFT JOIN LATERAL (SELECT id, content FROM messages WHERE conversation_id = c.id AND deleted_at IS NULL ORDER BY created_at DESC LIMIT 1) lm ON true",
		},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("c.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("(c.participant1_user_id::text = ? OR c.participant2_user_id::text = ?)", userID, userID)
		},
	},
	"messages": {
		Table:        "messages m",
		IDColumn:     "m.id",
		Select:       "m.*, u.id::text AS sender_expand_id, u.name AS sender_expand_name, u.email AS sender_expand_email, u.avatar AS sender_expand_avatar, u.verified AS sender_expand_verified",
		DefaultOrder: "m.created_at DESC",
		SearchColumns: []string{
			"m.content", "coalesce(m.message_type, '')",
		},
		FilterColumns: map[string]string{
			"conversation_id": "m.conversation_id::text",
			"sender_user_id":  "m.sender_user_id::text",
			"message_type":    "m.message_type",
		},
		Access: resourceAccessUser,
		Joins:  []string{"LEFT JOIN conversations c ON c.id = m.conversation_id", "LEFT JOIN users u ON u.id = m.sender_user_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("m.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("(c.participant1_user_id::text = ? OR c.participant2_user_id::text = ?)", userID, userID)
		},
	},
	"reading_progress": {
		Table:        "reading_progress rp",
		IDColumn:     "rp.id",
		Select:       "rp.*",
		DefaultOrder: "rp.updated_at DESC",
		FilterColumns: map[string]string{
			"guideline_document_id": "rp.guideline_document_id::text",
			"is_bookmarked":         "rp.is_bookmarked::text",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("rp.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("rp.user_id::text = ?", userID)
		},
	},
	"guideline_usage_logs": {
		Table:        "guideline_usage_logs gul",
		IDColumn:     "gul.id",
		Select:       "gul.*",
		DefaultOrder: "gul.created_at DESC",
		FilterColumns: map[string]string{
			"guideline_document_id": "gul.guideline_document_id::text",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("gul.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("gul.user_id::text = ?", userID)
		},
	},
	"abbreviation_usage_logs": {
		Table:        "abbreviation_usage_logs aul",
		IDColumn:     "aul.id",
		Select:       "aul.*",
		DefaultOrder: "aul.created_at DESC",
		FilterColumns: map[string]string{
			"abbreviation_id": "aul.abbreviation_id::text",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("aul.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("aul.user_id::text = ?", userID)
		},
	},
	"consultant_usage_logs": {
		Table:        "consultant_usage_logs cul",
		IDColumn:     "cul.id",
		Select:       "cul.*",
		DefaultOrder: "cul.created_at DESC",
		FilterColumns: map[string]string{
			"consultant_id": "cul.consultant_id::text",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("cul.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("cul.user_id::text = ?", userID)
		},
	},
	"ai_usage_logs": {
		Table:        "ai_usage_logs aiu",
		IDColumn:     "aiu.id",
		Select:       "aiu.*",
		DefaultOrder: "aiu.created_at DESC",
		Access:       resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("aiu.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("aiu.user_id::text = ?", userID)
		},
	},
}
