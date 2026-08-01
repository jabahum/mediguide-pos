package services

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrConversationInvalid   = errors.New("invalid conversation payload")
	ErrConversationForbidden = errors.New("conversation access denied")
)

type ConversationService struct{ DB *gorm.DB }
type ConversationQuery struct {
	Page                             PageInput
	Search, RecentSince, Sort, Order string
}
type ConversationCreate struct {
	OtherParticipantID string `json:"other_participant_id"`
}
type ConversationView struct {
	models.Conversation
	Participant1Name     string     `json:"participant1_name,omitempty"`
	Participant1Email    string     `json:"participant1_email,omitempty"`
	Participant1Avatar   string     `json:"participant1_avatar,omitempty"`
	Participant1Verified bool       `json:"participant1_verified"`
	Participant2Name     string     `json:"participant2_name,omitempty"`
	Participant2Email    string     `json:"participant2_email,omitempty"`
	Participant2Avatar   string     `json:"participant2_avatar,omitempty"`
	Participant2Verified bool       `json:"participant2_verified"`
	LastMessageID        *uuid.UUID `json:"last_message_id,omitempty"`
	LastMessage          string     `json:"last_message,omitempty"`
}
type MessageCreate struct {
	Content     string   `json:"content"`
	MessageType string   `json:"message_type"`
	ReplyToID   *string  `json:"reply_to_id"`
	Attachments []string `json:"attachments"`
}
type MessageReadInput struct {
	ReadAt string `json:"read_at"`
}
type MessageReactionInput struct {
	Emoji  string `json:"emoji"`
	Active bool   `json:"active"`
}
type MessageView struct {
	models.Message
	SenderName     string `json:"sender_name,omitempty"`
	SenderEmail    string `json:"sender_email,omitempty"`
	SenderAvatar   string `json:"sender_avatar,omitempty"`
	SenderVerified bool   `json:"sender_verified"`
}

