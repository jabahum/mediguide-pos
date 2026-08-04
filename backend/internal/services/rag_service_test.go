package services

import (
	"errors"
	"strings"
	"testing"
)

func TestRAGAskRejectsInvalidQuestionsBeforeDatabaseAccess(t *testing.T) {
	t.Parallel()

	service := RAGService{}
	for _, question := range []string{"", " ", "x", strings.Repeat("x", 12001)} {
		_, err := service.Ask(nil, AskRequest{Question: question})
		if !errors.Is(err, ErrInvalidRAGQuestion) {
			t.Fatalf("question length %d: expected ErrInvalidRAGQuestion, got %v", len(question), err)
		}
	}
}
