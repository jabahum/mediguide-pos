package services

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FacilityReference string

const (
	ReferenceRegions            FacilityReference = "regions"
	ReferenceHealthSubRegions   FacilityReference = "health_sub_regions"
	ReferenceDistricts          FacilityReference = "districts"
	ReferenceHealthSubDistricts FacilityReference = "health_sub_districts"
	ReferenceCounties           FacilityReference = "counties"
	ReferenceSubcounties        FacilityReference = "subcounties"
	ReferenceParishes           FacilityReference = "parishes"
	ReferenceFacilityLevels     FacilityReference = "facility_levels"
	ReferenceOwnershipTypes     FacilityReference = "ownership_types"
	ReferenceAuthorities        FacilityReference = "authorities"
)

type FacilityReferenceInput struct {
	Name              *string    `json:"name"`
	Code              *string    `json:"code"`
	NHPICode          *string    `json:"nhpi_code"`
	HSDTCode          *string    `json:"hsdt_code"`
	RegionID          *uuid.UUID `json:"region_id"`
	HealthSubRegionID *uuid.UUID `json:"health_sub_region_id"`
	DistrictID        *uuid.UUID `json:"district_id"`
	CountyID          *uuid.UUID `json:"county_id"`
	SubcountyID       *uuid.UUID `json:"subcounty_id"`
	OwnershipTypeID   *uuid.UUID `json:"ownership_type_id"`
}

type FacilityReferenceQuery struct {
	Page              PageInput
	Search            string
	RegionID          *uuid.UUID
	HealthSubRegionID *uuid.UUID
	DistrictID        *uuid.UUID
	CountyID          *uuid.UUID
	SubcountyID       *uuid.UUID
	OwnershipTypeID   *uuid.UUID
	Sort              string
	Order             string
}

