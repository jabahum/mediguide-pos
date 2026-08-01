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
import { useDomainCrud } from "@/hooks/use-domain-crud"
import { guidelineCategoryCrud } from "@/services/guideline-content.service"

interface CategoryCreateModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function CategoryCreateModal({
  open,
  onOpenChange,
  onSuccess
}: CategoryCreateModalProps) {
  const { create, loading } = useDomainCrud("guideline-categories", guidelineCategoryCrud, () => {
      onOpenChange(false)
      onSuccess?.()
  })

  const handleSubmit = async (data: GuidelineCategoryFormData) => {
    await create(data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="min-w-[700px] sm:max-w-[800px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Guideline Category</DialogTitle>
          <DialogDescription>
            Create a new category to organize clinical guidelines by specialty, condition, or treatment type.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          <GuidelineCategoryForm
            mode="create"
            onSubmit={handleSubmit}
            onCancel={handleCancel}
            loading={loading}
          />
        </div>
      </DialogContent>
    </Dialog>
  )
}
