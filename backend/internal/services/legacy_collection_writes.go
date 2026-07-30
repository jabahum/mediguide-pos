package services

import (
	"time"

	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
)

// createSupportTicket creates a new support ticket owned by the user.
func (s LegacyCollectionService) createSupportTicket(payload map[string]any, userID string) (*LegacyItemResult, error) {
	row := map[string]any{
		"id":          uuid.New(),
		"user_id":     mustUUID(userID),
		"subject":     firstPayloadString(payload, "subject"),
		"description": firstPayloadString(payload, "description"),
		"status":      defaultString(firstPayloadString(payload, "status"), "open"),
		"priority":    defaultString(firstPayloadString(payload, "priority"), "normal"),
		"category":    nullableString(firstPayloadString(payload, "category")),
		"created_at":  time.Now().UTC(),
		"updated_at":  time.Now().UTC(),
	}
	if row["subject"] == "" || row["description"] == "" {
		return nil, ErrLegacyCollectionInvalid
	}
	if err := s.DB.Table("support_tickets").Create(&row).Error; err != nil {
		return nil, err
	}
	return s.Get("support_tickets", row["id"].(uuid.UUID).String(), userID)
}

// createSupportTicketReply adds a reply to an existing ticket the user has access to.
func (s LegacyCollectionService) createSupportTicketReply(payload map[string]any, userID string) (*LegacyItemResult, error) {
	ticketID, err := parsePayloadUUID(payload, "ticket_id")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if err := s.ensureTicketAccess(ticketID, userID); err != nil {
		return nil, err
	}
	message := firstPayloadString(payload, "message")
	if message == "" {
		return nil, ErrLegacyCollectionInvalid
	}
	row := map[string]any{
		"id":          uuid.New(),
		"ticket_id":   ticketID,
		"user_id":     mustUUID(userID),
		"message":     message,
		"is_internal": false,
		"created_at":  time.Now().UTC(),
		"updated_at":  time.Now().UTC(),
	}
	if err := s.DB.Table("support_ticket_replies").Create(&row).Error; err != nil {
		return nil, err
	}
	return s.Get("support_ticket_replies", row["id"].(uuid.UUID).String(), userID)
}

// createConversation creates a new conversation between two participants (idempotent).
func (s LegacyCollectionService) createConversation(payload map[string]any, userID string) (*LegacyItemResult, error) {
	p1, err := parsePayloadUUIDAny(payload, "participant1_user_id", "participant1")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	p2, err := parsePayloadUUIDAny(payload, "participant2_user_id", "participant2")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	currentUserID := mustUUID(userID)
	if p1 != currentUserID && p2 != currentUserID {
		return nil, ErrLegacyCollectionForbidden
	}

	existingID, found, err := s.findConversationID(p1, p2)
	if err != nil {
		return nil, err
	}
	if found {
		return s.Get("conversations", existingID.String(), userID)
	}

	row := map[string]any{
		"id":                   uuid.New(),
		"participant1_user_id": p1,
		"participant2_user_id": p2,
		"last_activity":        nullableString(firstPayloadStringAny(payload, "last_activity")),
		"created_at":           time.Now().UTC(),
		"updated_at":           time.Now().UTC(),
	}
	if err := s.DB.Table("conversations").Create(&row).Error; err != nil {
		return nil, err
	}
	return s.Get("conversations", row["id"].(uuid.UUID).String(), userID)
}

// createMessage sends a message in a conversation the user participates in.
func (s LegacyCollectionService) createMessage(payload map[string]any, userID string) (*LegacyItemResult, error) {
	conversationID, err := parsePayloadUUIDAny(payload, "conversation_id", "conversation")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if err := s.ensureConversationAccess(conversationID, userID); err != nil {
		return nil, err
	}
	senderID, err := parsePayloadUUIDAny(payload, "sender_user_id", "sender")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if senderID != mustUUID(userID) {
		return nil, ErrLegacyCollectionForbidden
	}
	content := firstPayloadString(payload, "content")
	if content == "" {
		return nil, ErrLegacyCollectionInvalid
	}

	row := map[string]any{
		"id":               uuid.New(),
		"conversation_id":  conversationID,
		"sender_user_id":   senderID,
		"content":          content,
		"message_type":     nullableString(firstPayloadStringAny(payload, "message_type")),
		"attachments_json": jsonbValue(firstPayloadValue(payload, "attachments_json", "attachments")),
		"read_by_json":     jsonbValue(firstPayloadValue(payload, "read_by_json", "read_by")),
		"reactions_json":   jsonbValue(firstPayloadValue(payload, "reactions_json", "reactions")),
		"is_edited":        boolPayload(payload, "is_edited", false),
		"edited_at":        nullableString(firstPayloadStringAny(payload, "edited_at")),
		"created_at":       time.Now().UTC(),
		"updated_at":       time.Now().UTC(),
	}
	if replyID, ok := optionalPayloadUUIDAny(payload, "reply_to_id", "reply_to"); ok {
		row["reply_to_id"] = replyID
	}

	if err := s.DB.Table("messages").Create(&row).Error; err != nil {
		return nil, err
	}

	_ = s.DB.Table("conversations").Where("id = ?", conversationID).Updates(map[string]any{
		"last_activity": time.Now().UTC().Format(time.RFC3339),
		"updated_at":    time.Now().UTC(),
	}).Error

	return s.Get("messages", row["id"].(uuid.UUID).String(), userID)
}

