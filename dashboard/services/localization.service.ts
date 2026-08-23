/**
 * Comprehensive service for Languages collection CRUD operations
 * Handles all database interactions and business logic for language management
 */

import { backendClient } from "@/lib/backend-client";
import { showToast } from "@/lib/toast";
import {
  type LanguagesRecord,
  type LanguagesResponse,
  LanguagesStatusOptions,
} from "@/types/backend-types";
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
  ServiceResponse,
} from "@/types/localization";

interface LanguageWire extends Omit<LanguagesRecord, "created" | "updated"> {
  id: string;
  created_at?: string;
  updated_at?: string;
}
interface LanguagePage {
  items: LanguageWire[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}
const normalizeLanguage = (value: LanguageWire): LanguagesResponse =>
  ({
    ...value,
    created: value.created_at || "",
    updated: value.updated_at || "",
    collectionId: "languages",
    collectionName: "languages",
  }) as LanguagesResponse;
const languageSort = (sort: LanguageSortOptions) => ({
  sort: sort.startsWith("-")
    ? sort
        .slice(1)
        .replace("created", "created_at")
        .replace("updated", "updated_at")
    : sort.replace("created", "created_at").replace("updated", "updated_at"),
  order: sort.startsWith("-") ? "desc" : "asc",
});

export class LocalizationService {
  // ==================== CORE CRUD OPERATIONS ====================

