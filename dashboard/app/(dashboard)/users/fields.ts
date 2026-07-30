import { FieldOption } from "@/types/data-table"

/**
 * Available fields for users table advanced filtering
 * Based on legacy collection API users collection schema
 */
export const createUsersAvailableFields = (): FieldOption[] => [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Email", value: "email", type: "text" },
  { label: "Phone", value: "phone", type: "text" },
  
  // Professional Information
  { label: "Organization", value: "organization", type: "text" },
  { label: "Department", value: "department", type: "text" },
  { label: "Job Title", value: "jobTitle", type: "text" },
  { label: "License Number", value: "licenseNumber", type: "text" },
  { label: "Role", value: "role", type: "select" },
  { label: "Specialization", value: "specialization", type: "select" },
  
  // Location Information  
  { label: "City", value: "city", type: "text" },
  { label: "State", value: "state", type: "text" },
  { label: "Country", value: "country", type: "text" },
  
  // Settings & Status
  { label: "Status", value: "status", type: "select" },
  { label: "Preferred Language", value: "preferredLanguage", type: "select" },
  { label: "Verified", value: "verified", type: "boolean" },
  { label: "Email Visibility", value: "emailVisibility", type: "boolean" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]

// Default export for backward compatibility
export const usersAvailableFields = createUsersAvailableFields()