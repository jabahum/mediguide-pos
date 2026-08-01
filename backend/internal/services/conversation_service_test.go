package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func conversationTestService(t *testing.T) (ConversationService, models.User, models.User, models.Conversation) {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err = db.AutoMigrate(&models.User{}, &models.Conversation{}, &models.Message{}); err != nil {
		t.Fatal(err)
	}
	first := models.User{Name: "First", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", Status: "active"}
	second := models.User{Name: "Second", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", Status: "active"}
	if err = db.Create(&first).Error; err != nil {
		t.Fatal(err)
	}
	if err = db.Create(&second).Error; err != nil {
		t.Fatal(err)
	}
	conversation := models.Conversation{Participant1UserID: first.ID, Participant2UserID: second.ID}
	if err = db.Create(&conversation).Error; err != nil {
		t.Fatal(err)
	}
	return ConversationService{DB: db}, first, second, conversation
}

func TestConversationMessagesAreParticipantProtected(t *testing.T) {
	s, first, _, conversation := conversationTestService(t)
	outsider := uuid.New()
	if _, err := s.ListMessages(outsider, conversation.ID, PageInput{Page: 1, PerPage: 20}, "asc"); !errors.Is(err, ErrConversationForbidden) {
		t.Fatalf("expected participant isolation, got %v", err)
	}
	created, err := s.CreateMessage(first.ID, conversation.ID, MessageCreate{Content: "Hello", MessageType: "text"})
	if err != nil {
		t.Fatal(err)
	}
	if created.SenderUserID != first.ID {
		t.Fatal("sender must be derived from claims")
	}
}

func TestConversationMessagesUseDeterministicOrder(t *testing.T) {
	s, first, _, conversation := conversationTestService(t)
	for _, content := range []string{"first", "second"} {
		if _, err := s.CreateMessage(first.ID, conversation.ID, MessageCreate{Content: content, MessageType: "text"}); err != nil {
			t.Fatal(err)
		}
	}
	page, err := s.ListMessages(first.ID, conversation.ID, PageInput{Page: 1, PerPage: 20}, "asc")
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Items) != 2 || page.Items[0].Content != "first" || page.Items[1].Content != "second" {
		t.Fatalf("unexpected order: %#v", page.Items)
	}
}
