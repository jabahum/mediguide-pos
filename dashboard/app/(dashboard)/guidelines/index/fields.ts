import { FieldOption } from "@/types/data-table"

/**
 * Available fields for guideline index table advanced filtering
 * Based on legacy collection API guideline_index schema
 */
export const guidelineIndexAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Title", value: "title", type: "text" },
  { label: "Description", value: "description", type: "text" },
  
  // Hierarchy Information
  { label: "Level", value: "level", type: "number" },
  { label: "Order", value: "order", type: "number" },
  { label: "Has Children", value: "hasChildren", type: "boolean" },
  { label: "Parent", value: "parent", type: "select" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]