  /**
   * Get all languages with optional filtering and sorting
   */
  static async getAllLanguages(
    filters?: LanguageFilters,
    sort: LanguageSortOptions = "name",
    page?: number,
    perPage?: number,
  ): Promise<LanguagesResponse[]> {
    try {
      const result = await backendClient.send<LanguagePage>(
        "/api/v2/languages",
        {
          query: {
            page: page ?? 1,
            per_page: perPage ?? 100,
            search: filters?.search,
            status: filters?.status?.join(","),
            is_active: filters?.is_active,
            enabled_for_users: filters?.enabled_for_users,
            is_default: filters?.is_default,
            progress_min: filters?.progress_min,
            progress_max: filters?.progress_max,
            ...languageSort(sort),
          },
        },
      );
      return result.items.map(normalizeLanguage);
    } catch (error) {
      console.error("Error getting languages:", error);
      showToast.error(
        "Failed to load languages",
        "Please try refreshing the page",
      );
      throw new Error(
        `Failed to get languages: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  /**
   * Get single language by ID
   */
  static async getLanguageById(id: string): Promise<LanguagesResponse | null> {
    try {
      return normalizeLanguage(
        await backendClient.send<LanguageWire>(`/api/v2/languages/${id}`),
      );
    } catch (error) {
      console.error("Error getting language by ID:", error);
      return null;
    }
  }

  /**
   * Get single language by language code
   */
  static async getLanguageByCode(
    code: string,
  ): Promise<LanguagesResponse | null> {
    try {
      const result = await backendClient.send<LanguagePage>(
        "/api/v2/languages",
        {
          query: { code, page: 1, per_page: 1 },
        },
      );
      return result.items.length > 0
        ? normalizeLanguage(result.items[0])
        : null;
    } catch (error) {
      console.error("Error getting language by code:", error);
      return null;
    }
  }

  /**
   * Create new language
   */
  static async createLanguage(
    data: LanguageCreateData,
  ): Promise<LanguagesResponse> {
    try {
      // Validate the data
      const validation = this.validateLanguageData(data);
      if (!validation.isValid) {
        const errorMsg = `Validation failed: ${validation.errors.join(", ")}`;
        showToast.error("Invalid language data", errorMsg);
        throw new Error(errorMsg);
      }

      // Check if language code already exists
      const existing = await this.getLanguageByCode(data.code);
      if (existing) {
        const errorMsg = `Language with code "${data.code}" already exists`;
        showToast.error("Duplicate language code", errorMsg);
        throw new Error(errorMsg);
      }

      const newLanguage = normalizeLanguage(
        await backendClient.send<LanguageWire>("/api/v2/languages", {
          method: "POST",
          body: JSON.stringify(data),
        }),
      );

      showToast.success(
        "Language created successfully",
        `"${data.name}" has been added`,
      );
      return newLanguage;
    } catch (error) {
      console.error("Error creating language:", error);
      const errorString =
        error instanceof Error ? error.message : String(error);
      if (
        !errorString.includes("Validation failed") &&
        !errorString.includes("already exists")
      ) {
        showToast.error(
          "Failed to create language",
          "Please check your input and try again",
        );
      }
      throw error;
    }
  }

  /**
   * Update existing language
   */
  static async updateLanguage(
    id: string,
    data: LanguageUpdateData,
  ): Promise<LanguagesResponse> {
    try {
      // Get current language to validate
      const currentLang = await this.getLanguageById(id);
      if (!currentLang) {
        const errorMsg = `Language with ID "${id}" not found`;
        showToast.error("Language not found", errorMsg);
        throw new Error(errorMsg);
      }

      // If updating code, check for duplicates
      if (data.code && data.code !== currentLang.code) {
        const existing = await this.getLanguageByCode(data.code);
        if (existing && existing.id !== id) {
          const errorMsg = `Language with code "${data.code}" already exists`;
          showToast.error("Duplicate language code", errorMsg);
          throw new Error(errorMsg);
        }
      }

      const updatedLanguage = normalizeLanguage(
        await backendClient.send<LanguageWire>(`/api/v2/languages/${id}`, {
          method: "PATCH",
          body: JSON.stringify(data),
        }),
      );

      showToast.success(
        "Language updated successfully",
        `"${updatedLanguage.name}" has been updated`,
      );
      return updatedLanguage;
    } catch (error) {
      console.error("Error updating language:", error);
      const errorString =
        error instanceof Error ? error.message : String(error);
      if (
        !errorString.includes("not found") &&
        !errorString.includes("already exists")
      ) {
        showToast.error("Failed to update language", "Please try again");
      }
      throw error;
    }
  }

  /**
   * Delete language (with safety checks)
   */
  static async deleteLanguage(id: string): Promise<boolean> {
    try {
      // Get language to validate deletion
      const language = await this.getLanguageById(id);
      if (!language) {
        showToast.error(
          "Language not found",
          "Cannot delete non-existent language",
        );
        return false;
      }

      // Prevent deletion of default language
      if (language.is_default) {
        showToast.error(
          "Cannot delete default language",
          "Please set another language as default first",
        );
        return false;
      }

      await backendClient.send<void>(`/api/v2/languages/${id}`, {
        method: "DELETE",
      });

      showToast.success(
        "Language deleted successfully",
        `"${language.name}" has been removed`,
      );
      return true;
    } catch (error) {
      console.error("Error deleting language:", error);
      showToast.error("Failed to delete language", "Please try again");
      return false;
    }
  }

  // ==================== SPECIALIZED OPERATIONS ====================

  /**
   * Get only active languages
   */
  static async getActiveLanguages(): Promise<LanguagesResponse[]> {
    return this.getAllLanguages({ is_active: true });
  }

  /**
   * Get languages available for end users
   */
  static async getUserAvailableLanguages(): Promise<LanguagesResponse[]> {
    return this.getAllLanguages({
      is_active: true,
      enabled_for_users: true,
    });
  }

  /**
   * Get the default language
   */
  static async getDefaultLanguage(): Promise<LanguagesResponse | null> {
    try {
      const languages = await this.getAllLanguages({ is_default: true });
      return languages.length > 0 ? languages[0] : null;
    } catch (error) {
      console.error("Error getting default language:", error);
      return null;
    }
  }

  /**
   * Set a language as default (clears other defaults)
   */
  static async setDefaultLanguage(id: string): Promise<LanguagesResponse> {
    try {
      // The backend switches defaults atomically.
      return await this.updateLanguage(id, { is_default: true });
    } catch (error) {
      console.error("Error setting default language:", error);
      throw error;
    }
  }

  /**
   * Toggle language active status
   */
  static async toggleLanguageStatus(id: string): Promise<LanguagesResponse> {
    try {
      const language = await this.getLanguageById(id);
      if (!language) {
        throw new Error("Language not found");
      }

      return await this.updateLanguage(id, { is_active: !language.is_active });
    } catch (error) {
      console.error("Error toggling language status:", error);
      throw error;
    }
  }

  /**
   * Update translation progress
   */
  static async updateProgress(
    id: string,
    progress: number,
  ): Promise<LanguagesResponse> {
    try {
      // Validate progress value
      if (progress < 0 || progress > 100) {
        throw new Error("Progress must be between 0 and 100");
      }

      // Determine status based on progress
      let status: LanguagesStatusOptions = LanguagesStatusOptions.in_progress;
      if (progress === 100) status = LanguagesStatusOptions.complete;
      else if (progress === 0) status = LanguagesStatusOptions.draft;
      else if (progress >= 95) status = LanguagesStatusOptions.review;

      const updatedLanguage = await this.updateLanguage(id, {
        progress,
        status,
      });

      showToast.success(
        "Progress updated",
        `Translation progress set to ${progress}%`,
      );
      return updatedLanguage;
    } catch (error) {
      console.error("Error updating progress:", error);
      throw error;
    }
  }

  /**
   * Bulk update language status
   */
  static async bulkUpdateStatus(
    ids: string[],
    status: LanguagesStatusOptions,
  ): Promise<LanguagesResponse[]> {
    try {
      const results: LanguagesResponse[] = [];

      for (const id of ids) {
        try {
          const updated = await this.updateLanguage(id, { status });
          results.push(updated);
        } catch (error) {
          console.error(`Error updating language ${id}:`, error);
          // Continue with other updates
        }
      }

      showToast.success(
        "Bulk update completed",
        `Updated ${results.length} of ${ids.length} languages`,
      );
      return results;
    } catch (error) {
      console.error("Error in bulk update:", error);
      showToast.error(
        "Bulk update failed",
        "Some languages may not have been updated",
      );
      throw error;
    }
  }

  // ==================== TRANSLATION MANAGEMENT ====================

  /**
   * Upload/update translation data for a language
   */
  static async uploadTranslations(
    id: string,
    translations: TranslationData,
    version?: number,
  ): Promise<LanguagesResponse> {
    try {
      const updateData: LanguageUpdateData = {
        translations,
        version: version || 1,
      };

      const updatedLanguage = await this.updateLanguage(id, updateData);
      showToast.success(
        "Translations uploaded",
        "Translation data has been updated successfully",
      );

      return updatedLanguage;
    } catch (error) {
      console.error("Error uploading translations:", error);
      showToast.error("Failed to upload translations", "Please try again");
      throw error;
    }
  }

  /**
   * Download translation data for a language
   */
  static async downloadTranslations(
    id: string,
  ): Promise<TranslationData | null> {
    try {
      const language = await this.getLanguageById(id);
      if (!language || !language.translations) {
        showToast.warning(
          "No translations found",
          "This language has no translation data",
        );
        return null;
      }

      return language.translations as TranslationData;
    } catch (error) {
      console.error("Error downloading translations:", error);
      showToast.error("Failed to download translations", "Please try again");
      return null;
    }
  }

  // ==================== STATISTICS & ANALYTICS ====================

  /**
   * Get comprehensive language statistics
   */
  static async getLanguageStats(): Promise<LanguageStats> {
    try {
      const allLanguages = await this.getAllLanguages();

      const stats: LanguageStats = {
        total: allLanguages.length,
        active: allLanguages.filter((l) => l.is_active).length,
        enabled_for_users: allLanguages.filter((l) => l.enabled_for_users)
          .length,
        by_status: {
          draft: 0,
          in_progress: 0,
          complete: 0,
          review: 0,
        },
        average_progress: 0,
        languages_needing_attention: 0,
      };

      let totalProgress = 0;

      for (const lang of allLanguages) {
        // Count by status
        if (lang.status) {
          stats.by_status[lang.status]++;
        }

        // Calculate progress
        const progress = lang.progress || 0;
        totalProgress += progress;

        if (progress < 100) {
          stats.languages_needing_attention++;
        }
      }

      stats.average_progress =
        allLanguages.length > 0
          ? Math.round(totalProgress / allLanguages.length)
          : 0;

      return stats;
    } catch (error) {
      console.error("Error getting language stats:", error);
      throw error;
    }
  }

  /**
   * Get translation progress summary
   */
  static async getProgressSummary(): Promise<
    { language: string; progress: number; status: LanguagesStatusOptions }[]
  > {
    try {
      const languages = await this.getAllLanguages();

      return languages
        .map((lang) => ({
          language: lang.name,
          progress: lang.progress || 0,
          status: lang.status || "draft",
        }))
        .sort((a, b) => b.progress - a.progress);
    } catch (error) {
      console.error("Error getting progress summary:", error);
      throw error;
    }
  }

  // ==================== HELPER METHODS ====================

  /**
   * Validate language data
   */
  private static validateLanguageData(
    data: Partial<LanguageCreateData>,
  ): ValidationResult {
    const errors: string[] = [];

    if (!data.code || data.code.trim().length === 0) {
      errors.push("Language code is required");
    }

    if (data.code && (data.code.length < 2 || data.code.length > 5)) {
      errors.push("Language code must be 2-5 characters long");
    }

    if (!data.name || data.name.trim().length === 0) {
      errors.push("Language name is required");
    }

    if (!data.native_name || data.native_name.trim().length === 0) {
      errors.push("Native name is required");
    }

    if (
      data.progress !== undefined &&
      (data.progress < 0 || data.progress > 100)
    ) {
      errors.push("Progress must be between 0 and 100");
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Check if language code is unique
   */
  static async isCodeUnique(
    code: string,
    excludeId?: string,
  ): Promise<boolean> {
    try {
      const existing = await this.getLanguageByCode(code);
      return (
        existing === null ||
        (excludeId !== undefined && existing.id === excludeId)
      );
    } catch (error) {
      console.error("Error checking code uniqueness:", error);
      return false;
    }
  }

  /**
   * Generate enhanced language data with computed fields for UI
   */
  static enhanceLanguageData(
    language: LanguagesResponse,
  ): EnhancedLanguageResponse {
    const progress = language.progress || 0;

    let progress_color: "green" | "blue" | "yellow" | "red";
    let completion_status:
      | "complete"
      | "near_complete"
      | "in_progress"
      | "needs_work";

    if (progress >= 100) {
      progress_color = "green";
      completion_status = "complete";
    } else if (progress >= 95) {
      progress_color = "blue";
      completion_status = "near_complete";
    } else if (progress >= 40) {
      progress_color = "yellow";
      completion_status = "in_progress";
    } else {
      progress_color = "red";
      completion_status = "needs_work";
    }

    return {
      ...language,
      progress_color,
      needs_attention: progress < 100,
      completion_status,
    };
  }
}
