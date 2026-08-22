package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

var (
	ErrNotificationConflict   = errors.New("notification record was modified")
	ErrNotificationTransition = errors.New("invalid notification state transition")
	ErrNotificationApproval   = errors.New("notification campaign requires independent approval")
	templatePlaceholder       = regexp.MustCompile(`\{\{\s*([A-Za-z][A-Za-z0-9_.-]{0,63})\s*\}\}`)
	templateVariableName      = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_.-]{0,63}$`)
	templateKeyName           = regexp.MustCompile(`^[a-z][a-z0-9_.-]{0,63}$`)
	templateLocale            = regexp.MustCompile(`^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$`)
	templateHTMLTag           = regexp.MustCompile(`(?i)<\s*/?\s*[a-z!][^>]*>`)
)

type TemplateVariableRule struct {
	Type        string `json:"type"`
	Required    bool   `json:"required"`
	SampleValue any    `json:"sample_value,omitempty"`
}

type NotificationTemplateInput struct {
	Name           string                          `json:"name"`
	TemplateKey    string                          `json:"template_key"`
	Channel        string                          `json:"channel"`
	TitleTemplate  *string                         `json:"title_template"`
	BodyTemplate   string                          `json:"body_template"`
	ActionTemplate *NotificationAction             `json:"action_template"`
	VariableSchema map[string]TemplateVariableRule `json:"variable_schema"`
	Category       string                          `json:"category"`
	Locale         string                          `json:"locale"`
}

type NotificationTemplateVersionDTO struct {
	ID             uuid.UUID                       `json:"id"`
	TemplateID     uuid.UUID                       `json:"template_id"`
	Version        int                             `json:"version"`
	Channel        string                          `json:"channel"`
	TitleTemplate  *string                         `json:"title_template,omitempty"`
	BodyTemplate   string                          `json:"body_template"`
	ActionTemplate NotificationAction              `json:"action_template"`
	VariableSchema map[string]TemplateVariableRule `json:"variable_schema"`
	Category       string                          `json:"category"`
	Locale         string                          `json:"locale"`
	Status         string                          `json:"status"`
	CreatedBy      *uuid.UUID                      `json:"created_by,omitempty"`
	ReviewedBy     *uuid.UUID                      `json:"reviewed_by,omitempty"`
	PublishedAt    *time.Time                      `json:"published_at,omitempty"`
	CreatedAt      time.Time                       `json:"created_at"`
}

type NotificationTemplateDTO struct {
	ID             uuid.UUID                      `json:"id"`
	Name           string                         `json:"name"`
	TemplateKey    string                         `json:"template_key"`
	Status         string                         `json:"status"`
	CurrentVersion int                            `json:"current_version"`
	Locale         string                         `json:"locale"`
	CreatedBy      *uuid.UUID                     `json:"created_by,omitempty"`
	ReviewedBy     *uuid.UUID                     `json:"reviewed_by,omitempty"`
	Version        NotificationTemplateVersionDTO `json:"version"`
	CreatedAt      time.Time                      `json:"created_at"`
	UpdatedAt      time.Time                      `json:"updated_at"`
}

type NotificationTemplatePreviewInput struct {
	Variables map[string]any `json:"variables"`
}

type NotificationTemplatePreview struct {
	Title  string             `json:"title"`
	Body   string             `json:"body"`
	Action NotificationAction `json:"action"`
}

type NotificationAudienceDefinition struct {
	AllEligible            bool     `json:"all_eligible"`
	UserIDs                []string `json:"user_ids,omitempty"`
	RoleIDs                []string `json:"role_ids,omitempty"`
	Countries              []string `json:"countries,omitempty"`
	RegionIDs              []string `json:"region_ids,omitempty"`
	DistrictIDs            []string `json:"district_ids,omitempty"`
	FacilityIDs            []string `json:"facility_ids,omitempty"`
	FacilityLevelIDs       []string `json:"facility_level_ids,omitempty"`
	ProfessionalCategories []string `json:"professional_categories,omitempty"`
	Languages              []string `json:"languages,omitempty"`
	Platforms              []string `json:"platforms,omitempty"`
	ApplicationVersions    []string `json:"application_versions,omitempty"`
	PreferenceCategories   []string `json:"preference_categories,omitempty"`
}

type NotificationAudienceEstimate struct {
	EligibleUsers int64 `json:"eligible_users"`
	ActiveDevices int64 `json:"active_devices"`
}

type NotificationCampaignInput struct {
	Name              string                         `json:"name"`
	Type              string                         `json:"type"`
	TemplateVersionID uuid.UUID                      `json:"template_version_id"`
	Variables         map[string]any                 `json:"variables"`
	Audience          NotificationAudienceDefinition `json:"audience"`
	ScheduledAt       *time.Time                     `json:"scheduled_at"`
	Timezone          string                         `json:"timezone"`
	ExpiresAt         *time.Time                     `json:"expires_at"`
	TTLSeconds        *int                           `json:"ttl_seconds"`
	Priority          string                         `json:"priority"`
	CollapseKey       *string                        `json:"collapse_key"`
	RequestedChannels []string                       `json:"requested_channels"`
	IdempotencyKey    string                         `json:"idempotency_key"`
	LockVersion       int                            `json:"lock_version,omitempty"`
}

// GuidelineNotificationCampaignInput deliberately exposes only the editorial
// choices that are safe at the guideline boundary. The server selects the
// published template/version and derives all guideline variables and actions.
type GuidelineNotificationCampaignInput struct {
	Audience          NotificationAudienceDefinition `json:"audience"`
	ScheduledAt       *time.Time                     `json:"scheduled_at"`
	Timezone          string                         `json:"timezone"`
	Priority          string                         `json:"priority"`
	RequestedChannels []string                       `json:"requested_channels"`
	IdempotencyKey    string                         `json:"idempotency_key"`
}

// OutbreakNotificationCampaignInput deliberately omits template, action and
// source fields. Those values are selected and derived by the server so an
// editor cannot turn trusted public-health content into an arbitrary action.
type OutbreakNotificationCampaignInput struct {
	Kind              string                         `json:"kind" enums:"alert,update,status_change,closure,publication"`
	Audience          NotificationAudienceDefinition `json:"audience"`
	ScheduledAt       *time.Time                     `json:"scheduled_at"`
	Timezone          string                         `json:"timezone"`
	Priority          string                         `json:"priority" enums:"low,normal,high,urgent"`
	RequestedChannels []string                       `json:"requested_channels"`
	IdempotencyKey    string                         `json:"idempotency_key"`
	ConfirmedUrgent   bool                           `json:"confirmed_urgent"`
}

type NotificationCampaignDTO struct {
	ID                     uuid.UUID                      `json:"id"`
	Name                   string                         `json:"name"`
	Type                   string                         `json:"type"`
	Status                 string                         `json:"status"`
	TemplateVersionID      *uuid.UUID                     `json:"template_version_id,omitempty"`
	Variables              map[string]any                 `json:"variables"`
	RenderedTitle          string                         `json:"rendered_title"`
	RenderedBody           string                         `json:"rendered_body"`
	ActionSnapshot         NotificationAction             `json:"action_snapshot"`
	Audience               NotificationAudienceDefinition `json:"audience"`
	ResolvedRecipientCount int64                          `json:"resolved_recipient_count"`
	ScheduledAt            *time.Time                     `json:"scheduled_at,omitempty"`
	Timezone               string                         `json:"timezone"`
	ExpiresAt              *time.Time                     `json:"expires_at,omitempty"`
	TTLSeconds             *int                           `json:"ttl_seconds,omitempty"`
	Priority               string                         `json:"priority"`
	CollapseKey            *string                        `json:"collapse_key,omitempty"`
	RequestedChannels      []string                       `json:"requested_channels"`
	CreatedBy              *uuid.UUID                     `json:"created_by,omitempty"`
	ReviewedBy             *uuid.UUID                     `json:"reviewed_by,omitempty"`
	ReviewedAt             *time.Time                     `json:"reviewed_at,omitempty"`
	ApprovedBy             *uuid.UUID                     `json:"approved_by,omitempty"`
	ApprovedAt             *time.Time                     `json:"approved_at,omitempty"`
	StartedAt              *time.Time                     `json:"started_at,omitempty"`
	CompletedAt            *time.Time                     `json:"completed_at,omitempty"`
	CancelledAt            *time.Time                     `json:"cancelled_at,omitempty"`
	FailureReason          *string                        `json:"failure_reason,omitempty"`
	IdempotencyKey         string                         `json:"idempotency_key"`
	DispatchSnapshot       map[string]any                 `json:"dispatch_snapshot,omitempty"`
	LockVersion            int                            `json:"lock_version"`
	CreatedAt              time.Time                      `json:"created_at"`
	UpdatedAt              time.Time                      `json:"updated_at"`
}

type NotificationCampaignTransitionInput struct {
	LockVersion int        `json:"lock_version"`
	ScheduledAt *time.Time `json:"scheduled_at,omitempty"`
	Timezone    string     `json:"timezone,omitempty"`
	Reason      string     `json:"reason,omitempty"`
}

func (s NotificationService) ListTemplates(in NotificationAdminListInput) (*PageResult[NotificationTemplateDTO], error) {
	if (in.Type != "" && !oneOf(in.Type, "push", "email", "sms", "in-app")) || (in.Status != "" && !oneOf(in.Status, "draft", "published", "archived")) {
		return nil, ErrNotificationInvalid
	}
	page := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.NotificationTemplate{})
	if v := strings.TrimSpace(in.Search); v != "" {
		q = q.Where("LOWER(name) LIKE LOWER(?) OR LOWER(template_key) LIKE LOWER(?)", "%"+v+"%", "%"+v+"%")
	}
	if in.Status != "" {
		q = q.Where("status = ?", in.Status)
	}
	if in.Category != "" {
		q = q.Where("category = ?", in.Category)
	}
	if in.Type != "" {
		q = q.Where("type = ?", in.Type)
	}
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	var roots []models.NotificationTemplate
	if err := q.Order("name ASC").Limit(page.PerPage).Offset(page.Offset()).Find(&roots).Error; err != nil {
		return nil, err
	}
	items := make([]NotificationTemplateDTO, 0, len(roots))
	for i := range roots {
		dto, err := s.templateDTO(&roots[i])
		if err != nil {
			return nil, err
		}
		items = append(items, *dto)
	}
	return NewPageResult(items, page, total), nil
}

func (s NotificationService) GetTemplate(id uuid.UUID) (*NotificationTemplateDTO, error) {
	var root models.NotificationTemplate
	if err := s.DB.First(&root, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return s.templateDTO(&root)
}

func (s NotificationService) ListTemplateVersions(id uuid.UUID) ([]NotificationTemplateVersionDTO, error) {
	if _, err := s.GetTemplate(id); err != nil {
		return nil, err
	}
	var rows []models.NotificationTemplateVersion
	if err := s.DB.Where("template_id = ?", id).Order("version DESC").Find(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]NotificationTemplateVersionDTO, 0, len(rows))
	for i := range rows {
		dto, err := templateVersionDTO(rows[i])
		if err != nil {
			return nil, err
		}
		out = append(out, dto)
	}
	return out, nil
}

func (s NotificationService) SaveTemplate(id *uuid.UUID, in NotificationTemplateInput, actor uuid.UUID, ip string) (*NotificationTemplateDTO, error) {
	if err := validateTemplateInput(in); err != nil {
		return nil, err
	}
	var result *NotificationTemplateDTO
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var duplicate int64
		keyQuery := tx.Model(&models.NotificationTemplate{}).Where("template_key = ?", strings.TrimSpace(in.TemplateKey))
		if id != nil {
			keyQuery = keyQuery.Where("id <> ?", *id)
		}
		if err := keyQuery.Count(&duplicate).Error; err != nil {
			return err
		}
		if duplicate > 0 {
			return ErrNotificationConflict
		}
		schemaJSON, _ := json.Marshal(in.VariableSchema)
		root := models.NotificationTemplate{Name: strings.TrimSpace(in.Name), TemplateKey: strings.TrimSpace(in.TemplateKey), Type: in.Channel, Category: strings.TrimSpace(in.Category), Status: "draft", CurrentVersion: 1, Locale: normalizeLocale(in.Locale), CreatedBy: &actor, Subject: cleanOptional(in.TitleTemplate), Content: in.BodyTemplate, VariablesJSON: datatypes.JSON(schemaJSON)}
		versionNumber := 1
		if id == nil {
			if err := tx.Create(&root).Error; err != nil {
				return err
			}
		} else {
			if err := tx.First(&root, "id = ?", *id).Error; err != nil {
				return err
			}
			versionNumber = root.CurrentVersion + 1
			updates := map[string]any{"name": strings.TrimSpace(in.Name), "template_key": strings.TrimSpace(in.TemplateKey), "type": in.Channel, "category": strings.TrimSpace(in.Category), "status": "draft", "current_version": versionNumber, "locale": normalizeLocale(in.Locale), "subject": cleanOptional(in.TitleTemplate), "content": in.BodyTemplate, "variables_json": datatypes.JSON(schemaJSON)}
			if err := tx.Model(&root).Updates(updates).Error; err != nil {
				return err
			}
			if err := tx.First(&root, "id = ?", *id).Error; err != nil {
				return err
			}
		}
		action := in.ActionTemplate
		if action == nil {
			action = &NotificationAction{Type: NotificationActionNone, Parameters: map[string]string{}}
		}
		actionJSON, _ := json.Marshal(action)
		version := models.NotificationTemplateVersion{TemplateID: root.ID, Version: versionNumber, Channel: in.Channel, TitleTemplate: cleanOptional(in.TitleTemplate), BodyTemplate: in.BodyTemplate, ActionTemplate: datatypes.JSON(actionJSON), VariableSchema: datatypes.JSON(schemaJSON), Category: strings.TrimSpace(in.Category), Locale: normalizeLocale(in.Locale), Status: "draft", CreatedBy: &actor}
		if err := tx.Create(&version).Error; err != nil {
			return err
		}
		if err := writeNotificationAudit(tx, actor, "notification.template.version_created", "notification_template", root.ID, ip, map[string]any{"version": versionNumber}); err != nil {
			return err
		}
		var err error
		result, err = NotificationService{DB: tx, AllowedActionHosts: s.AllowedActionHosts}.GetTemplate(root.ID)
		return err
	})
	return result, err
}

func (s NotificationService) UpdateTemplateStatus(id uuid.UUID, status string, actor uuid.UUID, ip string) (*NotificationTemplateDTO, error) {
	if !oneOf(status, "published", "archived") {
		return nil, ErrNotificationInvalid
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var root models.NotificationTemplate
		if err := tx.First(&root, "id = ?", id).Error; err != nil {
			return err
		}
		now := time.Now().UTC()
		if status == "published" {
			result := tx.Model(&models.NotificationTemplateVersion{}).Where("template_id = ? AND version = ? AND status = 'draft'", id, root.CurrentVersion).Updates(map[string]any{"status": "published", "reviewed_by": actor, "published_at": now})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return ErrNotificationTransition
			}
		}
		if err := tx.Model(&root).Updates(map[string]any{"status": status, "reviewed_by": actor}).Error; err != nil {
			return err
		}
		return writeNotificationAudit(tx, actor, "notification.template."+status, "notification_template", id, ip, map[string]any{"version": root.CurrentVersion})
	})
	if err != nil {
		return nil, err
	}
	return s.GetTemplate(id)
}

func (s NotificationService) PreviewTemplateVersion(versionID uuid.UUID, variables map[string]any) (*NotificationTemplatePreview, error) {
	var version models.NotificationTemplateVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	return s.renderTemplate(version, variables)
}

type NotificationTemplateCloneInput struct {
	Name        string `json:"name"`
	TemplateKey string `json:"template_key"`
}

func (s NotificationService) CloneTemplate(id uuid.UUID, in NotificationTemplateCloneInput, actor uuid.UUID, ip string) (*NotificationTemplateDTO, error) {
	source, err := s.GetTemplate(id)
	if err != nil {
		return nil, err
	}
	name, key := strings.TrimSpace(in.Name), strings.TrimSpace(in.TemplateKey)
	if name == "" || key == "" {
		return nil, ErrNotificationInvalid
	}
	title := source.Version.TitleTemplate
	input := NotificationTemplateInput{Name: name, TemplateKey: key, Channel: source.Version.Channel, TitleTemplate: title, BodyTemplate: source.Version.BodyTemplate, ActionTemplate: &source.Version.ActionTemplate, VariableSchema: source.Version.VariableSchema, Category: source.Version.Category, Locale: source.Version.Locale}
	result, err := s.SaveTemplate(nil, input, actor, ip)
	if err == nil {
		_ = writeNotificationAudit(s.DB, actor, "notification.template.cloned", "notification_template", result.ID, ip, map[string]any{"source_template_id": id})
	}
	return result, err
}

func (s NotificationService) ListCampaigns(in NotificationAdminListInput) (*PageResult[NotificationCampaignDTO], error) {
	if (in.Type != "" && !oneOf(in.Type, "emergency", "update", "reminder", "marketing", "announcement")) || (in.Status != "" && !validCampaignStatus(in.Status)) {
		return nil, ErrNotificationInvalid
	}
	page := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.NotificationCampaign{})
	if v := strings.TrimSpace(in.Search); v != "" {
		q = q.Where("LOWER(name) LIKE LOWER(?)", "%"+v+"%")
	}
	if in.Type != "" {
		q = q.Where("type = ?", in.Type)
	}
	if in.Status != "" {
		q = q.Where("status = ?", in.Status)
	}
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.NotificationCampaign
	if err := q.Order("created_at DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]NotificationCampaignDTO, 0, len(rows))
	for _, row := range rows {
		dto, err := campaignDTO(row)
		if err != nil {
			return nil, err
		}
		items = append(items, dto)
	}
	return NewPageResult(items, page, total), nil
}

func (s NotificationService) GetCampaign(id uuid.UUID) (*NotificationCampaignDTO, error) {
	var row models.NotificationCampaign
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	dto, err := campaignDTO(row)
	return &dto, err
}

func (s NotificationService) SaveCampaign(id *uuid.UUID, in NotificationCampaignInput, actor uuid.UUID, ip string) (*NotificationCampaignDTO, error) {
	if err := validateCampaignInput(in); err != nil {
		return nil, err
	}
	var version models.NotificationTemplateVersion
	if err := s.DB.First(&version, "id = ? AND status = 'published'", in.TemplateVersionID).Error; err != nil {
		return nil, err
	}
	preview, err := s.renderTemplate(version, in.Variables)
	if err != nil {
		return nil, err
	}
	audienceJSON, _ := json.Marshal(in.Audience)
	channelsJSON, _ := json.Marshal(in.RequestedChannels)
	countriesJSON, _ := json.Marshal(in.Audience.Countries)
	rolesJSON, _ := json.Marshal(in.Audience.RoleIDs)
	actionJSON, _ := json.Marshal(preview.Action)
	variablesJSON, _ := json.Marshal(in.Variables)
	var result *NotificationCampaignDTO
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if id == nil {
			var existing models.NotificationCampaign
			err := tx.Where("idempotency_key = ?", strings.TrimSpace(in.IdempotencyKey)).First(&existing).Error
			if err == nil {
				if existing.RenderedTitle != preview.Title || existing.RenderedBody != preview.Body || existing.TemplateVersionID == nil || *existing.TemplateVersionID != in.TemplateVersionID {
					return ErrNotificationConflict
				}
				var mapErr error
				result, mapErr = NotificationService{DB: tx}.GetCampaign(existing.ID)
				return mapErr
			}
			if !errors.Is(err, gorm.ErrRecordNotFound) {
				return err
			}
		}
		item := models.NotificationCampaign{Name: strings.TrimSpace(in.Name), Type: strings.TrimSpace(in.Type), Status: "draft", TemplateVersionID: &in.TemplateVersionID, CampaignVariablesJSON: datatypes.JSON(variablesJSON), RenderedTitle: preview.Title, RenderedBody: preview.Body, ActionSnapshotJSON: datatypes.JSON(actionJSON), AudienceDefinitionJSON: datatypes.JSON(audienceJSON), ScheduledAt: in.ScheduledAt, Timezone: normalizeTimezone(in.Timezone), ExpiresAt: in.ExpiresAt, TTLSeconds: in.TTLSeconds, Priority: in.Priority, CollapseKey: cleanOptional(in.CollapseKey), RequestedChannelsJSON: datatypes.JSON(channelsJSON), CreatedBy: &actor, IdempotencyKey: strings.TrimSpace(in.IdempotencyKey), LockVersion: 1, ChannelsJSON: datatypes.JSON(channelsJSON), AudienceCountriesJSON: datatypes.JSON(countriesJSON), AudienceRolesJSON: datatypes.JSON(rolesJSON)}
		if id == nil {
			if err := tx.Create(&item).Error; err != nil {
				return err
			}
		} else {
			var existing models.NotificationCampaign
			if err := tx.First(&existing, "id = ?", *id).Error; err != nil {
				return err
			}
			if existing.Status != "draft" {
				return ErrNotificationTransition
			}
			if in.LockVersion != existing.LockVersion {
				return ErrNotificationConflict
			}
			item.Base = existing.Base
			item.CreatedBy = existing.CreatedBy
			item.LockVersion = existing.LockVersion + 1
			result := tx.Model(&existing).Where("lock_version = ?", in.LockVersion).Updates(item)
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return ErrNotificationConflict
			}
		}
		if err := writeNotificationAudit(tx, actor, "notification.campaign.saved", "notification_campaign", item.ID, ip, map[string]any{"lock_version": item.LockVersion}); err != nil {
			return err
		}
		var err error
		result, err = NotificationService{DB: tx}.GetCampaign(item.ID)
		return err
	})
	return result, err
}

// CreateGuidelineCampaign creates a draft in the normal campaign approval
// workflow. It never dispatches and it refuses documents whose selected
// current version is not published.
func (s NotificationService) CreateGuidelineCampaign(documentID uuid.UUID, in GuidelineNotificationCampaignInput, actor uuid.UUID, ip string) (*NotificationCampaignDTO, error) {
	var document models.GuidelineDocument
	if err := s.DB.First(&document, "id = ?", documentID).Error; err != nil {
		return nil, err
	}
	if document.CurrentVersionID == nil {
		return nil, ErrNotificationInvalid
	}
	var guidelineVersion models.GuidelineVersion
	if err := s.DB.First(&guidelineVersion, "id = ? AND document_id = ? AND status = 'published'", *document.CurrentVersionID, document.ID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotificationInvalid
		}
		return nil, err
	}

	var template models.NotificationTemplate
	if err := s.DB.First(&template, "template_key = ? AND status = 'published'", "guideline-update").Error; err != nil {
		return nil, err
	}
	var templateVersion models.NotificationTemplateVersion
	if err := s.DB.First(&templateVersion, "template_id = ? AND version = ? AND status = 'published'", template.ID, template.CurrentVersion).Error; err != nil {
		return nil, err
	}

	return s.SaveCampaign(nil, NotificationCampaignInput{
		Name:              "Guideline update: " + document.Title,
		Type:              "update",
		TemplateVersionID: templateVersion.ID,
		Variables: map[string]any{
			"guideline_id": document.ID.String(),
			"title":        document.Title,
			"version":      guidelineVersion.Version,
		},
		Audience:          in.Audience,
		ScheduledAt:       in.ScheduledAt,
		Timezone:          in.Timezone,
		Priority:          in.Priority,
		RequestedChannels: in.RequestedChannels,
		IdempotencyKey:    in.IdempotencyKey,
	}, actor, ip)
}

// CreateOutbreakCampaign creates a draft campaign from an explicitly
// published outbreak. It never submits, approves, schedules or dispatches it.
func (s NotificationService) CreateOutbreakCampaign(outbreakID uuid.UUID, in OutbreakNotificationCampaignInput, actor uuid.UUID, ip string) (*NotificationCampaignDTO, error) {
	var outbreak models.Outbreak
	if err := s.DB.First(&outbreak, "id = ? AND published_at IS NOT NULL AND withdrawn_at IS NULL AND status IN ?", outbreakID, []string{"published", "active", "monitoring", "contained", "closed"}).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotificationInvalid
		}
		return nil, err
	}
	kind := strings.TrimSpace(in.Kind)
	if kind == "" {
		kind = "alert"
	}
	key := map[string]string{"alert": "outbreak-alert", "update": "outbreak-update", "status_change": "outbreak-status-change", "closure": "outbreak-status-change"}[kind]
	if key == "" || in.Priority == "urgent" && !in.ConfirmedUrgent {
		return nil, ErrNotificationInvalid
	}
	version, err := s.currentPublishedTemplateVersion(key)
	if err != nil {
		return nil, err
	}
	return s.SaveCampaign(nil, NotificationCampaignInput{
		Name: "Outbreak notification: " + outbreak.Title, Type: "emergency",
		TemplateVersionID: version.ID,
		Variables:         map[string]any{"outbreak_id": outbreak.ID.String(), "title": outbreak.Title, "status": outbreak.Status, "area": outbreak.GeographicArea, "data_as_of": formatOptionalTime(outbreak.DataAsOf)},
		Audience:          in.Audience, ScheduledAt: in.ScheduledAt, Timezone: in.Timezone,
		Priority: in.Priority, RequestedChannels: in.RequestedChannels, IdempotencyKey: in.IdempotencyKey,
	}, actor, ip)
}

// CreateSituationReportCampaign creates a draft campaign from published,
// visible report content. Parent outbreak visibility is checked independently.
func (s NotificationService) CreateSituationReportCampaign(reportID uuid.UUID, in OutbreakNotificationCampaignInput, actor uuid.UUID, ip string) (*NotificationCampaignDTO, error) {
	if kind := strings.TrimSpace(in.Kind); kind != "" && kind != "publication" {
		return nil, ErrNotificationInvalid
	}
	var report models.SituationReport
	if err := s.DB.First(&report, "id = ? AND status = 'published' AND published_at IS NOT NULL AND withdrawn_at IS NULL", reportID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotificationInvalid
		}
		return nil, err
	}
	if report.OutbreakID != nil {
		var visible int64
		if err := s.DB.Model(&models.Outbreak{}).Where("id = ? AND published_at IS NOT NULL AND withdrawn_at IS NULL AND status IN ?", *report.OutbreakID, []string{"published", "active", "monitoring", "contained", "closed"}).Count(&visible).Error; err != nil {
			return nil, err
		}
		if visible != 1 {
			return nil, ErrNotificationInvalid
		}
	}
	if in.Priority == "urgent" && !in.ConfirmedUrgent {
		return nil, ErrNotificationInvalid
	}
	version, err := s.currentPublishedTemplateVersion("situation-report-publication")
	if err != nil {
		return nil, err
	}
	return s.SaveCampaign(nil, NotificationCampaignInput{
		Name: "Situation report: " + report.Title, Type: "update", TemplateVersionID: version.ID,
		Variables: map[string]any{"situation_report_id": report.ID.String(), "title": report.Title, "area": report.GeographicArea, "publication_date": report.PublicationDate.UTC().Format("2006-01-02")},
		Audience:  in.Audience, ScheduledAt: in.ScheduledAt, Timezone: in.Timezone,
		Priority: in.Priority, RequestedChannels: in.RequestedChannels, IdempotencyKey: in.IdempotencyKey,
	}, actor, ip)
}

func (s NotificationService) currentPublishedTemplateVersion(key string) (*models.NotificationTemplateVersion, error) {
	var template models.NotificationTemplate
	if err := s.DB.First(&template, "template_key = ? AND status = 'published'", key).Error; err != nil {
		return nil, err
	}
	var version models.NotificationTemplateVersion
	if err := s.DB.First(&version, "template_id = ? AND version = ? AND status = 'published'", template.ID, template.CurrentVersion).Error; err != nil {
		return nil, err
	}
	return &version, nil
}

func formatOptionalTime(value *time.Time) string {
	if value == nil {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}

func (s NotificationService) TransitionCampaign(id uuid.UUID, action string, in NotificationCampaignTransitionInput, actor uuid.UUID, ip string) (*NotificationCampaignDTO, error) {
	now := time.Now().UTC()
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var item models.NotificationCampaign
		if err := tx.First(&item, "id = ?", id).Error; err != nil {
			return err
		}
		if in.LockVersion != item.LockVersion {
			return ErrNotificationConflict
		}
		updates := map[string]any{"lock_version": item.LockVersion + 1}
		switch action {
		case "submit":
			if item.Status != "draft" {
				return ErrNotificationTransition
			}
			updates["status"] = "pending_review"
		case "reject":
			if item.Status != "pending_review" || strings.TrimSpace(in.Reason) == "" {
				return ErrNotificationTransition
			}
			updates["status"] = "draft"
			updates["reviewed_by"] = actor
			updates["reviewed_at"] = now
			updates["failure_reason"] = strings.TrimSpace(in.Reason)
		case "approve":
			if item.Status != "pending_review" {
				return ErrNotificationTransition
			}
			if item.CreatedBy != nil && *item.CreatedBy == actor && requiresIndependentApproval(item) {
				return ErrNotificationApproval
			}
			item.Status = "approved"
			item.ReviewedBy = &actor
			item.ReviewedAt = &now
			item.ApprovedBy = &actor
			item.ApprovedAt = &now
			item.FailureReason = nil
			estimate, err := s.prepareCampaignDispatch(tx, &item)
			if err != nil {
				return err
			}
			item.ResolvedRecipientCount = estimate.EligibleUsers
			snapshot, err := campaignDispatchSnapshot(item, now)
			if err != nil {
				return err
			}
			updates["status"] = "approved"
			updates["reviewed_by"] = actor
			updates["reviewed_at"] = now
			updates["approved_by"] = actor
			updates["approved_at"] = now
			updates["resolved_recipient_count"] = estimate.EligibleUsers
			updates["dispatch_snapshot_json"] = snapshot
			updates["failure_reason"] = nil
		case "schedule":
			if item.Status != "approved" {
				return ErrNotificationTransition
			}
			if item.ExpiresAt != nil && !item.ExpiresAt.After(now) {
				return ErrNotificationInvalid
			}
			scheduled := in.ScheduledAt
			if scheduled == nil {
				scheduled = item.ScheduledAt
			}
			if scheduled == nil {
				scheduled = &now
			}
			if item.ExpiresAt != nil && !item.ExpiresAt.After(*scheduled) {
				return ErrNotificationInvalid
			}
			timezone := strings.TrimSpace(in.Timezone)
			if timezone == "" {
				timezone = item.Timezone
			}
			if _, err := time.LoadLocation(timezone); err != nil {
				return ErrNotificationInvalid
			}
			updates["scheduled_at"] = scheduled.UTC()
			updates["timezone"] = timezone
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status = 'held'", item.ID).Updates(map[string]any{"status": "pending", "next_attempt_at": gorm.Expr("CASE WHEN next_attempt_at > ? THEN next_attempt_at ELSE ? END", scheduled.UTC(), scheduled.UTC())}).Error; err != nil {
				return err
			}
			if err := tx.Model(&models.Notification{}).Where("campaign_id = ?", item.ID).Update("publish_at", scheduled.UTC()).Error; err != nil {
				return err
			}
			if scheduled.After(now) {
				updates["status"] = "scheduled"
			} else {
				updates["status"] = "queued"
			}
			var externalJobs int64
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status = 'pending'", item.ID).Count(&externalJobs).Error; err != nil {
				return err
			}
			if externalJobs == 0 {
				updates["status"] = "completed"
				updates["started_at"] = now
				updates["completed_at"] = now
			}
		case "pause":
			if !oneOf(item.Status, "scheduled", "queued") || item.StartedAt != nil {
				return ErrNotificationTransition
			}
			updates["status"] = "paused"
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status IN ?", item.ID, []string{"pending", "retry"}).Update("status", "held").Error; err != nil {
				return err
			}
		case "resume":
			if item.Status != "paused" || item.StartedAt != nil {
				return ErrNotificationTransition
			}
			status := "queued"
			next := now
			if item.ScheduledAt != nil && item.ScheduledAt.After(now) {
				status = "scheduled"
				next = *item.ScheduledAt
			}
			updates["status"] = status
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status = 'held'", item.ID).Updates(map[string]any{"status": "pending", "next_attempt_at": next}).Error; err != nil {
				return err
			}
		case "cancel":
			if !oneOf(item.Status, "draft", "pending_review", "approved", "scheduled", "queued", "paused") || item.StartedAt != nil {
				return ErrNotificationTransition
			}
			updates["status"] = "cancelled"
			updates["cancelled_at"] = now
			updates["failure_reason"] = cleanOptional(&in.Reason)
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status IN ?", item.ID, []string{"held", "pending", "retry"}).Updates(map[string]any{"status": "cancelled", "completed_at": now, "last_error_code": "campaign_cancelled"}).Error; err != nil {
				return err
			}
			if err := tx.Model(&models.NotificationDelivery{}).Where("campaign_id = ? AND state IN ?", item.ID, []string{"queued", "attempted"}).Updates(map[string]any{"state": "rejected", "failed_at": now, "error_category": "campaign_cancelled", "updated_at": now}).Error; err != nil {
				return err
			}
			if err := tx.Model(&models.Notification{}).Where("campaign_id = ?", item.ID).Update("expires_at", now).Error; err != nil {
				return err
			}
		default:
			return ErrNotificationInvalid
		}
		result := tx.Model(&models.NotificationCampaign{}).Where("id = ? AND lock_version = ?", id, in.LockVersion).Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected != 1 {
			return ErrNotificationConflict
		}
		return writeNotificationAudit(tx, actor, "notification.campaign."+action, "notification_campaign", id, ip, map[string]any{"from": item.Status, "lock_version": item.LockVersion + 1})
	})
	if err != nil {
		return nil, err
	}
	return s.GetCampaign(id)
}

// AdvanceCampaignDelivery is the guarded state transition used by a durable
// delivery worker. It intentionally has no public HTTP route.
func (s NotificationService) AdvanceCampaignDelivery(id uuid.UUID, fromVersion int, target, failureReason string) (*NotificationCampaignDTO, error) {
	now := time.Now().UTC()
	updates := map[string]any{"status": target, "lock_version": fromVersion + 1}
	var current string
	switch target {
	case "sending":
		current = "queued"
		updates["started_at"] = now
	case "completed", "partially_failed", "failed":
		current = "sending"
		updates["completed_at"] = now
		if target != "completed" {
			if strings.TrimSpace(failureReason) == "" {
				return nil, ErrNotificationInvalid
			}
			updates["failure_reason"] = strings.TrimSpace(failureReason)
		}
	default:
		return nil, ErrNotificationTransition
	}
	result := s.DB.Model(&models.NotificationCampaign{}).Where("id = ? AND status = ? AND lock_version = ?", id, current, fromVersion).Updates(updates)
	if result.Error != nil {
		return nil, result.Error
	}
	if result.RowsAffected != 1 {
		return nil, ErrNotificationConflict
	}
	return s.GetCampaign(id)
}

func (s NotificationService) templateDTO(root *models.NotificationTemplate) (*NotificationTemplateDTO, error) {
	var version models.NotificationTemplateVersion
	if err := s.DB.First(&version, "template_id = ? AND version = ?", root.ID, root.CurrentVersion).Error; err != nil {
		return nil, err
	}
	vdto, err := templateVersionDTO(version)
	if err != nil {
		return nil, err
	}
	return &NotificationTemplateDTO{ID: root.ID, Name: root.Name, TemplateKey: root.TemplateKey, Status: root.Status, CurrentVersion: root.CurrentVersion, Locale: root.Locale, CreatedBy: root.CreatedBy, ReviewedBy: root.ReviewedBy, Version: vdto, CreatedAt: root.CreatedAt, UpdatedAt: root.UpdatedAt}, nil
}

func templateVersionDTO(row models.NotificationTemplateVersion) (NotificationTemplateVersionDTO, error) {
	action := NotificationAction{Type: NotificationActionNone, Parameters: map[string]string{}}
	schema := map[string]TemplateVariableRule{}
	if len(row.ActionTemplate) > 0 {
		if err := json.Unmarshal(row.ActionTemplate, &action); err != nil {
			return NotificationTemplateVersionDTO{}, err
		}
	}
	if len(row.VariableSchema) > 0 {
		if err := json.Unmarshal(row.VariableSchema, &schema); err != nil {
			return NotificationTemplateVersionDTO{}, err
		}
	}
	return NotificationTemplateVersionDTO{ID: row.ID, TemplateID: row.TemplateID, Version: row.Version, Channel: row.Channel, TitleTemplate: row.TitleTemplate, BodyTemplate: row.BodyTemplate, ActionTemplate: action, VariableSchema: schema, Category: row.Category, Locale: row.Locale, Status: row.Status, CreatedBy: row.CreatedBy, ReviewedBy: row.ReviewedBy, PublishedAt: row.PublishedAt, CreatedAt: row.CreatedAt}, nil
}

func campaignDTO(row models.NotificationCampaign) (NotificationCampaignDTO, error) {
	action := NotificationAction{Type: NotificationActionNone, Parameters: map[string]string{}}
	audience := NotificationAudienceDefinition{}
	channels := []string{}
	snapshot := map[string]any{}
	variables := map[string]any{}
	if len(row.ActionSnapshotJSON) > 0 {
		if err := json.Unmarshal(row.ActionSnapshotJSON, &action); err != nil {
			return NotificationCampaignDTO{}, err
		}
	}
	if len(row.AudienceDefinitionJSON) > 0 {
		if err := json.Unmarshal(row.AudienceDefinitionJSON, &audience); err != nil {
			return NotificationCampaignDTO{}, err
		}
	}
	if len(row.RequestedChannelsJSON) > 0 {
		if err := json.Unmarshal(row.RequestedChannelsJSON, &channels); err != nil {
			return NotificationCampaignDTO{}, err
		}
	}
	if len(row.DispatchSnapshotJSON) > 0 {
		_ = json.Unmarshal(row.DispatchSnapshotJSON, &snapshot)
	}
	if len(row.CampaignVariablesJSON) > 0 {
		if err := json.Unmarshal(row.CampaignVariablesJSON, &variables); err != nil {
			return NotificationCampaignDTO{}, err
		}
	}
	return NotificationCampaignDTO{ID: row.ID, Name: row.Name, Type: row.Type, Status: row.Status, TemplateVersionID: row.TemplateVersionID, Variables: variables, RenderedTitle: row.RenderedTitle, RenderedBody: row.RenderedBody, ActionSnapshot: action, Audience: audience, ResolvedRecipientCount: row.ResolvedRecipientCount, ScheduledAt: row.ScheduledAt, Timezone: row.Timezone, ExpiresAt: row.ExpiresAt, TTLSeconds: row.TTLSeconds, Priority: row.Priority, CollapseKey: row.CollapseKey, RequestedChannels: channels, CreatedBy: row.CreatedBy, ReviewedBy: row.ReviewedBy, ReviewedAt: row.ReviewedAt, ApprovedBy: row.ApprovedBy, ApprovedAt: row.ApprovedAt, StartedAt: row.StartedAt, CompletedAt: row.CompletedAt, CancelledAt: row.CancelledAt, FailureReason: row.FailureReason, IdempotencyKey: row.IdempotencyKey, DispatchSnapshot: snapshot, LockVersion: row.LockVersion, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}, nil
}

func validateTemplateInput(in NotificationTemplateInput) error {
	if strings.TrimSpace(in.Name) == "" || !templateKeyName.MatchString(strings.TrimSpace(in.TemplateKey)) || !templateLocale.MatchString(normalizeLocale(in.Locale)) || !oneOf(in.Channel, "push", "email", "sms", "in-app") || !oneOf(strings.TrimSpace(in.Category), "Content Updates", "Emergency", "Training", "System", "Marketing", "Reminder") {
		return ErrNotificationInvalid
	}
	if _, err := renderRestrictedTemplate(in.BodyTemplate, in.VariableSchema, sampleVariables(in.VariableSchema)); err != nil {
		return err
	}
	if in.TitleTemplate != nil {
		if _, err := renderRestrictedTemplate(*in.TitleTemplate, in.VariableSchema, sampleVariables(in.VariableSchema)); err != nil {
			return err
		}
	}
	if in.ActionTemplate != nil {
		encoded, err := json.Marshal(in.ActionTemplate)
		if err != nil {
			return ErrNotificationInvalid
		}
		if _, err := renderRestrictedTemplate(string(encoded), in.VariableSchema, sampleVariables(in.VariableSchema)); err != nil {
			return err
		}
	}
	for key, rule := range in.VariableSchema {
		if !templateVariableName.MatchString(key) || !oneOf(rule.Type, "string", "number", "boolean", "date") {
			return ErrNotificationInvalid
		}
	}
	if len(in.BodyTemplate) > bodyLimit(in.Channel) || (in.TitleTemplate != nil && len(*in.TitleTemplate) > titleLimit(in.Channel)) {
		return ErrNotificationInvalid
	}
	return nil
}

func validateCampaignInput(in NotificationCampaignInput) error {
	if strings.TrimSpace(in.Name) == "" || in.TemplateVersionID == uuid.Nil || !oneOf(in.Type, "emergency", "update", "reminder", "marketing", "announcement") || !oneOf(in.Priority, "low", "normal", "high", "urgent") || strings.TrimSpace(in.IdempotencyKey) == "" || len(in.IdempotencyKey) > 200 || len(in.RequestedChannels) == 0 {
		return ErrNotificationInvalid
	}
	for _, channel := range in.RequestedChannels {
		if !oneOf(channel, "push", "email", "sms", "in-app") {
			return ErrNotificationInvalid
		}
	}
	if err := validateNotificationAudience(in.Audience); err != nil {
		return ErrNotificationInvalid
	}
	if in.ScheduledAt != nil && in.ExpiresAt != nil && !in.ExpiresAt.After(*in.ScheduledAt) {
		return ErrNotificationInvalid
	}
	if strings.TrimSpace(in.Timezone) != "" {
		if _, err := time.LoadLocation(strings.TrimSpace(in.Timezone)); err != nil {
			return ErrNotificationInvalid
		}
	}
	if in.ExpiresAt != nil && !in.ExpiresAt.After(time.Now().UTC()) {
		return ErrNotificationInvalid
	}
	if in.TTLSeconds != nil && (*in.TTLSeconds < 60 || *in.TTLSeconds > 2419200) {
		return ErrNotificationInvalid
	}
	return nil
}

func (s NotificationService) renderTemplate(version models.NotificationTemplateVersion, variables map[string]any) (*NotificationTemplatePreview, error) {
	schema := map[string]TemplateVariableRule{}
	if err := json.Unmarshal(version.VariableSchema, &schema); err != nil {
		return nil, ErrNotificationInvalid
	}
	body, err := renderRestrictedTemplate(version.BodyTemplate, schema, variables)
	if err != nil {
		return nil, err
	}
	title := ""
	if version.TitleTemplate != nil {
		title, err = renderRestrictedTemplate(*version.TitleTemplate, schema, variables)
		if err != nil {
			return nil, err
		}
	}
	actionText, err := renderRestrictedTemplate(string(version.ActionTemplate), schema, variables)
	if err != nil {
		return nil, err
	}
	action := NotificationAction{}
	if err := json.Unmarshal([]byte(actionText), &action); err != nil {
		return nil, ErrNotificationInvalid
	}
	if err := s.validateTemplateActionShape(action); err != nil {
		return nil, err
	}
	if len(title) > titleLimit(version.Channel) || len(body) > bodyLimit(version.Channel) {
		return nil, ErrNotificationInvalid
	}
	return &NotificationTemplatePreview{Title: title, Body: body, Action: action}, nil
}

func (s NotificationService) validateTemplateActionShape(action NotificationAction) error {
	if action.Type == "" {
		action.Type = NotificationActionNone
	}
	switch action.Type {
	case NotificationActionNone:
		if action.ResourceID != nil || action.Route != nil || len(action.Parameters) > 0 {
			return ErrNotificationInvalid
		}
	case NotificationActionInternalRoute:
		if action.ResourceID != nil || action.Route == nil || !validNotificationInternalRoute(*action.Route) {
			return ErrNotificationInvalid
		}
	case NotificationActionExternalURL:
		if action.ResourceID != nil || action.Route == nil || !s.validApprovedExternalURL(*action.Route) {
			return ErrNotificationInvalid
		}
	default:
		if _, ok := notificationResourceTables[action.Type]; !ok || action.ResourceID == nil {
			return ErrNotificationInvalid
		}
		if _, err := uuid.Parse(*action.ResourceID); err != nil {
			return ErrNotificationInvalid
		}
	}
	if len(action.Parameters) > 20 {
		return ErrNotificationInvalid
	}
	for key, value := range action.Parameters {
		_, reserved := notificationReservedParameters[strings.ToLower(key)]
		if !notificationParameterKey.MatchString(key) || len(value) > 512 || reserved {
			return ErrNotificationInvalid
		}
	}
	return nil
}

func renderRestrictedTemplate(text string, schema map[string]TemplateVariableRule, variables map[string]any) (string, error) {
	if strings.Contains(text, "{{{") || strings.Contains(text, "{%") || templateHTMLTag.MatchString(text) {
		return "", ErrNotificationInvalid
	}
	for key, rule := range schema {
		if rule.Required {
			if _, ok := variables[key]; !ok {
				return "", ErrNotificationInvalid
			}
		}
	}
	for key := range variables {
		if _, ok := schema[key]; !ok {
			return "", ErrNotificationInvalid
		}
	}
	invalid := false
	result := templatePlaceholder.ReplaceAllStringFunc(text, func(token string) string {
		key := templatePlaceholder.FindStringSubmatch(token)[1]
		value, ok := variables[key]
		if !ok {
			invalid = true
			return ""
		}
		if !validVariableValue(schema[key].Type, value) {
			invalid = true
			return ""
		}
		return fmt.Sprint(value)
	})
	if invalid || templatePlaceholder.MatchString(result) {
		return "", ErrNotificationInvalid
	}
	return result, nil
}

func validVariableValue(kind string, value any) bool {
	switch kind {
	case "string", "date":
		_, ok := value.(string)
		return ok
	case "boolean":
		_, ok := value.(bool)
		return ok
	case "number":
		switch value.(type) {
		case int, int32, int64, float32, float64, json.Number:
			return true
		}
		return false
	default:
		return false
	}
}

func sampleVariables(schema map[string]TemplateVariableRule) map[string]any {
	out := map[string]any{}
	keys := make([]string, 0, len(schema))
	for key := range schema {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		rule := schema[key]
		if rule.SampleValue != nil {
			out[key] = rule.SampleValue
		} else {
			switch rule.Type {
			case "number":
				out[key] = 1
			case "boolean":
				out[key] = true
			case "date":
				out[key] = "2026-01-01"
			default:
				out[key] = key
			}
		}
	}
	return out
}
func titleLimit(channel string) int {
	if channel == "email" {
		return 998
	}
	return 200
}
func bodyLimit(channel string) int {
	switch channel {
	case "sms":
		return 1600
	case "email":
		return 100000
	default:
		return 4000
	}
}
func normalizeLocale(v string) string {
	v = strings.TrimSpace(v)
	if v == "" {
		return "en"
	}
	return v
}
func normalizeTimezone(v string) string {
	v = strings.TrimSpace(v)
	if v == "" {
		return "UTC"
	}
	if _, err := time.LoadLocation(v); err != nil {
		return "UTC"
	}
	return v
}
func validCampaignStatus(v string) bool {
	return oneOf(v, "draft", "pending_review", "approved", "scheduled", "queued", "paused", "sending", "completed", "partially_failed", "failed", "cancelled")
}
func requiresIndependentApproval(item models.NotificationCampaign) bool {
	if item.Priority == "urgent" || item.Type == "emergency" {
		return true
	}
	var audience NotificationAudienceDefinition
	_ = json.Unmarshal(item.AudienceDefinitionJSON, &audience)
	return audience.AllEligible
}
func campaignDispatchSnapshot(item models.NotificationCampaign, approvedAt time.Time) (datatypes.JSON, error) {
	dto, err := campaignDTO(item)
	if err != nil {
		return nil, err
	}
	payload, err := json.Marshal(map[string]any{"campaign": dto, "approved_at": approvedAt})
	return datatypes.JSON(payload), err
}
func cleanOptional(value *string) *string {
	if value == nil {
		return nil
	}
	v := strings.TrimSpace(*value)
	if v == "" {
		return nil
	}
	return &v
}
func writeNotificationAudit(tx *gorm.DB, actor uuid.UUID, action, entityType string, entityID uuid.UUID, ip string, metadata any) error {
	payload, err := json.Marshal(metadata)
	if err != nil {
		return err
	}
	return tx.Create(&models.AuditLog{ActorID: actor.String(), Action: action, EntityType: entityType, EntityID: entityID.String(), MetadataJSON: string(payload), IPAddress: ip}).Error
}
