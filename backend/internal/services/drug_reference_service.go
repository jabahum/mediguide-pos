package services

import (
	"errors"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrDrugReferenceInvalidPayload = errors.New("invalid drug reference payload")

type DrugReferenceService struct{ DB *gorm.DB }

type DrugReferenceListInput struct {
	Page   PageInput
	Search string
	Status string
}

type DrugCategoryInput struct {
	ParentCategoryID *string `json:"parent_category_id"`
	Name             *string `json:"name"`
	Description      *string `json:"description"`
	Color            *string `json:"color"`
	Icon             *string `json:"icon"`
	SortOrder        *int    `json:"sort_order"`
	Status           *string `json:"status"`
}

type DrugTagInput struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	Color       *string `json:"color"`
	TagCategory *string `json:"tag_category"`
	SortOrder   *int    `json:"sort_order"`
	Status      *string `json:"status"`
}

type DrugNamedReferenceInput struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	SortOrder   *int    `json:"sort_order"`
	Status      *string `json:"status"`
}

func (s DrugReferenceService) ListCategories(in DrugReferenceListInput) (*PageResult[models.DrugCategory], error) {
	return listDrugReferences[models.DrugCategory](s.DB, in, "COALESCE(sort_order, 999999), name ASC")
}

func (s DrugReferenceService) ListTags(in DrugReferenceListInput) (*PageResult[models.DrugTag], error) {
	return listDrugReferences[models.DrugTag](s.DB, in, "name ASC")
}

func (s DrugReferenceService) ListClasses(in DrugReferenceListInput) (*PageResult[models.DrugClass], error) {
	return listDrugReferences[models.DrugClass](s.DB, in, "name ASC")
}

func (s DrugReferenceService) ListTherapeuticCategories(in DrugReferenceListInput) (*PageResult[models.TherapeuticCategory], error) {
	return listDrugReferences[models.TherapeuticCategory](s.DB, in, "name ASC")
}

func (s DrugReferenceService) GetCategory(id uuid.UUID) (*models.DrugCategory, error) {
	return getDrugReference[models.DrugCategory](s.DB, id)
}

func (s DrugReferenceService) GetTag(id uuid.UUID) (*models.DrugTag, error) {
	return getDrugReference[models.DrugTag](s.DB, id)
}

func (s DrugReferenceService) GetClass(id uuid.UUID) (*models.DrugClass, error) {
	return getDrugReference[models.DrugClass](s.DB, id)
}

func (s DrugReferenceService) GetTherapeuticCategory(id uuid.UUID) (*models.TherapeuticCategory, error) {
	return getDrugReference[models.TherapeuticCategory](s.DB, id)
}

func (s DrugReferenceService) CreateCategory(in DrugCategoryInput) (*models.DrugCategory, error) {
	item := models.DrugCategory{Status: "active"}
	if err := applyDrugCategoryInput(&item, in); err != nil {
		return nil, err
	}
	return createDrugReference(s.DB, &item)
}

func (s DrugReferenceService) UpdateCategory(id uuid.UUID, in DrugCategoryInput) (*models.DrugCategory, error) {
	item, err := s.GetCategory(id)
	if err != nil {
		return nil, err
	}
	if err := applyDrugCategoryInput(item, in); err != nil {
		return nil, err
	}
	return saveDrugReference(s.DB, item)
}

func (s DrugReferenceService) CreateTag(in DrugTagInput) (*models.DrugTag, error) {
	item := models.DrugTag{Status: "active", TagCategory: "clinical"}
	if err := applyDrugTagInput(&item, in); err != nil {
		return nil, err
	}
	return createDrugReference(s.DB, &item)
}

func (s DrugReferenceService) UpdateTag(id uuid.UUID, in DrugTagInput) (*models.DrugTag, error) {
	item, err := s.GetTag(id)
	if err != nil {
		return nil, err
	}
	if err := applyDrugTagInput(item, in); err != nil {
		return nil, err
	}
	return saveDrugReference(s.DB, item)
}

func (s DrugReferenceService) CreateClass(in DrugNamedReferenceInput) (*models.DrugClass, error) {
	item := models.DrugClass{Status: "active"}
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, in); err != nil {
		return nil, err
	}
	return createDrugReference(s.DB, &item)
}

func (s DrugReferenceService) UpdateClass(id uuid.UUID, in DrugNamedReferenceInput) (*models.DrugClass, error) {
	item, err := s.GetClass(id)
	if err != nil {
		return nil, err
	}
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, in); err != nil {
		return nil, err
	}
	return saveDrugReference(s.DB, item)
}

