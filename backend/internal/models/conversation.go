package models

import (
	"encoding/json"

	"github.com/google/uuid"
)

type Conversation struct {
	Base
	Participant1UserID uuid.UUID `json:"participant1_user_id"`
	Participant2UserID uuid.UUID `json:"participant2_user_id"`
	LastActivity       *string   `json:"last_activity,omitempty"`
}

func (Conversation) TableName() string { return "conversations" }

type Message struct {
	Base
	ConversationID uuid.UUID       `json:"conversation_id"`
	SenderUserID   uuid.UUID       `json:"sender_user_id"`
	ReplyToID      *uuid.UUID      `json:"reply_to_id,omitempty"`
	Content        string          `json:"content"`
	MessageType    *string         `json:"message_type,omitempty"`
	Attachments    json.RawMessage `gorm:"column:attachments_json;type:jsonb" json:"attachments,omitempty" swaggertype:"array,string"`
	ReadBy         json.RawMessage `gorm:"column:read_by_json;type:jsonb" json:"read_by,omitempty" swaggertype:"object"`
	Reactions      json.RawMessage `gorm:"column:reactions_json;type:jsonb" json:"reactions,omitempty" swaggertype:"object"`
	IsEdited       bool            `json:"is_edited"`
	EditedAt       *string         `json:"edited_at,omitempty"`
}

func (Message) TableName() string { return "messages" }
