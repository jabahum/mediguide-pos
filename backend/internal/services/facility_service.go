package services

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrFacilityInvalid = errors.New("invalid facility payload")

type FacilityService struct{ DB *gorm.DB }

type FacilityQuery struct {
	Page                PageInput
	Search              string
	RegionID            *uuid.UUID
	HealthSubRegionID   *uuid.UUID
	DistrictID          *uuid.UUID
	HealthSubDistrictID *uuid.UUID
	CountyID            *uuid.UUID
	SubcountyID         *uuid.UUID
	ParishID            *uuid.UUID
	FacilityLevelID     *uuid.UUID
	OwnershipTypeID     *uuid.UUID
	AuthorityID         *uuid.UUID
	Sort                string
	Order               string
}

type FacilityInput struct {
	Name                *string    `json:"name"`
	NHPICode            *string    `json:"nhpi_code"`
	HSDTCode            *string    `json:"hsdt_code"`
	FacilityLevelID     *uuid.UUID `json:"facility_level_id"`
	AuthorityID         *uuid.UUID `json:"authority_id"`
	OwnershipTypeID     *uuid.UUID `json:"ownership_type_id"`
	HealthSubDistrictID *uuid.UUID `json:"health_sub_district_id"`
	ParishID            *uuid.UUID `json:"parish_id"`
	SubcountyID         *uuid.UUID `json:"subcounty_id"`
	CountyID            *uuid.UUID `json:"county_id"`
	DistrictID          *uuid.UUID `json:"district_id"`
	HealthSubRegionID   *uuid.UUID `json:"health_sub_region_id"`
	RegionID            *uuid.UUID `json:"region_id"`
}

type FacilityView struct {
	models.HealthFacility
	FacilityLevelName     string `json:"facility_level_name"`
	AuthorityName         string `json:"authority_name"`
	OwnershipTypeName     string `json:"ownership_type_name"`
	HealthSubDistrictName string `json:"health_sub_district_name"`
	ParishName            string `json:"parish_name"`
	SubcountyName         string `json:"subcounty_name"`
	CountyName            string `json:"county_name"`
	DistrictName          string `json:"district_name"`
	HealthSubRegionName   string `json:"health_sub_region_name"`
	RegionName            string `json:"region_name"`
}

type FacilityPage struct {
	Success    bool           `json:"success"`
	Resource   string         `json:"resource"`
	Page       int            `json:"page"`
	PerPage    int            `json:"per_page"`
	TotalItems int64          `json:"total_items"`
	TotalPages int            `json:"total_pages"`
	Items      []FacilityView `json:"items"`
}

type FacilityItem struct {
	Success  bool         `json:"success"`
	Resource string       `json:"resource"`
	Item     FacilityView `json:"item"`
}

