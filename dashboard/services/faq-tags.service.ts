import { getBackendClient } from "@/lib/backend-client"
import type { FaqTagsRecord, FaqTagsResponse, FaqsResponse } from "@/types/backend-types"
import type { 
  FaqTagWithStats, 
  FaqTagCreateData, 
  FaqTagUpdateData,
  FaqServiceResponse,
  BulkOperationResult 
} from "@/types/faq"

/**
 * FAQ Tags Service - Handles all FAQ tag-related business logic
 * Listing is handled by the Enhanced DataTable component
 */
export class FaqTagsService {
  private static readonly COLLECTION = 'faq_tags'
  private static readonly FAQ_COLLECTION = 'faqs'

  /**
   * Create a new tag
   */
  static async createTag(data: FaqTagCreateData): Promise<FaqServiceResponse<FaqTagsResponse>> {
    try {
      // Generate slug from name if not provided
      const tagData: FaqTagCreateData = {
        is_active: true,
        sort_order: 0,
        color: 'primary',
        ...data,
      }

      if (!tagData.slug && tagData.name) {
        tagData.slug = this.generateSlug(tagData.name)
      }

      // Validate slug uniqueness
      const existingTag = await this.checkSlugExists(tagData.slug!)
      if (existingTag) {
        return { success: false, error: 'A tag with this name already exists' }
      }
      
      const record = await getBackendClient().collection(this.COLLECTION).create<FaqTagsResponse>(tagData)
      return { success: true, data: record, message: 'Tag created successfully' }
    } catch (error) {
      console.error('Error creating tag:', error)
      return { success: false, error: 'Failed to create tag' }
    }
  }

  /**
   * Update a tag
   */
  static async updateTag(id: string, data: FaqTagUpdateData): Promise<FaqServiceResponse<FaqTagsResponse>> {
    try {
      // Generate new slug if name is being updated
      const updateData = { ...data }
      if (updateData.name && !updateData.slug) {
        const newSlug = this.generateSlug(updateData.name)
        
        // Check if new slug conflicts with existing tags (excluding current)
        const existing = await this.checkSlugExists(newSlug, id)
        if (existing) {
          return { success: false, error: 'A tag with this name already exists' }
        }
        
        updateData.slug = newSlug
      }

      const record = await getBackendClient().collection(this.COLLECTION).update<FaqTagsResponse>(id, updateData)
      return { success: true, data: record, message: 'Tag updated successfully' }
    } catch (error) {
      console.error('Error updating tag:', error)
      return { success: false, error: 'Failed to update tag' }
    }
  }

  /**
   * Get a single tag by ID
   */
  static async getTag(id: string): Promise<FaqServiceResponse<FaqTagsResponse>> {
    try {
      const record = await getBackendClient().collection(this.COLLECTION).getOne<FaqTagsResponse>(id)
      return { success: true, data: record }
    } catch (error) {
      console.error('Error fetching tag:', error)
      return { success: false, error: 'Failed to fetch tag' }
    }
  }

  /**
   * Delete a tag (with usage validation)
   */
  static async deleteTag(id: string, force = false): Promise<FaqServiceResponse<void>> {
    try {
      // Check if tag is in use unless forced
      if (!force) {
        const usage = await this.getTagUsageCount(id)
        if (usage > 0) {
          return { 
            success: false, 
            error: `Cannot delete tag that is used by ${usage} FAQ${usage > 1 ? 's' : ''}. Use force delete to remove anyway.` 
          }
        }
      } else {
        // Force delete: remove tag from all FAQs first
        await this.removeTagFromAllFaqs(id)
      }
      
      await getBackendClient().collection(this.COLLECTION).delete(id)
      return { success: true, message: 'Tag deleted successfully' }
    } catch (error) {
      console.error('Error deleting tag:', error)
      return { success: false, error: 'Failed to delete tag' }
    }
  }