// createReadingProgress creates or upserts a reading progress record for the user.
func (s LegacyCollectionService) createReadingProgress(payload map[string]any, userID string) (*LegacyItemResult, error) {
	docID, err := parsePayloadUUIDAny(payload, "guideline_document_id", "guideline_id")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}

	if existingID, found, err := s.findReadingProgressID(docID, mustUUID(userID)); err != nil {
		return nil, err
	} else if found {
		return s.updateReadingProgress(existingID.String(), payload, userID)
	}

	row := map[string]any{
		"id":                    uuid.New(),
		"user_id":               mustUUID(userID),
		"guideline_document_id": docID,
		"progress_percentage":   floatPayload(payload, "progress_percentage", 0),
		"current_section":       nullableString(firstPayloadStringAny(payload, "current_section")),
		"last_read_at":          nullableString(firstPayloadStringAny(payload, "last_read_at")),
		"is_bookmarked":         boolPayload(payload, "is_bookmarked", false),
		"reading_time_seconds":  nullableIntPayload(payload, "reading_time_seconds"),
		"created_at":            time.Now().UTC(),
		"updated_at":            time.Now().UTC(),
	}
	if err := s.DB.Table("reading_progress").Create(&row).Error; err != nil {
		return nil, err
	}
	return s.Get("reading_progress", row["id"].(uuid.UUID).String(), userID)
}

// createUsageLog records a usage event for any of the supported log collections.
func (s LegacyCollectionService) createUsageLog(collection string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	row := map[string]any{
		"id":         uuid.New(),
		"user_id":    mustUUID(userID),
		"created_at": time.Now().UTC(),
		"updated_at": time.Now().UTC(),
	}
	switch collection {
	case "guideline_usage_logs":
		id, err := parsePayloadUUIDAny(payload, "guideline_document_id", "guideline_id")
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		row["guideline_document_id"] = id
	case "drug_usage_logs":
		id, err := parsePayloadUUIDAny(payload, "drug_id")
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		row["drug_id"] = id
	case "abbreviation_usage_logs":
		id, err := parsePayloadUUIDAny(payload, "abbreviation_id")
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		row["abbreviation_id"] = id
	case "consultant_usage_logs":
		id, err := parsePayloadUUIDAny(payload, "consultant_id")
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		row["consultant_id"] = id
	case "facility_usage_logs":
		id, err := parsePayloadUUIDAny(payload, "facility_id")
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		row["facility_id"] = id
	case "ai_usage_logs":
		// no extra fields required
	default:
		return nil, ErrLegacyCollectionWrite
	}

	if err := s.DB.Table(collection).Create(&row).Error; err != nil {
		return nil, err
	}
	return s.Get(collection, row["id"].(uuid.UUID).String(), userID)
}

