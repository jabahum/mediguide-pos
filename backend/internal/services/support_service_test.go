package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func supportTestService(t *testing.T) SupportService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.Exec(`CREATE TABLE users (id text PRIMARY KEY, name text, email text)`).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.SupportTicket{}, &models.SupportTicketReply{}); err != nil {
		t.Fatal(err)
	}
	return SupportService{DB: db}
}

func TestSupportTicketsAreOwnerIsolated(t *testing.T) {
	service := supportTestService(t)
	owner, other := uuid.New(), uuid.New()
	ticket, err := service.CreateTicket(owner, SupportTicketCreate{Subject: "Cannot sign in", Description: "Login fails", Priority: "high"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.GetTicket(other, ticket.ID, false); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("unrelated user must not read ticket: %v", err)
	}
	page, err := service.ListTickets(other, false, SupportTicketQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if page.TotalItems != 0 {
		t.Fatalf("expected no unrelated tickets, got %d", page.TotalItems)
	}
	staffPage, err := service.ListTickets(other, true, SupportTicketQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || staffPage.TotalItems != 1 {
		t.Fatalf("staff should see ticket: total=%d err=%v", staffPage.TotalItems, err)
	}
}

func TestSupportReplyOwnershipAndInternalVisibility(t *testing.T) {
	service := supportTestService(t)
	owner, staff := uuid.New(), uuid.New()
	ticket, err := service.CreateTicket(owner, SupportTicketCreate{Subject: "Question", Description: "Need help", Priority: "normal"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreateReply(owner, ticket.ID, false, SupportReplyCreate{Message: "private", IsInternal: true}); !errors.Is(err, ErrSupportForbidden) {
		t.Fatalf("owner must not create internal reply: %v", err)
	}
	if _, err := service.CreateReply(staff, ticket.ID, true, SupportReplyCreate{Message: "staff note", IsInternal: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreateReply(staff, ticket.ID, true, SupportReplyCreate{Message: "public answer"}); err != nil {
		t.Fatal(err)
	}
	ownerPage, err := service.ListReplies(owner, ticket.ID, false, PageInput{Page: 1, PerPage: 20})
	if err != nil {
		t.Fatal(err)
	}
	if ownerPage.TotalItems != 1 || ownerPage.Items[0].Message != "public answer" {
		t.Fatal("owner response exposed an internal reply")
	}
}

func TestSupportStatusTransitionsRequireStaff(t *testing.T) {
	service := supportTestService(t)
	owner := uuid.New()
	ticket, err := service.CreateTicket(owner, SupportTicketCreate{Subject: "Issue", Description: "Details", Priority: "normal"})
	if err != nil {
		t.Fatal(err)
	}
	resolved := "resolved"
	if _, err := service.UpdateTicket(owner, ticket.ID, false, SupportTicketUpdate{Status: &resolved}); !errors.Is(err, ErrSupportForbidden) {
		t.Fatalf("owner changed status: %v", err)
	}
	if _, err := service.UpdateTicket(owner, ticket.ID, true, SupportTicketUpdate{Status: &resolved}); !errors.Is(err, ErrSupportTransition) {
		t.Fatalf("invalid transition accepted: %v", err)
	}
	inProgress := "in_progress"
	if _, err := service.UpdateTicket(owner, ticket.ID, true, SupportTicketUpdate{Status: &inProgress}); err != nil {
		t.Fatal(err)
	}
}
