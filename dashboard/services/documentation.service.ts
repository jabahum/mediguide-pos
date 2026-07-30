/**
 * Centralized service for Documentation CRUD operations
 * Handles all database interactions for the documentation collection
 */

import { getBackendClient } from "@/lib/backend-client"
import type { 
  DocumentationRecord, 
  DocumentationResponse
} from "@/types/backend-types"
import { Collections, DocumentationStatusOptions } from "@/types/backend-types"

export interface CreateDocumentationData {
  title: string
  description?: string
  content: string
  category?: string
  tags?: string
  status?: DocumentationStatusOptions
}

export interface UpdateDocumentationData extends Partial<CreateDocumentationData> {}

export class DocumentationService {
  /**
   * Get all documentation entries
   */
  static async getAll(options?: {
    sort?: string
    filter?: string
    expand?: string
    page?: number
    perPage?: number
  }): Promise<DocumentationResponse[]> {
    try {
      const pb = getBackendClient()
      
      const records = await pb.collection(Collections.Documentation).getFullList({
        sort: options?.sort || "-created",
        filter: options?.filter,
        expand: options?.expand,
      })

      return records as DocumentationResponse[]
    } catch (error) {
      console.error('Error getting documentation entries:', error)
      throw new Error(`Failed to fetch documentation entries: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get documentation entry by ID
   */
  static async getById(id: string, expand?: string): Promise<DocumentationResponse | null> {
    try {
      const pb = getBackendClient()
      
      const record = await pb.collection(Collections.Documentation).getOne(id, {
        expand: expand
      })

      return record as DocumentationResponse
    } catch (error) {
      console.error('Error getting documentation entry by ID:', error)
      return null
    }
  }

  /**
   * Create new documentation entry
   */
  static async create(data: CreateDocumentationData): Promise<DocumentationResponse> {
    try {
      const pb = getBackendClient()
      
      const createData: Omit<DocumentationRecord, 'id' | 'created' | 'updated'> = {
        title: data.title,
        description: data.description || "",
        content: data.content,
        category: data.category || "",
        tags: data.tags || "",
        status: data.status || DocumentationStatusOptions.draft
      }
      
      const newRecord = await pb.collection(Collections.Documentation).create(createData)
      return newRecord as DocumentationResponse
      
    } catch (error) {
      console.error('Error creating documentation entry:', error)
      throw new Error(`Failed to create documentation entry: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Update existing documentation entry
   */
  static async update(id: string, data: UpdateDocumentationData): Promise<DocumentationResponse> {
    try {
      const pb = getBackendClient()
      
      const updateData: Partial<DocumentationRecord> = {}
      
      if (data.title !== undefined) updateData.title = data.title
      if (data.description !== undefined) updateData.description = data.description
      if (data.content !== undefined) updateData.content = data.content
      if (data.category !== undefined) updateData.category = data.category
      if (data.tags !== undefined) updateData.tags = data.tags
      if (data.status !== undefined) updateData.status = data.status

      const updatedRecord = await pb.collection(Collections.Documentation).update(id, updateData)
      return updatedRecord as DocumentationResponse
      
    } catch (error) {
      console.error('Error updating documentation entry:', error)
      throw new Error(`Failed to update documentation entry: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Delete documentation entry
   */
  static async delete(id: string): Promise<boolean> {
    try {
      const pb = getBackendClient()
      
      await pb.collection(Collections.Documentation).delete(id)
      return true
      
    } catch (error) {
      console.error('Error deleting documentation entry:', error)
      throw new Error(`Failed to delete documentation entry: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Search documentation entries
   */
  static async search(query: string, options?: {
    category?: string
    status?: string
    limit?: number
  }): Promise<DocumentationResponse[]> {
    try {
      const pb = getBackendClient()
      
      let filter = `title ~ "${query}" || description ~ "${query}" || content ~ "${query}" || tags ~ "${query}"`
      
      if (options?.category) {
        filter += ` && category = "${options.category}"`
      }
      
      if (options?.status) {
        filter += ` && status = "${options.status}"`
      }

      const records = await pb.collection(Collections.Documentation).getFullList({
        filter: filter,
        sort: "-created",
        ...(options?.limit && { perPage: options.limit })
      })

      return records as DocumentationResponse[]
    } catch (error) {
      console.error('Error searching documentation entries:', error)
      throw new Error(`Failed to search documentation entries: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get documentation entries by category
   */
  static async getByCategory(category: string): Promise<DocumentationResponse[]> {
    try {
      const pb = getBackendClient()
      
      const records = await pb.collection(Collections.Documentation).getFullList({
        filter: `category = "${category}"`,
        sort: "-created"
      })

      return records as DocumentationResponse[]
    } catch (error) {
      console.error('Error getting documentation entries by category:', error)
      throw new Error(`Failed to get documentation entries by category: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get documentation entries by status
   */
  static async getByStatus(status: DocumentationStatusOptions): Promise<DocumentationResponse[]> {
    try {
      const pb = getBackendClient()
      
      const records = await pb.collection(Collections.Documentation).getFullList({
        filter: `status = "${status}"`,
        sort: "-created"
      })

      return records as DocumentationResponse[]
    } catch (error) {
      console.error('Error getting documentation entries by status:', error)
      throw new Error(`Failed to get documentation entries by status: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get unique categories
   */
  static async getCategories(): Promise<string[]> {
    try {
      const pb = getBackendClient()
      
      const records = await pb.collection(Collections.Documentation).getFullList({
        fields: "category"
      })

      const categories = records
        .map(record => (record as DocumentationResponse).category)
        .filter(category => category && category.trim() !== "")
        .filter((category, index, array) => array.indexOf(category) === index)
        .sort()

      return categories as string[]
    } catch (error) {
      console.error('Error getting documentation categories:', error)
      return []
    }
  }

  /**
   * Get unique tags
   */
  static async getTags(): Promise<string[]> {
    try {
      const pb = getBackendClient()
      
      const records = await pb.collection(Collections.Documentation).getFullList({
        fields: "tags"
      })

      const allTags = records
        .map(record => (record as DocumentationResponse).tags)
        .filter(tags => tags && tags.trim() !== "")
        .flatMap(tags => tags.split(',').map(tag => tag.trim()))
        .filter(tag => tag !== "")
        .filter((tag, index, array) => array.indexOf(tag) === index)
        .sort()

      return allTags as string[]
    } catch (error) {
      console.error('Error getting documentation tags:', error)
      return []
    }
  }

  /**
   * Bulk operations
   */
  static async bulkUpdateStatus(ids: string[], status: DocumentationStatusOptions): Promise<void> {
    try {
      const pb = getBackendClient()
      
      const promises = ids.map(id => 
        pb.collection(Collections.Documentation).update(id, { status })
      )
      
      await Promise.all(promises)
    } catch (error) {
      console.error('Error bulk updating documentation status:', error)
      throw new Error(`Failed to bulk update documentation status: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  static async bulkDelete(ids: string[]): Promise<void> {
    try {
      const pb = getBackendClient()
      
      const promises = ids.map(id => 
        pb.collection(Collections.Documentation).delete(id)
      )
      
      await Promise.all(promises)
    } catch (error) {
      console.error('Error bulk deleting documentation entries:', error)
      throw new Error(`Failed to bulk delete documentation entries: ${error instanceof Error ? error.message : String(error)}`)
    }
  }
}