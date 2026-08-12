package services

import (
	"context"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func TestGuidelineCollaborationScopesAssignmentsAndCommentsToVersion(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)
	reviewer := models.User{Name: "Clinical reviewer", Email: uuid.NewString() + "@example.test", PasswordHash: "not-returned", IsActive: true}
	if err := service.DB.Create(&reviewer).Error; err != nil {
		t.Fatal(err)
	}
	assignment, err := service.AssignGuidelineReviewer(version.ID, actorID, AssignGuidelineReviewerInput{ReviewerID: reviewer.ID})
	if err != nil {
		t.Fatal(err)
	}
	if assignment.ReviewerID != reviewer.ID || assignment.AssignedBy == nil || *assignment.AssignedBy != actorID {
		t.Fatalf("actor ownership was not derived: %#v", assignment)
	}

	draft, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{Content: "# Reviewed draft", SourceType: "blank"})
	if err != nil {
		t.Fatal(err)
	}
	comment, err := service.CreateGuidelineEditorComment(version.ID, reviewer.ID, CreateGuidelineEditorCommentInput{RevisionID: &draft.Revision.ID, Body: "  Verify this recommendation.  "})
	if err != nil {
		t.Fatal(err)
	}
	if comment.AuthorID != reviewer.ID || comment.Body != "Verify this recommendation." {
		t.Fatalf("unexpected comment: %#v", comment)
	}
	resolved, err := service.ResolveGuidelineEditorComment(version.ID, comment.ID, actorID, true)
	if err != nil {
		t.Fatal(err)
	}
	if !resolved.Resolved || resolved.ResolvedBy == nil || *resolved.ResolvedBy != actorID {
		t.Fatalf("resolution audit missing: %#v", resolved)
	}

	rows, err := service.ListGuidelineEditorComments(version.ID, nil)
	if err != nil || len(rows) != 1 {
		t.Fatalf("version-scoped comments: rows=%d err=%v", len(rows), err)
	}
}
