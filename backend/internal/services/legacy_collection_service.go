package services

import (
	"errors"
	"fmt"
	"strings"

	"gorm.io/gorm"
)

var (
	ErrLegacyCollectionNotFound   = errors.New("legacy collection not found")
	ErrLegacyCollectionAuthNeeded = errors.New("legacy collection requires authentication")
	ErrLegacyCollectionForbidden  = errors.New("legacy collection forbidden")
	ErrLegacyCollectionWrite      = errors.New("legacy collection write unsupported")
	ErrLegacyCollectionInvalid    = errors.New("legacy collection invalid payload")
)

type LegacyCollectionService struct {
	DB *gorm.DB
}

type LegacyListInput struct {
	Page    int
	PerPage int
	Search  string
	Filters map[string]string
}

type LegacyListResult struct {
	Success    bool             `json:"success"`
	Collection string           `json:"collection"`
	Page       int              `json:"page"`
	PerPage    int              `json:"per_page"`
	TotalItems int64            `json:"total_items"`
	Items      []map[string]any `json:"items"`
}

type LegacyItemResult struct {
	Success    bool           `json:"success"`
	Collection string         `json:"collection"`
	Item       map[string]any `json:"item"`
}

type legacyAccessMode string

const (
	legacyAccessPublic legacyAccessMode = "public"
	legacyAccessAuth   legacyAccessMode = "auth"
	legacyAccessUser   legacyAccessMode = "user"
)

type legacyCollectionSpec struct {
	Table         string
	IDColumn      string
	Select        string
	DefaultOrder  string
	SearchColumns []string
	FilterColumns map[string]string
	Access        legacyAccessMode
	Joins         []string
	ApplyScopes   func(*gorm.DB) *gorm.DB
	ApplyAuth     func(*gorm.DB) *gorm.DB
	ApplyUser     func(*gorm.DB, string) *gorm.DB
}

func (s LegacyCollectionService) List(collection string, in LegacyListInput, userID string) (*LegacyListResult, error) {
	spec, ok := legacyCollectionSpecs[collection]
	if !ok {
		return nil, ErrLegacyCollectionNotFound
	}
	if err := validateLegacyAccess(spec, userID); err != nil {
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
	baseQuery = applyLegacySearch(baseQuery, spec.SearchColumns, in.Search)
	baseQuery = applyLegacyFilters(baseQuery, spec.FilterColumns, in.Filters)

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

	return &LegacyListResult{
		Success:    true,
		Collection: collection,
		Page:       page,
		PerPage:    perPage,
		TotalItems: total,
		Items:      items,
	}, nil
}

func (s LegacyCollectionService) Get(collection, id, userID string) (*LegacyItemResult, error) {
	spec, ok := legacyCollectionSpecs[collection]
	if !ok {
		return nil, ErrLegacyCollectionNotFound
	}
	if err := validateLegacyAccess(spec, userID); err != nil {
		return nil, err
	}

	item := map[string]any{}
	query := s.buildQuery(spec, userID).
		Select(spec.Select).
		Where(spec.IDColumn+" = ?", id)
	if err := query.Take(&item).Error; err != nil {
		return nil, err
	}

	return &LegacyItemResult{
		Success:    true,
		Collection: collection,
		Item:       item,
	}, nil
}

func (s LegacyCollectionService) Create(collection string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	spec, ok := legacyCollectionSpecs[collection]
	if !ok {
		return nil, ErrLegacyCollectionNotFound
	}
	if err := validateLegacyAccess(spec, userID); err != nil {
		return nil, err
	}

	switch collection {
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
		return s.createUsageLog(collection, payload, userID)
	case "drug_usage_logs":
		return s.createUsageLog(collection, payload, userID)
	case "abbreviation_usage_logs":
		return s.createUsageLog(collection, payload, userID)
	case "consultant_usage_logs":
		return s.createUsageLog(collection, payload, userID)
	case "facility_usage_logs":
		return s.createUsageLog(collection, payload, userID)
	case "ai_usage_logs":
		return s.createUsageLog(collection, payload, userID)
	default:
		return s.createGeneric(collection, payload, userID)
	}
}

func (s LegacyCollectionService) Update(collection, id string, payload map[string]any, userID string) (*LegacyItemResult, error) {
	spec, ok := legacyCollectionSpecs[collection]
	if !ok {
		return nil, ErrLegacyCollectionNotFound
	}
	if err := validateLegacyAccess(spec, userID); err != nil {
		return nil, err
	}

	switch collection {
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
		return s.updateGeneric(collection, id, payload, userID)
	}
}

func (s LegacyCollectionService) Delete(collection, id, userID string) error {
	spec, ok := legacyCollectionSpecs[collection]
	if !ok {
		return ErrLegacyCollectionNotFound
	}
	if err := validateLegacyAccess(spec, userID); err != nil {
		return err
	}

	switch collection {
	case "users":
		return s.deleteUser(id)
	default:
		return s.deleteGeneric(collection, id, userID)
	}
}

func (s LegacyCollectionService) buildQuery(spec legacyCollectionSpec, userID string) *gorm.DB {
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

func validateLegacyAccess(spec legacyCollectionSpec, userID string) error {
	if (spec.Access == legacyAccessAuth || spec.Access == legacyAccessUser) && strings.TrimSpace(userID) == "" {
		return ErrLegacyCollectionAuthNeeded
	}
	return nil
}

func applyLegacySearch(query *gorm.DB, columns []string, raw string) *gorm.DB {
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

func applyLegacyFilters(query *gorm.DB, columns map[string]string, filters map[string]string) *gorm.DB {
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

func (s LegacyCollectionService) SupportedCollections() []string {
	names := make([]string, 0, len(legacyCollectionSpecs))
	for name := range legacyCollectionSpecs {
		names = append(names, name)
	}
	return names
}

func LegacyCollectionErrorMessage(err error) string {
	switch {
	case errors.Is(err, ErrLegacyCollectionNotFound):
		return "collection not found"
	case errors.Is(err, ErrLegacyCollectionAuthNeeded):
		return "authentication required"
	case errors.Is(err, ErrLegacyCollectionForbidden):
		return "forbidden"
	case errors.Is(err, ErrLegacyCollectionWrite):
		return "write operation not supported"
	case errors.Is(err, ErrLegacyCollectionInvalid):
		return "invalid payload"
	case errors.Is(err, gorm.ErrRecordNotFound):
		return "record not found"
	default:
		return fmt.Sprintf("legacy collection error: %v", err)
	}
}
