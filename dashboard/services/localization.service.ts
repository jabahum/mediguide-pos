/**
 * Comprehensive service for Languages collection CRUD operations
 * Handles all database interactions and business logic for language management
 */

import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { Collections, type LanguagesRecord, type LanguagesResponse, LanguagesStatusOptions } from "@/types/backend-types"
import type {
  LanguageCreateData,
  LanguageUpdateData,
  LanguageFilters,
  LanguageSortOptions,
  LanguageStats,
  TranslationData,
  BulkUpdateData,
  EnhancedLanguageResponse,
  ValidationResult,
  ServiceResponse
} from "@/types/localization"

export class LocalizationService {
  // ==================== CORE CRUD OPERATIONS ====================

  /**
   * Get all languages with optional filtering and sorting
   */
  static async getAllLanguages(
    filters?: LanguageFilters,
    sort: LanguageSortOptions = 'name',
    page?: number,
    perPage?: number
  ): Promise<LanguagesResponse[]> {
    try {
      const pb = getBackendClient()
      
      // Build filter string
      const filterConditions: string[] = []
      
      if (filters?.status && filters.status.length > 0) {
        const statusFilter = filters.status.map(s => `status = "${s}"`).join(' || ')
        filterConditions.push(`(${statusFilter})`)
      }
      
      if (filters?.is_active !== undefined) {
        filterConditions.push(`is_active = ${filters.is_active}`)
      }
      
      if (filters?.enabled_for_users !== undefined) {
        filterConditions.push(`enabled_for_users = ${filters.enabled_for_users}`)
      }
      
      if (filters?.is_default !== undefined) {
        filterConditions.push(`is_default = ${filters.is_default}`)
      }
      
      if (filters?.progress_min !== undefined) {
        filterConditions.push(`progress >= ${filters.progress_min}`)
      }
      
      if (filters?.progress_max !== undefined) {
        filterConditions.push(`progress <= ${filters.progress_max}`)
      }
      
      if (filters?.search) {
        const searchTerm = filters.search.toLowerCase()
        filterConditions.push(
          `(name ~ "${searchTerm}" || native_name ~ "${searchTerm}" || code ~ "${searchTerm}")`
        )
      }
      
      const filter = filterConditions.length > 0 ? filterConditions.join(' && ') : ''
      
      // Get languages with pagination if specified
      const options: any = { sort: sort }
      if (filter) options.filter = filter
      
      let languages: LanguagesResponse[]
      
      if (page && perPage) {
        const result = await pb.collection(Collections.Languages).getList(page, perPage, options)
        languages = result.items as LanguagesResponse[]
      } else {
        languages = await pb.collection(Collections.Languages).getFullList(options) as LanguagesResponse[]
      }
      
      return languages
    } catch (error) {
      console.error('Error getting languages:', error)
      showToast.error('Failed to load languages', 'Please try refreshing the page')
      throw new Error(`Failed to get languages: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get single language by ID
   */
  static async getLanguageById(id: string): Promise<LanguagesResponse | null> {
    try {
      const pb = getBackendClient()
      const language = await pb.collection(Collections.Languages).getOne(id) as LanguagesResponse
      return language
    } catch (error) {
      console.error('Error getting language by ID:', error)
      return null
    }
  }

  /**
   * Get single language by language code
   */
  static async getLanguageByCode(code: string): Promise<LanguagesResponse | null> {
    try {
      const pb = getBackendClient()
      const languages = await pb.collection(Collections.Languages).getFullList({
        filter: `code = "${code}"`
      }) as LanguagesResponse[]
      
      return languages.length > 0 ? languages[0] : null
    } catch (error) {
      console.error('Error getting language by code:', error)
      return null
    }
  }

  /**
   * Create new language
   */
  static async createLanguage(data: LanguageCreateData): Promise<LanguagesResponse> {
    try {
      const pb = getBackendClient()
      
      // Validate the data
      const validation = this.validateLanguageData(data)
      if (!validation.isValid) {
        const errorMsg = `Validation failed: ${validation.errors.join(', ')}`
        showToast.error('Invalid language data', errorMsg)
        throw new Error(errorMsg)
      }
      
      // Check if language code already exists
      const existing = await this.getLanguageByCode(data.code)
      if (existing) {
        const errorMsg = `Language with code "${data.code}" already exists`
        showToast.error('Duplicate language code', errorMsg)
        throw new Error(errorMsg)
      }
      
      // If this is set as default, ensure no other language is default
      if (data.is_default) {
        await this.clearDefaultLanguage()
      }
      
      const newLanguage = await pb.collection(Collections.Languages).create(data) as LanguagesResponse
      
      showToast.success('Language created successfully', `"${data.name}" has been added`)
      return newLanguage
    } catch (error) {
      console.error('Error creating language:', error)
      const errorString = error instanceof Error ? error.message : String(error)
      if (!errorString.includes('Validation failed') && !errorString.includes('already exists')) {
        showToast.error('Failed to create language', 'Please check your input and try again')
      }
      throw error
    }
  }

  /**
   * Update existing language
   */
  static async updateLanguage(id: string, data: LanguageUpdateData): Promise<LanguagesResponse> {
    try {
      const pb = getBackendClient()
      
      // Get current language to validate
      const currentLang = await this.getLanguageById(id)
      if (!currentLang) {
        const errorMsg = `Language with ID "${id}" not found`
        showToast.error('Language not found', errorMsg)
        throw new Error(errorMsg)
      }
      
      // If updating code, check for duplicates
      if (data.code && data.code !== currentLang.code) {
        const existing = await this.getLanguageByCode(data.code)
        if (existing && existing.id !== id) {
          const errorMsg = `Language with code "${data.code}" already exists`
          showToast.error('Duplicate language code', errorMsg)
          throw new Error(errorMsg)
        }
      }
      
      // If setting as default, clear other defaults
      if (data.is_default && !currentLang.is_default) {
        await this.clearDefaultLanguage()
      }
      
      const updatedLanguage = await pb.collection(Collections.Languages).update(id, data) as LanguagesResponse
      
      showToast.success('Language updated successfully', `"${updatedLanguage.name}" has been updated`)
      return updatedLanguage
    } catch (error) {
      console.error('Error updating language:', error)
      const errorString = error instanceof Error ? error.message : String(error)
      if (!errorString.includes('not found') && !errorString.includes('already exists')) {
        showToast.error('Failed to update language', 'Please try again')
      }
      throw error
    }
  }

  /**
   * Delete language (with safety checks)
   */
  static async deleteLanguage(id: string): Promise<boolean> {
    try {
      const pb = getBackendClient()
      
      // Get language to validate deletion
      const language = await this.getLanguageById(id)
      if (!language) {
        showToast.error('Language not found', 'Cannot delete non-existent language')
        return false
      }
      
      // Prevent deletion of default language
      if (language.is_default) {
        showToast.error('Cannot delete default language', 'Please set another language as default first')
        return false
      }
      
      await pb.collection(Collections.Languages).delete(id)
      
      showToast.success('Language deleted successfully', `"${language.name}" has been removed`)
      return true
    } catch (error) {
      console.error('Error deleting language:', error)
      showToast.error('Failed to delete language', 'Please try again')
      return false
    }
  }

  // ==================== SPECIALIZED OPERATIONS ====================

  /**
   * Get only active languages
   */
  static async getActiveLanguages(): Promise<LanguagesResponse[]> {
    return this.getAllLanguages({ is_active: true })
  }

  /**
   * Get languages available for end users
   */
  static async getUserAvailableLanguages(): Promise<LanguagesResponse[]> {
    return this.getAllLanguages({ 
      is_active: true, 
      enabled_for_users: true 
    })
  }

  /**
   * Get the default language
   */
  static async getDefaultLanguage(): Promise<LanguagesResponse | null> {
    try {
      const languages = await this.getAllLanguages({ is_default: true })
      return languages.length > 0 ? languages[0] : null
    } catch (error) {
      console.error('Error getting default language:', error)
      return null
    }
  }

  /**
   * Set a language as default (clears other defaults)
   */
  static async setDefaultLanguage(id: string): Promise<LanguagesResponse> {
    try {
      // Clear current default
      await this.clearDefaultLanguage()
      
      // Set new default
      return await this.updateLanguage(id, { is_default: true })
    } catch (error) {
      console.error('Error setting default language:', error)
      throw error
    }
  }

  /**
   * Toggle language active status
   */
  static async toggleLanguageStatus(id: string): Promise<LanguagesResponse> {
    try {
      const language = await this.getLanguageById(id)
      if (!language) {
        throw new Error('Language not found')
      }
      
      return await this.updateLanguage(id, { is_active: !language.is_active })
    } catch (error) {
      console.error('Error toggling language status:', error)
      throw error
    }
  }

  /**
   * Update translation progress
   */
  static async updateProgress(id: string, progress: number): Promise<LanguagesResponse> {
    try {
      // Validate progress value
      if (progress < 0 || progress > 100) {
        throw new Error('Progress must be between 0 and 100')
      }
      
      // Determine status based on progress
      let status: LanguagesStatusOptions = LanguagesStatusOptions.in_progress
      if (progress === 100) status = LanguagesStatusOptions.complete
      else if (progress === 0) status = LanguagesStatusOptions.draft
      else if (progress >= 95) status = LanguagesStatusOptions.review
      
      const updatedLanguage = await this.updateLanguage(id, { progress, status })
      
      showToast.success('Progress updated', `Translation progress set to ${progress}%`)
      return updatedLanguage
    } catch (error) {
      console.error('Error updating progress:', error)
      throw error
    }
  }

  /**
   * Bulk update language status
   */
  static async bulkUpdateStatus(ids: string[], status: LanguagesStatusOptions): Promise<LanguagesResponse[]> {
    try {
      const results: LanguagesResponse[] = []
      
      for (const id of ids) {
        try {
          const updated = await this.updateLanguage(id, { status })
          results.push(updated)
        } catch (error) {
          console.error(`Error updating language ${id}:`, error)
          // Continue with other updates
        }
      }
      
      showToast.success('Bulk update completed', `Updated ${results.length} of ${ids.length} languages`)
      return results
    } catch (error) {
      console.error('Error in bulk update:', error)
      showToast.error('Bulk update failed', 'Some languages may not have been updated')
      throw error
    }
  }

  // ==================== TRANSLATION MANAGEMENT ====================

  /**
   * Upload/update translation data for a language
   */
  static async uploadTranslations(id: string, translations: TranslationData, version?: number): Promise<LanguagesResponse> {
    try {
      const updateData: LanguageUpdateData = { 
        translations,
        version: version || 1
      }
      
      const updatedLanguage = await this.updateLanguage(id, updateData)
      showToast.success('Translations uploaded', 'Translation data has been updated successfully')
      
      return updatedLanguage
    } catch (error) {
      console.error('Error uploading translations:', error)
      showToast.error('Failed to upload translations', 'Please try again')
      throw error
    }
  }

  /**
   * Download translation data for a language
   */
  static async downloadTranslations(id: string): Promise<TranslationData | null> {
    try {
      const language = await this.getLanguageById(id)
      if (!language || !language.translations) {
        showToast.warning('No translations found', 'This language has no translation data')
        return null
      }
      
      return language.translations as TranslationData
    } catch (error) {
      console.error('Error downloading translations:', error)
      showToast.error('Failed to download translations', 'Please try again')
      return null
    }
  }

  // ==================== STATISTICS & ANALYTICS ====================

  /**
   * Get comprehensive language statistics
   */
  static async getLanguageStats(): Promise<LanguageStats> {
    try {
      const allLanguages = await this.getAllLanguages()
      
      const stats: LanguageStats = {
        total: allLanguages.length,
        active: allLanguages.filter(l => l.is_active).length,
        enabled_for_users: allLanguages.filter(l => l.enabled_for_users).length,
        by_status: {
          draft: 0,
          in_progress: 0,
          complete: 0,
          review: 0
        },
        average_progress: 0,
        languages_needing_attention: 0
      }
      
      let totalProgress = 0
      
      for (const lang of allLanguages) {
        // Count by status
        if (lang.status) {
          stats.by_status[lang.status]++
        }
        
        // Calculate progress
        const progress = lang.progress || 0
        totalProgress += progress
        
        if (progress < 100) {
          stats.languages_needing_attention++
        }
      }
      
      stats.average_progress = allLanguages.length > 0 
        ? Math.round(totalProgress / allLanguages.length) 
        : 0
      
      return stats
    } catch (error) {
      console.error('Error getting language stats:', error)
      throw error
    }
  }

  /**
   * Get translation progress summary
   */
  static async getProgressSummary(): Promise<{ language: string; progress: number; status: LanguagesStatusOptions }[]> {
    try {
      const languages = await this.getAllLanguages()
      
      return languages.map(lang => ({
        language: lang.name,
        progress: lang.progress || 0,
        status: lang.status || 'draft'
      })).sort((a, b) => b.progress - a.progress)
    } catch (error) {
      console.error('Error getting progress summary:', error)
      throw error
    }
  }

  // ==================== HELPER METHODS ====================

  /**
   * Clear default flag from all languages
   */
  private static async clearDefaultLanguage(): Promise<void> {
    try {
      const currentDefault = await this.getDefaultLanguage()
      if (currentDefault) {
        const pb = getBackendClient()
        await pb.collection(Collections.Languages).update(currentDefault.id, { is_default: false })
      }
    } catch (error) {
      console.error('Error clearing default language:', error)
      // Don't throw, as this is a helper method
    }
  }

  /**
   * Validate language data
   */
  private static validateLanguageData(data: Partial<LanguageCreateData>): ValidationResult {
    const errors: string[] = []
    
    if (!data.code || data.code.trim().length === 0) {
      errors.push('Language code is required')
    }
    
    if (data.code && (data.code.length < 2 || data.code.length > 5)) {
      errors.push('Language code must be 2-5 characters long')
    }
    
    if (!data.name || data.name.trim().length === 0) {
      errors.push('Language name is required')
    }
    
    if (!data.native_name || data.native_name.trim().length === 0) {
      errors.push('Native name is required')
    }
    
    if (data.progress !== undefined && (data.progress < 0 || data.progress > 100)) {
      errors.push('Progress must be between 0 and 100')
    }
    
    return {
      isValid: errors.length === 0,
      errors
    }
  }

  /**
   * Check if language code is unique
   */
  static async isCodeUnique(code: string, excludeId?: string): Promise<boolean> {
    try {
      const existing = await this.getLanguageByCode(code)
      return existing === null || (excludeId !== undefined && existing.id === excludeId)
    } catch (error) {
      console.error('Error checking code uniqueness:', error)
      return false
    }
  }

  /**
   * Generate enhanced language data with computed fields for UI
   */
  static enhanceLanguageData(language: LanguagesResponse): EnhancedLanguageResponse {
    const progress = language.progress || 0
    
    let progress_color: 'green' | 'blue' | 'yellow' | 'red'
    let completion_status: 'complete' | 'near_complete' | 'in_progress' | 'needs_work'
    
    if (progress >= 100) {
      progress_color = 'green'
      completion_status = 'complete'
    } else if (progress >= 95) {
      progress_color = 'blue'
      completion_status = 'near_complete'
    } else if (progress >= 40) {
      progress_color = 'yellow'
      completion_status = 'in_progress'
    } else {
      progress_color = 'red'
      completion_status = 'needs_work'
    }
    
    return {
      ...language,
      progress_color,
      needs_attention: progress < 100,
      completion_status
    }
  }
}