  /**
   * Get tag with usage statistics
   */
  static async getTagWithStats(id: string): Promise<FaqServiceResponse<FaqTagWithStats>> {
    try {
      const tag = await getBackendClient().collection(this.COLLECTION).getOne<FaqTagsResponse>(id)
      
      // Get current FAQ count for this tag
      const faqCount = await this.getTagUsageCount(id)
      
      const tagWithStats: FaqTagWithStats = {
        ...tag,
        faq_count: faqCount
      }

      return { success: true, data: tagWithStats }
    } catch (error) {
      console.error('Error fetching tag with stats:', error)
      return { success: false, error: 'Failed to fetch tag' }
    }
  }

  /**
   * Merge tags (move all FAQs from source tags to target tag)
   */
  static async mergeTags(sourceIds: string[], targetId: string): Promise<FaqServiceResponse<BulkOperationResult>> {
    try {
      // Validate target tag exists
      await getBackendClient().collection(this.COLLECTION).getOne(targetId)

      let totalMoved = 0
      const errors: Array<{ id: string; error: string }> = []

      // Process each source tag
      for (const sourceId of sourceIds) {
        try {
          // Get all FAQs with this source tag
          const faqs = await getBackendClient().collection(this.FAQ_COLLECTION).getFullList<FaqsResponse>({
            filter: `tags ~ "${sourceId}"`
          })

          // Update each FAQ to replace source tag with target tag
          const faqUpdates = faqs.map(async (faq) => {
            const updatedTags = (faq.tags || [])
              .filter(tagId => tagId !== sourceId) // Remove source tag
              .concat(targetId) // Add target tag
            
            return getBackendClient().collection(this.FAQ_COLLECTION).update(faq.id, {
              tags: [...new Set(updatedTags)] // Remove duplicates
            })
          })
          
          await Promise.all(faqUpdates)
          totalMoved += faqs.length

          // Delete source tag
          await getBackendClient().collection(this.COLLECTION).delete(sourceId)
        } catch (error) {
          errors.push({
            id: sourceId,
            error: error instanceof Error ? error.message : 'Unknown error'
          })
        }
      }

      // Recalculate usage count for target tag
      const newUsageCount = await this.getTagUsageCount(targetId)
      await getBackendClient().collection(this.COLLECTION).update(targetId, {
        usage_count: newUsageCount
      })

      const result: BulkOperationResult = {
        success_count: sourceIds.length - errors.length,
        error_count: errors.length,
        errors: errors.length > 0 ? errors : undefined
      }

      return { 
        success: true, 
        data: result, 
        message: `Merged ${sourceIds.length - errors.length} tags, moved ${totalMoved} FAQ associations` 
      }
    } catch (error) {
      console.error('Error merging tags:', error)
      return { success: false, error: 'Failed to merge tags' }
    }
  }

  /**
   * Bulk activate/deactivate tags
   */
  static async bulkUpdateStatus(ids: string[], isActive: boolean): Promise<FaqServiceResponse<BulkOperationResult>> {
    try {
      const results = await Promise.allSettled(
        ids.map(id => 
          getBackendClient().collection(this.COLLECTION).update(id, { is_active: isActive })
        )
      )

      const successful = results.filter(result => result.status === 'fulfilled')
      const failed = results.filter(result => result.status === 'rejected') as PromiseRejectedResult[]

      const bulkResult: BulkOperationResult = {
        success_count: successful.length,
        error_count: failed.length,
        errors: failed.map((result, index) => ({
          id: ids[successful.length + index] || 'unknown',
          error: result.reason?.message || 'Unknown error'
        }))
      }

      return { 
        success: true, 
        data: bulkResult, 
        message: `${isActive ? 'Activated' : 'Deactivated'} ${successful.length} tags` 
      }
    } catch (error) {
      console.error('Error bulk updating tag status:', error)
      return { success: false, error: 'Failed to bulk update tags' }
    }
  }

  /**
   * Get tag suggestions for autocomplete
   */
  static async getTagSuggestions(query: string, limit = 10): Promise<FaqServiceResponse<FaqTagsResponse[]>> {
    try {
      const filter = `is_active = true && (name ~ "${query}" || slug ~ "${query}")`
      
      const records = await getBackendClient().collection(this.COLLECTION).getList<FaqTagsResponse>(1, limit, {
        filter,
        sort: '-usage_count,name'
      })

      return { success: true, data: records.items }
    } catch (error) {
      console.error('Error getting tag suggestions:', error)
      return { success: false, error: 'Failed to get suggestions', data: [] }
    }
  }

