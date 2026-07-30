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
import { useBackendCrud } from "@/hooks/use-backend-crud"

type CategoryFormData = {
  name: string
  description?: string
  parent_category: string[]
  color?: string
  icon?: string
  sort_order?: number
  status: "active" | "inactive"
}

interface CategoryCreateDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  parentCategories?: DrugCategoriesResponse[]
  onSuccess?: () => void
}

export function CategoryCreateDialog({
  open,
  onOpenChange,
  parentCategories = [],
  onSuccess
}: CategoryCreateDialogProps) {
  const { create, loading } = useBackendCrud({
    collectionName: "drug_categories",
    onSuccess: () => {
      onOpenChange(false)
      onSuccess?.()
    }
  })

  const handleSubmit = async (data: CategoryFormData) => {
    await create(data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Category</DialogTitle>
          <DialogDescription>
            Create a new drug category to organize medications by therapeutic class, mechanism, or clinical use.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          <CategoryForm
            mode="create"
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