// updateUser applies allowed profile field updates for the authenticated user only.
func (s LegacyCollectionService) updateUser(id string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	if id != userID {
		return nil, ErrLegacyCollectionForbidden
	}

	updates := map[string]any{}
	if password := firstPayloadString(payload, "password"); password != "" {
		passwordConfirm := firstPayloadStringAny(payload, "passwordConfirm", "password_confirm")
		if passwordConfirm != "" && passwordConfirm != password {
			return nil, ErrLegacyCollectionInvalid
		}
		hash, err := security.HashPassword(password)
		if err != nil {
			return nil, err
		}
		updates["password_hash"] = hash
	}
	copyStringUpdate(payload, updates, "name")
	copyStringUpdate(payload, updates, "phone")
	copyNullableStringUpdate(payload, updates, "alternative_phone")
	copyNullableStringUpdate(payload, updates, "facility_id")
	copyNullableStringUpdate(payload, updates, "address")
	copyNullableStringUpdate(payload, updates, "city")
	copyNullableStringUpdate(payload, updates, "state")
	copyNullableStringUpdate(payload, updates, "country")
	copyNullableStringUpdate(payload, updates, "postal_code")
	copyNullableStringUpdate(payload, updates, "license_number")
	copyNullableStringUpdate(payload, updates, "organization")
	copyNullableStringUpdate(payload, updates, "department")
	copyNullableStringUpdate(payload, updates, "job_title")
	copyNullableStringUpdate(payload, updates, "preferred_language")
	copyNullableStringUpdate(payload, updates, "timezone")
	copyNullableStringUpdate(payload, updates, "notes")
	if specialization, ok := payload["specialization"]; ok {
		list, err := stringListPayload(specialization)
		if err != nil {
			return nil, ErrLegacyCollectionInvalid
		}
		updates["specialization_json"] = models.StringList(list)
	}
	if len(updates) == 0 {
		return nil, ErrLegacyCollectionInvalid
	}
	updates["updated_at"] = time.Now().UTC()
	if err := s.DB.Model(&models.User{}).Where("id = ?", mustUUID(userID)).Updates(updates).Error; err != nil {
		return nil, err
	}

	var user models.User
	if err := s.DB.Preload("Roles.Permissions").First(&user, "id = ?", mustUUID(userID)).Error; err != nil {
		return nil, err
	}
	item, err := structToMap(user)
	if err != nil {
		return nil, err
	}
	return &LegacyItemResult{Success: true, Collection: "users", Item: item}, nil
}

// updateConversation updates the last_activity timestamp for a conversation.
func (s LegacyCollectionService) updateConversation(id string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	conversationID, err := parsePayloadUUIDAny(map[string]any{"id": id}, "id")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if err := s.ensureConversationAccess(conversationID, userID); err != nil {
		return nil, err
	}
	updates := map[string]any{}
	copyNullableStringUpdateAny(payload, updates, "last_activity")
	if len(updates) == 0 {
		return nil, ErrLegacyCollectionInvalid
	}
	updates["updated_at"] = time.Now().UTC()
	if err := s.DB.Table("conversations").Where("id = ?", conversationID).Updates(updates).Error; err != nil {
		return nil, err
	}
	return s.Get("conversations", id, userID)
}

// updateMessage applies allowed field updates to a message the user has access to.
func (s LegacyCollectionService) updateMessage(id string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	messageID, err := parsePayloadUUIDAny(map[string]any{"id": id}, "id")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if err := s.ensureMessageAccess(messageID, userID); err != nil {
		return nil, err
	}
	updates := map[string]any{}
	copyStringUpdate(payload, updates, "content")
	if value, ok := firstExistingPayloadValue(payload, "read_by_json", "read_by"); ok {
		updates["read_by_json"] = jsonbValue(value)
	}
	if value, ok := firstExistingPayloadValue(payload, "reactions_json", "reactions"); ok {
		updates["reactions_json"] = jsonbValue(value)
	}
	if value, ok := payload["is_edited"]; ok {
		updates["is_edited"] = value
	}
	copyNullableStringUpdateAny(payload, updates, "edited_at")
	if len(updates) == 0 {
		return nil, ErrLegacyCollectionInvalid
	}
	updates["updated_at"] = time.Now().UTC()
	if err := s.DB.Table("messages").Where("id = ?", messageID).Updates(updates).Error; err != nil {
		return nil, err
	}
	return s.Get("messages", id, userID)
}

// updateReadingProgress applies allowed field updates to a reading progress record.
func (s LegacyCollectionService) updateReadingProgress(id string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	rowID, err := parsePayloadUUIDAny(map[string]any{"id": id}, "id")
	if err != nil {
		return nil, ErrLegacyCollectionInvalid
	}
	if !s.ownsRow("reading_progress", rowID, userID) {
		return nil, ErrLegacyCollectionForbidden
	}
	updates := map[string]any{}
	copyNullableStringUpdateAny(payload, updates, "current_section")
	if value, ok := payload["progress_percentage"]; ok {
		updates["progress_percentage"] = value
	}
	copyNullableStringUpdateAny(payload, updates, "last_read_at")
	if value, ok := payload["is_bookmarked"]; ok {
		updates["is_bookmarked"] = value
	}
	if value, ok := payload["reading_time_seconds"]; ok {
		updates["reading_time_seconds"] = value
	}
	if len(updates) == 0 {
		return nil, ErrLegacyCollectionInvalid
	}
	updates["updated_at"] = time.Now().UTC()
	if err := s.DB.Table("reading_progress").Where("id = ?", rowID).Updates(updates).Error; err != nil {
		return nil, err
	}
	return s.Get("reading_progress", id, userID)
}