  /**
   * Get multiple tags by their IDs
   */
  static async getTagsByIds(ids: string[]): Promise<FaqServiceResponse<FaqTagsResponse[]>> {
    try {
      if (ids.length === 0) {
        return { success: true, data: [] }
      }

      const filter = ids.map(id => `id = "${id}"`).join(' || ')
      const records = await getBackendClient().collection(this.COLLECTION).getFullList<FaqTagsResponse>({
        filter,
        sort: 'name'
      })

      return { success: true, data: records }
    } catch (error) {
      console.error('Error getting tags by IDs:', error)
      return { success: false, error: 'Failed to get tags', data: [] }
    }
  }

  /**
   * Get most popular tags
   */
  static async getPopularTags(limit = 20): Promise<FaqServiceResponse<FaqTagsResponse[]>> {
    try {
      const records = await getBackendClient().collection(this.COLLECTION).getList<FaqTagsResponse>(1, limit, {
        filter: 'is_active = true && usage_count > 0',
        sort: '-usage_count,name'
      })

      return { success: true, data: records.items }
    } catch (error) {
      console.error('Error getting popular tags:', error)
      return { success: false, error: 'Failed to get popular tags', data: [] }
    }
  }

  /**
   * Recalculate and fix all tag usage counts
   */
  static async recalculateUsageCounts(): Promise<FaqServiceResponse<{ updated: number }>> {
    try {
      const tags = await getBackendClient().collection(this.COLLECTION).getFullList<FaqTagsResponse>()
      let updated = 0

      const updates = tags.map(async (tag) => {
        try {
          const actualUsage = await this.getTagUsageCount(tag.id)
          if (actualUsage !== tag.usage_count) {
            await getBackendClient().collection(this.COLLECTION).update(tag.id, {
              usage_count: actualUsage
            })
            updated++
          }
        } catch (error) {
          console.error(`Failed to update usage count for tag ${tag.id}:`, error)
        }
      })

      await Promise.allSettled(updates)

      return { 
        success: true, 
        data: { updated }, 
        message: `Recalculated usage counts for ${updated} tags` 
      }
    } catch (error) {
      console.error('Error recalculating usage counts:', error)
      return { success: false, error: 'Failed to recalculate usage counts' }
    }
  }

  /**
   * Generate URL-friendly slug from name
   * @private
   */
  private static generateSlug(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^\w\s-]/g, '') // Remove special characters
      .replace(/\s+/g, '-')     // Replace spaces with hyphens
      .replace(/-+/g, '-')      // Replace multiple hyphens with single
      .trim()
  }

  /**
   * Check if slug exists (excluding specified ID)
   * @private
   */
  private static async checkSlugExists(slug: string, excludeId?: string): Promise<boolean> {
    try {
      let filter = `slug = "${slug}"`
      if (excludeId) {
        filter += ` && id != "${excludeId}"`
      }

      const result = await getBackendClient().collection(this.COLLECTION).getList(1, 1, { filter })
      return result.totalItems > 0
    } catch (error) {
      return false
    }
  }

  /**
   * Get actual usage count for a tag
   * @private
   */
  private static async getTagUsageCount(tagId: string): Promise<number> {
    try {
      const result = await getBackendClient().collection(this.FAQ_COLLECTION).getList(1, 1, {
        filter: `tags ~ "${tagId}"`
      })
      return result.totalItems
    } catch (error) {
      return 0
    }
  }

  /**
   * Remove tag from all FAQs (for force deletion)
   * @private
   */
  private static async removeTagFromAllFaqs(tagId: string): Promise<void> {
    try {
      const faqs = await getBackendClient().collection(this.FAQ_COLLECTION).getFullList<FaqsResponse>({
        filter: `tags ~ "${tagId}"`
      })

      const updates = faqs.map(faq => {
        const updatedTags = (faq.tags || []).filter(id => id !== tagId)
        return getBackendClient().collection(this.FAQ_COLLECTION).update(faq.id, {
          tags: updatedTags
        })
      })

      await Promise.allSettled(updates)
    } catch (error) {
      console.error('Error removing tag from FAQs:', error)
    }
  }
}