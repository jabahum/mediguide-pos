import { FieldOption } from "@/types/data-table"

/**
 * Available fields for ownership types table advanced filtering
 * Based on legacy collection API ownership_types schema
 */
export const ownershipTypesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Code", value: "code", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]