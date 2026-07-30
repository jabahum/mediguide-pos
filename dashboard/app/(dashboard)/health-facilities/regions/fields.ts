import { FieldOption } from "@/types/data-table"

/**
 * Available fields for regions table advanced filtering
 * Based on legacy collection API regions schema
 */
export const regionsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]