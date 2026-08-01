/**
 * Centralized service for Generic Pages CRUD operations
 * Handles all database interactions for the generic_pages collection
 */

import { backendClient } from "@/lib/backend-client"
import type {
  TypedGenericPagesRecord,
  TypedGenericPagesResponse,
  GenericPageContent,
  GenericPageContentCollection
} from "@/types/generic-pages"
interface GenericPageWire { id?: string; created_at?: string; updated_at?: string; key?: string; title?: string; description?: string; content?: unknown }
interface GenericPageList { items: GenericPageWire[]; page: number; per_page: number; total_items: number; total_pages: number }

const normalizePage = (value: GenericPageWire): TypedGenericPagesResponse => ({
  ...value,
  id: value.id || "",
  key: value.key || "",
  title: value.title || "",
  description: value.description || "",
  content: value.content ?? null,
  created: value.created_at || "",
  updated: value.updated_at || "",
  collectionId: "generic_pages",
  collectionName: "generic_pages",
} as TypedGenericPagesResponse)

const getPageByKey = (key: string) => backendClient
  .send<GenericPageWire>(`/api/v2/pages/key/${encodeURIComponent(key)}`)
  .then(normalizePage)
const createPage = (data: Record<string, unknown>) => backendClient
  .send<GenericPageWire>("/api/v2/pages", { method: "POST", body: JSON.stringify(data) })
  .then(normalizePage)
const updatePage = (id: string, data: Record<string, unknown>) => backendClient
  .send<GenericPageWire>(`/api/v2/pages/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  .then(normalizePage)

export class GenericPagesService {
  static async list(params: { page?: number; perPage?: number; search?: string } = {}) {
    const result = await backendClient.send<GenericPageList>("/api/v2/pages", {
      query: { page: params.page ?? 1, per_page: params.perPage ?? 20, search: params.search },
    })
    return {
      items: result.items.map(normalizePage),
      page: result.page,
      perPage: result.per_page,
      totalItems: result.total_items,
      totalPages: result.total_pages,
    }
  }

  static async getPageById(id: string): Promise<TypedGenericPagesResponse> {
    return normalizePage(await backendClient.send<GenericPageWire>(`/api/v2/pages/${id}`))
  }

  static async deletePage(id: string): Promise<void> {
    await backendClient.send<void>(`/api/v2/pages/${id}`, { method: "DELETE" })
  }

  /**
   * Get page by key (returns null if not found)
   */
  static async getPageByKey(pageKey: string): Promise<TypedGenericPagesResponse | null> {
    try {
      return await getPageByKey(pageKey)
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
      const createData = {
        key: key,
        title: title,
        description: description || "",
        content: null // Start with null content, will be populated when content is added
      }

      return await createPage(createData)

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
    description?: string,
    key?: string,
  ): Promise<TypedGenericPagesResponse> {
    try {
      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Update the page
      const updatedRecord = await updatePage(page.id, {
        title,
        description: description || "",
        ...(key ? { key } : {}),
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
      // Find the page
      const page = await this.getPageByKey(pageKey)

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

      const updatedRecord = await updatePage(page.id, { content: updatedContent })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error adding content:', error)
      const serverMessage = error instanceof Error ? error.message : String(error)
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
      const updatedRecord = await updatePage(page.id, {
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
      const updatedRecord = await updatePage(page.id, {
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
      // Find the page
      const page = await this.getPageByKey(pageKey)
      if (!page) {
        throw new Error(`Page with key "${pageKey}" not found`)
      }

      // Update the page with direct content
      const updatedRecord = await updatePage(page.id, {
        content: content // Store as simple string
      })

      return updatedRecord as TypedGenericPagesResponse
    } catch (error) {
      console.error('Error updating page content:', error)
      throw new Error(`Failed to update content for page "${pageKey}": ${error instanceof Error ? error.message : String(error)}`)
    }
  }
}
