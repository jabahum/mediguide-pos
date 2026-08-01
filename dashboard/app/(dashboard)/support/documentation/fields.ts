import { FieldOption } from "@/types/data-table"

/**
 * Available fields for documentation table advanced filtering
 * Based on the typed documentation API schema
 */
export const documentationAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Title", value: "title", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Content", value: "content", type: "text" },
  
  // Categorization
  { label: "Category", value: "category", type: "text" },
  { label: "Tags", value: "tags", type: "text" },
  
  // Status & Workflow
  { 
    label: "Status", 
    value: "status", 
    type: "select"
  },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]
