package services

import (
	"encoding/json"
	"net/url"
	"regexp"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

const (
	NotificationActionNone            = "none"
	NotificationActionGuideline       = "guideline"
	NotificationActionOutbreak        = "outbreak"
	NotificationActionSituationReport = "situation_report"
	NotificationActionDrug            = "drug"
	NotificationActionCalculator      = "calculator"
	NotificationActionFacility        = "facility"
	NotificationActionSupportTicket   = "support_ticket"
	NotificationActionInternalRoute   = "internal_route"
	NotificationActionExternalURL     = "approved_external_url"
)

type NotificationAction = models.NotificationAction

var notificationParameterKey = regexp.MustCompile(`^[A-Za-z0-9_.-]{1,64}$`)

var notificationReservedParameters = map[string]struct{}{
	"redirect": {}, "redirect_uri": {}, "redirect_url": {}, "return_to": {},
	"return_url": {}, "next": {}, "url": {}, "uri": {}, "deeplink": {},
}

var notificationInternalRoutes = map[string]struct{}{
	"/main": {}, "/home": {}, "/search": {}, "/guidelines": {},
	"/public/guidelines": {}, "/tools": {}, "/profile": {}, "/library": {},
	"/offline-content": {}, "/outbreak-hub": {}, "/situation-reports": {},
	"/drug-index": {}, "/abbreviations": {}, "/health-infrastructure": {},
	"/health-facilities": {}, "/consultants": {}, "/ministry-directory": {},
	"/calculators": {}, "/ai-assistant": {}, "/chats": {}, "/all-actions": {},
	"/notifications": {}, "/help-center": {}, "/faq": {}, "/about-us": {},
	"/terms-and-conditions": {},
}

var notificationResourceTables = map[string]string{
	NotificationActionGuideline:       "guideline_documents",
	NotificationActionOutbreak:        "outbreaks",
	NotificationActionSituationReport: "situation_reports",
	NotificationActionDrug:            "drugs",
	NotificationActionCalculator:      "calculators",
	NotificationActionFacility:        "health_facilities",
	NotificationActionSupportTicket:   "support_tickets",
}

func (s NotificationService) ResolveAction(input *NotificationAction, legacyURL *string, recipientID *uuid.UUID) (NotificationAction, *string, error) {
	if input == nil {
		translated, err := s.translateLegacyAction(legacyURL)
		if err != nil {
			return NotificationAction{}, nil, err
		}
		input = &translated
	}

	action := NotificationAction{
		Type:       strings.TrimSpace(input.Type),
		ResourceID: cleanOptional(input.ResourceID),
		Route:      cleanOptional(input.Route),
		Parameters: input.Parameters,
	}
	if action.Type == "" {
		action.Type = NotificationActionNone
	}
	if action.Parameters == nil {
		action.Parameters = map[string]string{}
	}
	if len(action.Parameters) > 20 {
		return NotificationAction{}, nil, ErrNotificationInvalid
	}
	for key, value := range action.Parameters {
		_, reserved := notificationReservedParameters[strings.ToLower(key)]
		if !notificationParameterKey.MatchString(key) || len(value) > 512 || reserved {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
	}

	switch action.Type {
	case NotificationActionNone:
		if action.ResourceID != nil || action.Route != nil || len(action.Parameters) != 0 {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		return action, nil, nil
	case NotificationActionInternalRoute:
		if action.ResourceID != nil || action.Route == nil || !validNotificationInternalRoute(*action.Route) {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		return action, action.Route, nil
	case NotificationActionExternalURL:
		if action.ResourceID != nil || action.Route == nil || !s.validApprovedExternalURL(*action.Route) {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		return action, action.Route, nil
	default:
		table, ok := notificationResourceTables[action.Type]
		if !ok || action.ResourceID == nil {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		id, err := uuid.Parse(*action.ResourceID)
		if err != nil {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		query := s.DB.Table(table).Where("id = ? AND deleted_at IS NULL", id)
		if action.Type == NotificationActionSupportTicket {
			if recipientID == nil {
				return NotificationAction{}, nil, ErrNotificationInvalid
			}
			query = query.Where("user_id = ?", *recipientID)
		}
		var count int64
		if err := query.Count(&count).Error; err != nil {
			return NotificationAction{}, nil, err
		}
		if count != 1 {
			return NotificationAction{}, nil, ErrNotificationInvalid
		}
		route := notificationResourceRoute(action.Type, id)
		action.ResourceID = stringPointer(id.String())
		action.Route = &route
		return action, action.Route, nil
	}
}

func EncodeNotificationAction(action NotificationAction) ([]byte, error) {
	return json.Marshal(action)
}

func (s NotificationService) translateLegacyAction(value *string) (NotificationAction, error) {
	action := NotificationAction{Type: NotificationActionNone, Parameters: map[string]string{}}
	value = cleanOptional(value)
	if value == nil {
		return action, nil
	}
	if validNotificationInternalRoute(*value) {
		action.Type = NotificationActionInternalRoute
		action.Route = value
		return action, nil
	}
	parsed, err := url.Parse(*value)
	if err != nil {
		return NotificationAction{}, ErrNotificationInvalid
	}
	parts := strings.Split(strings.Trim(parsed.Path, "/"), "/")
	if len(parts) == 3 && parts[0] == "public" && parts[1] == "guidelines" {
		id, err := uuid.Parse(parts[2])
		if err != nil {
			return NotificationAction{}, ErrNotificationInvalid
		}
		action.Type = NotificationActionGuideline
		action.ResourceID = stringPointer(id.String())
		return action, nil
	}
	if s.validApprovedExternalURL(*value) {
		action.Type = NotificationActionExternalURL
		action.Route = value
		return action, nil
	}
	return NotificationAction{}, ErrNotificationInvalid
}

func validNotificationInternalRoute(value string) bool {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(value))
	if err != nil || parsed.IsAbs() || parsed.Host != "" || parsed.RawQuery != "" || parsed.Fragment != "" {
		return false
	}
	_, ok := notificationInternalRoutes[parsed.Path]
	return ok
}

func (s NotificationService) validApprovedExternalURL(value string) bool {
	return validApprovedHTTPSURL(value, s.AllowedActionHosts, false)
}

// validApprovedHTTPSURL is the shared trust boundary for external navigation
// used by notifications and outbreak resources.
func validApprovedHTTPSURL(value string, allowedHosts []string, allowAnyHost bool) bool {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(value))
	if err != nil || !strings.EqualFold(parsed.Scheme, "https") || parsed.Hostname() == "" || parsed.User != nil || strings.HasPrefix(strings.TrimSpace(value), "//") {
		return false
	}
	for key := range parsed.Query() {
		if _, reserved := notificationReservedParameters[strings.ToLower(key)]; reserved {
			return false
		}
	}
	if allowAnyHost && len(allowedHosts) == 0 {
		return true
	}
	host := strings.ToLower(parsed.Hostname())
	for _, allowed := range allowedHosts {
		if host == strings.ToLower(strings.TrimSpace(allowed)) {
			return true
		}
	}
	return false
}

func notificationResourceRoute(actionType string, id uuid.UUID) string {
	encoded := url.PathEscape(id.String())
	switch actionType {
	case NotificationActionGuideline:
		return "/public/guidelines/" + encoded
	case NotificationActionOutbreak:
		return "/outbreak-hub/" + encoded
	case NotificationActionSituationReport:
		return "/situation-reports/" + encoded
	case NotificationActionDrug:
		return "/drug-index?drug_id=" + url.QueryEscape(id.String())
	case NotificationActionCalculator:
		return "/calculators/" + encoded
	case NotificationActionFacility:
		return "/health-facilities/" + encoded
	case NotificationActionSupportTicket:
		return "/help-center?ticket_id=" + url.QueryEscape(id.String())
	default:
		return "/main"
	}
}
