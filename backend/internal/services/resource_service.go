package services

import (
	"errors"
	"fmt"
	"strings"

	"gorm.io/gorm"
)

var (
	ErrResourceNotFound   = errors.New("resource not found")
	ErrResourceAuthNeeded = errors.New("resource requires authentication")
	ErrResourceForbidden  = errors.New("resource forbidden")
	ErrResourceWrite      = errors.New("resource write unsupported")
	ErrResourceInvalid    = errors.New("resource invalid payload")
)

type ResourceService struct {
	DB *gorm.DB
}

type ResourceListInput struct {
	Page    int
	PerPage int
	Search  string
	Filters map[string]string
}

type ResourceListResult struct {
	Success    bool             `json:"success"`
	Resource   string           `json:"resource"`
	Page       int              `json:"page"`
	PerPage    int              `json:"per_page"`
	TotalItems int64            `json:"total_items"`
	Items      []map[string]any `json:"items"`
}

type ResourceItemResult struct {
	Success  bool           `json:"success"`
	Resource string         `json:"resource"`
	Item     map[string]any `json:"item"`
}

type resourceAccessMode string

const (
	resourceAccessPublic resourceAccessMode = "public"
	resourceAccessAuth   resourceAccessMode = "auth"
	resourceAccessUser   resourceAccessMode = "user"
)

type resourceSpec struct {
	Table         string
	IDColumn      string
	Select        string
	DefaultOrder  string
	SearchColumns []string
	FilterColumns map[string]string
	Access        resourceAccessMode
	Joins         []string
	ApplyScopes   func(*gorm.DB) *gorm.DB
	ApplyAuth     func(*gorm.DB) *gorm.DB
	ApplyUser     func(*gorm.DB, string) *gorm.DB
}

func (s ResourceService) List(resource string, in ResourceListInput, userID string) (*ResourceListResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	if err := validateResourceAccess(spec, userID); err != nil {
		return nil, err
	}

	page := in.Page
	if page < 1 {
		page = 1
	}
	perPage := in.PerPage
	if perPage < 1 {
		perPage = 20
	}
	if perPage > 100 {
		perPage = 100
	}

	baseQuery := s.buildQuery(spec, userID)
	baseQuery = applyResourceSearch(baseQuery, spec.SearchColumns, in.Search)
	baseQuery = applyResourceFilters(baseQuery, spec.FilterColumns, in.Filters)

	var total int64
	countQuery := baseQuery.Session(&gorm.Session{})
	if err := countQuery.Distinct(spec.IDColumn).Count(&total).Error; err != nil {
		return nil, err
	}

	items := []map[string]any{}
	dataQuery := baseQuery.Session(&gorm.Session{})
	if err := dataQuery.
		Select(spec.Select).
		Order(spec.DefaultOrder).
		Limit(perPage).
		Offset((page - 1) * perPage).
		Find(&items).Error; err != nil {
		return nil, err
	}

	return &ResourceListResult{
		Success:    true,
		Resource:   resource,
		Page:       page,
		PerPage:    perPage,
		TotalItems: total,
		Items:      items,
	}, nil
}

func (s ResourceService) Get(resource, id, userID string) (*ResourceItemResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	if err := validateResourceAccess(spec, userID); err != nil {
		return nil, err
	}

	item := map[string]any{}
	query := s.buildQuery(spec, userID).
		Select(spec.Select).
		Where(spec.IDColumn+" = ?", id)
	if err := query.Take(&item).Error; err != nil {
		return nil, err
	}

	return &ResourceItemResult{
		Success:  true,
		Resource: resource,
		Item:     item,
	}, nil
}

func (s ResourceService) Create(resource string, payload map[string]any, userID string) (*ResourceItemResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	if err := validateResourceAccess(spec, userID); err != nil {
		return nil, err
	}

	switch resource {
	case "users":
		return s.createUser(payload)
	case "support_tickets":
		return s.createSupportTicket(payload, userID)
	case "support_ticket_replies":
		return s.createSupportTicketReply(payload, userID)
	case "conversations":
		return s.createConversation(payload, userID)
	case "messages":
		return s.createMessage(payload, userID)
	case "reading_progress":
		return s.createReadingProgress(payload, userID)
	case "guideline_usage_logs":
		return s.createUsageLog(resource, payload, userID)
	case "abbreviation_usage_logs":
		return s.createUsageLog(resource, payload, userID)
	case "consultant_usage_logs":
		return s.createUsageLog(resource, payload, userID)
	case "facility_usage_logs":
		return s.createUsageLog(resource, payload, userID)
	case "ai_usage_logs":
		return s.createUsageLog(resource, payload, userID)
	default:
		return s.createGeneric(resource, payload, userID)
	}
}

