/**
 * Backup management type definitions
 * Based on legacy collection API backup API endpoints
 */

export interface BackupFile {
  key: string
  size: number
  modified: string
}

export interface BackupListResponse {
  page: number
  perPage: number
  totalItems: number
  totalPages: number
  items: BackupFile[]
}

export interface BackupCreateData {
  name?: string
}

export interface BackupUploadData {
  file: File
}

export interface BackupRestoreData {
  key: string
}

export interface BackupDownloadOptions {
  key: string
  token?: string
}

export interface BackupStats {
  totalBackups: number
  totalSize: number
  latestBackup?: BackupFile
  oldestBackup?: BackupFile
}

export interface BackupOperationResult {
  success: boolean
  message: string
  data?: any
}

export interface BackupServiceConfig {
  maxRetries?: number
  timeout?: number
  chunkSize?: number
}