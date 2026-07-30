import { getBackendClient } from "@/lib/backend-client"
import type { 
  FaqsRecord, 
  FaqsResponse, 
  FaqTagsRecord, 
  FaqTagsResponse,
  FaqsStatusOptions,
  FaqsPriorityOptions,
  FaqsTargetAudienceOptions
} from "@/types/backend-types"
import type { 
  FaqCreateData, 
  FaqUpdateData, 
  FaqStatus,
  FaqServiceResponse,
  BulkOperationResult 
} from "@/types/faq"
import type { FaqsWithExpanded } from "@/types/expanded"

/**
 * FAQ Service - Handles all FAQ-related business logic
 * Listing is handled by the Enhanced DataTable component
 */
export class FaqService {
  private static readonly COLLECTION = 'faqs'
  private static readonly TAGS_COLLECTION = 'faq_tags'

  /**
   * Create a new FAQ
   */
  static async createFaq(data: FaqCreateData): Promise<FaqServiceResponse<FaqsResponse>> {
    try {
      const backend = getBackendClient()
      
      // Set default values
      const faqData: FaqCreateData = {
        status: 'draft' as FaqsStatusOptions,
        priority: 'normal' as FaqsPriorityOptions,
        target_audience: 'all' as FaqsTargetAudienceOptions,
        is_featured: false,
        sort_order: 0,
        ...data,
      }

      // If published status, set published_at timestamp
      if (faqData.status === ('published' as FaqsStatusOptions) && !faqData.published_at) {
        faqData.published_at = new Date().toISOString()
      }

      const record = await backend.resource(this.COLLECTION).create<FaqsResponse>(faqData)
      
      // Update tag usage counts
      if (data.tags && data.tags.length > 0) {
        await this.updateTagUsageCounts(data.tags, 'increment')
      }
      
      return { success: true, data: record, message: 'FAQ created successfully' }
    } catch (error) {
      console.error('Error creating FAQ:', error)
      return { success: false, error: 'Failed to create FAQ' }
    }
  }

  /**
   * Update an existing FAQ
   */
  static async updateFaq(id: string, data: FaqUpdateData): Promise<FaqServiceResponse<FaqsResponse>> {
    try {
      // Get current FAQ to compare tags
      const currentFaq = await getBackendClient().resource(this.COLLECTION).getOne<FaqsResponse>(id)
      
      // Handle published status timestamp
      const updateData = { ...data }
      if (updateData.status === ('published' as FaqsStatusOptions) && currentFaq.status !== ('published' as FaqsStatusOptions)) {
        updateData.published_at = new Date().toISOString()
      } else if (updateData.status !== ('published' as FaqsStatusOptions) && updateData.status !== undefined) {
        updateData.published_at = undefined
      }

      const record = await getBackendClient().resource(this.COLLECTION).update<FaqsResponse>(id, updateData)
      
      // Update tag usage counts if tags changed
      if (data.tags !== undefined) {
        const oldTags = currentFaq.tags || []
        const newTags = data.tags || []
        
        // Decrement removed tags
        const removedTags = oldTags.filter(tag => !newTags.includes(tag))
        if (removedTags.length > 0) {
          await this.updateTagUsageCounts(removedTags, 'decrement')
        }
        
        // Increment added tags
        const addedTags = newTags.filter(tag => !oldTags.includes(tag))
        if (addedTags.length > 0) {
          await this.updateTagUsageCounts(addedTags, 'increment')
        }
      }
      
      return { success: true, data: record, message: 'FAQ updated successfully' }
    } catch (error) {
      console.error('Error updating FAQ:', error)
      return { success: false, error: 'Failed to update FAQ' }
    }
  }

  /**
   * Delete an FAQ
   */
  static async deleteFaq(id: string): Promise<FaqServiceResponse<void>> {
    try {
      // Get FAQ to update tag usage counts
      const faq = await getBackendClient().resource(this.COLLECTION).getOne<FaqsResponse>(id)
      
      await getBackendClient().resource(this.COLLECTION).delete(id)
      
      // Decrement tag usage counts
      if (faq.tags && faq.tags.length > 0) {
        await this.updateTagUsageCounts(faq.tags, 'decrement')
      }

      return { success: true, message: 'FAQ deleted successfully' }
    } catch (error) {
      console.error('Error deleting FAQ:', error)
      return { success: false, error: 'Failed to delete FAQ' }
    }
  }

  /**
   * Get FAQ with full relations
   */
  static async getFaqWithRelations(id: string): Promise<FaqServiceResponse<FaqsWithExpanded>> {
    try {
      const record = await getBackendClient().resource(this.COLLECTION).getOne<FaqsWithExpanded>(id, {
        expand: 'tags,author,reviewer,related_faqs'
      })
      return { success: true, data: record }
    } catch (error) {
      console.error('Error fetching FAQ:', error)
      return { success: false, error: 'Failed to fetch FAQ' }
    }
  }

