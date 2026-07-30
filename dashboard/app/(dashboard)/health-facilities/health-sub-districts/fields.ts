import { FieldOption } from "@/types/data-table"

/**
 * Available fields for health sub-districts table advanced filtering
 * Based on legacy collection API health_sub_districts schema
 */
export const healthSubDistrictsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "District", value: "district", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]