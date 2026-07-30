/**
 * Extended types for localization service operations
 * Based on legacy collection API Languages collection with additional helper types
 */

import type { 
  LanguagesRecord, 
  LanguagesResponse, 
  LanguagesStatusOptions 
} from "@/types/backend-types"

// Data types for creating new languages
export type LanguageCreateData = Omit<LanguagesRecord, 'id' | 'created' | 'updated'>

// Data types for updating languages (all fields optional)
export type LanguageUpdateData = Partial<Omit<LanguagesRecord, 'id' | 'created' | 'updated'>>

// Filter options for querying languages
export type LanguageFilters = {
  status?: LanguagesStatusOptions[]
  is_active?: boolean
  enabled_for_users?: boolean
  search?: string // Search in name, native_name, or code
  is_default?: boolean
  progress_min?: number
  progress_max?: number
}

// Sort options for language queries
export type LanguageSortOptions = 
  | 'name' 
  | '-name' 
  | 'code' 
  | '-code'
  | 'progress' 
  | '-progress'
  | 'created' 
  | '-created'
  | 'updated'
  | '-updated'

// Language statistics summary
export type LanguageStats = {
  total: number
  active: number
  enabled_for_users: number
  by_status: Record<LanguagesStatusOptions, number>
  average_progress: number
  languages_needing_attention: number // progress < 100
}

// Translation data structure
export type TranslationData = Record<string, string>

// Bulk operation data
export type BulkUpdateData = {
  ids: string[]
  data: LanguageUpdateData
}

// Language with computed fields for UI
export type EnhancedLanguageResponse = LanguagesResponse & {
  progress_color: 'green' | 'blue' | 'yellow' | 'red'
  needs_attention: boolean
  completion_status: 'complete' | 'near_complete' | 'in_progress' | 'needs_work'
}

// Form data for language creation/editing
export type LanguageFormData = {
  code: string
  name: string
  native_name: string
  is_active?: boolean
  enabled_for_users?: boolean
  status?: LanguagesStatusOptions
  progress?: number
  translations_url?: string
  translations?: TranslationData
  version?: number
}

// Validation result
export type ValidationResult = {
  isValid: boolean
  errors: string[]
}

// Service response wrapper for consistent error handling
export type ServiceResponse<T> = {
  success: boolean
  data?: T
  error?: string
  message?: string
}