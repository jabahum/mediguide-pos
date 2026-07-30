import { FieldOption } from "@/types/data-table"

/**
 * Available fields for authorities table advanced filtering
 * Based on legacy collection API authorities schema
 */
export const authoritiesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Code", value: "code", type: "text" },
  
  // Relations
  { label: "Ownership Type", value: "ownership_type", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]