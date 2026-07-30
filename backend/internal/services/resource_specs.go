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
	"faqs": {
		Table:        "faqs f",
		IDColumn:     "f.id",
		Select:       "f.*",
		DefaultOrder: "coalesce(f.sort_order, 999999), f.created_at DESC",
		SearchColumns: []string{
			"f.question", "f.answer", "coalesce(f.keywords, '')", "coalesce(f.target_audience, '')",
		},
		FilterColumns: map[string]string{
			"status":          "f.status",
			"priority":        "f.priority",
			"target_audience": "f.target_audience",
			"is_featured":     "f.is_featured::text",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("f.deleted_at IS NULL").Where("f.status = ?", "published")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("f.deleted_at IS NULL")
		},
	},
	"faq_tags": {
		Table:        "faq_tags ft",
		IDColumn:     "ft.id",
		Select:       "ft.*",
		DefaultOrder: "coalesce(ft.sort_order, 999999), ft.name ASC",
		SearchColumns: []string{
			"ft.name", "ft.slug", "coalesce(ft.description, '')",
		},
		FilterColumns: map[string]string{
			"is_active": "ft.is_active::text",
			"slug":      "ft.slug",
		},
		Access: resourceAccessAuth,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("ft.deleted_at IS NULL")
		},
	},
	"documentation": {
		Table:        "documentation doc",
		IDColumn:     "doc.id",
		Select:       "doc.*",
		DefaultOrder: "doc.title ASC",
		SearchColumns: []string{
			"doc.title", "coalesce(doc.description, '')", "doc.content", "coalesce(doc.category, '')", "coalesce(doc.tags, '')",
		},
		FilterColumns: map[string]string{
			"status":   "doc.status",
			"category": "doc.category",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("doc.deleted_at IS NULL").Where("doc.status = ?", "published")
		},
		ApplyAuth: func(query *gorm.DB) *gorm.DB {
			return query.Where("doc.deleted_at IS NULL")
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
	"health_sub_regions": {
		Table:        "health_sub_regions hsr",
		IDColumn:     "hsr.id",
		Select:       "hsr.*, r.name AS region_name",
		DefaultOrder: "hsr.name ASC",
		SearchColumns: []string{
			"hsr.name", "hsr.nhpi_code", "hsr.hsdt_code", "coalesce(r.name, '')",
		},
		FilterColumns: map[string]string{
			"region_id": "hsr.region_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN regions r ON r.id = hsr.region_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("hsr.deleted_at IS NULL")
		},
	},
	"health_facilities": {
		Table:        "health_facilities hf",
		IDColumn:     "hf.id",
		Select:       "hf.*, fl.name AS facility_level_name, a.name AS authority_name, ot.name AS ownership_type_name, d.name AS district_name, r.name AS region_name, c.name AS county_name, sc.name AS subcounty_name, p.name AS parish_name, hsd.name AS health_sub_district_name",
		DefaultOrder: "hf.name ASC",
		SearchColumns: []string{
			"hf.name", "hf.nhpi_code", "hf.hsdt_code", "coalesce(d.name, '')", "coalesce(r.name, '')",
		},
		FilterColumns: map[string]string{
			"region_id":         "hf.region_id::text",
			"district_id":       "hf.district_id::text",
			"facility_level_id": "hf.facility_level_id::text",
			"ownership_type_id": "hf.ownership_type_id::text",
			"authority_id":      "hf.authority_id::text",
		},
		Access: resourceAccessPublic,
		Joins: []string{
			"LEFT JOIN facility_levels fl ON fl.id = hf.facility_level_id",
			"LEFT JOIN authorities a ON a.id = hf.authority_id",
			"LEFT JOIN ownership_types ot ON ot.id = hf.ownership_type_id",
			"LEFT JOIN health_sub_districts hsd ON hsd.id = hf.health_sub_district_id",
			"LEFT JOIN parishes p ON p.id = hf.parish_id",
			"LEFT JOIN subcounties sc ON sc.id = hf.subcounty_id",
			"LEFT JOIN counties c ON c.id = hf.county_id",
			"LEFT JOIN districts d ON d.id = hf.district_id",
			"LEFT JOIN regions r ON r.id = hf.region_id",
		},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("hf.deleted_at IS NULL")
		},
	},
	"regions": {
		Table:        "regions r",
		IDColumn:     "r.id",
		Select:       "r.*",
		DefaultOrder: "r.name ASC",
		SearchColumns: []string{
			"r.name", "r.nhpi_code", "r.hsdt_code",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("r.deleted_at IS NULL")
		},
	},
	"districts": {
		Table:        "districts d",
		IDColumn:     "d.id",
		Select:       "d.*, r.name AS region_name",
		DefaultOrder: "d.name ASC",
		SearchColumns: []string{
			"d.name", "d.nhpi_code", "d.hsdt_code", "coalesce(r.name, '')",
		},
		FilterColumns: map[string]string{
			"region_id": "d.region_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN regions r ON r.id = d.region_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("d.deleted_at IS NULL")
		},
	},
	"health_sub_districts": {
		Table:        "health_sub_districts hsd",
		IDColumn:     "hsd.id",
		Select:       "hsd.*, d.name AS district_name",
		DefaultOrder: "hsd.name ASC",
		SearchColumns: []string{
			"hsd.name", "hsd.nhpi_code", "hsd.hsdt_code", "coalesce(d.name, '')",
		},
		FilterColumns: map[string]string{
			"district_id": "hsd.district_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN districts d ON d.id = hsd.district_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("hsd.deleted_at IS NULL")
		},
	},
	"counties": {
		Table:        "counties c",
		IDColumn:     "c.id",
		Select:       "c.*, d.name AS district_name",
		DefaultOrder: "c.name ASC",
		SearchColumns: []string{
			"c.name", "c.nhpi_code", "c.hsdt_code", "coalesce(d.name, '')",
		},
		FilterColumns: map[string]string{
			"district_id": "c.district_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN districts d ON d.id = c.district_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("c.deleted_at IS NULL")
		},
	},
	"subcounties": {
		Table:        "subcounties s",
		IDColumn:     "s.id",
		Select:       "s.*, d.name AS district_name, c.name AS county_name",
		DefaultOrder: "s.name ASC",
		SearchColumns: []string{
			"s.name", "s.nhpi_code", "s.hsdt_code", "coalesce(d.name, '')", "coalesce(c.name, '')",
		},
		FilterColumns: map[string]string{
			"district_id": "s.district_id::text",
			"county_id":   "s.county_id::text",
		},
		Access: resourceAccessPublic,
		Joins: []string{
			"LEFT JOIN districts d ON d.id = s.district_id",
			"LEFT JOIN counties c ON c.id = s.county_id",
		},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("s.deleted_at IS NULL")
		},
	},
	"parishes": {
		Table:        "parishes p",
		IDColumn:     "p.id",
		Select:       "p.*, s.name AS subcounty_name",
		DefaultOrder: "p.name ASC",
		SearchColumns: []string{
			"p.name", "p.nhpi_code", "p.hsdt_code", "coalesce(s.name, '')",
		},
		FilterColumns: map[string]string{
			"subcounty_id": "p.subcounty_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN subcounties s ON s.id = p.subcounty_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("p.deleted_at IS NULL")
		},
	},
	"facility_levels": {
		Table:        "facility_levels fl",
		IDColumn:     "fl.id",
		Select:       "fl.*",
		DefaultOrder: "fl.name ASC",
		SearchColumns: []string{
			"fl.code", "fl.name",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("fl.deleted_at IS NULL")
		},
	},
	"ownership_types": {
		Table:        "ownership_types ot",
		IDColumn:     "ot.id",
		Select:       "ot.*",
		DefaultOrder: "ot.name ASC",
		SearchColumns: []string{
			"ot.code", "ot.name",
		},
		Access: resourceAccessPublic,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("ot.deleted_at IS NULL")
		},
	},
	"authorities": {
		Table:        "authorities a",
		IDColumn:     "a.id",
		Select:       "a.*, ot.name AS ownership_type_name",
		DefaultOrder: "a.name ASC",
		SearchColumns: []string{
			"a.name", "coalesce(a.code, '')", "coalesce(ot.name, '')",
		},
		FilterColumns: map[string]string{
			"ownership_type_id": "a.ownership_type_id::text",
		},
		Access: resourceAccessPublic,
		Joins:  []string{"LEFT JOIN ownership_types ot ON ot.id = a.ownership_type_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("a.deleted_at IS NULL")
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
	"users": {
		Table:        "users u",
		IDColumn:     "u.id",
		Select:       "u.*, coalesce(r.role_key, r.name) AS role",
		DefaultOrder: "u.updated_at DESC",
		SearchColumns: []string{
			"u.name", "u.email", "coalesce(u.phone, '')",
		},
		FilterColumns: map[string]string{
			"status": "u.status",
			"role":   "coalesce(r.role_key, r.name)",
		},
		Access: resourceAccessAuth,
		Joins: []string{
			"LEFT JOIN user_roles ur ON ur.user_id = u.id",
			"LEFT JOIN roles r ON r.id = ur.role_id",
		},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("u.deleted_at IS NULL")
		},
	},
	"roles": {
		Table:        "roles r",
		IDColumn:     "r.id",
		Select:       "r.*, r.role_key AS key, r.permissions_json AS permissions, r.is_active AS \"isActive\"",
		DefaultOrder: "r.created_at DESC",
		SearchColumns: []string{
			"r.name", "coalesce(r.role_key, '')", "coalesce(r.description, '')",
		},
		FilterColumns: map[string]string{
			"is_active": "r.is_active::text",
			"isActive":  "r.is_active::text",
			"key":       "r.role_key",
		},
		Access: resourceAccessAuth,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("r.deleted_at IS NULL")
		},
	},
	"notifications": {
		Table:        "notifications n",
		IDColumn:     "n.id",
		Select:       "n.*",
		DefaultOrder: "n.created_at DESC",
		SearchColumns: []string{
			"n.title", "n.message", "n.type", "n.priority",
		},
		FilterColumns: map[string]string{
			"type":     "n.type",
			"priority": "n.priority",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("n.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("(n.user_id::text = ? OR n.user_id IS NULL)", userID)
		},
	},
	"notification_templates": {
		Table:        "notification_templates nt",
		IDColumn:     "nt.id",
		Select:       "nt.*",
		DefaultOrder: "nt.name ASC",
		SearchColumns: []string{
			"nt.name", "nt.type", "nt.category", "coalesce(nt.subject, '')",
		},
		FilterColumns: map[string]string{
			"status":   "nt.status",
			"type":     "nt.type",
			"category": "nt.category",
		},
		Access: resourceAccessAuth,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("nt.deleted_at IS NULL")
		},
	},
	"notification_campaigns": {
		Table:        "notification_campaigns nc",
		IDColumn:     "nc.id",
		Select:       "nc.*",
		DefaultOrder: "nc.created_at DESC",
		SearchColumns: []string{
			"nc.name", "nc.type", "nc.status",
		},
		FilterColumns: map[string]string{
			"status": "nc.status",
			"type":   "nc.type",
		},
		Access: resourceAccessAuth,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("nc.deleted_at IS NULL")
		},
	},
	"support_tickets": {
		Table:        "support_tickets st",
		IDColumn:     "st.id",
		Select:       "st.*",
		DefaultOrder: "st.updated_at DESC",
		SearchColumns: []string{
			"st.subject", "st.description", "coalesce(st.category, '')", "st.status", "st.priority",
		},
		FilterColumns: map[string]string{
			"status":   "st.status",
			"priority": "st.priority",
			"category": "st.category",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("st.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("(st.user_id::text = ? OR st.assigned_to::text = ?)", userID, userID)
		},
	},
	"support_ticket_replies": {
		Table:        "support_ticket_replies str",
		IDColumn:     "str.id",
		Select:       "str.*, u.id::text AS user_expand_id, u.name AS user_expand_name, u.email AS user_expand_email, u.avatar AS user_expand_avatar, u.verified AS user_expand_verified",
		DefaultOrder: "str.created_at ASC",
		SearchColumns: []string{
			"str.message",
		},
		FilterColumns: map[string]string{
			"ticket_id":   "str.ticket_id::text",
			"is_internal": "str.is_internal::text",
		},
		Access: resourceAccessUser,
		Joins:  []string{"LEFT JOIN support_tickets st ON st.id = str.ticket_id", "LEFT JOIN users u ON u.id = str.user_id"},
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("str.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("(str.user_id::text = ? OR st.user_id::text = ? OR st.assigned_to::text = ?)", userID, userID, userID)
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
	"facility_usage_logs": {
		Table:        "facility_usage_logs ful",
		IDColumn:     "ful.id",
		Select:       "ful.*",
		DefaultOrder: "ful.created_at DESC",
		FilterColumns: map[string]string{
			"facility_id": "ful.facility_id::text",
		},
		Access: resourceAccessUser,
		ApplyScopes: func(query *gorm.DB) *gorm.DB {
			return query.Where("ful.deleted_at IS NULL")
		},
		ApplyUser: func(query *gorm.DB, userID string) *gorm.DB {
			return query.Where("ful.user_id::text = ?", userID)
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
