import { FieldOption } from "@/types/data-table"

/**
 * Available fields for guideline tags table advanced filtering
 * Note: Column filtering is handled directly in columns.tsx using DataTableColumnHeader
 * This is only for advanced filtering dialog if implemented
 */
export const guidelineTagAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // System Fields
  { label: "Created", value: "created", type: "dateRange" },
  { label: "Updated", value: "updated", type: "dateRange" },
  { label: "ID", value: "id", type: "text" },
]
