import { FieldOption } from "@/types/data-table"

/**
 * Available fields for districts table advanced filtering
 * Based on legacy collection API districts schema
 */
export const districtsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "Region", value: "region", type: "text" },
  { label: "Health Sub-Region", value: "health_sub_region", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]