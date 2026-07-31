package services

import (
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type facilityFixture struct {
	service   FacilityService
	region    models.Region
	hsr       models.HealthSubRegion
	district  models.District
	county    models.County
	hsd       models.HealthSubDistrict
	subcounty models.Subcounty
	parish    models.Parish
	level     models.FacilityLevel
	ownership models.OwnershipType
	authority models.Authority
}

func TestFacilityServiceValidatesHierarchyFiltersAndUsageOwnership(t *testing.T) {
	fixture := newFacilityFixture(t)
	name, nhpi, hsdt := "Mulago Test Hospital", "HF-1", "HSDT-HF-1"
	input := FacilityInput{
		Name: &name, NHPICode: &nhpi, HSDTCode: &hsdt,
		FacilityLevelID: &fixture.level.ID, AuthorityID: &fixture.authority.ID,
		OwnershipTypeID: &fixture.ownership.ID, HealthSubDistrictID: &fixture.hsd.ID,
		ParishID: &fixture.parish.ID, SubcountyID: &fixture.subcounty.ID,
		CountyID: &fixture.county.ID, DistrictID: &fixture.district.ID,
		HealthSubRegionID: &fixture.hsr.ID, RegionID: &fixture.region.ID,
	}
	created, err := fixture.service.CreateFacility(input)
	if err != nil {
		t.Fatal(err)
	}

	page, err := fixture.service.ListFacilities(FacilityQuery{
		Page: PageInput{Page: 1, PerPage: 10}, Search: "mulago", RegionID: &fixture.region.ID,
	})
	if err != nil {
		t.Fatal(err)
	}
	if page.TotalItems != 1 || len(page.Items) != 1 || page.Items[0].DistrictName != fixture.district.Name {
		t.Fatalf("unexpected facility page: %#v", page)
	}
	if _, err := fixture.service.ListFacilities(FacilityQuery{Sort: "unsafe_sql"}); err == nil {
		t.Fatal("expected unknown sort field to be rejected")
	}

	userID := uuid.New()
	usage, err := fixture.service.RecordUsage(userID, created.Item.ID)
	if err != nil {
		t.Fatal(err)
	}
	if usage.UserID != userID || usage.FacilityID != created.Item.ID {
		t.Fatalf("usage ownership was not derived by the service caller: %#v", usage)
	}
	if err := fixture.service.DeleteFacility(created.Item.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := fixture.service.GetFacility(created.Item.ID); err == nil {
		t.Fatal("expected soft-deleted facility to be hidden")
	}
}

func TestFacilityServiceRejectsInconsistentHierarchy(t *testing.T) {
	fixture := newFacilityFixture(t)
	otherRegion := models.Region{Name: "Other", NHPICode: "R-2", HSDTCode: "H-R-2"}
	if err := fixture.service.DB.Create(&otherRegion).Error; err != nil {
		t.Fatal(err)
	}
	name, nhpi, hsdt := "Invalid", "HF-X", "H-X"
	input := FacilityInput{
		Name: &name, NHPICode: &nhpi, HSDTCode: &hsdt,
		FacilityLevelID: &fixture.level.ID, AuthorityID: &fixture.authority.ID,
		OwnershipTypeID: &fixture.ownership.ID, HealthSubDistrictID: &fixture.hsd.ID,
		SubcountyID: &fixture.subcounty.ID, CountyID: &fixture.county.ID,
		DistrictID: &fixture.district.ID, HealthSubRegionID: &fixture.hsr.ID, RegionID: &otherRegion.ID,
	}
	if _, err := fixture.service.CreateFacility(input); err == nil {
		t.Fatal("expected inconsistent region hierarchy to be rejected")
	}
}

func TestFacilityReferenceServiceRejectsInvalidParentAndPaginates(t *testing.T) {
	fixture := newFacilityFixture(t)
	name, nhpi, hsdt := "Invalid District", "D-X", "HD-X"
	otherRegion := models.Region{Name: "Other", NHPICode: "R-3", HSDTCode: "H-R-3"}
	if err := fixture.service.DB.Create(&otherRegion).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := fixture.service.CreateReference(ReferenceDistricts, FacilityReferenceInput{
		Name: &name, NHPICode: &nhpi, HSDTCode: &hsdt,
		RegionID: &otherRegion.ID, HealthSubRegionID: &fixture.hsr.ID,
	}); err == nil {
		t.Fatal("expected mismatched district parent to be rejected")
	}
	page, err := fixture.service.ListReferences(ReferenceDistricts, FacilityReferenceQuery{
		Page: PageInput{Page: 1, PerPage: 1}, RegionID: &fixture.region.ID,
	})
	if err != nil {
		t.Fatal(err)
	}
	if page.TotalItems != 1 || page.TotalPages != 1 || len(page.Items) != 1 {
		t.Fatalf("unexpected reference page: %#v", page)
	}
	if err := fixture.service.DeleteReference(ReferenceRegions, fixture.region.ID); err == nil {
		t.Fatal("expected deletion of an assigned hierarchy parent to be rejected")
	}
}

func newFacilityFixture(t *testing.T) facilityFixture {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.Region{}, &models.HealthSubRegion{}, &models.District{}, &models.County{},
		&models.HealthSubDistrict{}, &models.Subcounty{}, &models.Parish{}, &models.FacilityLevel{},
		&models.OwnershipType{}, &models.Authority{}, &models.HealthFacility{}, &models.FacilityUsageLog{},
	); err != nil {
		t.Fatal(err)
	}
	f := facilityFixture{service: FacilityService{DB: database}}
	f.region = models.Region{Name: "Central", NHPICode: "R-1", HSDTCode: "H-R-1"}
	database.Create(&f.region)
	f.hsr = models.HealthSubRegion{RegionID: f.region.ID, Name: "Central HSR", NHPICode: "HSR-1", HSDTCode: "H-HSR-1"}
	database.Create(&f.hsr)
	f.district = models.District{RegionID: f.region.ID, HealthSubRegionID: f.hsr.ID, Name: "Kampala", NHPICode: "D-1", HSDTCode: "H-D-1"}
	database.Create(&f.district)
	f.county = models.County{DistrictID: f.district.ID, Name: "County", NHPICode: "C-1", HSDTCode: "H-C-1"}
	database.Create(&f.county)
	f.hsd = models.HealthSubDistrict{DistrictID: f.district.ID, Name: "HSD", NHPICode: "HSD-1", HSDTCode: "H-HSD-1"}
	database.Create(&f.hsd)
	f.subcounty = models.Subcounty{CountyID: f.county.ID, DistrictID: f.district.ID, Name: "Subcounty", NHPICode: "SC-1", HSDTCode: "H-SC-1"}
	database.Create(&f.subcounty)
	f.parish = models.Parish{SubcountyID: f.subcounty.ID, Name: "Parish", NHPICode: "P-1", HSDTCode: "H-P-1"}
	database.Create(&f.parish)
	f.level = models.FacilityLevel{Code: "HCIV", Name: "Health Centre IV"}
	database.Create(&f.level)
	f.ownership = models.OwnershipType{Code: "GOV", Name: "Government"}
	database.Create(&f.ownership)
	f.authority = models.Authority{Name: "Ministry", OwnershipTypeID: f.ownership.ID}
	database.Create(&f.authority)
	return f
}
