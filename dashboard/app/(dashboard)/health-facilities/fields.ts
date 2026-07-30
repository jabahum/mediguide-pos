import { FieldOption } from "@/types/data-table"

/**
 * Available fields for health facilities table advanced filtering.
 * Relation fields are wired to their legacy collection API source collections so the
 * filter dropdown can search by human-readable name while sending the
 * underlying record id to legacy collection API.
 */
export const healthFacilitiesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },

  // Classification
  {
    label: "Facility Level",
    value: "facility_level",
    type: "select",
    relation: { collection: "facility_levels", labelField: "name", sort: "name" },
  },
  {
    label: "Authority",
    value: "authority",
    type: "select",
    relation: { collection: "authorities", labelField: "name", sort: "name" },
  },
  {
    label: "Ownership Type",
    value: "ownership_type",
    type: "select",
    relation: { collection: "ownership_types", labelField: "name", sort: "name" },
  },

  // Geographic Hierarchy (Top Level)
  {
    label: "Region",
    value: "region",
    type: "select",
    relation: { collection: "regions", labelField: "name", sort: "name" },
  },
  {
    label: "Health Sub Region",
    value: "health_sub_region",
    type: "select",
    relation: { collection: "health_sub_regions", labelField: "name", sort: "name" },
  },

  // Geographic Hierarchy (District Level)
  {
    label: "District",
    value: "district",
    type: "select",
    relation: { collection: "districts", labelField: "name", sort: "name" },
  },
  {
    label: "Health Sub District",
    value: "health_sub_district",
    type: "select",
    relation: { collection: "health_sub_districts", labelField: "name", sort: "name" },
  },

  // Geographic Hierarchy (Local Level)
  {
    label: "County",
    value: "county",
    type: "select",
    relation: { collection: "counties", labelField: "name", sort: "name" },
  },
  {
    label: "Subcounty",
    value: "subcounty",
    type: "select",
    relation: { collection: "subcounties", labelField: "name", sort: "name" },
  },
  {
    label: "Parish",
    value: "parish",
    type: "select",
    relation: { collection: "parishes", labelField: "name", sort: "name" },
  },

  // Timestamps
  { label: "Created Date", value: "created", type: "date" },
  { label: "Updated Date", value: "updated", type: "date" },
]
