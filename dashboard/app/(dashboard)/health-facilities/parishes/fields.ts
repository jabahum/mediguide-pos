import { FieldOption } from "@/types/data-table"

/**
 * Available fields for parishes table advanced filtering
 * Based on legacy collection API parishes schema
 */
export const parishesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "Subcounty", value: "subcounty", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]