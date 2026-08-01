import { FieldOption } from "@/types/data-table"

/**
 * Available fields for guideline categories table advanced filtering
 * Note: Column filtering is handled directly in columns.tsx using DataTableColumnHeader
 * This is only for advanced filtering dialog if implemented
 */
export const guidelineCategoryAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Slug", value: "slug", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // Hierarchy & Organization  
  { label: "Parent Category", value: "parent_category", type: "text" },
  { label: "Sort Order", value: "sort_order", type: "number" },
  
  // Status & Settings
  { label: "Status", value: "status", type: "select" },
  { label: "Color", value: "color", type: "text" },
  { label: "Icon", value: "icon", type: "text" },
  
  // System Fields
  { label: "Created", value: "created", type: "dateRange" },
  { label: "Updated", value: "updated", type: "dateRange" },
  { label: "ID", value: "id", type: "text" },
]
