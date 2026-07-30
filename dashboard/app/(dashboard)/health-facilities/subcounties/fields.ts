import { FieldOption } from "@/types/data-table"

/**
 * Available fields for subcounties table advanced filtering
 * Based on legacy collection API subcounties schema
 */
export const subcountiesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "NHPI Code", value: "nhpi_code", type: "text" },
  { label: "HSDT Code", value: "hsdt_code", type: "text" },
  
  // Relations
  { label: "County", value: "county", type: "text" },
  { label: "District", value: "district", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]