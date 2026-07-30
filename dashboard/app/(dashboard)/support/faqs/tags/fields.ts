import type { FieldOption } from "@/types/data-table"

/**
 * Available fields for FAQ tags table advanced filtering
 * Based on legacy collection API faq_tags collection schema
 */
export const tagAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Tag Name", value: "name", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Slug", value: "slug", type: "text" },
  
  // Status & Properties
  { label: "Status", value: "is_active", type: "boolean" },
  { label: "Color", value: "color", type: "select" },
  { label: "Has Icon", value: "icon", type: "boolean" },
  
  // Usage Statistics
  { label: "Usage Count", value: "usage_count", type: "number" },
  
  // Dates
  { label: "Created Date", value: "created", type: "date" },
  { label: "Updated Date", value: "updated", type: "date" },
  
  // Organization
  { label: "Sort Order", value: "sort_order", type: "number" },
]