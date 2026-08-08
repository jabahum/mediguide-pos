package services

import (
	"errors"
	"regexp"
	"strings"
	"time"

	cachepkg "mediguide/internal/cache"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrGuidelineContentInvalid  = errors.New("invalid guideline content payload")
	ErrGuidelineContentConflict = errors.New("guideline content already exists")
	ErrGuidelineHierarchyCycle  = errors.New("guideline hierarchy cycle")
	ErrGuidelineParentInUse     = errors.New("guideline hierarchy item has children")
)

type GuidelineContentService struct {
	DB    *gorm.DB
	Cache *cachepkg.Store
}

type GuidelineContentQuery struct {
	Page                                                                                                  PageInput
	Search, Status, ParentID, CategoryID, TagID, Priority, HealthcareLevel, TargetPopulation, Sort, Order string
	Level                                                                                                 *int
	Published, CommonUsage, RootOnly                                                                      *bool
}

type GuidelineCategoryInput struct {
	ParentCategoryID *string `json:"parent_category_id"`
	Name             *string `json:"name"`
	Slug             *string `json:"slug"`
	Description      *string `json:"description"`
	SortOrder        *int    `json:"sort_order"`
	Status           *string `json:"status"`
	Color            *string `json:"color"`
	Icon             *string `json:"icon"`
}

type GuidelineTagInput struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

type AbbreviationInput struct {
	Abbreviation *string   `json:"abbreviation"`
	Meaning      *string   `json:"meaning"`
	Description  *string   `json:"description"`
	CommonUsage  *bool     `json:"common_usage"`
	Categories   *[]string `json:"categories"`
	Tags         *[]string `json:"tags"`
}

type GuidelineIndexInput struct {
	ParentID    *string `json:"parent_id"`
	Title       *string `json:"title"`
	SortOrder   *int    `json:"sort_order"`
	Description *string `json:"description"`
}

type MedicalGuidelineInput struct {
	IndexItemID              *string   `json:"index_item_id"`
	ConditionName            *string   `json:"condition_name"`
	ICD10Code                *string   `json:"icd10_code"`
	TargetPopulation         *string   `json:"target_population"`
	Definition               *string   `json:"definition"`
	Causes                   *string   `json:"causes"`
	ClinicalFeatures         *string   `json:"clinical_features"`
	DifferentialDiagnosis    *string   `json:"differential_diagnosis"`
	ClassificationMild       *string   `json:"classification_mild"`
	ClassificationModerate   *string   `json:"classification_moderate"`
	ClassificationSevere     *string   `json:"classification_severe"`
	ClassificationCritical   *string   `json:"classification_critical"`
	GeneralManagement        *string   `json:"general_management"`
	MedicationPrimary        *string   `json:"medication_primary"`
	DosageAdult              *string   `json:"dosage_adult"`
	DosagePediatric          *string   `json:"dosage_pediatric"`
	MedicationSecondary      *string   `json:"medication_secondary"`
	DosageSecondaryAdult     *string   `json:"dosage_secondary_adult"`
	DosageSecondaryPediatric *string   `json:"dosage_secondary_pediatric"`
	HealthcareLevelRequired  *string   `json:"healthcare_level_required"`
	RouteAdministration      *string   `json:"route_administration"`
	MonitoringRequirements   *string   `json:"monitoring_requirements"`
	Contraindications        *string   `json:"contraindications"`
	PreventionMeasures       *string   `json:"prevention_measures"`
	SpecialNotes             *string   `json:"special_notes"`
	Status                   *string   `json:"status"`
	IsPublished              *bool     `json:"is_published"`
	Priority                 *string   `json:"priority"`
	Version                  *string   `json:"version"`
	Categories               *[]string `json:"categories"`
	Tags                     *[]string `json:"tags"`
}

