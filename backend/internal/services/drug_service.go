package services

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

var ErrDrugInvalidPayload = errors.New("invalid drug payload")

type DrugService struct{ DB *gorm.DB }

type DrugListInput struct {
	Page                  PageInput
	Search                string
	Status                string
	ReviewStatus          string
	DrugClassID           string
	TherapeuticCategoryID string
	Route                 string
	PregnancyCategory     string
	WHOEML                *bool
	Antimicrobial         *bool
	Sort                  string
	Order                 string
}

type DrugInput struct {
	DrugClassID           *string         `json:"drug_class_id"`
	TherapeuticCategoryID *string         `json:"therapeutic_category_id"`
	Name                  *string         `json:"name"`
	BrandNames            *string         `json:"brand_names"`
	Description           *string         `json:"description"`
	MechanismOfAction     *string         `json:"mechanism_of_action"`
	AdultDose             *string         `json:"adult_dose"`
	PediatricDose         *string         `json:"pediatric_dose"`
	ElderlyDose           *string         `json:"elderly_dose"`
	MaxDailyDose          *string         `json:"max_daily_dose"`
	RouteOfAdministration *string         `json:"route_of_administration"`
	Frequency             *string         `json:"frequency"`
	Duration              *string         `json:"duration"`
	Indications           *string         `json:"indications"`
	Contraindications     *string         `json:"contraindications"`
	SideEffects           *string         `json:"side_effects"`
	Warnings              *string         `json:"warnings"`
	MonitoringParameters  *string         `json:"monitoring_parameters"`
	PregnancyCategory     *string         `json:"pregnancy_category"`
	ClinicalNotes         *string         `json:"clinical_notes"`
	Categories            json.RawMessage `json:"categories" swaggertype:"array,string"`
	Tags                  json.RawMessage `json:"tags" swaggertype:"array,string"`
	WHOEMLStatus          *bool           `json:"who_eml_status"`
	AntimicrobialStatus   *bool           `json:"antimicrobial_status"`
	ControlledSubstance   *string         `json:"controlled_substance"`
	Status                *string         `json:"status"`
	ReviewStatus          *string         `json:"review_status"`
	SearchKeywords        *string         `json:"search_keywords"`
	ReferenceText         *string         `json:"reference_text"`
}

func (s DrugService) List(in DrugListInput) (*PageResult[models.Drug], error) {
	page := in.Page.Normalize(20, 100)
	query := s.drugQuery()
	if value := strings.TrimSpace(in.Search); value != "" {
		like := "%" + value + "%"
		query = query.Where(`LOWER(d.name) LIKE LOWER(?) OR LOWER(COALESCE(d.brand_names, '')) LIKE LOWER(?) OR LOWER(COALESCE(d.description, '')) LIKE LOWER(?) OR LOWER(COALESCE(d.indications, '')) LIKE LOWER(?) OR LOWER(COALESCE(d.search_keywords, '')) LIKE LOWER(?)`, like, like, like, like, like)
	}
	for _, filter := range []struct {
		value  string
		column string
	}{
		{in.Status, "d.status"},
		{in.ReviewStatus, "d.review_status"},
		{in.DrugClassID, "d.drug_class_id"},
		{in.TherapeuticCategoryID, "d.therapeutic_category_id"},
		{in.Route, "d.route_of_administration"},
		{in.PregnancyCategory, "d.pregnancy_category"},
	} {
		value, column := filter.value, filter.column
		if strings.TrimSpace(value) != "" {
			query = query.Where(column+" = ?", strings.TrimSpace(value))
		}
	}
	if in.WHOEML != nil {
		query = query.Where("d.who_eml_status = ?", *in.WHOEML)
	}
	if in.Antimicrobial != nil {
		query = query.Where("d.antimicrobial_status = ?", *in.Antimicrobial)
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Distinct("d.id").Count(&total).Error; err != nil {
		return nil, err
	}
	items := []models.Drug{}
	if err := query.Session(&gorm.Session{}).Select("d.*, dc.name AS drug_class_name, tc.name AS therapeutic_category_name").
		Order(drugSort(in.Sort, in.Order)).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s DrugService) Get(id uuid.UUID) (*models.Drug, error) {
	var item models.Drug
	err := s.drugQuery().Select("d.*, dc.name AS drug_class_name, tc.name AS therapeutic_category_name").
		Where("d.id = ?", id).Take(&item).Error
	return &item, err
}

func (s DrugService) Create(in DrugInput) (*models.Drug, error) {
	if in.Name == nil || strings.TrimSpace(*in.Name) == "" {
		return nil, ErrDrugInvalidPayload
	}
	drug := models.Drug{Name: strings.TrimSpace(*in.Name), Status: "active", ReviewStatus: "pending"}
	if err := applyDrugInput(&drug, in); err != nil {
		return nil, err
	}
	if err := s.DB.Create(&drug).Error; err != nil {
		return nil, err
	}
	return s.Get(drug.ID)
}

func (s DrugService) Update(id uuid.UUID, in DrugInput) (*models.Drug, error) {
	var drug models.Drug
	if err := s.DB.First(&drug, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if err := applyDrugInput(&drug, in); err != nil {
		return nil, err
	}
	drug.UpdatedAt = time.Now().UTC()
	if err := s.DB.Save(&drug).Error; err != nil {
		return nil, err
	}
	return s.Get(id)
}

func (s DrugService) Delete(id uuid.UUID) error {
	result := s.DB.Delete(&models.Drug{}, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s DrugService) RecordUsage(userID, drugID uuid.UUID) (*models.DrugUsageLog, error) {
	if _, err := s.Get(drugID); err != nil {
		return nil, err
	}
	log := models.DrugUsageLog{UserID: userID, DrugID: drugID}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&log).Error; err != nil {
			return err
		}
		return tx.Model(&models.Drug{}).Where("id = ?", drugID).
			UpdateColumn("usage_count", gorm.Expr("usage_count + 1")).Error
	}); err != nil {
		return nil, err
	}
	return &log, nil
}

