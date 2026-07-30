import { FieldOption } from "@/types/data-table"

/**
 * Available fields for facility levels table advanced filtering
 * Based on legacy collection API facility_levels schema
 */
export const facilityLevelsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Code", value: "code", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]