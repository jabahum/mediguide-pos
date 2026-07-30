import type { RowAction, BulkAction } from "@/types/data-table"
import type { FaqsWithExpanded } from "@/types/expanded"
import type { FaqsStatusOptions } from "@/types/backend-types"
import { 
  Eye, 
  Edit, 
  Copy, 
  Archive, 
  Trash2, 
  CheckCircle, 
  Clock, 
  Star,
  StarOff,
  FileDown
} from "lucide-react"
import { showToast } from "@/lib/toast"
import { FaqService } from "@/services/faq.service"

/**
 * Factory function for FAQ row actions
 * Uses dependency injection pattern for navigation
 */
export const createFaqRowActions = (navigate: (path: string) => void): RowAction<FaqsWithExpanded>[] => [
  {
    id: "view",
    label: "View FAQ",
    icon: Eye,
    onClick: async (faq) => {
      navigate(`/support/faqs/${faq.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit FAQ",
    icon: Edit,
    onClick: async (faq) => {
      navigate(`/support/faqs/${faq.id}/edit`)
    },
  },
  {
    id: "duplicate",
    label: "Duplicate FAQ", 
    icon: Copy,
    onClick: async (faq) => {
      try {
        const result = await FaqService.duplicateFaq(faq.id)
        if (result.success) {
          showToast.success("Success", result.message || "FAQ duplicated successfully")
        } else {
          showToast.error("Error", result.error || "Failed to duplicate FAQ")
        }
      } catch (error: unknown) {
        console.error('Error duplicating FAQ:', error)
        showToast.error("Error", "Failed to duplicate FAQ")
      }
    },
    separator: true,
  },
  {
    id: "toggle-featured",
    label: "Toggle Featured Status",
    icon: Star,
    onClick: async (faq) => {
      try {
        const result = await FaqService.updateFaq(faq.id, {
          is_featured: !faq.is_featured
        })
        if (result.success) {
          const action = faq.is_featured ? "removed from featured" : "marked as featured"
          showToast.success("Success", `FAQ ${action}`)
        } else {
          showToast.error("Error", result.error || "Failed to update FAQ")
        }
      } catch (error: unknown) {
        console.error('Error updating FAQ:', error)
        showToast.error("Error", "Failed to update FAQ")
      }
    },
  },
  {
    id: "publish",
    label: "Publish FAQ",
    icon: CheckCircle,
    onClick: async (faq) => {
      try {
        const result = await FaqService.updateFaq(faq.id, {
          status: 'published' as FaqsStatusOptions
        })
        if (result.success) {
          showToast.success("Success", "FAQ published successfully")
        } else {
          showToast.error("Error", result.error || "Failed to publish FAQ")
        }
      } catch (error: unknown) {
        console.error('Error publishing FAQ:', error)
        showToast.error("Error", "Failed to publish FAQ")
      }
    },
    disabled: (faq) => faq.status === 'published',
  },
  {
    id: "archive",
    label: "Archive FAQ",
    icon: Archive,
    onClick: async (faq) => {
      try {
        const result = await FaqService.updateFaq(faq.id, {
          status: 'archived' as FaqsStatusOptions
        })
        if (result.success) {
          showToast.success("Success", "FAQ archived successfully")
        } else {
          showToast.error("Error", result.error || "Failed to archive FAQ")
        }
      } catch (error: unknown) {
        console.error('Error archiving FAQ:', error)
        showToast.error("Error", "Failed to archive FAQ")
      }
    },
    disabled: (faq) => faq.status === 'archived',
  },
  {
    id: "delete",
    label: "Delete FAQ",
    icon: Trash2,
    variant: "destructive",
    onClick: async (faq) => {
      try {
        const result = await FaqService.deleteFaq(faq.id)
        if (result.success) {
          showToast.success("Success", result.message || "FAQ deleted successfully")
        } else {
          showToast.error("Error", result.error || "Failed to delete FAQ")
        }
      } catch (error: unknown) {
        console.error('Error deleting FAQ:', error)
        showToast.error("Error", "Failed to delete FAQ")
      }
    },
    confirmMessage: "Are you sure you want to delete this FAQ? This action cannot be undone.",
    separator: true,
  },
]

/**
 * Bulk actions for selected FAQs
 */
export const faqBulkActions: BulkAction<FaqsWithExpanded>[] = [
  {
    id: "bulk-publish",
    label: "Publish Selected",
    icon: CheckCircle,
    onClick: async (faqs) => {
      try {
        const ids = faqs.map(faq => faq.id)
        const result = await FaqService.bulkUpdateStatus(ids, 'published' as FaqsStatusOptions)
        if (result.success && result.data) {
          const { success_count, error_count } = result.data
          if (error_count > 0) {
            showToast.warning("Partial Success", 
              `Published ${success_count} FAQs, ${error_count} failed`)
          } else {
            showToast.success("Success", `Published ${success_count} FAQs`)
          }
        } else {
          showToast.error("Error", result.error || "Failed to publish FAQs")
        }
      } catch (error: unknown) {
        console.error('Error bulk publishing:', error)
        showToast.error("Error", "Failed to publish FAQs")
      }
    },
    disabled: (faqs) => faqs.every(faq => faq.status === 'published'),
    description: "Publish all selected FAQs",
  },
  {
    id: "bulk-draft",
    label: "Move to Draft",
    icon: Clock,
    onClick: async (faqs) => {
      try {
        const ids = faqs.map(faq => faq.id)
        const result = await FaqService.bulkUpdateStatus(ids, 'draft' as FaqsStatusOptions)
        if (result.success && result.data) {
          const { success_count, error_count } = result.data
          if (error_count > 0) {
            showToast.warning("Partial Success", 
              `Moved ${success_count} FAQs to draft, ${error_count} failed`)
          } else {
            showToast.success("Success", `Moved ${success_count} FAQs to draft`)
          }
        } else {
          showToast.error("Error", result.error || "Failed to update FAQs")
        }
      } catch (error: unknown) {
        console.error('Error moving to draft:', error)
        showToast.error("Error", "Failed to update FAQs")
      }
    },
    variant: "outline",
    description: "Move selected FAQs to draft status",
  },
  {
    id: "bulk-archive",
    label: "Archive Selected",
    icon: Archive,
    onClick: async (faqs) => {
      try {
        const ids = faqs.map(faq => faq.id)
        const result = await FaqService.bulkUpdateStatus(ids, 'archived' as FaqsStatusOptions)
        if (result.success && result.data) {
          const { success_count, error_count } = result.data
          if (error_count > 0) {
            showToast.warning("Partial Success", 
              `Archived ${success_count} FAQs, ${error_count} failed`)
          } else {
            showToast.success("Success", `Archived ${success_count} FAQs`)
          }
        } else {
          showToast.error("Error", result.error || "Failed to archive FAQs")
        }
      } catch (error: unknown) {
        console.error('Error bulk archiving:', error)
        showToast.error("Error", "Failed to archive FAQs")
      }
    },
    variant: "outline",
    description: "Archive all selected FAQs",
    separator: true,
  },
  {
    id: "bulk-feature",
    label: "Mark as Featured",
    icon: Star,
    onClick: async (faqs) => {
      try {
        const updates = faqs.map(faq => 
          FaqService.updateFaq(faq.id, { is_featured: true })
        )
        const results = await Promise.allSettled(updates)
        const successful = results.filter(r => r.status === 'fulfilled').length
        const failed = results.filter(r => r.status === 'rejected').length
        
        if (failed > 0) {
          showToast.warning("Partial Success", 
            `Featured ${successful} FAQs, ${failed} failed`)
        } else {
          showToast.success("Success", `Marked ${successful} FAQs as featured`)
        }
      } catch (error: unknown) {
        console.error('Error bulk featuring:', error)
        showToast.error("Error", "Failed to update FAQs")
      }
    },
    disabled: (faqs) => faqs.every(faq => faq.is_featured),
    description: "Mark selected FAQs as featured",
  },
  {
    id: "bulk-unfeature", 
    label: "Remove from Featured",
    icon: StarOff,
    onClick: async (faqs) => {
      try {
        const updates = faqs.map(faq => 
          FaqService.updateFaq(faq.id, { is_featured: false })
        )
        const results = await Promise.allSettled(updates)
        const successful = results.filter(r => r.status === 'fulfilled').length
        const failed = results.filter(r => r.status === 'rejected').length
        
        if (failed > 0) {
          showToast.warning("Partial Success", 
            `Unfeatured ${successful} FAQs, ${failed} failed`)
        } else {
          showToast.success("Success", `Removed ${successful} FAQs from featured`)
        }
      } catch (error: unknown) {
        console.error('Error bulk unfeaturing:', error)
        showToast.error("Error", "Failed to update FAQs")
      }
    },
    disabled: (faqs) => faqs.every(faq => !faq.is_featured),
    description: "Remove selected FAQs from featured",
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: FileDown,
    onClick: async (faqs) => {
      try {
        // TODO: Implement export functionality
        showToast.info("Export", `Exporting ${faqs.length} FAQs...`)
      } catch (error: unknown) {
        console.error('Error exporting FAQs:', error)
        showToast.error("Error", "Failed to export FAQs")
      }
    },
    variant: "outline",
    description: "Export selected FAQs to CSV/JSON",
    separator: true,
  },
]