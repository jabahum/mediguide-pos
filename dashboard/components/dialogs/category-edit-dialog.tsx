"use client"

import * as React from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { CategoryForm } from "@/components/forms/category-form"
import { DrugCategoriesResponse } from "@/types/backend-types"

// Import the form data type
type CategoryFormData = {
  name: string
  description?: string
  parent_category: string[]
  color?: string
  icon?: string
  sort_order?: number
  status: "active" | "inactive"
}
import { useBackendCrud } from "@/hooks/use-backend-crud"

interface CategoryEditDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  category: DrugCategoriesResponse
  parentCategories?: DrugCategoriesResponse[]
  onSuccess?: () => void
}

export function CategoryEditDialog({
  open,
  onOpenChange,
  category,
  parentCategories = [],
  onSuccess
}: CategoryEditDialogProps) {
  const { update, loading } = useBackendCrud({
    collectionName: "drug_categories",
    onSuccess: () => {
      onOpenChange(false)
      onSuccess?.()
    }
  })

  const handleSubmit = async (data: CategoryFormData) => {
    await update(category.id, data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Category</DialogTitle>
          <DialogDescription>
            Update the details of the &quot;{category.name}&quot; category.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          <CategoryForm
            mode="edit"
            initialData={category}
            parentCategories={parentCategories}
            onSubmit={handleSubmit}
            onCancel={handleCancel}
            loading={loading}
          />
        </div>
      </DialogContent>
    </Dialog>
  )
}