package services

import (
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ensureConversationAccess verifies the user is a participant in the conversation.
func (s ResourceService) ensureConversationAccess(conversationID uuid.UUID, userID string) error {
	var count int64
	if err := s.DB.Table("conversations").
		Where("id = ? AND deleted_at IS NULL AND (participant1_user_id::text = ? OR participant2_user_id::text = ?)", conversationID, userID, userID).
		Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return ErrResourceForbidden
	}
	return nil
}

// ensureMessageAccess verifies the user participates in the conversation the message belongs to.
func (s ResourceService) ensureMessageAccess(messageID uuid.UUID, userID string) error {
	var count int64
	if err := s.DB.Table("messages m").
		Joins("JOIN conversations c ON c.id = m.conversation_id").
		Where("m.id = ? AND m.deleted_at IS NULL AND (c.participant1_user_id::text = ? OR c.participant2_user_id::text = ?)", messageID, userID, userID).
		Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return ErrResourceForbidden
	}
	return nil
}

// ownsRow returns true when the user_id column on the row matches userID.
func (s ResourceService) ownsRow(table string, rowID uuid.UUID, userID string) bool {
	var count int64
	err := s.DB.Table(table).
		Where("id = ? AND deleted_at IS NULL AND user_id::text = ?", rowID, userID).
		Count(&count).Error
	return err == nil && count > 0
}

// findConversationID looks for an existing conversation between two participants.
func (s ResourceService) findConversationID(participant1, participant2 uuid.UUID) (uuid.UUID, bool, error) {
	var row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	err := s.DB.Table("conversations").
		Select("id").
		Where("deleted_at IS NULL").
		Where(
			"((participant1_user_id = ? AND participant2_user_id = ?) OR (participant1_user_id = ? AND participant2_user_id = ?))",
			participant1, participant2, participant2, participant1,
		).
		Take(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return uuid.Nil, false, nil
	}
	if err != nil {
		return uuid.Nil, false, err
	}
	return row.ID, true, nil
}

// findReadingProgressID looks for an existing reading progress record for a user + document.
func (s ResourceService) findReadingProgressID(guidelineDocumentID, userID uuid.UUID) (uuid.UUID, bool, error) {
	var row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	err := s.DB.Table("reading_progress").
		Select("id").
		Where("deleted_at IS NULL AND user_id = ? AND guideline_document_id = ?", userID, guidelineDocumentID).
		Order("updated_at DESC").
		Take(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return uuid.Nil, false, nil
	}
	if err != nil {
		return uuid.Nil, false, err
	}
	return row.ID, true, nil
}
