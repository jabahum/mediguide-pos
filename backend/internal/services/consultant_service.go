package services

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrConsultantInvalid = errors.New("invalid consultant payload")

type ConsultantService struct{ DB *gorm.DB }

type ConsultantQuery struct {
	Page             PageInput
	Search           string
	Status           string
	Specialty        string
	Qualification    string
	Language         string
	Region           string
	City             string
	ConsultationType string
	Verified         *bool
	Sort             string
	Order            string
	IncludeInactive  bool
}

type ConsultantInput struct {
	UserID             *uuid.UUID       `json:"user_id"`
	Name               *string          `json:"name"`
	Email              *string          `json:"email"`
	Phone              *string          `json:"phone"`
	AlternativePhone   *string          `json:"alternative_phone"`
	ProfilePicture     *json.RawMessage `json:"profile_picture" swaggertype:"object"`
	Avatar             *json.RawMessage `json:"avatar" swaggertype:"object"`
	Specialty          *string          `json:"specialty"`
	LicenseNumber      *string          `json:"license_number"`
	YearsOfExperience  *float64         `json:"years_of_experience"`
	Qualifications     *[]string        `json:"qualifications"`
	Certifications     *string          `json:"certifications"`
	Address            *string          `json:"address"`
	City               *string          `json:"city"`
	Region             *string          `json:"region"`
	Country            *string          `json:"country"`
	PostalCode         *string          `json:"postal_code"`
	Organization       *string          `json:"organization"`
	Department         *string          `json:"department"`
	PreferredLanguage  *string          `json:"preferred_language"`
	Timezone           *string          `json:"timezone"`
	Availability       *json.RawMessage `json:"availability" swaggertype:"object"`
	ConsultationTypes  *[]string        `json:"consultation_types"`
	Status             *string          `json:"status"`
	IsVerified         *bool            `json:"is_verified"`
	Rating             *float64         `json:"rating"`
	TotalConsultations *int             `json:"total_consultations"`
	Notes              *string          `json:"notes"`
}

type ConsultantUserView struct {
	ID       uuid.UUID `json:"id"`
	Name     string    `json:"name"`
	Email    string    `json:"email"`
	Avatar   string    `json:"avatar,omitempty"`
	Verified bool      `json:"verified"`
}

type ConsultantView struct {
	models.Consultant
	ProfilePicture    json.RawMessage     `json:"profile_picture,omitempty" swaggertype:"object"`
	Avatar            json.RawMessage     `json:"avatar,omitempty" swaggertype:"object"`
	Availability      json.RawMessage     `json:"availability,omitempty" swaggertype:"object"`
	Qualifications    []string            `json:"qualifications"`
	ConsultationTypes []string            `json:"consultation_types"`
	User              *ConsultantUserView `json:"user,omitempty" gorm:"-"`
	UserName          string              `json:"-" gorm:"column:user_name"`
	UserEmail         string              `json:"-" gorm:"column:user_email"`
	UserAvatar        string              `json:"-" gorm:"column:user_avatar"`
	UserVerified      bool                `json:"-" gorm:"column:user_verified"`
}

type ConsultantPage struct {
	Items      []ConsultantView `json:"items"`
	Page       int              `json:"page"`
	PerPage    int              `json:"per_page"`
	TotalItems int64            `json:"total_items"`
	TotalPages int              `json:"total_pages"`
}

type ConsultantItem struct {
	Item ConsultantView `json:"item"`
}