func (s FacilityService) ListFacilities(in FacilityQuery) (*FacilityPage, error) {
	page := in.Page.Normalize(20, 100)
	query := s.facilityQuery()
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(hf.name) LIKE ? OR lower(hf.nhpi_code) LIKE ? OR lower(hf.hsdt_code) LIKE ? OR lower(coalesce(d.name, '')) LIKE ?", like, like, like, like)
	}
	filters := []struct {
		column string
		value  *uuid.UUID
	}{
		{"hf.region_id", in.RegionID}, {"hf.health_sub_region_id", in.HealthSubRegionID},
		{"hf.district_id", in.DistrictID}, {"hf.health_sub_district_id", in.HealthSubDistrictID},
		{"hf.county_id", in.CountyID}, {"hf.subcounty_id", in.SubcountyID}, {"hf.parish_id", in.ParishID},
		{"hf.facility_level_id", in.FacilityLevelID}, {"hf.ownership_type_id", in.OwnershipTypeID}, {"hf.authority_id", in.AuthorityID},
	}
	for _, filter := range filters {
		if filter.value != nil {
			query = query.Where(filter.column+" = ?", *filter.value)
		}
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Distinct("hf.id").Count(&total).Error; err != nil {
		return nil, err
	}
	order, err := facilityOrder(in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	items := []FacilityView{}
	if err := query.Select(facilitySelect).Order(order).Offset(page.Offset()).Limit(page.PerPage).Scan(&items).Error; err != nil {
		return nil, err
	}
	totalPages := 0
	if total > 0 {
		totalPages = int((total + int64(page.PerPage) - 1) / int64(page.PerPage))
	}
	return &FacilityPage{true, "health_facilities", page.Page, page.PerPage, total, totalPages, items}, nil
}

func (s FacilityService) GetFacility(id uuid.UUID) (*FacilityItem, error) {
	var item FacilityView
	if err := s.facilityQuery().Select(facilitySelect).Where("hf.id = ?", id).Take(&item).Error; err != nil {
		return nil, err
	}
	return &FacilityItem{Success: true, Resource: "health_facilities", Item: item}, nil
}

func (s FacilityService) CreateFacility(in FacilityInput) (*FacilityItem, error) {
	model, err := facilityFromInput(in)
	if err != nil {
		return nil, err
	}
	if err := s.validateFacility(model); err != nil {
		return nil, err
	}
	if err := s.DB.Create(model).Error; err != nil {
		return nil, err
	}
	return s.GetFacility(model.ID)
}

func (s FacilityService) UpdateFacility(id uuid.UUID, in FacilityInput) (*FacilityItem, error) {
	var current models.HealthFacility
	if err := s.DB.First(&current, "id = ?", id).Error; err != nil {
		return nil, err
	}
	applyFacilityInput(&current, in)
	if err := s.validateFacility(&current); err != nil {
		return nil, err
	}
	current.UpdatedAt = time.Now()
	if err := s.DB.Save(&current).Error; err != nil {
		return nil, err
	}
	return s.GetFacility(id)
}

func (s FacilityService) DeleteFacility(id uuid.UUID) error {
	result := s.DB.Delete(&models.HealthFacility{}, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s FacilityService) RecordUsage(userID, facilityID uuid.UUID) (*models.FacilityUsageLog, error) {
	var count int64
	if err := s.DB.Model(&models.HealthFacility{}).Where("id = ? AND deleted_at IS NULL", facilityID).Count(&count).Error; err != nil || count == 0 {
		return nil, gorm.ErrRecordNotFound
	}
	usage := models.FacilityUsageLog{UserID: userID, FacilityID: facilityID}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&usage).Error; err != nil {
			return err
		}
		return tx.Model(&models.HealthFacility{}).Where("id = ?", facilityID).UpdateColumn("usage_count", gorm.Expr("usage_count + 1")).Error
	}); err != nil {
		return nil, err
	}
	return &usage, nil
}

func (s FacilityService) validateFacility(f *models.HealthFacility) error {
	if strings.TrimSpace(f.Name) == "" || strings.TrimSpace(f.NHPICode) == "" || strings.TrimSpace(f.HSDTCode) == "" {
		return ErrFacilityInvalid
	}
	var hsr models.HealthSubRegion
	var district models.District
	var county models.County
	var subcounty models.Subcounty
	var hsd models.HealthSubDistrict
	var authority models.Authority
	if s.DB.First(&hsr, "id = ?", f.HealthSubRegionID).Error != nil || hsr.RegionID != f.RegionID ||
		s.DB.First(&district, "id = ?", f.DistrictID).Error != nil || district.RegionID != f.RegionID || district.HealthSubRegionID != f.HealthSubRegionID ||
		s.DB.First(&county, "id = ?", f.CountyID).Error != nil || county.DistrictID != f.DistrictID ||
		s.DB.First(&subcounty, "id = ?", f.SubcountyID).Error != nil || subcounty.CountyID != f.CountyID || subcounty.DistrictID != f.DistrictID ||
		s.DB.First(&hsd, "id = ?", f.HealthSubDistrictID).Error != nil || hsd.DistrictID != f.DistrictID ||
		s.DB.First(&authority, "id = ?", f.AuthorityID).Error != nil || authority.OwnershipTypeID != f.OwnershipTypeID ||
		!existsByID(s.DB, "facility_levels", f.FacilityLevelID) || !existsByID(s.DB, "ownership_types", f.OwnershipTypeID) {
		return ErrFacilityInvalid
	}
	if f.ParishID != nil {
		var parish models.Parish
		if s.DB.First(&parish, "id = ?", *f.ParishID).Error != nil || parish.SubcountyID != f.SubcountyID {
			return ErrFacilityInvalid
		}
	}
	return nil
}

