import { FieldOption } from "@/types/data-table"

/**
 * Available fields for health sub-regions table advanced filtering
 * Based on legacy collection API health_sub_regions schema
 */
export const healthSubRegionsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "Region", value: "region", type: "select" },
  { label: "Region Name", value: "expand.region.name", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]