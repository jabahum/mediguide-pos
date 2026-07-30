import { FieldOption } from "@/types/data-table"

/**
 * Available fields for guideline tags table advanced filtering
 * Based on legacy collection API guideline_tags schema
 * 
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

/**
 * Quick filter options for common tag filters
 */
export const quickFilterOptions = [
  {
    label: "Recently Created",
    filter: 'created >= "2024-01-01"',
    description: "Show tags created this year"
  },
  {
    label: "With Description",
    filter: 'description != ""',
    description: "Show tags that have descriptions"
  },
  {
    label: "Without Description",
    filter: 'description = ""',
    description: "Show tags without descriptions"
  },
]

/**
 * Common search fields for the search functionality
 */
export const searchFields = ["name", "description"]

/**
 * Default sort options for the table
 */
export const sortOptions = [
  { label: "Name (A-Z)", value: "name" },
  { label: "Name (Z-A)", value: "-name" },
  { label: "Recently Created", value: "-created" },
  { label: "Recently Updated", value: "-updated" },
]