func (s DrugReferenceService) CreateTherapeuticCategory(in DrugNamedReferenceInput) (*models.TherapeuticCategory, error) {
	item := models.TherapeuticCategory{Status: "active"}
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, in); err != nil {
		return nil, err
	}
	return createDrugReference(s.DB, &item)
}

func (s DrugReferenceService) UpdateTherapeuticCategory(id uuid.UUID, in DrugNamedReferenceInput) (*models.TherapeuticCategory, error) {
	item, err := s.GetTherapeuticCategory(id)
	if err != nil {
		return nil, err
	}
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, in); err != nil {
		return nil, err
	}
	return saveDrugReference(s.DB, item)
}

func (s DrugReferenceService) Delete(kind string, id uuid.UUID) error {
	var model any
	switch kind {
	case "category":
		model = &models.DrugCategory{}
	case "tag":
		model = &models.DrugTag{}
	case "class":
		model = &models.DrugClass{}
	case "therapeutic-category":
		model = &models.TherapeuticCategory{}
	default:
		return ErrDrugReferenceInvalidPayload
	}
	result := s.DB.Delete(model, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func listDrugReferences[T any](db *gorm.DB, in DrugReferenceListInput, order string) (*PageResult[T], error) {
	page := in.Page.Normalize(20, 100)
	query := db.Model(new(T))
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		query = query.Where("LOWER(name) LIKE LOWER(?) OR LOWER(COALESCE(description, '')) LIKE LOWER(?)", like, like)
	}
	if status := strings.TrimSpace(in.Status); status != "" {
		if !oneOf(status, "active", "inactive") {
			return nil, ErrDrugReferenceInvalidPayload
		}
		query = query.Where("status = ?", status)
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	items := []T{}
	if err := query.Session(&gorm.Session{}).Order(order).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func getDrugReference[T any](db *gorm.DB, id uuid.UUID) (*T, error) {
	var item T
	return &item, db.First(&item, "id = ?", id).Error
}

func createDrugReference[T any](db *gorm.DB, item *T) (*T, error) {
	if err := db.Create(item).Error; err != nil {
		return nil, err
	}
	return item, nil
}

func saveDrugReference[T any](db *gorm.DB, item *T) (*T, error) {
	if err := db.Save(item).Error; err != nil {
		return nil, err
	}
	return item, nil
}

func applyDrugCategoryInput(item *models.DrugCategory, in DrugCategoryInput) error {
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, DrugNamedReferenceInput{
		Name: in.Name, Description: in.Description, SortOrder: in.SortOrder, Status: in.Status,
	}); err != nil {
		return err
	}
	if err := setOptionalUUID(&item.ParentCategoryID, in.ParentCategoryID); err != nil {
		return ErrDrugReferenceInvalidPayload
	}
	copyOptionalString(&item.Color, in.Color)
	copyOptionalString(&item.Icon, in.Icon)
	return nil
}

func applyDrugTagInput(item *models.DrugTag, in DrugTagInput) error {
	if err := applyNamedReference(&item.Name, &item.Description, &item.SortOrder, &item.Status, DrugNamedReferenceInput{
		Name: in.Name, Description: in.Description, SortOrder: in.SortOrder, Status: in.Status,
	}); err != nil {
		return err
	}
	copyOptionalString(&item.Color, in.Color)
	if in.TagCategory != nil {
		if !oneOf(*in.TagCategory, "clinical", "administrative", "regulatory", "safety") {
			return ErrDrugReferenceInvalidPayload
		}
		item.TagCategory = strings.TrimSpace(*in.TagCategory)
	}
	return nil
}

func applyNamedReference(name *string, description **string, sortOrder **int, status *string, in DrugNamedReferenceInput) error {
	if in.Name != nil {
		if strings.TrimSpace(*in.Name) == "" {
			return ErrDrugReferenceInvalidPayload
		}
		*name = strings.TrimSpace(*in.Name)
	}
	if strings.TrimSpace(*name) == "" {
		return ErrDrugReferenceInvalidPayload
	}
	copyOptionalString(description, in.Description)
	if in.SortOrder != nil {
		*sortOrder = in.SortOrder
	}
	if in.Status != nil {
		if !oneOf(*in.Status, "active", "inactive") {
			return ErrDrugReferenceInvalidPayload
		}
		*status = strings.TrimSpace(*in.Status)
	}
	return nil
}

func copyOptionalString(target **string, value *string) {
	if value == nil {
		return
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		*target = nil
	} else {
		*target = &trimmed
	}
}
