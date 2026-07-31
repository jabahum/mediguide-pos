import { FieldOption } from "@/types/data-table"
import { facilityRelationOptions } from "@/services/health-facilities.service"

/**
 * Available fields for health facilities table advanced filtering.
 * Relation fields load through the focused facility service while retaining
 * opaque IDs as typed query parameters.
 */
export const healthFacilitiesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },

  // Classification
  {
    label: "Facility Level",
    value: "facility_level_id",
    type: "select",
    relation: facilityRelationOptions.facilityLevels,
  },
  {
    label: "Authority",
    value: "authority_id",
    type: "select",
    relation: facilityRelationOptions.authorities,
  },
  {
    label: "Ownership Type",
    value: "ownership_type_id",
    type: "select",
    relation: facilityRelationOptions.ownershipTypes,
  },

  // Geographic Hierarchy (Top Level)
  {
    label: "Region",
    value: "region_id",
    type: "select",
    relation: facilityRelationOptions.regions,
  },
  {
    label: "Health Sub Region",
    value: "health_sub_region_id",
    type: "select",
    relation: facilityRelationOptions.healthSubRegions,
  },

  // Geographic Hierarchy (District Level)
  {
    label: "District",
    value: "district_id",
    type: "select",
    relation: facilityRelationOptions.districts,
  },
  {
    label: "Health Sub District",
    value: "health_sub_district_id",
    type: "select",
    relation: facilityRelationOptions.healthSubDistricts,
  },

  // Geographic Hierarchy (Local Level)
  {
    label: "County",
    value: "county_id",
    type: "select",
    relation: facilityRelationOptions.counties,
  },
  {
    label: "Subcounty",
    value: "subcounty_id",
    type: "select",
    relation: facilityRelationOptions.subcounties,
  },
  {
    label: "Parish",
    value: "parish_id",
    type: "select",
    relation: facilityRelationOptions.parishes,
  },

  // Timestamps
  { label: "Created Date", value: "created", type: "date" },
  { label: "Updated Date", value: "updated", type: "date" },
]
