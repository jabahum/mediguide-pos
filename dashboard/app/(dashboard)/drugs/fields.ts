import { FieldOption } from "@/types/data-table"

/**
 * Available fields for drugs table advanced filtering
 * Based on legacy collection API drugs collection schema
 */
export const drugAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Name", value: "name", type: "text" },
  { label: "Brand Names", value: "brand_names", type: "text" },
  { label: "Drug Class", value: "drug_class", type: "text" },
  { label: "Therapeutic Category", value: "therapeutic_category", type: "text" },
  
  // Dosing Information
  { label: "Adult Dose", value: "adult_dose", type: "text" },
  { label: "Pediatric Dose", value: "pediatric_dose", type: "text" },
  { label: "Elderly Dose", value: "elderly_dose", type: "text" },
  { label: "Max Daily Dose", value: "max_daily_dose", type: "text" },
  { label: "Frequency", value: "frequency", type: "text" },
  { label: "Duration", value: "duration", type: "text" },
  
  // Administration
  { label: "Route of Administration", value: "route_of_administration", type: "select" },
  
  // Clinical Information
  { label: "Monitoring Parameters", value: "monitoring_parameters", type: "text" },
  { label: "Pregnancy Category", value: "pregnancy_category", type: "select" },
  
  // Classification & Status
  { label: "WHO EML Status", value: "who_eml_status", type: "boolean" },
  { label: "Antimicrobial Status", value: "antimicrobial_status", type: "boolean" },
  { label: "Controlled Substance", value: "controlled_substance", type: "select" },
  { label: "Status", value: "status", type: "select" },
  { label: "Review Status", value: "review_status", type: "select" },
  
  // Search & Keywords
  { label: "Search Keywords", value: "search_keywords", type: "text" },
  
  // Relations
  { label: "Categories", value: "categories", type: "text" },
  { label: "Tags", value: "tags", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]