package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AccountActionToken struct {
	ID         uuid.UUID  `gorm:"type:uuid;primaryKey"`
	UserID     uuid.UUID  `gorm:"type:uuid;index;not null"`
	Purpose    string     `gorm:"not null"`
	TokenHash  string     `gorm:"uniqueIndex;not null"`
	ExpiresAt  time.Time  `gorm:"index;not null"`
	ConsumedAt *time.Time `gorm:"index"`
	CreatedAt  time.Time
}

func (token *AccountActionToken) BeforeCreate(_ *gorm.DB) error {
	if token.ID == uuid.Nil {
		token.ID = uuid.New()
	}
	return nil
}
