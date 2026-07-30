import { FieldOption } from "@/types/data-table"

/**
 * Available fields for roles table advanced filtering
 * Based on legacy collection API roles schema
 */
export const rolesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Role Name", value: "name", type: "text" },
  { label: "Role Key", value: "key", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // Status
  { label: "Status", value: "isActive", type: "boolean" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]