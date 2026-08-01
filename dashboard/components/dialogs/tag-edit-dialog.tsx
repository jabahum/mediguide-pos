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
import { DrugTagsResponse } from "@/types/backend-types"
import { useDomainCrud } from "@/hooks/use-domain-crud"
import { drugTagCrud } from "@/services/drug.service"

type TagFormData = {
  name: string
  description?: string
  tag_category: "clinical" | "administrative" | "regulatory" | "safety"
  color?: string
  sort_order?: number
  status: "active" | "inactive"
}

interface TagEditDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tag: DrugTagsResponse
  onSuccess?: () => void
}

export function TagEditDialog({
  open,
  onOpenChange,
  tag,
  onSuccess
}: TagEditDialogProps) {
  const { update, loading } = useDomainCrud("drug_tags", drugTagCrud, () => {
      onOpenChange(false)
      onSuccess?.()
  })

  const handleSubmit = async (data: TagFormData) => {
    await update(tag.id, data)
  }

  const handleCancel = () => {
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Tag</DialogTitle>
          <DialogDescription>
            Update the details of the &quot;{tag.name}&quot; tag.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          <TagForm
            mode="edit"
            initialData={tag}
            onSubmit={handleSubmit}
            onCancel={handleCancel}
            loading={loading}
          />
        </div>
      </DialogContent>
    </Dialog>
  )
}