func (s ResourceService) Update(resource, id string, payload map[string]any, userID string) (*ResourceItemResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	if err := validateResourceAccess(spec, userID); err != nil {
		return nil, err
	}

	switch resource {
	case "users":
		if id == userID {
			return s.updateUser(id, payload, userID)
		}
		return s.updateUserAdmin(id, payload)
	case "conversations":
		return s.updateConversation(id, payload, userID)
	case "messages":
		return s.updateMessage(id, payload, userID)
	case "reading_progress":
		return s.updateReadingProgress(id, payload, userID)
	default:
		return s.updateGeneric(resource, id, payload, userID)
	}
}

func (s ResourceService) Delete(resource, id, userID string) error {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return ErrResourceNotFound
	}
	if err := validateResourceAccess(spec, userID); err != nil {
		return err
	}

	switch resource {
	case "users":
		return s.deleteUser(id)
	default:
		return s.deleteGeneric(resource, id, userID)
	}
}

func (s ResourceService) buildQuery(spec resourceSpec, userID string) *gorm.DB {
	query := s.DB.Table(spec.Table)
	for _, join := range spec.Joins {
		query = query.Joins(join)
	}
	if strings.TrimSpace(userID) != "" && spec.ApplyAuth != nil {
		query = spec.ApplyAuth(query)
	} else if spec.ApplyScopes != nil {
		query = spec.ApplyScopes(query)
	}
	if spec.ApplyUser != nil && strings.TrimSpace(userID) != "" {
		query = spec.ApplyUser(query, userID)
	}
	return query
}

func validateResourceAccess(spec resourceSpec, userID string) error {
	if (spec.Access == resourceAccessAuth || spec.Access == resourceAccessUser) && strings.TrimSpace(userID) == "" {
		return ErrResourceAuthNeeded
	}
	return nil
}

func applyResourceSearch(query *gorm.DB, columns []string, raw string) *gorm.DB {
	term := strings.TrimSpace(raw)
	if term == "" || len(columns) == 0 {
		return query
	}

	parts := make([]string, 0, len(columns))
	args := make([]any, 0, len(columns))
	like := "%" + term + "%"
	for _, column := range columns {
		parts = append(parts, column+" ILIKE ?")
		args = append(args, like)
	}
	return query.Where("("+strings.Join(parts, " OR ")+")", args...)
}

func applyResourceFilters(query *gorm.DB, columns map[string]string, filters map[string]string) *gorm.DB {
	if len(columns) == 0 || len(filters) == 0 {
		return query
	}
	for key, value := range filters {
		column, ok := columns[key]
		if !ok {
			continue
		}
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		if strings.EqualFold(trimmed, "null") {
			query = query.Where(column + " IS NULL")
			continue
		}
		query = query.Where(column+" = ?", trimmed)
	}
	return query
}

func (s ResourceService) SupportedResources() []string {
	names := make([]string, 0, len(resourceSpecs))
	for name := range resourceSpecs {
		names = append(names, name)
	}
	return names
}

func ResourceErrorMessage(err error) string {
	switch {
	case errors.Is(err, ErrResourceNotFound):
		return "resource not found"
	case errors.Is(err, ErrResourceAuthNeeded):
		return "authentication required"
	case errors.Is(err, ErrResourceForbidden):
		return "forbidden"
	case errors.Is(err, ErrResourceWrite):
		return "write operation not supported"
	case errors.Is(err, ErrResourceInvalid):
		return "invalid payload"
	case errors.Is(err, gorm.ErrRecordNotFound):
		return "record not found"
	default:
		return fmt.Sprintf("resource error: %v", err)
	}
}
