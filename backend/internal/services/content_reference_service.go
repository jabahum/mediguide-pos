package services

import (
	"encoding/json"
	"errors"
	"regexp"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrContentReferenceInvalid  = errors.New("invalid content reference payload")
	ErrContentReferenceConflict = errors.New("content reference already exists")
	ErrDefaultLanguage          = errors.New("default language cannot be deleted")
)

type ContentReferenceService struct{ DB *gorm.DB }
type ContentReferenceQuery struct {
	Page                                                                               PageInput
	Search, Key, Ministry, Department, DistrictID, RegionID, Status, Code, Sort, Order string
	Active, Default, Enabled                                                           *bool
	ProgressMin, ProgressMax                                                           *float64
}
type GenericPageInput struct {
	Title       *string          `json:"title"`
	Description *string          `json:"description"`
	Content     *json.RawMessage `json:"content" swaggertype:"object"`
	Key         *string          `json:"key"`
}
type MinistryDirectoryInput struct {
	DistrictID        *string `json:"district_id"`
	RegionID          *string `json:"region_id"`
	Name              *string `json:"name"`
	Title             *string `json:"title"`
	Ministry          *string `json:"ministry"`
	Department        *string `json:"department"`
	Phone             *string `json:"phone"`
	AlternativePhone  *string `json:"alternative_phone"`
	Email             *string `json:"email"`
	OfficeAddress     *string `json:"office_address"`
	PriorityLevel     *int    `json:"priority_level"`
	AvailabilityHours *string `json:"availability_hours"`
	Specialization    *string `json:"specialization"`
	Status            *string `json:"status"`
	Notes             *string `json:"notes"`
}
type LanguageInput struct {
	Code            *string          `json:"code"`
	Name            *string          `json:"name"`
	NativeName      *string          `json:"native_name"`
	IsActive        *bool            `json:"is_active"`
	IsDefault       *bool            `json:"is_default"`
	TranslationsURL *string          `json:"translations_url"`
	Translations    *json.RawMessage `json:"translations" swaggertype:"object"`
	Version         *float64         `json:"version"`
	Status          *string          `json:"status"`
	Progress        *float64         `json:"progress"`
	EnabledForUsers *bool            `json:"enabled_for_users"`
}

