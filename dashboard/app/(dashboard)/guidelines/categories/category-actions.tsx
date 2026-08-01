"use client"

import { Eye, Edit, Trash2, Copy, ToggleLeft, ToggleRight } from "lucide-react"
import type { RowAction, BulkAction } from "@/types/data-table"
import type { GuidelineCategoriesResponse } from "@/types/backend-types"
import { guidelineCategoryService } from "@/services/guideline-content.service"
import { showToast } from "@/lib/toast"

// Row Actions Factory
export const createCategoryRowActions = (
  onEdit: (category: GuidelineCategoriesResponse) => void,
  onView?: (category: GuidelineCategoriesResponse) => void
): RowAction<GuidelineCategoriesResponse>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (category) => {
      if (onView) {
        onView(category)
      } else {
        // Default view action - could navigate to category detail page
        showToast.info("Category Details", `Viewing ${category.name}`)
      }
    },
  },
  {
    id: "edit",
    label: "Edit Category",
    icon: Edit,
    onClick: async (category) => {
      onEdit(category)
    },
  },
  {
    id: "duplicate",
    label: "Duplicate Category",
    icon: Copy,
    onClick: async (category) => {
      await duplicateCategory(category)
    },
  },
  {
    id: "toggle-status",
    label: "Toggle Status",
    icon: ToggleLeft,
    variant: "default",
    onClick: async (category) => {
      await toggleCategoryStatus(category)
    },
    separator: true,
  },
  {
    id: "delete",
    label: "Delete Category",
    icon: Trash2,
    variant: "destructive",
    onClick: async (category) => {
      await deleteCategory(category)
    },
    disabled: () => {
      // Could add logic to check if category has subcategories or is in use
      return false
    },
    confirmMessage: "Are you sure you want to delete this category? This action cannot be undone.",
    separator: true,
  },
]

// Bulk Actions
export const categoryBulkActions: BulkAction<GuidelineCategoriesResponse>[] = [
  {
    id: "bulk-activate",
    label: "Activate Selected",
    icon: ToggleRight,
    onClick: async (categories) => {
      await bulkUpdateCategoryStatus(categories, "active")
    },
    disabled: (categories) => categories.every(cat => cat.status === "active"),
    description: "Activate selected inactive categories",
  },
  {
    id: "bulk-deactivate",
    label: "Deactivate Selected",
    icon: ToggleLeft,
    onClick: async (categories) => {
      await bulkUpdateCategoryStatus(categories, "inactive")
    },
    disabled: (categories) => categories.every(cat => cat.status === "inactive"),
    description: "Deactivate selected active categories",
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: Copy,
    variant: "outline",
    onClick: async (categories) => {
      await exportCategories(categories)
    },
    description: "Export selected categories as JSON file",
    separator: true,
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (categories) => {
      await bulkDeleteCategories(categories)
    },
    description: "Permanently delete selected categories",
    requiresConfirmation: true,
    separator: true,
  },
]

// Action implementation functions
async function duplicateCategory(category: GuidelineCategoriesResponse): Promise<void> {
  const duplicateData = {
    name: `${category.name} (Copy)`,
    slug: category.slug ? `${category.slug}-copy` : undefined,
    description: category.description,
    parent_category: category.parent_category,
    sort_order: (category.sort_order || 0) + 1,
    status: "inactive" as const, // Start copies as inactive
    color: category.color,
    icon: category.icon,
  }

  try {
    await guidelineCategoryService.create(duplicateData)
    showToast.success("Category duplicated", "Category has been duplicated successfully")
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to duplicate category'
    showToast.error("Failed to duplicate category", message)
    throw error
  }
}

async function toggleCategoryStatus(category: GuidelineCategoriesResponse): Promise<void> {
  try {
    const newStatus = category.status === "active" ? "inactive" : "active"
    await guidelineCategoryService.update(category.id, { status: newStatus })
    
    showToast.success(
      "Status Updated",
      `Category ${category.name} has been ${newStatus === 'active' ? 'activated' : 'deactivated'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update category status'
    showToast.error("Update Failed", message)
    throw error
  }
}

async function deleteCategory(category: GuidelineCategoriesResponse): Promise<void> {
  try {
    await guidelineCategoryService.delete(category.id)
    
    showToast.success(
      "Category Deleted",
      `${category.name} has been permanently deleted`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete category'
    showToast.error("Delete Failed", message)
    throw error
  }
}

// Bulk action implementation functions
async function bulkUpdateCategoryStatus(categories: GuidelineCategoriesResponse[], status: "active" | "inactive"): Promise<void> {
  const targetCategories = categories.filter(cat => cat.status !== status)
  
  if (targetCategories.length === 0) {
    showToast.info("No Action Needed", `All selected categories are already ${status}`)
    return
  }
  
  let successCount = 0
  let errorCount = 0

  for (const category of targetCategories) {
    try {
      await guidelineCategoryService.update(category.id, { status })
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to update status for category ${category.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Bulk Update Complete",
      `Successfully ${status === 'active' ? 'activated' : 'deactivated'} ${successCount} categor${successCount === 1 ? 'y' : 'ies'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Updates Failed",
      `${errorCount} categor${errorCount === 1 ? 'y' : 'ies'} could not be updated`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to update any categories")
  }
}

async function exportCategories(categories: GuidelineCategoriesResponse[]): Promise<void> {
  try {
    const exportData = categories.map(cat => ({
      name: cat.name,
      slug: cat.slug,
      description: cat.description,
      status: cat.status,
      sort_order: cat.sort_order,
      color: cat.color,
      icon: cat.icon,
      created: cat.created,
      updated: cat.updated,
    }))

    const dataStr = JSON.stringify(exportData, null, 2)
    const dataBlob = new Blob([dataStr], { type: "application/json" })
    const url = URL.createObjectURL(dataBlob)
    
    const link = document.createElement("a")
    link.href = url
    link.download = `guideline-categories-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)

    showToast.success("Export completed", `Exported ${categories.length} categories`)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to export categories'
    showToast.error("Export Failed", message)
    throw error
  }
}

async function bulkDeleteCategories(categories: GuidelineCategoriesResponse[]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const category of categories) {
    try {
      await guidelineCategoryService.delete(category.id)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to delete category ${category.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Categories Deleted",
      `Successfully deleted ${successCount} categor${successCount === 1 ? 'y' : 'ies'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Deletions Failed",
      `${errorCount} categor${errorCount === 1 ? 'y' : 'ies'} could not be deleted`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to delete any categories")
  }
}