  /**
   * Duplicate an FAQ
   */
  static async duplicateFaq(id: string): Promise<FaqServiceResponse<FaqsResponse>> {
    try {
      const originalResult = await this.getFaqWithRelations(id)
      if (!originalResult.success || !originalResult.data) {
        return { success: false, error: 'Original FAQ not found' }
      }

      const original = originalResult.data
      
      const duplicateData: FaqCreateData = {
        question: `${original.question} (Copy)`,
        answer: original.answer,
        tags: original.tags,
        status: 'draft' as FaqsStatusOptions, // Always set duplicates as draft
        priority: original.priority,
        is_featured: false, // Duplicates should not be featured
        target_audience: original.target_audience,
        keywords: original.keywords,
        author: original.author,
        sort_order: 0
      }
      
      return await this.createFaq(duplicateData)
    } catch (error) {
      console.error('Error duplicating FAQ:', error)
      return { success: false, error: 'Failed to duplicate FAQ' }
    }
  }

  /**
   * Bulk status update
   */
  static async bulkUpdateStatus(ids: string[], status: FaqStatus): Promise<FaqServiceResponse<BulkOperationResult>> {
    try {
      const results = await Promise.allSettled(
        ids.map(async (id) => {
          const updateData: FaqUpdateData = { status }
          
          // Set published_at if publishing
          if (status === ('published' as FaqsStatusOptions)) {
            updateData.published_at = new Date().toISOString()
          } else if (status !== ('published' as FaqsStatusOptions)) {
            updateData.published_at = undefined
          }

          const result = await getBackendClient().resource(this.COLLECTION).update(id, updateData)
          return { id, result }
        })
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
        message: `Updated ${successful.length} FAQs successfully` 
      }
    } catch (error) {
      console.error('Error bulk updating status:', error)
      return { success: false, error: 'Failed to bulk update status' }
    }
  }

  /**
   * Bulk tag assignment
   */
  static async bulkAssignTags(faqIds: string[], tagIds: string[], action: 'add' | 'remove'): Promise<FaqServiceResponse<BulkOperationResult>> {
    try {
      const results = await Promise.allSettled(
        faqIds.map(async (faqId) => {
          const currentFaq = await getBackendClient().resource(this.COLLECTION).getOne<FaqsResponse>(faqId)
          const currentTags = currentFaq.tags || []
          
          let newTags: string[]
          if (action === 'add') {
            // Add tags that don't already exist
            newTags = [...new Set([...currentTags, ...tagIds])]
          } else {
            // Remove specified tags
            newTags = currentTags.filter(tagId => !tagIds.includes(tagId))
          }

          const result = await getBackendClient().resource(this.COLLECTION).update(faqId, {
            tags: newTags
          })
          return { id: faqId, result }
        })
      )

      // Update tag usage counts
      if (action === 'add') {
        await this.updateTagUsageCounts(tagIds, 'increment')
      } else {
        await this.updateTagUsageCounts(tagIds, 'decrement')
      }

      const successful = results.filter(result => result.status === 'fulfilled')
      const failed = results.filter(result => result.status === 'rejected') as PromiseRejectedResult[]

      const bulkResult: BulkOperationResult = {
        success_count: successful.length,
        error_count: failed.length,
        errors: failed.map((result, index) => ({
          id: faqIds[successful.length + index] || 'unknown',
          error: result.reason?.message || 'Unknown error'
        }))
      }

      return { 
        success: true, 
        data: bulkResult, 
        message: `${action === 'add' ? 'Added' : 'Removed'} tags for ${successful.length} FAQs` 
      }
    } catch (error) {
      console.error('Error bulk assigning tags:', error)
      return { success: false, error: 'Failed to bulk assign tags' }
    }
  }

  /**
   * Update tag usage counts
   * @private
   */
  private static async updateTagUsageCounts(
    tagIds: string[], 
    operation: 'increment' | 'decrement'
  ): Promise<void> {
    try {
      const updates = tagIds.map(async (tagId) => {
        try {
          const tag = await getBackendClient().resource(this.TAGS_COLLECTION).getOne<FaqTagsResponse>(tagId)
          const currentCount = tag.usage_count || 0
          const newCount = operation === 'increment' 
            ? currentCount + 1 
            : Math.max(0, currentCount - 1)
          
          return getBackendClient().resource(this.TAGS_COLLECTION).update(tagId, {
            usage_count: newCount
          })
        } catch (error) {
          console.error(`Error updating tag usage count for ${tagId}:`, error)
          return null
        }
      })
      
      await Promise.allSettled(updates)
    } catch (error) {
      console.error('Error updating tag usage counts:', error)
    }
  }

  /**
   * Get related FAQ suggestions based on tags and keywords
   */
  static async getRelatedFaqSuggestions(
    currentFaqId: string, 
    tags: string[], 
    keywords?: string
  ): Promise<FaqServiceResponse<FaqsResponse[]>> {
    try {
      let filter = `id != "${currentFaqId}" && status = "published"`
      
      // Build filter for tags
      if (tags.length > 0) {
        const tagFilters = tags.map(tagId => `tags ~ "${tagId}"`).join(' || ')
        filter += ` && (${tagFilters})`
      }

      // Add keyword search if provided
      if (keywords && keywords.trim()) {
        const keywordFilter = `question ~ "${keywords}" || keywords ~ "${keywords}" || answer ~ "${keywords}"`
        filter += ` && (${keywordFilter})`
      }

      const records = await getBackendClient().resource(this.COLLECTION).getList<FaqsResponse>(1, 5, {
        filter,
        sort: '-created',
        expand: 'tags'
      })

      return { success: true, data: records.items }
    } catch (error) {
      console.error('Error getting related FAQ suggestions:', error)
      return { success: false, error: 'Failed to get suggestions', data: [] }
    }
  }
}