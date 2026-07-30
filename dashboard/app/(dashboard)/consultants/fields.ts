import { FieldOption } from "@/types/data-table"

/**
 * Available fields for consultants table advanced filtering
 * Based on legacy collection API consultants collection schema
 */
export const consultantsAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Email", value: "email", type: "text" },
  { label: "Phone", value: "phone", type: "text" },
  { label: "Alternative Phone", value: "alternativePhone", type: "text" },
  
  // Professional Information
  { label: "Specialty", value: "specialty", type: "select" },
  { label: "License Number", value: "licenseNumber", type: "text" },
  { label: "Years of Experience", value: "yearsOfExperience", type: "number" },
  { label: "Qualifications", value: "qualifications", type: "select" },
  { label: "Certifications", value: "certifications", type: "text" },
  
  // Location Information  
  { label: "Address", value: "address", type: "text" },
  { label: "City", value: "city", type: "text" },
  { label: "Region", value: "region", type: "text" },
  { label: "Country", value: "country", type: "text" },
  { label: "Postal Code", value: "postalCode", type: "text" },
  
  // Organization Information
  { label: "Organization", value: "organization", type: "text" },
  { label: "Department", value: "department", type: "text" },
  
  // Settings & Preferences
  { label: "Preferred Language", value: "preferredLanguage", type: "select" },
  { label: "Timezone", value: "timezone", type: "text" },
  { label: "Consultation Types", value: "consultationTypes", type: "select" },
  
  // Performance & Verification
  { label: "Rating", value: "rating", type: "number" },
  { label: "Total Consultations", value: "totalConsultations", type: "number" },
  { label: "Verified", value: "isVerified", type: "boolean" },
  { label: "Status", value: "status", type: "select" },
  
  // System Information
  { label: "Notes", value: "notes", type: "text" },
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]

// Specialty options for filtering (matches legacy collection API schema)
export const SpecialtyFilterOptions = [
  "General Practice",
  "Internal Medicine",
  "Pediatrics", 
  "Surgery",
  "Cardiology",
  "Neurology",
  "Psychiatry",
  "Orthopedics",
  "Dermatology",
  "Obstetrics & Gynecology",
  "Ophthalmology",
  "Emergency Medicine",
  "Radiology",
  "Anesthesiology",
  "Pathology",
  "Oncology",
  "Endocrinology",
  "Gastroenterology",
  "Pulmonology",
  "Nephrology",
  "Infectious Diseases",
  "Rheumatology",
  "Public Health",
  "Nursing",
  "Pharmacy",
  "Laboratory Medicine",
  "Other"
]

// Qualification options for filtering (matches legacy collection API schema)
export const QualificationFilterOptions = [
  "MD",
  "MBBS", 
  "DO",
  "DDS",
  "PharmD",
  "RN",
  "BSN",
  "MSN",
  "DNP",
  "PhD",
  "MPH",
  "MS",
  "MA",
  "Diploma",
  "Certificate",
  "Fellowship",
  "Residency",
  "Other"
]

// Language options for filtering (matches legacy collection API schema)
export const LanguageFilterOptions = [
  "English",
  "French",
  "Spanish",
  "Portuguese",
  "Arabic",
  "Swahili",
  "Amharic",
  "Other"
]

// Consultation type options for filtering (matches legacy collection API schema)
export const ConsultationTypeFilterOptions = [
  "In-Person",
  "Telemedicine",
  "Phone Consultation",
  "Emergency Consultation",
  "Second Opinion",
  "Follow-up",
  "Diagnostic Review",
  "Treatment Planning",
  "Medication Review",
  "Health Education"
]

// Status options for filtering (matches legacy collection API schema)
export const StatusFilterOptions = [
  { label: "Active", value: "active" },
  { label: "Inactive", value: "inactive" },
  { label: "Pending Approval", value: "pending_approval" },
  { label: "Suspended", value: "suspended" }
]

// Common countries for filtering (most common in healthcare contexts)
export const CountryFilterOptions = [
  "Afghanistan",
  "Albania",
  "Algeria",
  "Angola",
  "Argentina",
  "Bangladesh",
  "Benin",
  "Bolivia",
  "Brazil",
  "Burkina Faso",
  "Burundi",
  "Cambodia",
  "Cameroon",
  "Central African Republic",
  "Chad",
  "Colombia",
  "Democratic Republic of Congo",
  "Ecuador",
  "Egypt",
  "Ethiopia",
  "Ghana",
  "Guatemala",
  "Guinea",
  "Haiti",
  "Honduras",
  "India",
  "Indonesia",
  "Iraq",
  "Jordan",
  "Kenya",
  "Lebanon",
  "Liberia",
  "Madagascar",
  "Malawi",
  "Mali",
  "Mauritania",
  "Morocco",
  "Mozambique",
  "Myanmar",
  "Nepal",
  "Nicaragua",
  "Niger",
  "Nigeria",
  "Pakistan",
  "Peru",
  "Philippines",
  "Rwanda",
  "Senegal",
  "Sierra Leone",
  "Somalia",
  "South Sudan",
  "Sudan",
  "Tanzania",
  "Togo",
  "Tunisia",
  "Uganda",
  "United States",
  "Yemen",
  "Zambia",
  "Zimbabwe"
]