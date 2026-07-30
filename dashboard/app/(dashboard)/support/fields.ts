import { FieldOption } from "@/types/data-table"

/**
 * Available fields for support tickets table advanced filtering
 * Based on legacy collection API support_tickets schema
 */
export const supportTicketsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Subject", value: "subject", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Category", value: "category", type: "text" },
  
  // Status & Priority
  { label: "Status", value: "status", type: "select" },
  { label: "Priority", value: "priority", type: "select" },
  
  // User Relations
  { label: "Created By", value: "user_id", type: "text" },
  { label: "Assigned To", value: "assigned_to", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]