func (s ConsultantService) List(in ConsultantQuery) (*ConsultantPage, error) {
	page := in.Page.Normalize(20, 100)
	query := s.query()
	if !in.IncludeInactive {
		query = query.Where("c.status = ?", "active")
	}
	if q := strings.TrimSpace(in.Search); q != "" {
		like := "%" + strings.ToLower(q) + "%"
		query = query.Where("lower(c.name) LIKE ? OR lower(c.email) LIKE ? OR lower(c.specialty) LIKE ? OR lower(coalesce(c.organization,'')) LIKE ? OR lower(coalesce(c.city,'')) LIKE ? OR lower(c.country) LIKE ?", like, like, like, like, like, like)
	}
	for column, value := range map[string]string{
		"c.status": in.Status, "c.specialty": in.Specialty, "c.preferred_language": in.Language,
		"c.region": in.Region, "c.city": in.City,
	} {
		if value = strings.TrimSpace(value); value != "" {
			query = query.Where("lower("+column+") = ?", strings.ToLower(value))
		}
	}
	if v := strings.TrimSpace(in.Qualification); v != "" {
		query = query.Where("lower(coalesce(c.qualifications,'')) LIKE ?", "%"+strings.ToLower(v)+"%")
	}
	if v := strings.TrimSpace(in.ConsultationType); v != "" {
		query = query.Where("lower(coalesce(c.consultation_types,'')) LIKE ?", "%"+strings.ToLower(v)+"%")
	}
	if in.Verified != nil {
		query = query.Where("c.is_verified = ?", *in.Verified)
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Distinct("c.id").Count(&total).Error; err != nil {
		return nil, err
	}
	order, err := consultantOrder(in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	rows := []ConsultantView{}
	if err := query.Select(consultantSelect).Order(order).Offset(page.Offset()).Limit(page.PerPage).Scan(&rows).Error; err != nil {
		return nil, err
	}
	for i := range rows {
		normalizeConsultantView(&rows[i])
	}
	result := NewPageResult(rows, page, total)
	return &ConsultantPage{result.Items, result.Page, result.PerPage, result.TotalItems, result.TotalPages}, nil
}

func (s ConsultantService) Get(id uuid.UUID, includeInactive bool) (*ConsultantItem, error) {
	query := s.query().Where("c.id = ?", id)
	if !includeInactive {
		query = query.Where("c.status = ?", "active")
	}
	var row ConsultantView
	if err := query.Select(consultantSelect).Take(&row).Error; err != nil {
		return nil, err
	}
	normalizeConsultantView(&row)
	return &ConsultantItem{Item: row}, nil
}

func (s ConsultantService) Create(in ConsultantInput) (*ConsultantItem, error) {
	item := models.Consultant{Status: "pending_approval"}
	applyConsultantInput(&item, in)
	if err := validateConsultant(&item, in); err != nil {
		return nil, err
	}
	if err := s.validateUser(item.UserID); err != nil {
		return nil, err
	}
	if err := s.DB.Create(&item).Error; err != nil {
		return nil, err
	}
	return s.Get(item.ID, true)
}

func (s ConsultantService) Update(id uuid.UUID, in ConsultantInput) (*ConsultantItem, error) {
	var item models.Consultant
	if err := s.DB.First(&item, "id = ?", id).Error; err != nil {
		return nil, err
	}
	applyConsultantInput(&item, in)
	if err := validateConsultant(&item, in); err != nil {
		return nil, err
	}
	if err := s.validateUser(item.UserID); err != nil {
		return nil, err
	}
	item.UpdatedAt = time.Now()
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return s.Get(id, true)
}

func (s ConsultantService) Delete(id uuid.UUID) error {
	result := s.DB.Delete(&models.Consultant{}, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s ConsultantService) query() *gorm.DB {
	return s.DB.Table("consultants c").Joins("LEFT JOIN users u ON u.id = c.user_id").Where("c.deleted_at IS NULL")
}

const consultantSelect = "c.*, u.name AS user_name, u.email AS user_email, coalesce(u.avatar,'') AS user_avatar, coalesce(u.verified,false) AS user_verified"

func (s ConsultantService) validateUser(id *uuid.UUID) error {
	if id == nil {
		return nil
	}
	var count int64
	if err := s.DB.Table("users").Where("id = ? AND deleted_at IS NULL", *id).Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return ErrConsultantInvalid
	}
	return nil
}

func consultantOrder(sort, order string) (string, error) {
	columns := map[string]string{"": "c.name", "name": "c.name", "created_at": "c.created_at", "updated_at": "c.updated_at", "rating": "c.rating", "total_consultations": "c.total_consultations", "usage_count": "c.usage_count", "specialty": "c.specialty"}
	column, ok := columns[strings.TrimSpace(sort)]
	if !ok {
		return "", ErrConsultantInvalid
	}
	direction := strings.ToUpper(strings.TrimSpace(order))
	if direction == "" {
		direction = "ASC"
	}
	if direction != "ASC" && direction != "DESC" {
		return "", ErrConsultantInvalid
	}
	return column + " " + direction + ", c.id " + direction, nil
}

func applyConsultantInput(item *models.Consultant, in ConsultantInput) {
	if in.UserID != nil {
		item.UserID = in.UserID
	}
	if in.Name != nil {
		item.Name = strings.TrimSpace(*in.Name)
	}
	if in.Email != nil {
		item.Email = strings.ToLower(strings.TrimSpace(*in.Email))
	}
	if in.Phone != nil {
		item.Phone = strings.TrimSpace(*in.Phone)
	}
	if in.AlternativePhone != nil {
		item.AlternativePhone = cleanOptional(in.AlternativePhone)
	}
	if in.ProfilePicture != nil {
		item.ProfilePictureJSON = models.JSONOrNull(*in.ProfilePicture)
	}
	if in.Avatar != nil {
		item.AvatarJSON = models.JSONOrNull(*in.Avatar)
	}
	if in.Specialty != nil {
		item.Specialty = strings.TrimSpace(*in.Specialty)
	}
	if in.LicenseNumber != nil {
		item.LicenseNumber = cleanOptional(in.LicenseNumber)
	}
	if in.YearsOfExperience != nil {
		item.YearsOfExperience = in.YearsOfExperience
	}
	if in.Qualifications != nil {
		item.Qualifications = encodedStringList(*in.Qualifications)
	}
	if in.Certifications != nil {
		item.Certifications = cleanOptional(in.Certifications)
	}
	if in.Address != nil {
		item.Address = cleanOptional(in.Address)
	}
	if in.City != nil {
		item.City = cleanOptional(in.City)
	}
	if in.Region != nil {
		item.Region = cleanOptional(in.Region)
	}
	if in.Country != nil {
		item.Country = strings.TrimSpace(*in.Country)
	}
	if in.PostalCode != nil {
		item.PostalCode = cleanOptional(in.PostalCode)
	}
	if in.Organization != nil {
		item.Organization = cleanOptional(in.Organization)
	}
	if in.Department != nil {
		item.Department = cleanOptional(in.Department)
	}
	if in.PreferredLanguage != nil {
		item.PreferredLanguage = cleanOptional(in.PreferredLanguage)
	}
	if in.Timezone != nil {
		item.Timezone = cleanOptional(in.Timezone)
	}
	if in.Availability != nil {
		item.AvailabilityJSON = models.JSONOrNull(*in.Availability)
	}
	if in.ConsultationTypes != nil {
		item.ConsultationTypes = encodedStringList(*in.ConsultationTypes)
	}
	if in.Status != nil {
		item.Status = strings.TrimSpace(*in.Status)
	}
	if in.IsVerified != nil {
		item.IsVerified = *in.IsVerified
	}
	if in.Rating != nil {
		item.Rating = in.Rating
	}
	if in.TotalConsultations != nil {
		item.TotalConsultations = *in.TotalConsultations
	}
	if in.Notes != nil {
		item.Notes = cleanOptional(in.Notes)
	}
}

func validateConsultant(item *models.Consultant, in ConsultantInput) error {
	if item.Name == "" || item.Email == "" || !strings.Contains(item.Email, "@") || item.Phone == "" || item.Specialty == "" || item.Country == "" {
		return ErrConsultantInvalid
	}
	allowed := map[string]bool{"active": true, "inactive": true, "pending_approval": true, "suspended": true}
	if !allowed[item.Status] || (item.YearsOfExperience != nil && *item.YearsOfExperience < 0) || (item.Rating != nil && (*item.Rating < 0 || *item.Rating > 5)) || item.TotalConsultations < 0 {
		return ErrConsultantInvalid
	}
	for _, raw := range []*json.RawMessage{in.ProfilePicture, in.Avatar, in.Availability} {
		if raw != nil && len(*raw) > 0 && !json.Valid(*raw) {
			return ErrConsultantInvalid
		}
	}
	return nil
}

func encodedStringList(values []string) *string {
	clean := make([]string, 0, len(values))
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			clean = append(clean, value)
		}
	}
	data, _ := json.Marshal(clean)
	v := string(data)
	return &v
}

func decodedStringList(value *string) []string {
	if value == nil || strings.TrimSpace(*value) == "" {
		return []string{}
	}
	var values []string
	if json.Unmarshal([]byte(*value), &values) == nil {
		return values
	}
	for _, value := range strings.Split(*value, ",") {
		if value = strings.TrimSpace(value); value != "" {
			values = append(values, value)
		}
	}
	return values
}

func normalizeConsultantView(row *ConsultantView) {
	row.ProfilePicture = json.RawMessage(row.ProfilePictureJSON)
	row.Avatar = json.RawMessage(row.AvatarJSON)
	row.Availability = json.RawMessage(row.AvailabilityJSON)
	row.Qualifications = decodedStringList(row.Consultant.Qualifications)
	row.ConsultationTypes = decodedStringList(row.Consultant.ConsultationTypes)
	if row.UserID != nil {
		row.User = &ConsultantUserView{ID: *row.UserID, Name: row.UserName, Email: row.UserEmail, Avatar: row.UserAvatar, Verified: row.UserVerified}
	}
}
