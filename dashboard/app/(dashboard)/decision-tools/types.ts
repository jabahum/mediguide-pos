import { CalculatorsResponse, UsersResponse } from "@/types/backend-types"

/**
 * Enhanced decision tool type with relations
 * Based on legacy collection API calculators collection schema
 */
export type DecisionToolWithRelations = CalculatorsResponse<{
  addedBy: UsersResponse[]
}>

/**
 * Decision tool type enum for better type safety
 */
export enum DecisionToolType {
  Calculator = "calculator",
  DecisionTool = "decision_tool", 
  Checklist = "checklist"
}

/**
 * Decision tool status enum for better type safety
 */
export enum DecisionToolStatus {
  Active = "active",
  Draft = "draft",
  Archived = "archived"
}

/**
 * Decision tool category groupings for organization
 */
export const DecisionToolCategories = {
  "Emergency Medicine": ["Glasgow Coma Scale", "APGAR Score", "Wells Score"],
  "Cardiovascular": ["Cardiac Risk Assessment", "Hypertension Calculator"],
  "Pediatrics": ["Pediatric Dosing", "Growth Charts", "Vaccination Schedule"],
  "Obstetrics": ["APGAR Score", "Bishop Score", "Pregnancy Calculator"],
  "General Practice": ["BMI Calculator", "Drug Dosing", "Risk Assessment"],
  "Specialized": ["Research Tools", "Training Calculators", "Custom Tools"]
} as const