func (s ContentReferenceService) ListPages(in ContentReferenceQuery) (*PageResult[models.GenericPage], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.GenericPage{})
	if in.Key != "" {
		q = q.Where("key=?", in.Key)
	}
	if v := strings.TrimSpace(in.Search); v != "" {
		like := "%" + v + "%"
		q = q.Where("LOWER(title) LIKE LOWER(?) OR LOWER(COALESCE(description,'')) LIKE LOWER(?) OR LOWER(key) LIKE LOWER(?)", like, like, like)
	}
	return pageHelp[models.GenericPage](q, p, map[string]string{"title": "title", "key": "key", "created_at": "created_at", "updated_at": "updated_at"}, in.Sort, in.Order, "title ASC")
}
func (s ContentReferenceService) GetPage(id uuid.UUID) (*models.GenericPage, error) {
	var v models.GenericPage
	err := s.DB.First(&v, "id=?", id).Error
	return &v, err
}
func (s ContentReferenceService) GetPageByKey(key string) (*models.GenericPage, error) {
	var v models.GenericPage
	err := s.DB.First(&v, "key=?", strings.TrimSpace(key)).Error
	return &v, err
}
func (s ContentReferenceService) SavePage(id *uuid.UUID, in GenericPageInput) (*models.GenericPage, error) {
	v := models.GenericPage{Content: json.RawMessage(`{}`)}
	if id != nil {
		x, err := s.GetPage(*id)
		if err != nil {
			return nil, err
		}
		v = *x
	}
	if in.Title != nil {
		v.Title = strings.TrimSpace(*in.Title)
	}
	v.Description = mergeOptionalString(v.Description, in.Description)
	if in.Key != nil {
		v.Key = strings.TrimSpace(*in.Key)
	}
	if in.Content != nil {
		if !json.Valid(*in.Content) {
			return nil, ErrContentReferenceInvalid
		}
		v.Content = append([]byte(nil), (*in.Content)...)
	}
	if v.Title == "" || !validContentKey(v.Key) || !json.Valid(v.Content) {
		return nil, ErrContentReferenceInvalid
	}
	var count int64
	q := s.DB.Model(&models.GenericPage{}).Where("key=?", v.Key)
	if id != nil {
		q = q.Where("id<>?", *id)
	}
	if err := q.Count(&count).Error; err != nil {
		return nil, err
	}
	if count > 0 {
		return nil, ErrContentReferenceConflict
	}
	if err := s.DB.Save(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}
func (s ContentReferenceService) DeletePage(id uuid.UUID) error {
	return deleteExisting(s.DB, &models.GenericPage{}, id)
}

func (s ContentReferenceService) directoryQuery() *gorm.DB {
	return s.DB.Table("ministry_directory md").Select("md.*,d.name AS district_name,r.name AS region_name").Joins("LEFT JOIN districts d ON d.id=md.district_id").Joins("LEFT JOIN regions r ON r.id=md.region_id").Where("md.deleted_at IS NULL")
}
func (s ContentReferenceService) ListDirectory(editor bool, in ContentReferenceQuery) (*PageResult[models.MinistryDirectoryEntry], error) {
	p := in.Page.Normalize(20, 100)
	q := s.directoryQuery()
	if !editor {
		q = q.Where("md.status=?", "active")
	} else if in.Status != "" {
		if !oneOf(in.Status, "active", "inactive", "pending") {
			return nil, ErrContentReferenceInvalid
		}
		q = q.Where("md.status=?", in.Status)
	}
	for raw, column := range map[string]string{in.DistrictID: "md.district_id", in.RegionID: "md.region_id"} {
		if raw != "" {
			id, err := uuid.Parse(raw)
			if err != nil {
				return nil, ErrContentReferenceInvalid
			}
			q = q.Where(column+"=?", id)
		}
	}
	if in.Ministry != "" {
		q = q.Where("md.ministry=?", in.Ministry)
	}
	if in.Department != "" {
		q = q.Where("md.department=?", in.Department)
	}
	if v := strings.TrimSpace(in.Search); v != "" {
		like := "%" + v + "%"
		q = q.Where("LOWER(md.name) LIKE LOWER(?) OR LOWER(md.title) LIKE LOWER(?) OR LOWER(md.ministry) LIKE LOWER(?) OR LOWER(COALESCE(md.department,'')) LIKE LOWER(?)", like, like, like, like)
	}
	return pageHelp[models.MinistryDirectoryEntry](q, p, map[string]string{"name": "md.name", "title": "md.title", "ministry": "md.ministry", "priority_level": "md.priority_level", "created_at": "md.created_at", "updated_at": "md.updated_at"}, in.Sort, in.Order, "md.priority_level ASC, md.name ASC")
}
func (s ContentReferenceService) GetDirectory(id uuid.UUID, editor bool) (*models.MinistryDirectoryEntry, error) {
	q := s.directoryQuery().Where("md.id=?", id)
	if !editor {
		q = q.Where("md.status=?", "active")
	}
	var v models.MinistryDirectoryEntry
	err := q.First(&v).Error
	return &v, err
}
func (s ContentReferenceService) SaveDirectory(id *uuid.UUID, in MinistryDirectoryInput) (*models.MinistryDirectoryEntry, error) {
	v := models.MinistryDirectoryEntry{Status: "pending"}
	if id != nil {
		x, err := s.GetDirectory(*id, true)
		if err != nil {
			return nil, err
		}
		v = *x
	}
	if in.Name != nil {
		v.Name = strings.TrimSpace(*in.Name)
	}
	if in.Title != nil {
		v.Title = strings.TrimSpace(*in.Title)
	}
	if in.Ministry != nil {
		v.Ministry = strings.TrimSpace(*in.Ministry)
	}
	if in.Phone != nil {
		v.Phone = strings.TrimSpace(*in.Phone)
	}
	if in.Status != nil {
		v.Status = strings.TrimSpace(*in.Status)
	}
	v.Department = mergeOptionalString(v.Department, in.Department)
	v.AlternativePhone = mergeOptionalString(v.AlternativePhone, in.AlternativePhone)
	v.Email = mergeOptionalString(v.Email, in.Email)
	v.OfficeAddress = mergeOptionalString(v.OfficeAddress, in.OfficeAddress)
	v.AvailabilityHours = mergeOptionalString(v.AvailabilityHours, in.AvailabilityHours)
	v.Specialization = mergeOptionalString(v.Specialization, in.Specialization)
	v.Notes = mergeOptionalString(v.Notes, in.Notes)
	if in.PriorityLevel != nil {
		v.PriorityLevel = in.PriorityLevel
	}
	if in.DistrictID != nil {
		x, err := uuid.Parse(*in.DistrictID)
		if err != nil {
			return nil, ErrContentReferenceInvalid
		}
		v.DistrictID = x
	}
	if in.RegionID != nil {
		x, err := optionalUUIDInput(in.RegionID)
		if err != nil {
			return nil, ErrContentReferenceInvalid
		}
		v.RegionID = x
	}
	if v.DistrictID == uuid.Nil || v.Name == "" || v.Title == "" || v.Ministry == "" || v.Phone == "" || !oneOf(v.Status, "active", "inactive", "pending") {
		return nil, ErrContentReferenceInvalid
	}
	var district models.District
	if err := s.DB.Where("id=? AND deleted_at IS NULL", v.DistrictID).First(&district).Error; err != nil {
		return nil, ErrContentReferenceInvalid
	}
	if v.RegionID != nil && !existsActive(s.DB, &models.Region{}, *v.RegionID) {
		return nil, ErrContentReferenceInvalid
	}
	if v.RegionID != nil && district.RegionID != *v.RegionID {
		return nil, ErrContentReferenceInvalid
	}
	if err := s.DB.Save(&v).Error; err != nil {
		return nil, err
	}
	return s.GetDirectory(v.ID, true)
}
func (s ContentReferenceService) DeleteDirectory(id uuid.UUID) error {
	return deleteExisting(s.DB, &models.MinistryDirectoryEntry{}, id)
}

func (s ContentReferenceService) ListLanguages(in ContentReferenceQuery) (*PageResult[models.Language], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.Language{})
	if in.Active != nil {
		q = q.Where("is_active=?", *in.Active)
	}
	if in.Default != nil {
		q = q.Where("is_default=?", *in.Default)
	}
	if in.Enabled != nil {
		q = q.Where("enabled_for_users=?", *in.Enabled)
	}
	if in.Status != "" {
		statuses := strings.Split(in.Status, ",")
		for i := range statuses {
			statuses[i] = strings.TrimSpace(statuses[i])
			if !validLanguageStatus(statuses[i]) {
				return nil, ErrContentReferenceInvalid
			}
		}
		q = q.Where("status IN ?", statuses)
	}
	if in.Code != "" {
		q = q.Where("LOWER(code)=LOWER(?)", in.Code)
	}
	if in.ProgressMin != nil {
		q = q.Where("progress>=?", *in.ProgressMin)
	}
	if in.ProgressMax != nil {
		q = q.Where("progress<=?", *in.ProgressMax)
	}
	if v := strings.TrimSpace(in.Search); v != "" {
		like := "%" + v + "%"
		q = q.Where("LOWER(name) LIKE LOWER(?) OR LOWER(native_name) LIKE LOWER(?) OR LOWER(code) LIKE LOWER(?)", like, like, like)
	}
	return pageHelp[models.Language](q, p, map[string]string{"name": "name", "code": "code", "status": "status", "progress": "progress", "created_at": "created_at", "updated_at": "updated_at"}, in.Sort, in.Order, "is_default DESC, name ASC")
}
func (s ContentReferenceService) GetLanguage(id uuid.UUID) (*models.Language, error) {
	var v models.Language
	err := s.DB.First(&v, "id=?", id).Error
	return &v, err
}
func (s ContentReferenceService) SaveLanguage(id *uuid.UUID, in LanguageInput) (*models.Language, error) {
	v := models.Language{IsActive: true, EnabledForUsers: true, Status: "draft"}
	if id != nil {
		x, err := s.GetLanguage(*id)
		if err != nil {
			return nil, err
		}
		v = *x
	}
	if in.Code != nil {
		v.Code = strings.ToLower(strings.TrimSpace(*in.Code))
	}
	if in.Name != nil {
		v.Name = strings.TrimSpace(*in.Name)
	}
	if in.NativeName != nil {
		v.NativeName = strings.TrimSpace(*in.NativeName)
	}
	if in.IsActive != nil {
		v.IsActive = *in.IsActive
	}
	if in.IsDefault != nil {
		v.IsDefault = *in.IsDefault
	}
	if in.EnabledForUsers != nil {
		v.EnabledForUsers = *in.EnabledForUsers
	}
	if in.Status != nil {
		v.Status = strings.TrimSpace(*in.Status)
	}
	if in.TranslationsURL != nil {
		v.TranslationsURL = strings.TrimSpace(*in.TranslationsURL)
	}
	if in.Translations != nil {
		if !json.Valid(*in.Translations) {
			return nil, ErrContentReferenceInvalid
		}
		v.TranslationsJSON = append([]byte(nil), (*in.Translations)...)
	}
	if in.Version != nil {
		v.Version = in.Version
	}
	if in.Progress != nil {
		v.Progress = in.Progress
	}
	if !validLanguageCode(v.Code) || v.Name == "" || v.NativeName == "" || !validLanguageStatus(v.Status) || (v.Progress != nil && (*v.Progress < 0 || *v.Progress > 100)) {
		return nil, ErrContentReferenceInvalid
	}
	var count int64
	q := s.DB.Model(&models.Language{}).Where("LOWER(code)=LOWER(?)", v.Code)
	if id != nil {
		q = q.Where("id<>?", *id)
	}
	if err := q.Count(&count).Error; err != nil {
		return nil, err
	}
	if count > 0 {
		return nil, ErrContentReferenceConflict
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if v.IsDefault {
			if err := tx.Model(&models.Language{}).Where("id<>?", v.ID).Update("is_default", false).Error; err != nil {
				return err
			}
		}
		return tx.Save(&v).Error
	})
	if err != nil {
		return nil, err
	}
	return &v, nil
}
func (s ContentReferenceService) DeleteLanguage(id uuid.UUID) error {
	v, err := s.GetLanguage(id)
	if err != nil {
		return err
	}
	if v.IsDefault {
		return ErrDefaultLanguage
	}
	return deleteExisting(s.DB, &models.Language{}, id)
}
func existsActive(db *gorm.DB, model any, id uuid.UUID) bool {
	var count int64
	return db.Model(model).Where("id=? AND deleted_at IS NULL", id).Count(&count).Error == nil && count == 1
}

var contentKeyPattern = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)
var languageCodePattern = regexp.MustCompile(`^[a-z]{2,3}(?:-[a-z0-9]{2,8})?$`)

func validContentKey(v string) bool   { return contentKeyPattern.MatchString(v) }
func validLanguageCode(v string) bool { return languageCodePattern.MatchString(v) }
func validLanguageStatus(v string) bool {
	return oneOf(v, "draft", "in_progress", "complete", "review")
}
