package handlers

import (
	"errors"
	"net/http"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FacilityHandler struct{ Service services.FacilityService }

func NewFacilityHandler(service services.FacilityService) FacilityHandler {
	return FacilityHandler{Service: service}
}

// ListFacilities godoc
// @Summary List health facilities
// @Tags facilities
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Name, code, or district search"
// @Param region_id query string false "Region UUID"
// @Param district_id query string false "District UUID"
// @Param facility_level_id query string false "Facility level UUID"
// @Param ownership_type_id query string false "Ownership type UUID"
// @Param sort query string false "name, created_at, updated_at, or usage_count"
// @Param order query string false "asc or desc"
// @Success 200 {object} services.FacilityPage
// @Failure 400,401 {object} handlers.ErrorResponse
// @Router /api/v2/facilities [get]
func (h FacilityHandler) ListFacilities(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	query := services.FacilityQuery{Page: page, Search: c.Query("search"), Sort: c.Query("sort"), Order: c.Query("order")}
	if !bindOptionalUUIDs(c, map[string]**uuid.UUID{
		"region_id": &query.RegionID, "health_sub_region_id": &query.HealthSubRegionID,
		"district_id": &query.DistrictID, "health_sub_district_id": &query.HealthSubDistrictID,
		"county_id": &query.CountyID, "subcounty_id": &query.SubcountyID, "parish_id": &query.ParishID,
		"facility_level_id": &query.FacilityLevelID, "ownership_type_id": &query.OwnershipTypeID, "authority_id": &query.AuthorityID,
	}) {
		httpx.Error(c, http.StatusBadRequest, "invalid filter UUID")
		return
	}
	result, err := h.Service.ListFacilities(query)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// GetFacility godoc
// @Summary Get a health facility
// @Tags facilities
// @Security BearerAuth
// @Param id path string true "Facility UUID"
// @Success 200 {object} services.FacilityItem
// @Failure 400,401,404 {object} handlers.ErrorResponse
// @Router /api/v2/facilities/{id} [get]
func (h FacilityHandler) GetFacility(c *gin.Context) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetFacility(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, item)
}

// CreateFacility godoc
// @Summary Create a health facility
// @Tags facilities
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param payload body services.FacilityInput true "Facility"
// @Success 201 {object} services.FacilityItem
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/facilities [post]
func (h FacilityHandler) CreateFacility(c *gin.Context) {
	var input services.FacilityInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.CreateFacility(input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusCreated, item)
}

// UpdateFacility godoc
// @Summary Update a health facility
// @Tags facilities
// @Security BearerAuth
// @Accept json
// @Param id path string true "Facility UUID"
// @Param payload body services.FacilityInput true "Facility changes"
// @Success 200 {object} services.FacilityItem
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/facilities/{id} [patch]
func (h FacilityHandler) UpdateFacility(c *gin.Context) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	var input services.FacilityInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.UpdateFacility(id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, item)
}

// DeleteFacility godoc
// @Summary Soft-delete a health facility
// @Tags facilities
// @Security BearerAuth
// @Param id path string true "Facility UUID"
// @Success 204
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/facilities/{id} [delete]
func (h FacilityHandler) DeleteFacility(c *gin.Context) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteFacility(id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// RecordUsage godoc
// @Summary Record current-user facility usage
// @Tags facilities
// @Security BearerAuth
// @Param id path string true "Facility UUID"
// @Success 201 {object} models.FacilityUsageLog
// @Failure 400,401,404 {object} handlers.ErrorResponse
// @Router /api/v2/facilities/{id}/usage [post]
func (h FacilityHandler) RecordUsage(c *gin.Context) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	item, err := h.Service.RecordUsage(claims.UserID, id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, item)
}

