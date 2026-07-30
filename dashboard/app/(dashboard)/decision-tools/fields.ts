import { FieldOption } from "@/types/data-table"

/**
 * Available fields for decision tools table advanced filtering
 * Based on legacy collection API calculators collection schema
 */
export const decisionToolsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Version", value: "version", type: "text" },
  
  // Classification
  { label: "Type", value: "type", type: "select" },
  { label: "Status", value: "status", type: "select" },
  
  // Visual Properties
  { label: "Icon", value: "icon", type: "text" },
  { label: "Color", value: "color", type: "text" },
  { label: "Background Color", value: "backgroundColor", type: "text" },
  
  // File Information
  { label: "App File", value: "appFile", type: "text" },
  
  // Relations
  { label: "Added By", value: "addedBy", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]