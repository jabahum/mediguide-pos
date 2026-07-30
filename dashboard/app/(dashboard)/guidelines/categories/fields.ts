import { FieldOption } from "@/types/data-table"

/**
 * Available fields for guideline categories table advanced filtering
 * Based on legacy collection API guideline_categories schema
 * 
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

/**
 * Quick filter options for common category filters
 */
export const quickFilterOptions = [
  {
    label: "Active Categories",
    filter: 'status = "active"',
    description: "Show only active categories"
  },
  {
    label: "Inactive Categories", 
    filter: 'status = "inactive"',
    description: "Show only inactive categories"
  },
  {
    label: "Root Categories",
    filter: 'parent_category = ""',
    description: "Show only top-level categories without parents"
  },
  {
    label: "Subcategories",
    filter: 'parent_category != ""',
    description: "Show only categories that have parent categories"
  },
  {
    label: "Recently Created",
    filter: 'created >= "2024-01-01"',
    description: "Show categories created this year"
  },
  {
    label: "With Icons",
    filter: 'icon != ""',
    description: "Show categories that have icons assigned"
  },
  {
    label: "With Colors",
    filter: 'color != ""',
    description: "Show categories that have colors assigned"
  },
]

/**
 * Status filter options for select fields
 */
export const statusFilterOptions = [
  { label: "Active", value: "active" },
  { label: "Inactive", value: "inactive" },
]

/**
 * Common search fields for the search functionality
 */
export const searchFields = ["name", "description", "slug"]

/**
 * Default sort options for the table
 */
export const sortOptions = [
  { label: "Name (A-Z)", value: "name" },
  { label: "Name (Z-A)", value: "-name" },
  { label: "Sort Order", value: "sort_order,name" },
  { label: "Recently Created", value: "-created" },
  { label: "Recently Updated", value: "-updated" },
  { label: "Status", value: "status,name" },
]

/**
 * Hierarchical sort option for proper parent-child ordering
 */
export const hierarchicalSort = "parent_category,sort_order,name"