func (h FacilityHandler) ListHealthSubRegions(c *gin.Context) {
	h.listReference(c, services.ReferenceHealthSubRegions)
}
func (h FacilityHandler) ListRegions(c *gin.Context) { h.listReference(c, services.ReferenceRegions) }
func (h FacilityHandler) ListDistricts(c *gin.Context) {
	h.listReference(c, services.ReferenceDistricts)
}
func (h FacilityHandler) ListHealthSubDistricts(c *gin.Context) {
	h.listReference(c, services.ReferenceHealthSubDistricts)
}
func (h FacilityHandler) ListCounties(c *gin.Context) { h.listReference(c, services.ReferenceCounties) }
func (h FacilityHandler) ListSubcounties(c *gin.Context) {
	h.listReference(c, services.ReferenceSubcounties)
}
func (h FacilityHandler) ListParishes(c *gin.Context) { h.listReference(c, services.ReferenceParishes) }
func (h FacilityHandler) ListFacilityLevels(c *gin.Context) {
	h.listReference(c, services.ReferenceFacilityLevels)
}
func (h FacilityHandler) ListOwnershipTypes(c *gin.Context) {
	h.listReference(c, services.ReferenceOwnershipTypes)
}
func (h FacilityHandler) ListAuthorities(c *gin.Context) {
	h.listReference(c, services.ReferenceAuthorities)
}
func (h FacilityHandler) GetHealthSubRegion(c *gin.Context) {
	h.getReference(c, services.ReferenceHealthSubRegions)
}
func (h FacilityHandler) GetRegion(c *gin.Context)   { h.getReference(c, services.ReferenceRegions) }
func (h FacilityHandler) GetDistrict(c *gin.Context) { h.getReference(c, services.ReferenceDistricts) }
func (h FacilityHandler) GetHealthSubDistrict(c *gin.Context) {
	h.getReference(c, services.ReferenceHealthSubDistricts)
}
func (h FacilityHandler) GetCounty(c *gin.Context) { h.getReference(c, services.ReferenceCounties) }
func (h FacilityHandler) GetSubcounty(c *gin.Context) {
	h.getReference(c, services.ReferenceSubcounties)
}
func (h FacilityHandler) GetParish(c *gin.Context) { h.getReference(c, services.ReferenceParishes) }
func (h FacilityHandler) GetFacilityLevel(c *gin.Context) {
	h.getReference(c, services.ReferenceFacilityLevels)
}
func (h FacilityHandler) GetOwnershipType(c *gin.Context) {
	h.getReference(c, services.ReferenceOwnershipTypes)
}
func (h FacilityHandler) GetAuthority(c *gin.Context) {
	h.getReference(c, services.ReferenceAuthorities)
}

