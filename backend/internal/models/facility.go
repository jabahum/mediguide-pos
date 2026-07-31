package models

import "github.com/google/uuid"

type Region struct {
	Base
	Name     string `json:"name"`
	NHPICode string `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode string `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type HealthSubRegion struct {
	Base
	RegionID uuid.UUID `gorm:"type:uuid" json:"region_id"`
	Name     string    `json:"name"`
	NHPICode string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type District struct {
	Base
	HealthSubRegionID uuid.UUID `gorm:"type:uuid" json:"health_sub_region_id"`
	RegionID          uuid.UUID `gorm:"type:uuid" json:"region_id"`
	Name              string    `json:"name"`
	NHPICode          string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode          string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type County struct {
	Base
	DistrictID uuid.UUID `gorm:"type:uuid" json:"district_id"`
	Name       string    `json:"name"`
	NHPICode   string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode   string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type HealthSubDistrict struct {
	Base
	DistrictID uuid.UUID `gorm:"type:uuid" json:"district_id"`
	Name       string    `json:"name"`
	NHPICode   string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode   string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type Subcounty struct {
	Base
	CountyID   uuid.UUID `gorm:"type:uuid" json:"county_id"`
	DistrictID uuid.UUID `gorm:"type:uuid" json:"district_id"`
	Name       string    `json:"name"`
	NHPICode   string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode   string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type Parish struct {
	Base
	SubcountyID uuid.UUID `gorm:"type:uuid" json:"subcounty_id"`
	Name        string    `json:"name"`
	NHPICode    string    `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode    string    `gorm:"column:hsdt_code" json:"hsdt_code"`
}

type FacilityLevel struct {
	Base
	Code string `json:"code"`
	Name string `json:"name"`
}

type OwnershipType struct {
	Base
	Code string `json:"code"`
	Name string `json:"name"`
}

type Authority struct {
	Base
	Name            string    `json:"name"`
	Code            *string   `json:"code,omitempty"`
	OwnershipTypeID uuid.UUID `gorm:"type:uuid" json:"ownership_type_id"`
}

type HealthFacility struct {
	Base
	Name                string     `json:"name"`
	NHPICode            string     `gorm:"column:nhpi_code" json:"nhpi_code"`
	HSDTCode            string     `gorm:"column:hsdt_code" json:"hsdt_code"`
	FacilityLevelID     uuid.UUID  `gorm:"type:uuid" json:"facility_level_id"`
	AuthorityID         uuid.UUID  `gorm:"type:uuid" json:"authority_id"`
	OwnershipTypeID     uuid.UUID  `gorm:"type:uuid" json:"ownership_type_id"`
	HealthSubDistrictID uuid.UUID  `gorm:"type:uuid" json:"health_sub_district_id"`
	ParishID            *uuid.UUID `gorm:"type:uuid" json:"parish_id,omitempty"`
	SubcountyID         uuid.UUID  `gorm:"type:uuid" json:"subcounty_id"`
	CountyID            uuid.UUID  `gorm:"type:uuid" json:"county_id"`
	DistrictID          uuid.UUID  `gorm:"type:uuid" json:"district_id"`
	HealthSubRegionID   uuid.UUID  `gorm:"type:uuid" json:"health_sub_region_id"`
	RegionID            uuid.UUID  `gorm:"type:uuid" json:"region_id"`
	UsageCount          int64      `json:"usage_count"`
}

type FacilityUsageLog struct {
	Base
	UserID     uuid.UUID `gorm:"type:uuid" json:"user_id"`
	FacilityID uuid.UUID `gorm:"type:uuid" json:"facility_id"`
}
