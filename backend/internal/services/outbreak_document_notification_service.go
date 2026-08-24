package services

import (
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// OutbreakDocumentNotificationService turns clinical document lifecycle
// changes into idempotent, typed in-app notifications. Lifecycle callers pass
// their transaction so the publication and its notification cannot diverge.
type OutbreakDocumentNotificationService struct {
	DB                 *gorm.DB
	AllowedActionHosts []string
	Clock              func() time.Time
}

func (s OutbreakDocumentNotificationService) now() time.Time {
	if s.Clock != nil {
		return s.Clock().UTC()
	}
	return time.Now().UTC()
}

func (s OutbreakDocumentNotificationService) NotifyTransitionTx(
	tx *gorm.DB,
	actor OutbreakActor,
	outbreakID, documentID uuid.UUID,
	action string,
) error {
	var document models.OutbreakResource
	if err := tx.First(&document, "id = ? AND outbreak_id = ?", documentID, outbreakID).Error; err != nil {
		return err
	}
	var outbreak models.Outbreak
	if err := tx.First(&outbreak, "id = ?", outbreakID).Error; err != nil {
		return err
	}

	title := ""
	message := ""
	permission := ""
	priority := "normal"
	actionType := NotificationActionOutbreak
	sourceEvent := action
	switch action {
	case "submit":
		title = "Outbreak document review requested"
		message = fmt.Sprintf("%s was submitted for clinician review in %s.", document.Title, outbreak.Title)
		permission = "outbreak.review"
	case "approve":
		title = "Outbreak document approved"
		message = fmt.Sprintf("%s has clinician approval and is ready to publish.", document.Title)
		permission = "outbreak.publish"
	case "publish":
		actionType = NotificationActionOutbreakDocument
		priority = "high"
		if document.SupersedesID != nil {
			title = "Replacement outbreak guidance published"
			message = fmt.Sprintf("A reviewed replacement for %s is now available.", document.Title)
			sourceEvent = "replacement_published"
		} else {
			title = "New outbreak guidance published"
			message = fmt.Sprintf("%s from %s is now available.", document.Title, document.IssuingAuthority)
		}
	case "withdraw":
		priority = "high"
		title = "Outbreak document withdrawn"
		message = fmt.Sprintf("%s is no longer current. Open the outbreak hub for current guidance.", document.Title)
	default:
		return ErrNotificationInvalid
	}

	recipients, err := outbreakNotificationRecipients(tx, permission)
	if err != nil {
		return err
	}
	if permission == "" {
		recipients = []*uuid.UUID{nil}
	}
	for _, recipient := range recipients {
		parameters := map[string]string{
			"outbreak_id":     outbreakID.String(),
			"dashboard_route": "/outbreaks/" + outbreakID.String() + "?document=" + documentID.String(),
		}
		resourceID := outbreakID.String()
		if actionType == NotificationActionOutbreakDocument {
			resourceID = documentID.String()
		}
		dedup := "outbreak-document:" + documentID.String() + ":" + sourceEvent
		var userID *string
		if recipient != nil {
			value := recipient.String()
			userID = &value
			dedup += ":" + value
		}
		sourceType := "outbreak_document"
		sourceID := documentID.String()
		_, err := (NotificationService{DB: tx, AllowedActionHosts: s.AllowedActionHosts}).CreateForActor(NotificationInput{
			UserID:           userID,
			Title:            title,
			Message:          message,
			Type:             "info",
			Priority:         priority,
			Action:           &NotificationAction{Type: actionType, ResourceID: &resourceID, Parameters: parameters},
			SourceType:       &sourceType,
			SourceID:         &sourceID,
			DeduplicationKey: &dedup,
		}, actor.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

// ProcessReviewReminders creates at most one reminder per document and due-date
// state. It is safe to invoke repeatedly from every worker poll.
func (s OutbreakDocumentNotificationService) ProcessReviewReminders() (int, error) {
	now := s.now()
	soon := now.Add(30 * 24 * time.Hour)
	var documents []models.OutbreakResource
	if err := s.DB.Where(
		"resource_type IN ? AND status = 'published' AND withdrawn_at IS NULL AND ((review_date IS NOT NULL AND review_date <= ?) OR (expires_at IS NOT NULL AND expires_at <= ?))",
		[]string{"managed_document", "downloadable_asset"}, soon, now,
	).Find(&documents).Error; err != nil {
		return 0, err
	}
	recipients, err := outbreakNotificationRecipients(s.DB, "outbreak.review")
	if err != nil {
		return 0, err
	}
	created := 0
	for _, document := range documents {
		state := "review_due"
		title := "Outbreak document review date approaching"
		message := fmt.Sprintf("Review %s before its clinical review date.", document.Title)
		date := document.ReviewDate
		if document.ExpiresAt != nil && !document.ExpiresAt.After(now) {
			state = "expired"
			title = "Outbreak document expired"
			message = fmt.Sprintf("%s has expired and is no longer shown publicly.", document.Title)
			date = document.ExpiresAt
		}
		if date == nil {
			continue
		}
		for _, recipient := range recipients {
			user := recipient.String()
			resource := document.OutbreakID.String()
			dedup := strings.Join([]string{"outbreak-document", document.ID.String(), state, date.UTC().Format("2006-01-02"), user}, ":")
			var existing int64
			if err := s.DB.Model(&models.Notification{}).Where("deduplication_key = ?", dedup).Count(&existing).Error; err != nil {
				return created, err
			}
			if existing > 0 {
				continue
			}
			sourceType := "outbreak_document"
			sourceID := document.ID.String()
			_, err := (NotificationService{DB: s.DB, AllowedActionHosts: s.AllowedActionHosts}).Create(NotificationInput{
				UserID:           &user,
				Title:            title,
				Message:          message,
				Type:             "warning",
				Priority:         "high",
				Action:           &NotificationAction{Type: NotificationActionOutbreak, ResourceID: &resource, Parameters: map[string]string{"dashboard_route": "/outbreaks/" + document.OutbreakID.String() + "?document=" + document.ID.String()}},
				SourceType:       &sourceType,
				SourceID:         &sourceID,
				DeduplicationKey: &dedup,
			})
			if err != nil {
				return created, err
			}
			created++
		}
	}
	return created, nil
}

func outbreakNotificationRecipients(db *gorm.DB, permission string) ([]*uuid.UUID, error) {
	if permission == "" {
		return nil, nil
	}
	var ids []uuid.UUID
	err := db.Raw(`
		SELECT DISTINCT users.id
		FROM users
		JOIN user_roles ON user_roles.user_id = users.id
		JOIN roles ON roles.id = user_roles.role_id AND roles.deleted_at IS NULL AND roles.is_active = true
		JOIN role_permissions ON role_permissions.role_id = roles.id
		JOIN permissions ON permissions.id = role_permissions.permission_id AND permissions.deleted_at IS NULL
		WHERE users.deleted_at IS NULL AND users.is_active = true
		  AND permissions.code IN (?, 'admin.all')`, permission).Scan(&ids).Error
	if err != nil {
		return nil, err
	}
	recipients := make([]*uuid.UUID, len(ids))
	for index := range ids {
		id := ids[index]
		recipients[index] = &id
	}
	return recipients, nil
}