// GetRegionChildren godoc
// @Summary Get typed children for a region
// @Tags facilities
// @Security BearerAuth
// @Param id path string true "Region UUID"
// @Success 200 {object} services.RegionChildren
// @Failure 400,401,404 {object} handlers.ErrorResponse
// @Router /api/v2/regions/{id}/children [get]
func (h FacilityHandler) GetRegionChildren(c *gin.Context) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	result, err := h.Service.GetRegionChildren(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

func (h FacilityHandler) CreateHealthSubRegion(c *gin.Context) {
	h.createReference(c, services.ReferenceHealthSubRegions)
}
func (h FacilityHandler) UpdateHealthSubRegion(c *gin.Context) {
	h.updateReference(c, services.ReferenceHealthSubRegions)
}
func (h FacilityHandler) DeleteHealthSubRegion(c *gin.Context) {
	h.deleteReference(c, services.ReferenceHealthSubRegions)
}
func (h FacilityHandler) CreateRegion(c *gin.Context) {
	h.createReference(c, services.ReferenceRegions)
}
func (h FacilityHandler) UpdateRegion(c *gin.Context) {
	h.updateReference(c, services.ReferenceRegions)
}
func (h FacilityHandler) DeleteRegion(c *gin.Context) {
	h.deleteReference(c, services.ReferenceRegions)
}
func (h FacilityHandler) CreateDistrict(c *gin.Context) {
	h.createReference(c, services.ReferenceDistricts)
}
func (h FacilityHandler) UpdateDistrict(c *gin.Context) {
	h.updateReference(c, services.ReferenceDistricts)
}
func (h FacilityHandler) DeleteDistrict(c *gin.Context) {
	h.deleteReference(c, services.ReferenceDistricts)
}
func (h FacilityHandler) CreateHealthSubDistrict(c *gin.Context) {
	h.createReference(c, services.ReferenceHealthSubDistricts)
}
func (h FacilityHandler) UpdateHealthSubDistrict(c *gin.Context) {
	h.updateReference(c, services.ReferenceHealthSubDistricts)
}
func (h FacilityHandler) DeleteHealthSubDistrict(c *gin.Context) {
	h.deleteReference(c, services.ReferenceHealthSubDistricts)
}
func (h FacilityHandler) CreateCounty(c *gin.Context) {
	h.createReference(c, services.ReferenceCounties)
}
func (h FacilityHandler) UpdateCounty(c *gin.Context) {
	h.updateReference(c, services.ReferenceCounties)
}
func (h FacilityHandler) DeleteCounty(c *gin.Context) {
	h.deleteReference(c, services.ReferenceCounties)
}
func (h FacilityHandler) CreateSubcounty(c *gin.Context) {
	h.createReference(c, services.ReferenceSubcounties)
}
func (h FacilityHandler) UpdateSubcounty(c *gin.Context) {
	h.updateReference(c, services.ReferenceSubcounties)
}
func (h FacilityHandler) DeleteSubcounty(c *gin.Context) {
	h.deleteReference(c, services.ReferenceSubcounties)
}
func (h FacilityHandler) CreateParish(c *gin.Context) {
	h.createReference(c, services.ReferenceParishes)
}
func (h FacilityHandler) UpdateParish(c *gin.Context) {
	h.updateReference(c, services.ReferenceParishes)
}
func (h FacilityHandler) DeleteParish(c *gin.Context) {
	h.deleteReference(c, services.ReferenceParishes)
}
func (h FacilityHandler) CreateFacilityLevel(c *gin.Context) {
	h.createReference(c, services.ReferenceFacilityLevels)
}
func (h FacilityHandler) UpdateFacilityLevel(c *gin.Context) {
	h.updateReference(c, services.ReferenceFacilityLevels)
}
func (h FacilityHandler) DeleteFacilityLevel(c *gin.Context) {
	h.deleteReference(c, services.ReferenceFacilityLevels)
}
func (h FacilityHandler) CreateOwnershipType(c *gin.Context) {
	h.createReference(c, services.ReferenceOwnershipTypes)
}
func (h FacilityHandler) UpdateOwnershipType(c *gin.Context) {
	h.updateReference(c, services.ReferenceOwnershipTypes)
}
func (h FacilityHandler) DeleteOwnershipType(c *gin.Context) {
	h.deleteReference(c, services.ReferenceOwnershipTypes)
}
func (h FacilityHandler) CreateAuthority(c *gin.Context) {
	h.createReference(c, services.ReferenceAuthorities)
}
func (h FacilityHandler) UpdateAuthority(c *gin.Context) {
	h.updateReference(c, services.ReferenceAuthorities)
}
func (h FacilityHandler) DeleteAuthority(c *gin.Context) {
	h.deleteReference(c, services.ReferenceAuthorities)
}

func (h FacilityHandler) listReference(c *gin.Context, resource services.FacilityReference) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	query := services.FacilityReferenceQuery{Page: page, Search: c.Query("search"), Sort: c.Query("sort"), Order: c.Query("order")}
	if !bindOptionalUUIDs(c, map[string]**uuid.UUID{"region_id": &query.RegionID, "health_sub_region_id": &query.HealthSubRegionID, "district_id": &query.DistrictID, "county_id": &query.CountyID, "subcounty_id": &query.SubcountyID, "ownership_type_id": &query.OwnershipTypeID}) {
		httpx.Error(c, http.StatusBadRequest, "invalid filter UUID")
		return
	}
	result, err := h.Service.ListReferences(resource, query)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

func (h FacilityHandler) getReference(c *gin.Context, resource services.FacilityReference) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetReference(resource, id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h FacilityHandler) createReference(c *gin.Context, resource services.FacilityReference) {
	var input services.FacilityReferenceInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.CreateReference(resource, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusCreated, item)
}

func (h FacilityHandler) updateReference(c *gin.Context, resource services.FacilityReference) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	var input services.FacilityReferenceInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.UpdateReference(resource, id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h FacilityHandler) deleteReference(c *gin.Context, resource services.FacilityReference) {
	id, ok := facilityID(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteReference(resource, id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h FacilityHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrFacilityInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid facility data")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "facility data not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "facility operation failed")
	}
}

func facilityID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(strings.TrimSpace(c.Param("id")))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid UUID")
		return uuid.Nil, false
	}
	return id, true
}

func bindOptionalUUIDs(c *gin.Context, targets map[string]**uuid.UUID) bool {
	for key, target := range targets {
		raw := strings.TrimSpace(c.Query(key))
		if raw == "" {
			continue
		}
		id, err := uuid.Parse(raw)
		if err != nil {
			return false
		}
		value := id
		*target = &value
	}
	return true
}
