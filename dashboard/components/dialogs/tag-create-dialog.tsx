"use client"

import * as React from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { TagForm } from "@/components/forms/tag-form"
import { useBackendCrud } from "@/hooks/use-backend-crud"

type TagFormData = {
  name: string
  description?: string
  tag_category: "clinical" | "administrative" | "regulatory" | "safety"
  color?: string
  sort_order?: number
  status: "active" | "inactive"
}

interface TagCreateDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function TagCreateDialog({
  open,
  onOpenChange,
  onSuccess
}: TagCreateDialogProps) {
  const { create, loading } = useBackendCrud({
    collectionName: "drug_tags",
    onSuccess: () => {
      onOpenChange(false)
      onSuccess?.()
    }
  })

  const handleSubmit = async (data: TagFormData) => {
    await create(data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Tag</DialogTitle>
          <DialogDescription>
            Create a new drug tag for flexible categorization including clinical, administrative, regulatory, and safety tags.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          <TagForm
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