"use client"

import { Eye, Edit, Trash2, Copy, Download } from "lucide-react"
import type { RowAction, BulkAction } from "@/types/data-table"
import type { GuidelineTagsResponse } from "@/types/backend-types"
import { guidelineTagService } from "@/services/guideline-content.service"
import { showToast } from "@/lib/toast"

// Row Actions Factory
export const createTagRowActions = (
  onEdit: (tag: GuidelineTagsResponse) => void,
  onView?: (tag: GuidelineTagsResponse) => void
): RowAction<GuidelineTagsResponse>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (tag) => {
      if (onView) {
        onView(tag)
      } else {
        showToast.info("Tag Details", `Viewing ${tag.name}`)
      }
    },
  },
  {
    id: "edit",
    label: "Edit Tag",
    icon: Edit,
    onClick: async (tag) => {
      onEdit(tag)
    },
  },
  {
    id: "duplicate",
    label: "Duplicate Tag",
    icon: Copy,
    onClick: async (tag) => {
      await duplicateTag(tag)
    },
  },
  {
    id: "delete",
    label: "Delete Tag",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tag) => {
      await deleteTag(tag)
    },
    confirmMessage: "Are you sure you want to delete this tag? This action cannot be undone.",
    separator: true,
  },
]

// Bulk Actions
export const tagBulkActions: BulkAction<GuidelineTagsResponse>[] = [
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: Download,
    variant: "outline",
    onClick: async (tags) => {
      await exportTags(tags)
    },
    description: "Export selected tags as JSON file",
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tags) => {
      await bulkDeleteTags(tags)
    },
    description: "Permanently delete selected tags",
    requiresConfirmation: true,
    separator: true,
  },
]

// Action implementation functions
async function duplicateTag(tag: GuidelineTagsResponse): Promise<void> {
  const duplicateData = {
    name: `${tag.name} (Copy)`,
    description: tag.description,
  }

  try {
    await guidelineTagService.create(duplicateData)
    showToast.success("Tag duplicated", "Tag has been duplicated successfully")
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to duplicate tag'
    showToast.error("Failed to duplicate tag", message)
    throw error
  }
}

async function deleteTag(tag: GuidelineTagsResponse): Promise<void> {
  try {
    await guidelineTagService.delete(tag.id)
    
    showToast.success(
      "Tag Deleted",
      `${tag.name} has been permanently deleted`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete tag'
    showToast.error("Delete Failed", message)
    throw error
  }
}

// Bulk action implementation functions
async function exportTags(tags: GuidelineTagsResponse[]): Promise<void> {
  try {
    const exportData = tags.map(tag => ({
      name: tag.name,
      description: tag.description,
      created: tag.created,
      updated: tag.updated,
    }))

    const dataStr = JSON.stringify(exportData, null, 2)
    const dataBlob = new Blob([dataStr], { type: "application/json" })
    const url = URL.createObjectURL(dataBlob)
    
    const link = document.createElement("a")
    link.href = url
    link.download = `guideline-tags-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)

    showToast.success("Export completed", `Exported ${tags.length} tags`)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to export tags'
    showToast.error("Export Failed", message)
    throw error
  }
}

async function bulkDeleteTags(tags: GuidelineTagsResponse[]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const tag of tags) {
    try {
      await guidelineTagService.delete(tag.id)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to delete tag ${tag.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Tags Deleted",
      `Successfully deleted ${successCount} tag${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Deletions Failed",
      `${errorCount} tag${errorCount === 1 ? '' : 's'} could not be deleted`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to delete any tags")
  }
}