func (s DrugService) drugQuery() *gorm.DB {
	return s.DB.Table("drugs d").
		Joins("LEFT JOIN drug_classes dc ON dc.id = d.drug_class_id").
		Joins("LEFT JOIN therapeutic_categories tc ON tc.id = d.therapeutic_category_id").
		Where("d.deleted_at IS NULL")
}

func applyDrugInput(drug *models.Drug, in DrugInput) error {
	if in.Name != nil {
		if strings.TrimSpace(*in.Name) == "" {
			return ErrDrugInvalidPayload
		}
		drug.Name = strings.TrimSpace(*in.Name)
	}
	if err := setOptionalUUID(&drug.DrugClassID, in.DrugClassID); err != nil {
		return err
	}
	if err := setOptionalUUID(&drug.TherapeuticCategoryID, in.TherapeuticCategoryID); err != nil {
		return err
	}
	copyDrugString := func(target **string, value *string) {
		if value != nil {
			trimmed := strings.TrimSpace(*value)
			if trimmed == "" {
				*target = nil
			} else {
				*target = &trimmed
			}
		}
	}
	copyDrugString(&drug.BrandNames, in.BrandNames)
	copyDrugString(&drug.Description, in.Description)
	copyDrugString(&drug.MechanismOfAction, in.MechanismOfAction)
	copyDrugString(&drug.AdultDose, in.AdultDose)
	copyDrugString(&drug.PediatricDose, in.PediatricDose)
	copyDrugString(&drug.ElderlyDose, in.ElderlyDose)
	copyDrugString(&drug.MaxDailyDose, in.MaxDailyDose)
	copyDrugString(&drug.RouteOfAdministration, in.RouteOfAdministration)
	copyDrugString(&drug.Frequency, in.Frequency)
	copyDrugString(&drug.Duration, in.Duration)
	copyDrugString(&drug.Indications, in.Indications)
	copyDrugString(&drug.Contraindications, in.Contraindications)
	copyDrugString(&drug.SideEffects, in.SideEffects)
	copyDrugString(&drug.Warnings, in.Warnings)
	copyDrugString(&drug.MonitoringParameters, in.MonitoringParameters)
	copyDrugString(&drug.PregnancyCategory, in.PregnancyCategory)
	copyDrugString(&drug.ClinicalNotes, in.ClinicalNotes)
	copyDrugString(&drug.ControlledSubstance, in.ControlledSubstance)
	copyDrugString(&drug.SearchKeywords, in.SearchKeywords)
	copyDrugString(&drug.ReferenceText, in.ReferenceText)
	if in.Categories != nil {
		if !json.Valid(in.Categories) {
			return ErrDrugInvalidPayload
		}
		drug.CategoriesJSON = datatypes.JSON(in.Categories)
	}
	if in.Tags != nil {
		if !json.Valid(in.Tags) {
			return ErrDrugInvalidPayload
		}
		drug.TagsJSON = datatypes.JSON(in.Tags)
	}
	if in.WHOEMLStatus != nil {
		drug.WHOEMLStatus = *in.WHOEMLStatus
	}
	if in.AntimicrobialStatus != nil {
		drug.AntimicrobialStatus = *in.AntimicrobialStatus
	}
	if in.Status != nil {
		if !oneOf(*in.Status, "active", "inactive", "under_review", "archived") {
			return ErrDrugInvalidPayload
		}
		drug.Status = strings.TrimSpace(*in.Status)
	}
	if in.ReviewStatus != nil {
		if !oneOf(*in.ReviewStatus, "approved", "pending", "needs_update") {
			return ErrDrugInvalidPayload
		}
		drug.ReviewStatus = strings.TrimSpace(*in.ReviewStatus)
	}
	return nil
}

func setOptionalUUID(target **uuid.UUID, raw *string) error {
	if raw == nil {
		return nil
	}
	if strings.TrimSpace(*raw) == "" {
		*target = nil
		return nil
	}
	value, err := uuid.Parse(strings.TrimSpace(*raw))
	if err != nil {
		return ErrDrugInvalidPayload
	}
	*target = &value
	return nil
}

func oneOf(value string, allowed ...string) bool {
	value = strings.TrimSpace(value)
	for _, candidate := range allowed {
		if value == candidate {
			return true
		}
	}
	return false
}

func drugSort(field, order string) string {
	columns := map[string]string{"name": "d.name", "created_at": "d.created_at", "updated_at": "d.updated_at", "usage_count": "d.usage_count"}
	column := columns[strings.TrimSpace(field)]
	if column == "" {
		column = "d.name"
	}
	direction := "ASC"
	if strings.EqualFold(strings.TrimSpace(order), "desc") {
		direction = "DESC"
	}
	return column + " " + direction
}
