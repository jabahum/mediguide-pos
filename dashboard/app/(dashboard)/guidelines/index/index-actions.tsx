"use client"

import { RowAction, BulkAction } from "@/types/data-table"
import { GuidelineIndexType } from "./columns"
import { Edit, Trash2, FolderPlus, ArrowUp, ArrowDown } from "lucide-react"
import { showToast } from "@/lib/toast"
import { guidelineIndexService } from "@/services/guideline-content.service"

/**
 * Factory function to create row actions with navigation dependency injection
 */
export const createGuidelineIndexRowActions = (
  navigate: (path: string) => void,
  onRefresh?: () => void,
  allIndexItems?: GuidelineIndexType[],
  setCreateModalOpen?: (open: boolean) => void,
  setEditModalOpen?: (open: boolean) => void,
  setEditingItem?: (item: GuidelineIndexType) => void
): RowAction<GuidelineIndexType>[] => [
  {
    id: "edit",
    label: "Edit Index Item",
    icon: Edit,
    onClick: async (indexItem) => {
      if (setEditModalOpen && setEditingItem) {
        setEditingItem(indexItem)
        setEditModalOpen(true)
      } else {
        showToast.info("Edit Feature", "Edit modal not available")
      }
    },
  },
  {
    id: "add-child",
    label: "Add Sub-item",
    icon: FolderPlus,
    onClick: async (indexItem) => {
      if (setCreateModalOpen) {
        // We'll need to modify CreateIndexModal to accept a parentId prop
        // For now, show the modal and let user select parent
        setCreateModalOpen(true)
        showToast.info("Create Sub-item", "Select the parent item in the modal form")
      } else {
        // Fallback to direct creation
        try {
          const newOrder = await getNextOrderForParent(indexItem.id)
          await guidelineIndexService.create({
            title: "New Sub-item",
            parent: indexItem.id,
            order: newOrder,
          })
          
          showToast.success("Success", "Sub-item created successfully")
          onRefresh?.()
        } catch (error) {
          showToast.error("Error", "Failed to create sub-item")
          console.error("Failed to create sub-item:", error)
        }
      }
    },
  },
  {
    id: "move-up",
    label: "Move Up",
    icon: ArrowUp,
    onClick: async (indexItem) => {
      try {
        await moveIndexItem(indexItem, 'up')
        showToast.success("Success", "Item moved up")
        onRefresh?.()
      } catch (error) {
        showToast.error("Error", "Failed to move item")
        console.error("Failed to move item:", error)
      }
    },
    disabled: (indexItem) => (indexItem.order || 0) <= 0,
  },
  {
    id: "move-down",
    label: "Move Down", 
    icon: ArrowDown,
    onClick: async (indexItem) => {
      try {
        await moveIndexItem(indexItem, 'down')
        showToast.success("Success", "Item moved down")
        onRefresh?.()
      } catch (error) {
        showToast.error("Error", "Failed to move item")
        console.error("Failed to move item:", error)
      }
    },
  },
  {
    id: "delete",
    label: "Delete Index Item",
    icon: Trash2,
    variant: "destructive",
    separator: true,
    onClick: async (indexItem) => {
      try {
        // Check if this item has children
        const children = await guidelineIndexService.children(indexItem.id, { per_page: 1 })
        
        if (children.length > 0) {
          showToast.error("Cannot Delete", "This item has sub-items. Delete sub-items first.")
          return
        }
        
        await guidelineIndexService.delete(indexItem.id)
        showToast.success("Deleted", "Index item deleted successfully")
        onRefresh?.()
      } catch (error) {
        showToast.error("Error", "Failed to delete index item")
        console.error("Failed to delete index item:", error)
      }
    },
    confirmMessage: "Are you sure you want to delete this index item? This action cannot be undone.",
  },
]

/**
 * Bulk actions for selected guideline index items
 */
export const guidelineIndexBulkActions: BulkAction<GuidelineIndexType>[] = [
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (indexItems) => {
      try {
        // Check if any selected items have children
        for (const item of indexItems) {
          const children = await guidelineIndexService.children(item.id, { per_page: 1 })
          
          if (children.length > 0) {
            showToast.error("Cannot Delete", `Item "${item.title}" has sub-items. Delete sub-items first.`)
            return
          }
        }
        
        // Delete all selected items
        await Promise.all(
          indexItems.map(item => 
            guidelineIndexService.delete(item.id)
          )
        )
        
        showToast.success("Success", `Deleted ${indexItems.length} index items`)
      } catch (error) {
        showToast.error("Error", "Failed to delete selected items")
        console.error("Failed to delete items:", error)
      }
    },
    description: "Delete selected index items (items with children cannot be deleted)",
    requiresConfirmation: true,
  },
]

/**
 * Helper function to get the next order number for items under a parent
 */
async function getNextOrderForParent(parentId: string): Promise<number> {
  try {
    const siblings = await guidelineIndexService.children(parentId, { per_page: 100 })
    
    const maxOrder = Math.max(0, ...siblings.map(item => item.order || 0))
    return maxOrder + 1
  } catch (error) {
    console.error("Failed to get next order:", error)
    return 1
  }
}

/**
 * Helper function to move an index item up or down in the order
 */
async function moveIndexItem(item: GuidelineIndexType, direction: 'up' | 'down'): Promise<void> {
  const currentOrder = item.order || 0
  const newOrder = direction === 'up' ? currentOrder - 1 : currentOrder + 1
  
  // Find the item that currently occupies the target position
  const parentId = typeof item.parent === "string" ? item.parent : ""
  const siblings = parentId ? await guidelineIndexService.children(parentId, { per_page: 100 }) : await guidelineIndexService.all({ per_page: 100 })
  const targetItems = siblings.filter(candidate => (candidate.parent || "") === parentId && (candidate.order || 0) === newOrder)
  
  if (targetItems.length > 0) {
    const targetItem = targetItems[0]
    // Swap orders
    await guidelineIndexService.update(targetItem.id, {
      order: currentOrder
    })
  }
  
  // Update the current item's order
  await guidelineIndexService.update(item.id, {
    order: newOrder
  })
}
