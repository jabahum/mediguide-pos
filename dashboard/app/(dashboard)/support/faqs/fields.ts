import type { FieldOption } from "@/types/data-table"

/**
 * Available fields for FAQ table advanced filtering
 * Based on legacy collection API faqs collection schema
 */
export const faqAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Question", value: "question", type: "text" },
  { label: "Answer", value: "answer", type: "text" },
  { label: "Keywords", value: "keywords", type: "text" },
  
  // Status & Management
  { label: "Status", value: "status", type: "select" },
  { label: "Priority", value: "priority", type: "select" },
  { label: "Featured", value: "is_featured", type: "boolean" },
  
  // Audience & Organization
  { label: "Target Audience", value: "target_audience", type: "select" },
  { label: "Has Tags", value: "tags", type: "boolean" },
  
  // Dates
  { label: "Created Date", value: "created", type: "date" },
  { label: "Updated Date", value: "updated", type: "date" },
  { label: "Published Date", value: "published_at", type: "date" },
  
  // Numeric
  { label: "Sort Order", value: "sort_order", type: "number" },
]