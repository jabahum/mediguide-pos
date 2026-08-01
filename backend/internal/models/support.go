package models

import "github.com/google/uuid"

type SupportTicket struct {
	Base
	UserID       uuid.UUID  `json:"user_id"`
	AssignedTo   *uuid.UUID `json:"assigned_to,omitempty"`
	Subject      string     `json:"subject"`
	Description  string     `json:"description"`
	Status       string     `json:"status"`
	Priority     string     `json:"priority"`
	Category     *string    `json:"category,omitempty"`
	UserName     string     `gorm:"->" json:"user_name,omitempty"`
	UserEmail    string     `gorm:"->" json:"user_email,omitempty"`
	AssigneeName string     `gorm:"->" json:"assignee_name,omitempty"`
}

type SupportTicketReply struct {
	Base
	TicketID   uuid.UUID `json:"ticket_id"`
	UserID     uuid.UUID `json:"user_id"`
	Message    string    `json:"message"`
	IsInternal bool      `json:"is_internal"`
	UserName   string    `gorm:"->" json:"user_name,omitempty"`
	UserEmail  string    `gorm:"->" json:"user_email,omitempty"`
}
