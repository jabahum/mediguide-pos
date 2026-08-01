package services

import (
	"encoding/json"
	"errors"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

var ErrEmergencyProtocolInvalid = errors.New("invalid emergency protocol")

type EmergencyProtocolService struct{ DB *gorm.DB }
type EmergencyProtocolQuery struct {
	Page                                            PageInput
	Search, Category, Priority, Status, Sort, Order string
}
type EmergencyProtocolInput struct {
	Title             *string          `json:"title"`
	Description       *string          `json:"description"`
	Category          *string          `json:"category"`
	Priority          *string          `json:"priority"`
	Status            *string          `json:"status"`
	Timeframe         *string          `json:"timeframe"`
	Steps             *json.RawMessage `json:"steps" swaggertype:"object"`
	CriticalActions   *json.RawMessage `json:"critical_actions" swaggertype:"object"`
	Medications       *json.RawMessage `json:"medications" swaggertype:"object"`
	VitalSigns        *json.RawMessage `json:"vital_signs" swaggertype:"object"`
	TransferChecklist *json.RawMessage `json:"transfer_checklist" swaggertype:"object"`
	ContactInfo       *json.RawMessage `json:"contact_info" swaggertype:"object"`
	Tags              *json.RawMessage `json:"tags" swaggertype:"array,string"`
}

func (s EmergencyProtocolService) List(editor bool, in EmergencyProtocolQuery) (*PageResult[models.EmergencyProtocol], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.EmergencyProtocol{})
	if !editor {
		q = q.Where("status=?", "active")
	} else if in.Status != "" {
		if !oneOf(in.Status, "active", "draft", "archived") {
			return nil, ErrEmergencyProtocolInvalid
		}
		q = q.Where("status=?", in.Status)
	}
	if in.Category != "" {
		if !validProtocolCategory(in.Category) {
			return nil, ErrEmergencyProtocolInvalid
		}
		q = q.Where("category=?", in.Category)
	}
	if in.Priority != "" {
		if !oneOf(in.Priority, "critical", "high", "medium", "low") {
			return nil, ErrEmergencyProtocolInvalid
		}
		q = q.Where("priority=?", in.Priority)
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(title) LIKE LOWER(?) OR LOWER(COALESCE(description,'')) LIKE LOWER(?)", like, like)
	}
	return pageHelp[models.EmergencyProtocol](q, p, map[string]string{"title": "title", "category": "category", "priority": "priority", "created_at": "created_at", "updated_at": "updated_at", "access_count": "access_count"}, in.Sort, in.Order, "CASE priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END, title ASC")
}
func (s EmergencyProtocolService) Get(id uuid.UUID, editor bool) (*models.EmergencyProtocol, error) {
	var item models.EmergencyProtocol
	q := s.DB.Where("id=?", id)
	if !editor {
		q = q.Where("status=?", "active")
	}
	err := q.First(&item).Error
	return &item, err
}
func (s EmergencyProtocolService) Save(id *uuid.UUID, in EmergencyProtocolInput) (*models.EmergencyProtocol, error) {
	item := models.EmergencyProtocol{Priority: "medium", Status: "draft"}
	if id != nil {
		existing, err := s.Get(*id, true)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.Title != nil {
		item.Title = strings.TrimSpace(*in.Title)
	}
	item.Description = mergeOptionalString(item.Description, in.Description)
	item.Timeframe = mergeOptionalString(item.Timeframe, in.Timeframe)
	if in.Category != nil {
		item.Category = strings.TrimSpace(*in.Category)
	}
	if in.Priority != nil {
		item.Priority = strings.TrimSpace(*in.Priority)
	}
	if in.Status != nil {
		item.Status = strings.TrimSpace(*in.Status)
	}
	if item.Title == "" || !validProtocolCategory(item.Category) || !oneOf(item.Priority, "critical", "high", "medium", "low") || !oneOf(item.Status, "active", "draft", "archived") {
		return nil, ErrEmergencyProtocolInvalid
	}
	jsonFields := []struct {
		raw    *json.RawMessage
		target *datatypes.JSON
	}{{in.Steps, &item.Steps}, {in.CriticalActions, &item.CriticalActions}, {in.Medications, &item.Medications}, {in.VitalSigns, &item.VitalSigns}, {in.TransferChecklist, &item.TransferChecklist}, {in.ContactInfo, &item.ContactInfo}, {in.Tags, &item.Tags}}
	for _, field := range jsonFields {
		if field.raw != nil {
			if !json.Valid(*field.raw) {
				return nil, ErrEmergencyProtocolInvalid
			}
			*field.target = datatypes.JSON(append([]byte(nil), (*field.raw)...))
		}
	}
	if len(item.Tags) > 0 {
		var tags []string
		if json.Unmarshal(item.Tags, &tags) != nil {
			return nil, ErrEmergencyProtocolInvalid
		}
		clean := cleanStrings(tags)
		encoded, _ := json.Marshal(clean)
		item.Tags = encoded
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}
func (s EmergencyProtocolService) Delete(id uuid.UUID) error {
	return deleteExisting(s.DB, &models.EmergencyProtocol{}, id)
}
func validProtocolCategory(value string) bool {
	return oneOf(value, "Resuscitation", "Trauma", "Emergency Medicine", "Critical Care", "Toxicology", "Environmental", "Pediatric", "Obstetric", "Cardiac", "Neurology")
}