func (s GuidelineContentService) ListCategories(editor bool, in GuidelineContentQuery) (*PageResult[models.GuidelineCategory], error) {
	if !editor && strings.TrimSpace(in.Search) == "" {
		return cachedServiceValue(s.Cache, "guideline-taxonomy", struct {
			Kind  string                `json:"kind"`
			Query GuidelineContentQuery `json:"query"`
		}{"categories", in}, 30*time.Minute, func() (*PageResult[models.GuidelineCategory], error) { return s.listCategoriesUncached(editor, in) })
	}
	return s.listCategoriesUncached(editor, in)
}

func (s GuidelineContentService) listCategoriesUncached(editor bool, in GuidelineContentQuery) (*PageResult[models.GuidelineCategory], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Table("guideline_categories gc").Select("gc.*, parent.name AS parent_name").Joins("LEFT JOIN guideline_categories parent ON parent.id=gc.parent_category_id").Where("gc.deleted_at IS NULL")
	if !editor {
		q = q.Where("gc.status = ?", "active")
	} else if in.Status != "" {
		if !oneOf(in.Status, "active", "inactive") {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("gc.status = ?", in.Status)
	}
	if in.ParentID != "" {
		id, err := uuid.Parse(in.ParentID)
		if err != nil {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("gc.parent_category_id = ?", id)
	} else if in.RootOnly != nil && *in.RootOnly {
		q = q.Where("gc.parent_category_id IS NULL")
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(gc.name) LIKE LOWER(?) OR LOWER(COALESCE(gc.slug,'')) LIKE LOWER(?) OR LOWER(COALESCE(gc.description,'')) LIKE LOWER(?)", like, like, like)
	}
	return pageHelp[models.GuidelineCategory](q, p, map[string]string{"name": "gc.name", "sort_order": "gc.sort_order", "created_at": "gc.created_at", "updated_at": "gc.updated_at"}, in.Sort, in.Order, "gc.sort_order ASC, gc.name ASC")
}

func (s GuidelineContentService) GetCategory(id uuid.UUID, editor bool) (*models.GuidelineCategory, error) {
	q := s.DB.Table("guideline_categories gc").Select("gc.*, parent.name AS parent_name").Joins("LEFT JOIN guideline_categories parent ON parent.id=gc.parent_category_id").Where("gc.id=? AND gc.deleted_at IS NULL", id)
	if !editor {
		q = q.Where("gc.status=?", "active")
	}
	var item models.GuidelineCategory
	err := q.First(&item).Error
	return &item, err
}

func (s GuidelineContentService) SaveCategory(id *uuid.UUID, in GuidelineCategoryInput) (*models.GuidelineCategory, error) {
	item := models.GuidelineCategory{Status: "active"}
	if id != nil {
		existing, err := s.GetCategory(*id, true)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.Name != nil {
		item.Name = strings.TrimSpace(*in.Name)
	}
	if in.Slug != nil {
		slug := strings.TrimSpace(*in.Slug)
		if slug == "" {
			slug = taxonomySlugify(item.Name)
		}
		item.Slug = &slug
	} else if id == nil {
		slug := taxonomySlugify(item.Name)
		item.Slug = &slug
	}
	item.Description = mergeOptionalString(item.Description, in.Description)
	item.Color = mergeOptionalString(item.Color, in.Color)
	item.Icon = mergeOptionalString(item.Icon, in.Icon)
	if in.SortOrder != nil {
		item.SortOrder = *in.SortOrder
	}
	if in.Status != nil {
		item.Status = strings.TrimSpace(*in.Status)
	}
	parent, err := optionalUUIDInput(in.ParentCategoryID)
	if err != nil {
		return nil, ErrGuidelineContentInvalid
	}
	if in.ParentCategoryID != nil {
		item.ParentCategoryID = parent
	}
	if item.Name == "" || item.Slug == nil || !validTaxonomySlug(*item.Slug) || !oneOf(item.Status, "active", "inactive") || item.SortOrder < 0 {
		return nil, ErrGuidelineContentInvalid
	}
	var duplicateCount int64
	duplicateQuery := s.DB.Model(&models.GuidelineCategory{}).Where("slug=?", *item.Slug)
	if id != nil {
		duplicateQuery = duplicateQuery.Where("id<>?", *id)
	}
	if err := duplicateQuery.Count(&duplicateCount).Error; err != nil {
		return nil, err
	}
	if duplicateCount > 0 {
		return nil, ErrGuidelineContentConflict
	}
	if id != nil && item.ParentCategoryID != nil && *item.ParentCategoryID == *id {
		return nil, ErrGuidelineHierarchyCycle
	}
	if item.ParentCategoryID != nil {
		if err := s.validateCategoryParent(*item.ParentCategoryID, id); err != nil {
			return nil, err
		}
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	invalidateServiceCaches(s.Cache, "guideline-taxonomy", "public-guidelines", "guideline-search")
	return s.GetCategory(item.ID, true)
}

func (s GuidelineContentService) DeleteCategory(id uuid.UUID) error {
	var count int64
	if err := s.DB.Model(&models.GuidelineCategory{}).Where("parent_category_id=? AND deleted_at IS NULL", id).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrGuidelineParentInUse
	}
	err := deleteExisting(s.DB, &models.GuidelineCategory{}, id)
	if err == nil {
		invalidateServiceCaches(s.Cache, "guideline-taxonomy", "public-guidelines", "guideline-search")
	}
	return err
}

func (s GuidelineContentService) ListTags(in GuidelineContentQuery) (*PageResult[models.GuidelineTag], error) {
	if strings.TrimSpace(in.Search) == "" {
		return cachedServiceValue(s.Cache, "guideline-taxonomy", struct {
			Kind  string                `json:"kind"`
			Query GuidelineContentQuery `json:"query"`
		}{"tags", in}, 30*time.Minute, func() (*PageResult[models.GuidelineTag], error) { return s.listTagsUncached(in) })
	}
	return s.listTagsUncached(in)
}

func (s GuidelineContentService) listTagsUncached(in GuidelineContentQuery) (*PageResult[models.GuidelineTag], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.GuidelineTag{})
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(name) LIKE LOWER(?) OR LOWER(COALESCE(description,'')) LIKE LOWER(?)", like, like)
	}
	return pageHelp[models.GuidelineTag](q, p, map[string]string{"name": "name", "created_at": "created_at", "updated_at": "updated_at"}, in.Sort, in.Order, "name ASC")
}

func (s GuidelineContentService) GetTag(id uuid.UUID) (*models.GuidelineTag, error) {
	var item models.GuidelineTag
	err := s.DB.First(&item, "id=?", id).Error
	return &item, err
}

func (s GuidelineContentService) SaveTag(id *uuid.UUID, in GuidelineTagInput) (*models.GuidelineTag, error) {
	item := models.GuidelineTag{}
	if id != nil {
		existing, err := s.GetTag(*id)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.Name != nil {
		item.Name = strings.TrimSpace(*in.Name)
	}
	item.Description = mergeOptionalString(item.Description, in.Description)
	if item.Name == "" {
		return nil, ErrGuidelineContentInvalid
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	invalidateServiceCaches(s.Cache, "guideline-taxonomy", "public-guidelines", "guideline-search")
	return &item, nil
}

func (s GuidelineContentService) DeleteTag(id uuid.UUID) error {
	err := deleteExisting(s.DB, &models.GuidelineTag{}, id)
	if err == nil {
		invalidateServiceCaches(s.Cache, "guideline-taxonomy", "public-guidelines", "guideline-search")
	}
	return err
}

func (s GuidelineContentService) ListAbbreviations(in GuidelineContentQuery) (*PageResult[models.Abbreviation], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.Abbreviation{})
	if in.CommonUsage != nil {
		q = q.Where("common_usage=?", *in.CommonUsage)
	}
	if err := applyJSONUUIDFilter(&q, "category_json", in.CategoryID); err != nil {
		return nil, err
	}
	if err := applyJSONUUIDFilter(&q, "tags_json", in.TagID); err != nil {
		return nil, err
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(abbreviation) LIKE LOWER(?) OR LOWER(meaning) LIKE LOWER(?) OR LOWER(COALESCE(description,'')) LIKE LOWER(?)", like, like, like)
	}
	return pageHelp[models.Abbreviation](q, p, map[string]string{"abbreviation": "abbreviation", "meaning": "meaning", "usage_count": "usage_count", "created_at": "created_at"}, in.Sort, in.Order, "abbreviation ASC")
}

func (s GuidelineContentService) GetAbbreviation(id uuid.UUID) (*models.Abbreviation, error) {
	var item models.Abbreviation
	err := s.DB.First(&item, "id=?", id).Error
	return &item, err
}

func (s GuidelineContentService) SaveAbbreviation(id *uuid.UUID, in AbbreviationInput) (*models.Abbreviation, error) {
	item := models.Abbreviation{}
	if id != nil {
		existing, err := s.GetAbbreviation(*id)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.Abbreviation != nil {
		item.Abbreviation = strings.TrimSpace(*in.Abbreviation)
	}
	if in.Meaning != nil {
		item.Meaning = strings.TrimSpace(*in.Meaning)
	}
	item.Description = mergeOptionalString(item.Description, in.Description)
	if in.CommonUsage != nil {
		item.CommonUsage = *in.CommonUsage
	}
	if in.Categories != nil {
		values, err := s.validRelatedIDs(*in.Categories, &models.GuidelineCategory{})
		if err != nil {
			return nil, err
		}
		item.Categories = models.StringList(values)
	}
	if in.Tags != nil {
		values, err := s.validRelatedIDs(*in.Tags, &models.GuidelineTag{})
		if err != nil {
			return nil, err
		}
		item.Tags = models.StringList(values)
	}
	if item.Abbreviation == "" || item.Meaning == "" {
		return nil, ErrGuidelineContentInvalid
	}
	var duplicateCount int64
	duplicateQuery := s.DB.Model(&models.Abbreviation{}).Where("LOWER(abbreviation)=LOWER(?)", item.Abbreviation)
	if id != nil {
		duplicateQuery = duplicateQuery.Where("id<>?", *id)
	}
	if err := duplicateQuery.Count(&duplicateCount).Error; err != nil {
		return nil, err
	}
	if duplicateCount > 0 {
		return nil, ErrGuidelineContentConflict
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s GuidelineContentService) DeleteAbbreviation(id uuid.UUID) error {
	return deleteExisting(s.DB, &models.Abbreviation{}, id)
}

func (s GuidelineContentService) ListIndex(in GuidelineContentQuery) (*PageResult[models.GuidelineIndexEntry], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Table("guideline_index gi").Select("gi.*, parent.title AS parent_title").Joins("LEFT JOIN guideline_index parent ON parent.id=gi.parent_id").Where("gi.deleted_at IS NULL")
	if in.ParentID != "" {
		id, err := uuid.Parse(in.ParentID)
		if err != nil {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("gi.parent_id=?", id)
	} else if in.RootOnly != nil && *in.RootOnly {
		q = q.Where("gi.parent_id IS NULL")
	}
	if in.Level != nil {
		if *in.Level < 0 {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("gi.level=?", *in.Level)
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(gi.title) LIKE LOWER(?) OR LOWER(COALESCE(gi.description,'')) LIKE LOWER(?)", like, like)
	}
	return pageHelp[models.GuidelineIndexEntry](q, p, map[string]string{"title": "gi.title", "level": "gi.level", "sort_order": "gi.sort_order", "created_at": "gi.created_at"}, in.Sort, in.Order, "gi.level ASC, gi.sort_order ASC, gi.title ASC")
}

func (s GuidelineContentService) GetIndex(id uuid.UUID) (*models.GuidelineIndexEntry, error) {
	var item models.GuidelineIndexEntry
	err := s.DB.Table("guideline_index gi").Select("gi.*, parent.title AS parent_title").Joins("LEFT JOIN guideline_index parent ON parent.id=gi.parent_id").Where("gi.id=? AND gi.deleted_at IS NULL", id).First(&item).Error
	return &item, err
}

func (s GuidelineContentService) IndexChildren(id uuid.UUID, in GuidelineContentQuery) (*PageResult[models.GuidelineIndexEntry], error) {
	in.ParentID = id.String()
	return s.ListIndex(in)
}

func (s GuidelineContentService) SaveIndex(id *uuid.UUID, in GuidelineIndexInput) (*models.GuidelineIndexEntry, error) {
	item := models.GuidelineIndexEntry{}
	if id != nil {
		existing, err := s.GetIndex(*id)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.Title != nil {
		item.Title = strings.TrimSpace(*in.Title)
	}
	item.Description = mergeOptionalString(item.Description, in.Description)
	if in.SortOrder != nil {
		item.SortOrder = *in.SortOrder
	}
	parent, err := optionalUUIDInput(in.ParentID)
	if err != nil {
		return nil, ErrGuidelineContentInvalid
	}
	if in.ParentID != nil {
		item.ParentID = parent
	}
	if item.Title == "" || item.SortOrder < 0 {
		return nil, ErrGuidelineContentInvalid
	}
	item.Level = 0
	if item.ParentID != nil {
		if id != nil && *item.ParentID == *id {
			return nil, ErrGuidelineHierarchyCycle
		}
		if err := s.validateIndexParent(*item.ParentID, id); err != nil {
			return nil, err
		}
		parentItem, err := s.GetIndex(*item.ParentID)
		if err != nil {
			return nil, ErrGuidelineContentInvalid
		}
		item.Level = parentItem.Level + 1
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(&item).Error; err != nil {
			return err
		}
		return recalculateIndexChildren(tx)
	})
	if err != nil {
		return nil, err
	}
	return s.GetIndex(item.ID)
}

func (s GuidelineContentService) DeleteIndex(id uuid.UUID) error {
	var count int64
	if err := s.DB.Model(&models.GuidelineIndexEntry{}).Where("parent_id=? AND deleted_at IS NULL", id).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrGuidelineParentInUse
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := deleteExisting(tx, &models.GuidelineIndexEntry{}, id); err != nil {
			return err
		}
		return recalculateIndexChildren(tx)
	})
}

func (s GuidelineContentService) ListMedicalGuidelines(editor bool, in GuidelineContentQuery) (*PageResult[models.MedicalGuideline], error) {
	p := in.Page.Normalize(20, 100)
	q := s.medicalQuery()
	if !editor {
		q = q.Where("mg.is_published=? AND mg.status=?", true, "published")
	} else if in.Status != "" {
		if !validMedicalStatus(in.Status) {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("mg.status=?", in.Status)
	}
	if in.Published != nil {
		q = q.Where("mg.is_published=?", *in.Published)
	}
	if in.ParentID != "" {
		id, err := uuid.Parse(in.ParentID)
		if err != nil {
			return nil, ErrGuidelineContentInvalid
		}
		q = q.Where("mg.index_item_id=?", id)
	}
	if in.Priority != "" {
		q = q.Where("mg.priority=?", strings.TrimSpace(in.Priority))
	}
	if in.HealthcareLevel != "" {
		q = q.Where("mg.healthcare_level_required=?", strings.TrimSpace(in.HealthcareLevel))
	}
	if in.TargetPopulation != "" {
		q = q.Where("mg.target_population=?", strings.TrimSpace(in.TargetPopulation))
	}
	if err := applyJSONUUIDFilter(&q, "mg.categories_json", in.CategoryID); err != nil {
		return nil, err
	}
	if err := applyJSONUUIDFilter(&q, "mg.tags_json", in.TagID); err != nil {
		return nil, err
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(mg.condition_name) LIKE LOWER(?) OR LOWER(COALESCE(mg.icd10_code,'')) LIKE LOWER(?) OR LOWER(COALESCE(mg.target_population,'')) LIKE LOWER(?)", like, like, like)
	}
	result, err := pageHelp[models.MedicalGuideline](q, p, map[string]string{"condition_name": "mg.condition_name", "priority": "mg.priority", "usage_count": "mg.usage_count", "created_at": "mg.created_at", "updated_at": "mg.updated_at"}, in.Sort, in.Order, "mg.updated_at DESC")
	if err != nil {
		return nil, err
	}
	if err := s.populateMedicalGuidelineTaxonomy(result.Items); err != nil {
		return nil, err
	}
	return result, nil
}

func (s GuidelineContentService) GetMedicalGuideline(id uuid.UUID, editor bool) (*models.MedicalGuideline, error) {
	q := s.medicalQuery().Where("mg.id=?", id)
	if !editor {
		q = q.Where("mg.is_published=? AND mg.status=?", true, "published")
	}
	var item models.MedicalGuideline
	err := q.First(&item).Error
	if err == nil {
		items := []models.MedicalGuideline{item}
		err = s.populateMedicalGuidelineTaxonomy(items)
		item = items[0]
	}
	return &item, err
}

func (s GuidelineContentService) SaveMedicalGuideline(id *uuid.UUID, in MedicalGuidelineInput) (*models.MedicalGuideline, error) {
	item := models.MedicalGuideline{Status: "draft"}
	if id != nil {
		existing, err := s.GetMedicalGuideline(*id, true)
		if err != nil {
			return nil, err
		}
		item = *existing
	}
	if in.ConditionName != nil {
		item.ConditionName = strings.TrimSpace(*in.ConditionName)
	}
	if in.IndexItemID != nil {
		value, err := optionalUUIDInput(in.IndexItemID)
		if err != nil {
			return nil, ErrGuidelineContentInvalid
		}
		item.IndexItemID = value
		if value != nil {
			if _, err := s.GetIndex(*value); err != nil {
				return nil, ErrGuidelineContentInvalid
			}
		}
	}
	mergeMedicalStrings(&item, in)
	if in.Status != nil {
		item.Status = strings.TrimSpace(*in.Status)
		switch item.Status {
		case "published":
			item.IsPublished = true
		case "draft", "archived":
			item.IsPublished = false
		}
	}
	if in.IsPublished != nil {
		item.IsPublished = *in.IsPublished
		if *in.IsPublished {
			item.Status = "published"
		}
	}
	if in.Categories != nil {
		values, err := s.validRelatedIDs(*in.Categories, &models.GuidelineCategory{})
		if err != nil {
			return nil, err
		}
		item.Categories = models.StringList(values)
	}
	if in.Tags != nil {
		values, err := s.validRelatedIDs(*in.Tags, &models.GuidelineTag{})
		if err != nil {
			return nil, err
		}
		item.Tags = models.StringList(values)
	}
	if item.ConditionName == "" || !validMedicalStatus(item.Status) {
		return nil, ErrGuidelineContentInvalid
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return s.GetMedicalGuideline(item.ID, true)
}

func (s GuidelineContentService) DeleteMedicalGuideline(id uuid.UUID) error {
	return deleteExisting(s.DB, &models.MedicalGuideline{}, id)
}

func (s GuidelineContentService) medicalQuery() *gorm.DB {
	return s.DB.Table("medical_guidelines mg").Select("mg.*, gi.title AS index_item_title").Joins("LEFT JOIN guideline_index gi ON gi.id=mg.index_item_id").Where("mg.deleted_at IS NULL")
}

func (s GuidelineContentService) populateMedicalGuidelineTaxonomy(items []models.MedicalGuideline) error {
	categoryIDs := make(map[uuid.UUID]struct{})
	tagIDs := make(map[uuid.UUID]struct{})
	for _, item := range items {
		collectUUIDStrings(item.Categories, categoryIDs)
		collectUUIDStrings(item.Tags, tagIDs)
	}

	categories := make([]models.GuidelineCategory, 0, len(categoryIDs))
	if len(categoryIDs) > 0 {
		ids := uuidSetValues(categoryIDs)
		if err := s.DB.Where("id IN ? AND deleted_at IS NULL", ids).Find(&categories).Error; err != nil {
			return err
		}
	}
	tags := make([]models.GuidelineTag, 0, len(tagIDs))
	if len(tagIDs) > 0 {
		ids := uuidSetValues(tagIDs)
		if err := s.DB.Where("id IN ? AND deleted_at IS NULL", ids).Find(&tags).Error; err != nil {
			return err
		}
	}

	categoryByID := make(map[string]models.GuidelineCategory, len(categories))
	for _, category := range categories {
		categoryByID[category.ID.String()] = category
	}
	tagByID := make(map[string]models.GuidelineTag, len(tags))
	for _, tag := range tags {
		tagByID[tag.ID.String()] = tag
	}
	for index := range items {
		items[index].CategoryDetails = orderedGuidelineCategories(items[index].Categories, categoryByID)
		items[index].TagDetails = orderedGuidelineTags(items[index].Tags, tagByID)
	}
	return nil
}

func collectUUIDStrings(values []string, target map[uuid.UUID]struct{}) {
	for _, raw := range values {
		if id, err := uuid.Parse(strings.TrimSpace(raw)); err == nil {
			target[id] = struct{}{}
		}
	}
}

func uuidSetValues(values map[uuid.UUID]struct{}) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(values))
	for id := range values {
		result = append(result, id)
	}
	return result
}

func orderedGuidelineCategories(ids []string, values map[string]models.GuidelineCategory) []models.GuidelineCategory {
	result := make([]models.GuidelineCategory, 0, len(ids))
	for _, id := range ids {
		if value, ok := values[strings.TrimSpace(id)]; ok {
			result = append(result, value)
		}
	}
	return result
}

func orderedGuidelineTags(ids []string, values map[string]models.GuidelineTag) []models.GuidelineTag {
	result := make([]models.GuidelineTag, 0, len(ids))
	for _, id := range ids {
		if value, ok := values[strings.TrimSpace(id)]; ok {
			result = append(result, value)
		}
	}
	return result
}

func (s GuidelineContentService) validateCategoryParent(parent uuid.UUID, itemID *uuid.UUID) error {
	current := parent
	for depth := 0; depth < 100; depth++ {
		if itemID != nil && current == *itemID {
			return ErrGuidelineHierarchyCycle
		}
		var item models.GuidelineCategory
		if err := s.DB.First(&item, "id=?", current).Error; err != nil {
			return ErrGuidelineContentInvalid
		}
		if item.ParentCategoryID == nil {
			return nil
		}
		current = *item.ParentCategoryID
	}
	return ErrGuidelineHierarchyCycle
}

func (s GuidelineContentService) validateIndexParent(parent uuid.UUID, itemID *uuid.UUID) error {
	current := parent
	for depth := 0; depth < 100; depth++ {
		if itemID != nil && current == *itemID {
			return ErrGuidelineHierarchyCycle
		}
		var item models.GuidelineIndexEntry
		if err := s.DB.First(&item, "id=?", current).Error; err != nil {
			return ErrGuidelineContentInvalid
		}
		if item.ParentID == nil {
			return nil
		}
		current = *item.ParentID
	}
	return ErrGuidelineHierarchyCycle
}

func (s GuidelineContentService) validRelatedIDs(values []string, model any) ([]string, error) {
	clean, err := validUUIDStrings(values)
	if err != nil {
		return nil, ErrGuidelineContentInvalid
	}
	if len(clean) == 0 {
		return clean, nil
	}
	var count int64
	if err := s.DB.Model(model).Where("id IN ? AND deleted_at IS NULL", clean).Count(&count).Error; err != nil {
		return nil, err
	}
	if count != int64(len(clean)) {
		return nil, ErrGuidelineContentInvalid
	}
	return clean, nil
}

func mergeMedicalStrings(item *models.MedicalGuideline, in MedicalGuidelineInput) {
	pairs := []struct {
		target **string
		value  *string
	}{
		{&item.ICD10Code, in.ICD10Code}, {&item.TargetPopulation, in.TargetPopulation}, {&item.Definition, in.Definition}, {&item.Causes, in.Causes},
		{&item.ClinicalFeatures, in.ClinicalFeatures}, {&item.DifferentialDiagnosis, in.DifferentialDiagnosis}, {&item.ClassificationMild, in.ClassificationMild},
		{&item.ClassificationModerate, in.ClassificationModerate}, {&item.ClassificationSevere, in.ClassificationSevere}, {&item.ClassificationCritical, in.ClassificationCritical},
		{&item.GeneralManagement, in.GeneralManagement}, {&item.MedicationPrimary, in.MedicationPrimary}, {&item.DosageAdult, in.DosageAdult},
		{&item.DosagePediatric, in.DosagePediatric}, {&item.MedicationSecondary, in.MedicationSecondary}, {&item.DosageSecondaryAdult, in.DosageSecondaryAdult},
		{&item.DosageSecondaryPediatric, in.DosageSecondaryPediatric}, {&item.HealthcareLevelRequired, in.HealthcareLevelRequired}, {&item.RouteAdministration, in.RouteAdministration},
		{&item.MonitoringRequirements, in.MonitoringRequirements}, {&item.Contraindications, in.Contraindications}, {&item.PreventionMeasures, in.PreventionMeasures},
		{&item.SpecialNotes, in.SpecialNotes}, {&item.Priority, in.Priority}, {&item.Version, in.Version},
	}
	for _, pair := range pairs {
		*pair.target = mergeOptionalString(*pair.target, pair.value)
	}
}

func optionalUUIDInput(raw *string) (*uuid.UUID, error) {
	if raw == nil {
		return nil, nil
	}
	value := strings.TrimSpace(*raw)
	if value == "" {
		return nil, nil
	}
	id, err := uuid.Parse(value)
	if err != nil {
		return nil, err
	}
	return &id, nil
}

func mergeOptionalString(current *string, raw *string) *string {
	if raw == nil {
		return current
	}
	value := strings.TrimSpace(*raw)
	if value == "" {
		return nil
	}
	return &value
}

func cleanStrings(values []string) []string {
	seen := map[string]struct{}{}
	out := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		out = append(out, value)
	}
	return out
}

func applyJSONUUIDFilter(query **gorm.DB, column, raw string) error {
	if raw == "" {
		return nil
	}
	values := cleanStrings(strings.Split(raw, ","))
	if len(values) == 0 {
		return nil
	}
	parts := make([]string, 0, len(values))
	args := make([]any, 0, len(values))
	for _, value := range values {
		if _, err := uuid.Parse(value); err != nil {
			return ErrGuidelineContentInvalid
		}
		parts = append(parts, column+" @> ?::jsonb")
		args = append(args, `[`+quoteJSON(value)+`]`)
	}
	*query = (*query).Where("("+strings.Join(parts, " OR ")+")", args...)
	return nil
}

func recalculateIndexChildren(db *gorm.DB) error {
	return db.Exec("UPDATE guideline_index SET has_children=EXISTS(SELECT 1 FROM guideline_index child WHERE child.parent_id=guideline_index.id AND child.deleted_at IS NULL), updated_at=? WHERE guideline_index.deleted_at IS NULL", time.Now().UTC()).Error
}

func deleteExisting(db *gorm.DB, model any, id uuid.UUID) error {
	result := db.Delete(model, "id=?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

var taxonomySlugPattern = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

func taxonomySlugify(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = regexp.MustCompile(`[^a-z0-9]+`).ReplaceAllString(value, "-")
	return strings.Trim(value, "-")
}
func validTaxonomySlug(value string) bool { return taxonomySlugPattern.MatchString(value) }
func validMedicalStatus(value string) bool {
	return oneOf(value, "draft", "review", "published", "archived", "active", "inactive")
}
