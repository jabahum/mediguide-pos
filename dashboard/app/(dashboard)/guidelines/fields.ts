import { FieldOption } from "@/types/data-table"

/**
 * Available fields for medical guidelines table advanced filtering
 * Based on legacy collection API medical_guidelines schema
 */
export const medicalGuidelinesAvailableFields: FieldOption[] = [
  // Basic Information
  { label: "Condition Name", value: "condition_name", type: "text" },
  { label: "ICD-10 Code", value: "icd10_code", type: "text" },
  { label: "Target Population", value: "target_population", type: "text" },
  
  // Medical Content (Rich Text Fields)
  { label: "Definition", value: "definition", type: "text" },
  { label: "Causes", value: "causes", type: "text" },
  { label: "Clinical Features", value: "clinical_features", type: "text" },
  { label: "Differential Diagnosis", value: "differential_diagnosis", type: "text" },
  
  // Classification Levels
  { label: "Classification - Mild", value: "classification_mild", type: "text" },
  { label: "Classification - Moderate", value: "classification_moderate", type: "text" },
  { label: "Classification - Severe", value: "classification_severe", type: "text" },
  { label: "Classification - Critical", value: "classification_critical", type: "text" },
  
  // Management & Treatment
  { label: "General Management", value: "general_management", type: "text" },
  { label: "Primary Medication", value: "medication_primary", type: "text" },
  { label: "Secondary Medication", value: "medication_secondary", type: "text" },
  { label: "Adult Dosage", value: "dosage_adult", type: "text" },
  { label: "Pediatric Dosage", value: "dosage_pediatric", type: "text" },
  { label: "Secondary Adult Dosage", value: "dosage_secondary_adult", type: "text" },
  { label: "Secondary Pediatric Dosage", value: "dosage_secondary_pediatric", type: "text" },
  
  // Healthcare Requirements
  { label: "Healthcare Level Required", value: "healthcare_level_required", type: "text" },
  { label: "Route of Administration", value: "route_administration", type: "text" },
  { label: "Monitoring Requirements", value: "monitoring_requirements", type: "text" },
  { label: "Contraindications", value: "contraindications", type: "text" },
  
  // Prevention & Additional Info
  { label: "Prevention Measures", value: "prevention_measures", type: "text" },
  { label: "Special Notes", value: "special_notes", type: "text" },
  
  // Status & Publication
  { label: "Status", value: "status", type: "select" },
  { label: "Is Published", value: "is_published", type: "boolean" },
  { label: "Priority", value: "priority", type: "select" },
  { label: "Version", value: "version", type: "text" },
  
  // Relations
  { label: "Categories", value: "categories", type: "text" },
  { label: "Tags", value: "tags", type: "text" },
  
  // Timestamps
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]