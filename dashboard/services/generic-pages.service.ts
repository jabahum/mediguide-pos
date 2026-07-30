/**
 * Centralized service for Generic Pages CRUD operations
 * Handles all database interactions for the generic_pages collection
 */

import { getBackendClient } from "@/lib/backend-client"
import type {
  TypedGenericPagesRecord,
  TypedGenericPagesResponse,
  GenericPageContent,
  GenericPageContentCollection
} from "@/types/generic-pages"
import { Collections } from "@/types/backend-types"

export class GenericPagesService {
  /**
   * Get page by key (returns null if not found)
   */
  static async getPageByKey(pageKey: string): Promise<TypedGenericPagesResponse | null> {
    try {
      const backend = getBackendClient()

      const records = await backend.resource(Collections.GenericPages).getFullList({
        filter: `key = "${pageKey}"`
      })

      return records.length > 0 ? (records[0] as TypedGenericPagesResponse) : null
    } catch (error) {
      console.error('Error getting page by key:', error)
      return null
    }
  }

  /**
   * Create a new page with initial data
   */
  static async createPage(
    key: string,
    title: string,
    description?: string
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      const createData = {
        key: key,
        title: title,
        description: description || "",
        content: null // Start with null content, will be populated when content is added
      }

      const newRecord = await backend.resource(Collections.GenericPages).create(createData)
      return newRecord as TypedGenericPagesResponse

    } catch (error) {
      console.error('Error creating page:', error)
      throw new Error(`Failed to create page with key "${key}": ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Update page info (title, description)
   */
  static async updatePageInfo(
    pageKey: string,
    title: string,
    description?: string
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Update the page
      const updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
        title,
        description: description || ""
      })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error updating page info:', error)
      throw new Error(`Failed to update page info for "${pageKey}"`)
    }
  }

  /**
   * Add new content section
   */
  static async addContent(
    pageKey: string,
    contentKey: string,
    content: GenericPageContent
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      // Find the page
      const page = await this.getPageByKey(pageKey)

      console.log(page, "pageeeeeeeee")
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Get current content or initialize empty object
      const currentContent = page.content || {}

      // Check if content key already exists
      if (currentContent[contentKey]) {
        throw new Error(`Content with key "${contentKey}" already exists`)
      }

      // Add new content
      const updatedContent = {
        ...currentContent,
        [contentKey]: content
      }


      console.log(updatedContent, "=======")

      // Update the page
      console.log(page.id, "PAGE IDDDDD")
      const payloadBody = JSON.stringify({ content: updatedContent })
      console.log("PATCH body size (bytes):", new Blob([payloadBody]).size)
      console.log("PATCH content keys:", Object.keys(updatedContent))

      // Try update; if PB rejects the JSON field as object, retry with a stringified value.
      let updatedRecord
      try {
        updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
          content: updatedContent,
        })
      } catch (firstErr) {
        const status = (firstErr as { status?: number })?.status
        console.warn("First PATCH attempt failed (status", status, ") — retrying with stringified JSON field")
        updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
          content: JSON.stringify(updatedContent),
        })
      }


      console.log("=======", updatedRecord, "=======")

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      const pbErr = error as { status?: number; data?: unknown; response?: unknown; message?: string }
      console.error('Error adding content:', {
        message: pbErr?.message,
        status: pbErr?.status,
        data: pbErr?.data,
        response: pbErr?.response,
      })
      const serverMessage =
        (pbErr?.data && typeof pbErr.data === 'object' && 'message' in (pbErr.data as object) && (pbErr.data as { message?: string }).message) ||
        pbErr?.message ||
        String(error)
      throw new Error(`Failed to add content to page "${pageKey}": ${serverMessage}`)
    }
  }

  /**
   * Update existing content section
   */
  static async updateContent(
    pageKey: string,
    contentKey: string,
    content: GenericPageContent
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Get current content
      const currentContent = page.content || {}

      // Check if content key exists
      if (!currentContent[contentKey]) {
        throw new Error(`Content with key "${contentKey}" does not exist`)
      }

      // Update content
      const updatedContent = {
        ...currentContent,
        [contentKey]: content
      }

      // Update the page
      const updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
        content: updatedContent
      })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error updating content:', error)
      throw new Error(`Failed to update content in page "${pageKey}": ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Delete content section
   */
  static async deleteContent(
    pageKey: string,
    contentKey: string
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Get current content
      const currentContent = page.content || {}

      // Check if content key exists
      if (!currentContent[contentKey]) {
        throw new Error(`Content with key "${contentKey}" does not exist`)
      }

      // Remove content
      const { [contentKey]: removed, ...updatedContent } = currentContent

      // Update the page
      const updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
        content: updatedContent
      })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error deleting content:', error)
      throw new Error(`Failed to delete content from page "${pageKey}": ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  /**
   * Get all content keys for a page
   */
  static async getContentKeys(pageKey: string): Promise<string[]> {
    try {
      const page = await this.getPageByKey(pageKey)
      if (!page) return []
      const content = page.content || {}
      return Object.keys(content)
    } catch (error) {
      console.error('Error getting content keys:', error)
      return []
    }
  }


  /**
   * Get content by page key and content key
   */
  static async getContent(
    pageKey: string,
    contentKey: string
  ): Promise<GenericPageContent | null> {
    try {
      const page = await this.getPageByKey(pageKey)
      if (!page) return null
      const content = page.content || {}
      return content[contentKey] || null
    } catch (error) {
      console.error('Error getting content:', error)
      return null
    }
  }

  /**
   * Helper: Generate slug from title
   */
  static generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-') // Replace non-alphanumeric with hyphens
      .replace(/^-+|-+$/g, '') // Remove leading/trailing hyphens
      .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
  }

  /**
   * Check if content key is unique within a page
   */
  static async isContentKeyUnique(pageKey: string, contentKey: string): Promise<boolean> {
    try {
      const content = await this.getContent(pageKey, contentKey)
      return content === null
    } catch (error) {
      // If page doesn't exist, key is unique
      return true
    }
  }

  /**
   * Update page content directly (for simple HTML structure)
   */
  static async updatePageContent(
    pageKey: string,
    content: string
  ): Promise<TypedGenericPagesResponse> {
    try {
      const backend = getBackendClient()

      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Update the page with direct content
      const updatedRecord = await backend.resource(Collections.GenericPages).update(page.id, {
        content: content // Store as simple string
      })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error updating page content:', error)
      throw new Error(`Failed to update content for page "${pageKey}": ${error instanceof Error ? error.message : String(error)}`)
    }
  }
}