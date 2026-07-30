/**
 * Backup Service
 * Handles legacy collection API backup operations following project best practices
 */

import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import type {
  BackupFile,
  BackupListResponse,
  BackupCreateData,
  BackupUploadData,
  BackupRestoreData,
  BackupDownloadOptions,
  BackupStats,
  BackupOperationResult,
  BackupServiceConfig,
} from "@/types/backup"

export class BackupService {
  private config: BackupServiceConfig

  constructor(config: BackupServiceConfig = {}) {
    this.config = {
      maxRetries: 3,
      timeout: 30000,
      chunkSize: 1024 * 1024, // 1MB
      ...config,
    }
  }

  /**
   * List all available backups
   */
  async listBackups(page = 1, perPage = 100): Promise<BackupListResponse> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      const response = await backend.send("/api/backups", {
        method: "GET",
        params: { page, perPage },
      })

      return response
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to list backups"
      showToast.error("Error", error)
      throw new Error(error)
    }
  }

  /**
   * Create a new backup
   */
  async createBackup(data: BackupCreateData = {}): Promise<BackupOperationResult> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      const formData = new FormData()
      if (data.name) {
        formData.append("name", data.name)
      }

      const response = await backend.send("/api/backups", {
        method: "POST",
        body: formData,
      })

      showToast.success("Success", "Backup created successfully")
      return {
        success: true,
        message: "Backup created successfully",
        data: response,
      }
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to create backup"
      showToast.error("Error", error)
      return {
        success: false,
        message: error,
      }
    }
  }

  /**
   * Upload backup file for restoration
   */
  async uploadBackup(data: BackupUploadData): Promise<BackupOperationResult> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      if (!data.file) {
        throw new Error("Backup file is required")
      }

      // Validate file type
      if (!data.file.name.endsWith('.zip')) {
        throw new Error("Only ZIP backup files are supported")
      }

      const formData = new FormData()
      formData.append("file", data.file)

      const response = await backend.send("/api/backups/upload", {
        method: "POST",
        body: formData,
      })

      showToast.success("Success", "Backup uploaded successfully")
      return {
        success: true,
        message: "Backup uploaded successfully",
        data: response,
      }
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to upload backup"
      showToast.error("Error", error)
      return {
        success: false,
        message: error,
      }
    }
  }

  /**
   * Restore from backup (requires server restart)
   */
  async restoreBackup(data: BackupRestoreData): Promise<BackupOperationResult> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      if (!data.key) {
        throw new Error("Backup key is required")
      }

      const formData = new FormData()
      formData.append("key", data.key)

      const response = await backend.send("/api/backups/restore", {
        method: "POST",
        body: formData,
      })

      showToast.success("Success", "Backup restore initiated. Server will restart.")
      return {
        success: true,
        message: "Backup restore initiated. Server will restart.",
        data: response,
      }
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to restore backup"
      showToast.error("Error", error)
      return {
        success: false,
        message: error,
      }
    }
  }

  /**
   * Generate download URL for backup
   */
  async downloadBackup(options: BackupDownloadOptions): Promise<string> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      if (!options.key) {
        throw new Error("Backup key is required")
      }

      // Generate download token
      const tokenResponse = await backend.send(`/api/backups/${options.key}`, {
        method: "GET",
      })

      const downloadUrl = `${backend.baseUrl}/api/backups/${options.key}?token=${tokenResponse.token}`
      return downloadUrl
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to generate download URL"
      showToast.error("Error", error)
      throw new Error(error)
    }
  }

  /**
   * Delete a backup file
   */
  async deleteBackup(key: string): Promise<BackupOperationResult> {
    try {
      const backend = getBackendClient()
      if (!backend.authStore.model?.id) {
        throw new Error("Authentication required for backup operations")
      }

      if (!key) {
        throw new Error("Backup key is required")
      }

      await backend.send(`/api/backups/${key}`, {
        method: "DELETE",
      })

      showToast.success("Success", "Backup deleted successfully")
      return {
        success: true,
        message: "Backup deleted successfully",
      }
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to delete backup"
      showToast.error("Error", error)
      return {
        success: false,
        message: error,
      }
    }
  }

  /**
   * Get backup statistics
   */
  async getBackupStats(): Promise<BackupStats> {
    try {
      const response = await this.listBackups()
      const backups = response.items

      let totalSize = 0
      let latestBackup: BackupFile | undefined
      let oldestBackup: BackupFile | undefined

      if (backups.length > 0) {
        totalSize = backups.reduce((sum, backup) => sum + backup.size, 0)
        
        // Sort by modified date to find latest and oldest
        const sortedByDate = [...backups].sort((a, b) => 
          new Date(b.modified).getTime() - new Date(a.modified).getTime()
        )
        
        latestBackup = sortedByDate[0]
        oldestBackup = sortedByDate[sortedByDate.length - 1]
      }

      return {
        totalBackups: backups.length,
        totalSize,
        latestBackup,
        oldestBackup,
      }
    } catch (err) {
      const error = err instanceof Error ? err.message : "Failed to get backup statistics"
      showToast.error("Error", error)
      throw new Error(error)
    }
  }

  /**
   * Format file size for display
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  /**
   * Format date for display
   */
  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString()
  }
}

// Export singleton instance
export const backupService = new BackupService()