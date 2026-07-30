"use client"

import * as React from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { GuidelineCategoryForm, GuidelineCategoryFormData } from "@/components/forms/guideline-category-form"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { showToast } from "@/lib/toast"
import type { GuidelineCategoriesResponse } from "@/types/backend-types"

interface CategoryEditModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  category?: GuidelineCategoriesResponse | null
  onSuccess?: () => void
}

export function CategoryEditModal({
  open,
  onOpenChange,
  category,
  onSuccess
}: CategoryEditModalProps) {
  const { update, loading } = useBackendCrud({
    collectionName: "guideline_categories",
    onSuccess: () => {
      showToast.success("Category updated", "The category has been updated successfully")
      onOpenChange(false)
      onSuccess?.()
    },
    onError: (error) => {
      showToast.error("Failed to update category", error.message)
    }
  })

  const handleSubmit = async (data: GuidelineCategoryFormData) => {
    if (!category?.id) return
    await update(category.id, data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  // Convert category data to form format
  const defaultValues = React.useMemo(() => {
    if (!category) return undefined

    return {
      name: category.name,
      slug: category.slug || "",
      description: category.description || "",
      parent_category: category.parent_category || "",
      sort_order: category.sort_order || 0,
      status: category.status,
      color: category.color || "",
      icon: category.icon || "",
    } as Partial<GuidelineCategoryFormData>
  }, [category])

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="min-w-[700px] sm:max-w-[800px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Guideline Category</DialogTitle>
          <DialogDescription>
            Update the category information and organization settings.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          {category && (
            <GuidelineCategoryForm
              mode="edit"
              defaultValues={defaultValues}
              onSubmit={handleSubmit}
              onCancel={handleCancel}
              loading={loading}
              editingCategoryId={category.id}
            />
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}