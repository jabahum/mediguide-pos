import { FieldOption } from "@/types/data-table"

/**
 * Available fields for pages table advanced filtering
 * Based on legacy collection API generic_pages collection schema
 */
export const pagesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Title", value: "title", type: "text" },
  { label: "Key", value: "key", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // Content Information
  { label: "Has Content", value: "content", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]