func (s FacilityService) facilityQuery() *gorm.DB {
	return s.DB.Table("health_facilities hf").
		Joins("LEFT JOIN facility_levels fl ON fl.id = hf.facility_level_id").
		Joins("LEFT JOIN authorities a ON a.id = hf.authority_id").
		Joins("LEFT JOIN ownership_types ot ON ot.id = hf.ownership_type_id").
		Joins("LEFT JOIN health_sub_districts hsd ON hsd.id = hf.health_sub_district_id").
		Joins("LEFT JOIN parishes p ON p.id = hf.parish_id").
		Joins("LEFT JOIN subcounties sc ON sc.id = hf.subcounty_id").
		Joins("LEFT JOIN counties c ON c.id = hf.county_id").
		Joins("LEFT JOIN districts d ON d.id = hf.district_id").
		Joins("LEFT JOIN health_sub_regions hsr ON hsr.id = hf.health_sub_region_id").
		Joins("LEFT JOIN regions r ON r.id = hf.region_id").Where("hf.deleted_at IS NULL")
}

const facilitySelect = "hf.*, fl.name AS facility_level_name, a.name AS authority_name, ot.name AS ownership_type_name, hsd.name AS health_sub_district_name, p.name AS parish_name, sc.name AS subcounty_name, c.name AS county_name, d.name AS district_name, hsr.name AS health_sub_region_name, r.name AS region_name"

func facilityOrder(sort, order string) (string, error) {
	columns := map[string]string{"": "hf.name", "name": "hf.name", "created_at": "hf.created_at", "updated_at": "hf.updated_at", "usage_count": "hf.usage_count"}
	column, ok := columns[strings.TrimSpace(sort)]
	if !ok {
		return "", ErrFacilityInvalid
	}
	direction := strings.ToUpper(strings.TrimSpace(order))
	if direction == "" {
		direction = "ASC"
	}
	if direction != "ASC" && direction != "DESC" {
		return "", ErrFacilityInvalid
	}
	return fmt.Sprintf("%s %s", column, direction), nil
}

func facilityFromInput(in FacilityInput) (*models.HealthFacility, error) {
	if in.Name == nil || in.NHPICode == nil || in.HSDTCode == nil || in.FacilityLevelID == nil || in.AuthorityID == nil || in.OwnershipTypeID == nil || in.HealthSubDistrictID == nil || in.SubcountyID == nil || in.CountyID == nil || in.DistrictID == nil || in.HealthSubRegionID == nil || in.RegionID == nil {
		return nil, ErrFacilityInvalid
	}
	f := &models.HealthFacility{}
	applyFacilityInput(f, in)
	return f, nil
}

func applyFacilityInput(f *models.HealthFacility, in FacilityInput) {
	if in.Name != nil {
		f.Name = strings.TrimSpace(*in.Name)
	}
	if in.NHPICode != nil {
		f.NHPICode = strings.TrimSpace(*in.NHPICode)
	}
	if in.HSDTCode != nil {
		f.HSDTCode = strings.TrimSpace(*in.HSDTCode)
	}
	if in.FacilityLevelID != nil {
		f.FacilityLevelID = *in.FacilityLevelID
	}
	if in.AuthorityID != nil {
		f.AuthorityID = *in.AuthorityID
	}
	if in.OwnershipTypeID != nil {
		f.OwnershipTypeID = *in.OwnershipTypeID
	}
	if in.HealthSubDistrictID != nil {
		f.HealthSubDistrictID = *in.HealthSubDistrictID
	}
	if in.ParishID != nil {
		f.ParishID = in.ParishID
	}
	if in.SubcountyID != nil {
		f.SubcountyID = *in.SubcountyID
	}
	if in.CountyID != nil {
		f.CountyID = *in.CountyID
	}
	if in.DistrictID != nil {
		f.DistrictID = *in.DistrictID
	}
	if in.HealthSubRegionID != nil {
		f.HealthSubRegionID = *in.HealthSubRegionID
	}
	if in.RegionID != nil {
		f.RegionID = *in.RegionID
	}
}

func existsByID(db *gorm.DB, table string, id uuid.UUID) bool {
	if id == uuid.Nil {
		return false
	}
	var count int64
	return db.Table(table).Where("id = ? AND deleted_at IS NULL", id).Count(&count).Error == nil && count > 0
}