type FacilityReferenceView struct {
	ID                  uuid.UUID  `json:"id"`
	Name                string     `json:"name"`
	Code                *string    `json:"code,omitempty"`
	NHPICode            string     `json:"nhpi_code,omitempty"`
	HSDTCode            string     `json:"hsdt_code,omitempty"`
	RegionID            *uuid.UUID `json:"region_id,omitempty"`
	HealthSubRegionID   *uuid.UUID `json:"health_sub_region_id,omitempty"`
	DistrictID          *uuid.UUID `json:"district_id,omitempty"`
	CountyID            *uuid.UUID `json:"county_id,omitempty"`
	SubcountyID         *uuid.UUID `json:"subcounty_id,omitempty"`
	OwnershipTypeID     *uuid.UUID `json:"ownership_type_id,omitempty"`
	RegionName          string     `json:"region_name,omitempty"`
	HealthSubRegionName string     `json:"health_sub_region_name,omitempty"`
	DistrictName        string     `json:"district_name,omitempty"`
	CountyName          string     `json:"county_name,omitempty"`
	SubcountyName       string     `json:"subcounty_name,omitempty"`
	OwnershipTypeName   string     `json:"ownership_type_name,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

type FacilityReferencePage struct {
	Success    bool                    `json:"success"`
	Resource   string                  `json:"resource"`
	Page       int                     `json:"page"`
	PerPage    int                     `json:"per_page"`
	TotalItems int64                   `json:"total_items"`
	TotalPages int                     `json:"total_pages"`
	Items      []FacilityReferenceView `json:"items"`
}

type FacilityReferenceItem struct {
	Success  bool                  `json:"success"`
	Resource string                `json:"resource"`
	Item     FacilityReferenceView `json:"item"`
}

type RegionChildren struct {
	Region           FacilityReferenceView   `json:"region"`
	HealthSubRegions []FacilityReferenceView `json:"health_sub_regions"`
	Districts        []FacilityReferenceView `json:"districts"`
}

func (s FacilityService) GetRegionChildren(id uuid.UUID) (*RegionChildren, error) {
	region, err := s.GetReference(ReferenceRegions, id)
	if err != nil {
		return nil, err
	}
	page := PageInput{Page: 1, PerPage: 100}
	hsr, err := s.ListReferences(ReferenceHealthSubRegions, FacilityReferenceQuery{Page: page, RegionID: &id})
	if err != nil {
		return nil, err
	}
	districts, err := s.ListReferences(ReferenceDistricts, FacilityReferenceQuery{Page: page, RegionID: &id})
	if err != nil {
		return nil, err
	}
	return &RegionChildren{Region: region.Item, HealthSubRegions: hsr.Items, Districts: districts.Items}, nil
}

type facilityReferenceSpec struct {
	table, alias, selectSQL string
	joins                   []string
	filterColumns           map[string]string
}

func (s FacilityService) ListReferences(resource FacilityReference, in FacilityReferenceQuery) (*FacilityReferencePage, error) {
	spec, ok := facilityReferenceSpecs[resource]
	if !ok {
		return nil, ErrFacilityInvalid
	}
	page := in.Page.Normalize(20, 100)
	query := s.referenceQuery(spec)
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower("+spec.alias+".name) LIKE ?", like)
	}
	filters := map[string]*uuid.UUID{
		"region_id": in.RegionID, "health_sub_region_id": in.HealthSubRegionID,
		"district_id": in.DistrictID, "county_id": in.CountyID,
		"subcounty_id": in.SubcountyID, "ownership_type_id": in.OwnershipTypeID,
	}
	for key, value := range filters {
		if value != nil {
			column, allowed := spec.filterColumns[key]
			if !allowed {
				return nil, ErrFacilityInvalid
			}
			query = query.Where(column+" = ?", *value)
		}
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Distinct(spec.alias + ".id").Count(&total).Error; err != nil {
		return nil, err
	}
	order, err := referenceOrder(spec.alias, in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	items := []FacilityReferenceView{}
	if err := query.Select(spec.selectSQL).Order(order).Offset(page.Offset()).Limit(page.PerPage).Scan(&items).Error; err != nil {
		return nil, err
	}
	totalPages := 0
	if total > 0 {
		totalPages = int((total + int64(page.PerPage) - 1) / int64(page.PerPage))
	}
	return &FacilityReferencePage{true, string(resource), page.Page, page.PerPage, total, totalPages, items}, nil
}

func (s FacilityService) GetReference(resource FacilityReference, id uuid.UUID) (*FacilityReferenceItem, error) {
	spec, ok := facilityReferenceSpecs[resource]
	if !ok {
		return nil, ErrFacilityInvalid
	}
	var item FacilityReferenceView
	if err := s.referenceQuery(spec).Select(spec.selectSQL).Where(spec.alias+".id = ?", id).Take(&item).Error; err != nil {
		return nil, err
	}
	return &FacilityReferenceItem{true, string(resource), item}, nil
}

func (s FacilityService) CreateReference(resource FacilityReference, in FacilityReferenceInput) (*FacilityReferenceItem, error) {
	if err := s.validateReference(resource, in); err != nil {
		return nil, err
	}
	values := referenceValues(in)
	values["id"] = uuid.New()
	values["created_at"], values["updated_at"] = time.Now(), time.Now()
	spec := facilityReferenceSpecs[resource]
	if err := s.DB.Table(spec.table).Create(&values).Error; err != nil {
		return nil, err
	}
	return s.GetReference(resource, values["id"].(uuid.UUID))
}

func (s FacilityService) UpdateReference(resource FacilityReference, id uuid.UUID, in FacilityReferenceInput) (*FacilityReferenceItem, error) {
	current, err := s.GetReference(resource, id)
	if err != nil {
		return nil, err
	}
	merged := mergeReferenceInput(current.Item, in)
	if err := s.validateReference(resource, merged); err != nil {
		return nil, err
	}
	values := referenceValues(in)
	if len(values) == 0 {
		return nil, ErrFacilityInvalid
	}
	values["updated_at"] = time.Now()
	spec := facilityReferenceSpecs[resource]
	if err := s.DB.Table(spec.table).Where("id = ? AND deleted_at IS NULL", id).Updates(values).Error; err != nil {
		return nil, err
	}
	return s.GetReference(resource, id)
}

func (s FacilityService) DeleteReference(resource FacilityReference, id uuid.UUID) error {
	spec, ok := facilityReferenceSpecs[resource]
	if !ok {
		return ErrFacilityInvalid
	}
	if s.referenceHasChildren(resource, id) {
		return ErrFacilityInvalid
	}
	result := s.DB.Table(spec.table).Where("id = ? AND deleted_at IS NULL", id).Update("deleted_at", time.Now())
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s FacilityService) referenceHasChildren(resource FacilityReference, id uuid.UUID) bool {
	references := map[FacilityReference][]struct{ table, column string }{
		ReferenceRegions:            {{"health_sub_regions", "region_id"}, {"districts", "region_id"}, {"health_facilities", "region_id"}},
		ReferenceHealthSubRegions:   {{"districts", "health_sub_region_id"}, {"health_facilities", "health_sub_region_id"}},
		ReferenceDistricts:          {{"health_sub_districts", "district_id"}, {"counties", "district_id"}, {"subcounties", "district_id"}, {"health_facilities", "district_id"}},
		ReferenceHealthSubDistricts: {{"health_facilities", "health_sub_district_id"}},
		ReferenceCounties:           {{"subcounties", "county_id"}, {"health_facilities", "county_id"}},
		ReferenceSubcounties:        {{"parishes", "subcounty_id"}, {"health_facilities", "subcounty_id"}},
		ReferenceParishes:           {{"health_facilities", "parish_id"}},
		ReferenceFacilityLevels:     {{"health_facilities", "facility_level_id"}},
		ReferenceOwnershipTypes:     {{"authorities", "ownership_type_id"}, {"health_facilities", "ownership_type_id"}},
		ReferenceAuthorities:        {{"health_facilities", "authority_id"}},
	}
	for _, ref := range references[resource] {
		var count int64
		if s.DB.Table(ref.table).Where(ref.column+" = ? AND deleted_at IS NULL", id).Count(&count).Error != nil || count > 0 {
			return true
		}
	}
	return false
}

func (s FacilityService) validateReference(resource FacilityReference, in FacilityReferenceInput) error {
	if in.Name == nil || strings.TrimSpace(*in.Name) == "" {
		return ErrFacilityInvalid
	}
	switch resource {
	case ReferenceRegions:
		return requireCodes(in)
	case ReferenceHealthSubRegions:
		if requireCodes(in) != nil || in.RegionID == nil || !existsByID(s.DB, "regions", *in.RegionID) {
			return ErrFacilityInvalid
		}
	case ReferenceDistricts:
		if requireCodes(in) != nil || in.RegionID == nil || in.HealthSubRegionID == nil {
			return ErrFacilityInvalid
		}
		var hsr struct{ RegionID uuid.UUID }
		if s.DB.Table("health_sub_regions").Select("region_id").Where("id = ? AND deleted_at IS NULL", *in.HealthSubRegionID).Take(&hsr).Error != nil || hsr.RegionID != *in.RegionID {
			return ErrFacilityInvalid
		}
	case ReferenceHealthSubDistricts, ReferenceCounties:
		if requireCodes(in) != nil || in.DistrictID == nil || !existsByID(s.DB, "districts", *in.DistrictID) {
			return ErrFacilityInvalid
		}
	case ReferenceSubcounties:
		if requireCodes(in) != nil || in.CountyID == nil || in.DistrictID == nil {
			return ErrFacilityInvalid
		}
		var county struct{ DistrictID uuid.UUID }
		if s.DB.Table("counties").Select("district_id").Where("id = ? AND deleted_at IS NULL", *in.CountyID).Take(&county).Error != nil || county.DistrictID != *in.DistrictID {
			return ErrFacilityInvalid
		}
	case ReferenceParishes:
		if requireCodes(in) != nil || in.SubcountyID == nil || !existsByID(s.DB, "subcounties", *in.SubcountyID) {
			return ErrFacilityInvalid
		}
	case ReferenceFacilityLevels, ReferenceOwnershipTypes:
		if in.Code == nil || strings.TrimSpace(*in.Code) == "" {
			return ErrFacilityInvalid
		}
	case ReferenceAuthorities:
		if in.OwnershipTypeID == nil || !existsByID(s.DB, "ownership_types", *in.OwnershipTypeID) {
			return ErrFacilityInvalid
		}
	default:
		return ErrFacilityInvalid
	}
	return nil
}

func requireCodes(in FacilityReferenceInput) error {
	if in.NHPICode == nil || strings.TrimSpace(*in.NHPICode) == "" || in.HSDTCode == nil || strings.TrimSpace(*in.HSDTCode) == "" {
		return ErrFacilityInvalid
	}
	return nil
}

func referenceValues(in FacilityReferenceInput) map[string]any {
	values := map[string]any{}
	stringsMap := map[string]*string{"name": in.Name, "code": in.Code, "nhpi_code": in.NHPICode, "hsdt_code": in.HSDTCode}
	for key, value := range stringsMap {
		if value != nil {
			values[key] = strings.TrimSpace(*value)
		}
	}
	ids := map[string]*uuid.UUID{"region_id": in.RegionID, "health_sub_region_id": in.HealthSubRegionID, "district_id": in.DistrictID, "county_id": in.CountyID, "subcounty_id": in.SubcountyID, "ownership_type_id": in.OwnershipTypeID}
	for key, value := range ids {
		if value != nil {
			values[key] = *value
		}
	}
	return values
}

func mergeReferenceInput(current FacilityReferenceView, update FacilityReferenceInput) FacilityReferenceInput {
	result := FacilityReferenceInput{Name: &current.Name, Code: current.Code, RegionID: current.RegionID, HealthSubRegionID: current.HealthSubRegionID, DistrictID: current.DistrictID, CountyID: current.CountyID, SubcountyID: current.SubcountyID, OwnershipTypeID: current.OwnershipTypeID}
	if current.NHPICode != "" {
		result.NHPICode = &current.NHPICode
	}
	if current.HSDTCode != "" {
		result.HSDTCode = &current.HSDTCode
	}
	if update.Name != nil {
		result.Name = update.Name
	}
	if update.Code != nil {
		result.Code = update.Code
	}
	if update.NHPICode != nil {
		result.NHPICode = update.NHPICode
	}
	if update.HSDTCode != nil {
		result.HSDTCode = update.HSDTCode
	}
	if update.RegionID != nil {
		result.RegionID = update.RegionID
	}
	if update.HealthSubRegionID != nil {
		result.HealthSubRegionID = update.HealthSubRegionID
	}
	if update.DistrictID != nil {
		result.DistrictID = update.DistrictID
	}
	if update.CountyID != nil {
		result.CountyID = update.CountyID
	}
	if update.SubcountyID != nil {
		result.SubcountyID = update.SubcountyID
	}
	if update.OwnershipTypeID != nil {
		result.OwnershipTypeID = update.OwnershipTypeID
	}
	return result
}

func referenceOrder(alias, sort, order string) (string, error) {
	columns := map[string]string{"": alias + ".name", "name": alias + ".name", "created_at": alias + ".created_at", "updated_at": alias + ".updated_at"}
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
	return column + " " + direction, nil
}

func (s FacilityService) referenceQuery(spec facilityReferenceSpec) *gorm.DB {
	query := s.DB.Table(spec.table + " " + spec.alias)
	for _, join := range spec.joins {
		query = query.Joins(join)
	}
	return query.Where(spec.alias + ".deleted_at IS NULL")
}

var facilityReferenceSpecs = map[FacilityReference]facilityReferenceSpec{
	ReferenceRegions:            {"regions", "r", "r.*", nil, map[string]string{}},
	ReferenceHealthSubRegions:   {"health_sub_regions", "hsr", "hsr.*, r.name AS region_name", []string{"LEFT JOIN regions r ON r.id = hsr.region_id"}, map[string]string{"region_id": "hsr.region_id"}},
	ReferenceDistricts:          {"districts", "d", "d.*, r.name AS region_name, hsr.name AS health_sub_region_name", []string{"LEFT JOIN regions r ON r.id = d.region_id", "LEFT JOIN health_sub_regions hsr ON hsr.id = d.health_sub_region_id"}, map[string]string{"region_id": "d.region_id", "health_sub_region_id": "d.health_sub_region_id"}},
	ReferenceHealthSubDistricts: {"health_sub_districts", "hsd", "hsd.*, d.name AS district_name", []string{"LEFT JOIN districts d ON d.id = hsd.district_id"}, map[string]string{"district_id": "hsd.district_id"}},
	ReferenceCounties:           {"counties", "c", "c.*, d.name AS district_name", []string{"LEFT JOIN districts d ON d.id = c.district_id"}, map[string]string{"district_id": "c.district_id"}},
	ReferenceSubcounties:        {"subcounties", "sc", "sc.*, d.name AS district_name, c.name AS county_name", []string{"LEFT JOIN districts d ON d.id = sc.district_id", "LEFT JOIN counties c ON c.id = sc.county_id"}, map[string]string{"district_id": "sc.district_id", "county_id": "sc.county_id"}},
	ReferenceParishes:           {"parishes", "p", "p.*, sc.name AS subcounty_name", []string{"LEFT JOIN subcounties sc ON sc.id = p.subcounty_id"}, map[string]string{"subcounty_id": "p.subcounty_id"}},
	ReferenceFacilityLevels:     {"facility_levels", "fl", "fl.*", nil, map[string]string{}},
	ReferenceOwnershipTypes:     {"ownership_types", "ot", "ot.*", nil, map[string]string{}},
	ReferenceAuthorities:        {"authorities", "a", "a.*, ot.name AS ownership_type_name", []string{"LEFT JOIN ownership_types ot ON ot.id = a.ownership_type_id"}, map[string]string{"ownership_type_id": "a.ownership_type_id"}},
}