func (s ConversationService) conversationQuery() *gorm.DB {
	return s.DB.Table("conversations c").Select("c.*,p1.name participant1_name,p1.email participant1_email,p1.avatar participant1_avatar,p1.verified participant1_verified,p2.name participant2_name,p2.email participant2_email,p2.avatar participant2_avatar,p2.verified participant2_verified,lm.id last_message_id,lm.content last_message").Joins("JOIN users p1 ON p1.id=c.participant1_user_id").Joins("JOIN users p2 ON p2.id=c.participant2_user_id").Joins("LEFT JOIN LATERAL (SELECT id,content FROM messages WHERE conversation_id=c.id AND deleted_at IS NULL ORDER BY created_at DESC,id DESC LIMIT 1) lm ON true").Where("c.deleted_at IS NULL")
}
func (s ConversationService) List(userID uuid.UUID, in ConversationQuery) (*PageResult[ConversationView], error) {
	p := in.Page.Normalize(20, 100)
	q := s.conversationQuery().Where("c.participant1_user_id=? OR c.participant2_user_id=?", userID, userID)
	if v := strings.TrimSpace(in.Search); v != "" {
		like := "%" + v + "%"
		q = q.Where("(c.participant1_user_id<>? AND (LOWER(p1.name) LIKE LOWER(?) OR LOWER(p1.email) LIKE LOWER(?))) OR (c.participant2_user_id<>? AND (LOWER(p2.name) LIKE LOWER(?) OR LOWER(p2.email) LIKE LOWER(?)))", userID, like, like, userID, like, like)
	}
	if in.RecentSince != "" {
		if _, e := time.Parse(time.RFC3339, in.RecentSince); e != nil {
			return nil, ErrConversationInvalid
		}
		q = q.Where("c.last_activity>=?", in.RecentSince)
	}
	return pageHelp[ConversationView](q, p, map[string]string{"last_activity": "c.last_activity", "created_at": "c.created_at", "updated_at": "c.updated_at"}, in.Sort, in.Order, "c.updated_at DESC")
}
func (s ConversationService) Get(userID, id uuid.UUID) (*ConversationView, error) {
	var v ConversationView
	e := s.conversationQuery().Where("c.id=? AND (c.participant1_user_id=? OR c.participant2_user_id=?)", id, userID, userID).First(&v).Error
	return &v, e
}
func (s ConversationService) Create(userID uuid.UUID, in ConversationCreate) (*ConversationView, error) {
	other, e := uuid.Parse(in.OtherParticipantID)
	if e != nil || other == userID {
		return nil, ErrConversationInvalid
	}
	var count int64
	if e = s.DB.Model(&models.User{}).Where("id=? AND deleted_at IS NULL", other).Count(&count).Error; e != nil || count != 1 {
		return nil, ErrConversationInvalid
	}
	var existing models.Conversation
	e = s.DB.Where("deleted_at IS NULL AND ((participant1_user_id=? AND participant2_user_id=?) OR (participant1_user_id=? AND participant2_user_id=?))", userID, other, other, userID).First(&existing).Error
	if e == nil {
		return s.Get(userID, existing.ID)
	}
	if !errors.Is(e, gorm.ErrRecordNotFound) {
		return nil, e
	}
	now := time.Now().UTC().Format(time.RFC3339)
	v := models.Conversation{Participant1UserID: userID, Participant2UserID: other, LastActivity: &now}
	if e = s.DB.Create(&v).Error; e != nil {
		return nil, e
	}
	return s.Get(userID, v.ID)
}
func (s ConversationService) Delete(userID, id uuid.UUID) error {
	r := s.DB.Where("id=? AND (participant1_user_id=? OR participant2_user_id=?)", id, userID, userID).Delete(&models.Conversation{})
	if r.Error != nil {
		return r.Error
	}
	if r.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
func (s ConversationService) participant(conversationID, userID uuid.UUID) bool {
	var count int64
	return s.DB.Model(&models.Conversation{}).Where("id=? AND deleted_at IS NULL AND (participant1_user_id=? OR participant2_user_id=?)", conversationID, userID, userID).Count(&count).Error == nil && count == 1
}
func (s ConversationService) messageQuery() *gorm.DB {
	return s.DB.Table("messages m").Select("m.*,u.name sender_name,u.email sender_email,u.avatar sender_avatar,u.verified sender_verified").Joins("JOIN users u ON u.id=m.sender_user_id").Where("m.deleted_at IS NULL")
}
func (s ConversationService) ListMessages(userID, conversationID uuid.UUID, page PageInput, order string) (*PageResult[MessageView], error) {
	if !s.participant(conversationID, userID) {
		return nil, ErrConversationForbidden
	}
	p := page.Normalize(50, 100)
	sortOrder := "ASC"
	if strings.EqualFold(order, "desc") {
		sortOrder = "DESC"
	} else if order != "" && !strings.EqualFold(order, "asc") {
		return nil, ErrConversationInvalid
	}
	query := s.messageQuery().Where("m.conversation_id=?", conversationID)
	var total int64
	if err := query.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	items := []MessageView{}
	ordering := "m.created_at " + sortOrder + ", m.id " + sortOrder
	if err := query.Session(&gorm.Session{}).Order(ordering).Limit(p.PerPage).Offset(p.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, p, total), nil
}
func (s ConversationService) CreateMessage(userID, conversationID uuid.UUID, in MessageCreate) (*MessageView, error) {
	if !s.participant(conversationID, userID) {
		return nil, ErrConversationForbidden
	}
	in.Content = strings.TrimSpace(in.Content)
	if in.Content == "" || len(in.Content) > 10000 {
		return nil, ErrConversationInvalid
	}
	if in.MessageType == "" {
		in.MessageType = "text"
	}
	if !oneOf(in.MessageType, "text", "image", "file", "voice") {
		return nil, ErrConversationInvalid
	}
	attachments, e := json.Marshal(in.Attachments)
	if e != nil {
		return nil, ErrConversationInvalid
	}
	empty := json.RawMessage(`{}`)
	v := models.Message{ConversationID: conversationID, SenderUserID: userID, Content: in.Content, MessageType: &in.MessageType, Attachments: attachments, ReadBy: empty, Reactions: empty}
	if in.ReplyToID != nil {
		id, e := uuid.Parse(*in.ReplyToID)
		if e != nil {
			return nil, ErrConversationInvalid
		}
		var count int64
		if e = s.DB.Model(&models.Message{}).Where("id=? AND conversation_id=? AND deleted_at IS NULL", id, conversationID).Count(&count).Error; e != nil || count != 1 {
			return nil, ErrConversationInvalid
		}
		v.ReplyToID = &id
	}
	e = s.DB.Transaction(func(tx *gorm.DB) error {
		if e := tx.Create(&v).Error; e != nil {
			return e
		}
		now := time.Now().UTC().Format(time.RFC3339)
		return tx.Model(&models.Conversation{}).Where("id=?", conversationID).Updates(map[string]any{"last_activity": now, "updated_at": time.Now().UTC()}).Error
	})
	if e != nil {
		return nil, e
	}
	return s.GetMessage(userID, conversationID, v.ID)
}
func (s ConversationService) GetMessage(userID, conversationID, messageID uuid.UUID) (*MessageView, error) {
	if !s.participant(conversationID, userID) {
		return nil, ErrConversationForbidden
	}
	var v MessageView
	e := s.messageQuery().Where("m.id=? AND m.conversation_id=?", messageID, conversationID).First(&v).Error
	return &v, e
}
func (s ConversationService) MarkRead(userID, conversationID, messageID uuid.UUID, in MessageReadInput) (*MessageView, error) {
	v, e := s.GetMessage(userID, conversationID, messageID)
	if e != nil {
		return nil, e
	}
	read := map[string]any{}
	_ = json.Unmarshal(v.ReadBy, &read)
	at := in.ReadAt
	if at == "" {
		at = time.Now().UTC().Format(time.RFC3339)
	} else if _, e = time.Parse(time.RFC3339, at); e != nil {
		return nil, ErrConversationInvalid
	}
	read[userID.String()] = at
	raw, _ := json.Marshal(read)
	if e = s.DB.Model(&models.Message{}).Where("id=?", messageID).Update("read_by_json", raw).Error; e != nil {
		return nil, e
	}
	return s.GetMessage(userID, conversationID, messageID)
}
func (s ConversationService) React(userID, conversationID, messageID uuid.UUID, in MessageReactionInput) (*MessageView, error) {
	v, e := s.GetMessage(userID, conversationID, messageID)
	if e != nil {
		return nil, e
	}
	in.Emoji = strings.TrimSpace(in.Emoji)
	if in.Emoji == "" || len(in.Emoji) > 32 {
		return nil, ErrConversationInvalid
	}
	reactions := map[string][]string{}
	_ = json.Unmarshal(v.Reactions, &reactions)
	users := reactions[in.Emoji]
	filtered := users[:0]
	for _, id := range users {
		if id != userID.String() {
			filtered = append(filtered, id)
		}
	}
	if in.Active {
		filtered = append(filtered, userID.String())
	}
	if len(filtered) == 0 {
		delete(reactions, in.Emoji)
	} else {
		reactions[in.Emoji] = filtered
	}
	raw, _ := json.Marshal(reactions)
	if e = s.DB.Model(&models.Message{}).Where("id=?", messageID).Update("reactions_json", raw).Error; e != nil {
		return nil, e
	}
	return s.GetMessage(userID, conversationID, messageID)
}
