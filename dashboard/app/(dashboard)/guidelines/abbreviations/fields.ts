import { FieldOption } from "@/types/data-table"

/**
 * Available fields for abbreviations table advanced filtering
 * Based on legacy collection API abbreviations schema
 */
export const abbreviationsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Abbreviation", value: "abbreviation", type: "text" },
  { label: "Meaning", value: "meaning", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // Status & Settings
  { label: "Common Usage", value: "common_usage", type: "boolean" },
  { label: "Category", value: "category", type: "select" },
  { label: "Tags", value: "tags", type: "select" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]