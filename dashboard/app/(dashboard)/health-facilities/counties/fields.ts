import { FieldOption } from "@/types/data-table"

/**
 * Available fields for counties table advanced filtering
 * Based on legacy collection API counties schema
 */
export const countiesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "District", value: "district", type: "select" },
  { label: "District Name", value: "expand.district.name", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]