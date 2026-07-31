package handlers

import (
	"mediguide/internal/config"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

type FacilityHandler struct {
	ResourceHandler
}

func NewFacilityHandler(s services.ResourceService, cfg config.Config) FacilityHandler {
	return FacilityHandler{
		ResourceHandler: ResourceHandler{
			Service: s,
			Cfg:     cfg,
		},
	}
}

func (h FacilityHandler) ListFacilities(c *gin.Context) {
	h.serve(c, "health_facilities", ResourceHandler.List)
}
func (h FacilityHandler) GetFacility(c *gin.Context) {
	h.serve(c, "health_facilities", ResourceHandler.Get)
}
func (h FacilityHandler) CreateFacility(c *gin.Context) {
	h.serve(c, "health_facilities", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateFacility(c *gin.Context) {
	h.serve(c, "health_facilities", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteFacility(c *gin.Context) {
	h.serve(c, "health_facilities", ResourceHandler.Delete)
}
func (h FacilityHandler) ListHealthSubRegions(c *gin.Context) {
	h.serve(c, "health_sub_regions", ResourceHandler.List)
}
func (h FacilityHandler) ListRegions(c *gin.Context)   { h.serve(c, "regions", ResourceHandler.List) }
func (h FacilityHandler) ListDistricts(c *gin.Context) { h.serve(c, "districts", ResourceHandler.List) }
func (h FacilityHandler) ListHealthSubDistricts(c *gin.Context) {
	h.serve(c, "health_sub_districts", ResourceHandler.List)
}
func (h FacilityHandler) ListCounties(c *gin.Context) { h.serve(c, "counties", ResourceHandler.List) }
func (h FacilityHandler) ListSubcounties(c *gin.Context) {
	h.serve(c, "subcounties", ResourceHandler.List)
}
func (h FacilityHandler) ListParishes(c *gin.Context) { h.serve(c, "parishes", ResourceHandler.List) }
func (h FacilityHandler) ListFacilityLevels(c *gin.Context) {
	h.serve(c, "facility_levels", ResourceHandler.List)
}
func (h FacilityHandler) ListOwnershipTypes(c *gin.Context) {
	h.serve(c, "ownership_types", ResourceHandler.List)
}
func (h FacilityHandler) ListAuthorities(c *gin.Context) {
	h.serve(c, "authorities", ResourceHandler.List)
}

func (h FacilityHandler) CreateHealthSubRegion(c *gin.Context) {
	h.serve(c, "health_sub_regions", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateHealthSubRegion(c *gin.Context) {
	h.serve(c, "health_sub_regions", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteHealthSubRegion(c *gin.Context) {
	h.serve(c, "health_sub_regions", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateRegion(c *gin.Context) { h.serve(c, "regions", ResourceHandler.Create) }
func (h FacilityHandler) UpdateRegion(c *gin.Context) { h.serve(c, "regions", ResourceHandler.Update) }
func (h FacilityHandler) DeleteRegion(c *gin.Context) { h.serve(c, "regions", ResourceHandler.Delete) }
func (h FacilityHandler) CreateDistrict(c *gin.Context) {
	h.serve(c, "districts", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateDistrict(c *gin.Context) {
	h.serve(c, "districts", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteDistrict(c *gin.Context) {
	h.serve(c, "districts", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateHealthSubDistrict(c *gin.Context) {
	h.serve(c, "health_sub_districts", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateHealthSubDistrict(c *gin.Context) {
	h.serve(c, "health_sub_districts", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteHealthSubDistrict(c *gin.Context) {
	h.serve(c, "health_sub_districts", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateCounty(c *gin.Context) { h.serve(c, "counties", ResourceHandler.Create) }
func (h FacilityHandler) UpdateCounty(c *gin.Context) { h.serve(c, "counties", ResourceHandler.Update) }
func (h FacilityHandler) DeleteCounty(c *gin.Context) { h.serve(c, "counties", ResourceHandler.Delete) }
func (h FacilityHandler) CreateSubcounty(c *gin.Context) {
	h.serve(c, "subcounties", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateSubcounty(c *gin.Context) {
	h.serve(c, "subcounties", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteSubcounty(c *gin.Context) {
	h.serve(c, "subcounties", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateParish(c *gin.Context) { h.serve(c, "parishes", ResourceHandler.Create) }
func (h FacilityHandler) UpdateParish(c *gin.Context) { h.serve(c, "parishes", ResourceHandler.Update) }
func (h FacilityHandler) DeleteParish(c *gin.Context) { h.serve(c, "parishes", ResourceHandler.Delete) }
func (h FacilityHandler) CreateFacilityLevel(c *gin.Context) {
	h.serve(c, "facility_levels", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateFacilityLevel(c *gin.Context) {
	h.serve(c, "facility_levels", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteFacilityLevel(c *gin.Context) {
	h.serve(c, "facility_levels", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateOwnershipType(c *gin.Context) {
	h.serve(c, "ownership_types", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateOwnershipType(c *gin.Context) {
	h.serve(c, "ownership_types", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteOwnershipType(c *gin.Context) {
	h.serve(c, "ownership_types", ResourceHandler.Delete)
}
func (h FacilityHandler) CreateAuthority(c *gin.Context) {
	h.serve(c, "authorities", ResourceHandler.Create)
}
func (h FacilityHandler) UpdateAuthority(c *gin.Context) {
	h.serve(c, "authorities", ResourceHandler.Update)
}
func (h FacilityHandler) DeleteAuthority(c *gin.Context) {
	h.serve(c, "authorities", ResourceHandler.Delete)
}

func (h FacilityHandler) serve(c *gin.Context, resource string, fn func(ResourceHandler, *gin.Context)) {
	c.Set("resource", resource)
	fn(h.ResourceHandler, c)
}
