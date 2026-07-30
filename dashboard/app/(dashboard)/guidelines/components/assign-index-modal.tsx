"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { GuidelineIndexSelector } from "@/components/ui/guideline-index-selector"
import { MedicalGuidelinesWithExpanded } from "@/types/expanded"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"

const assignIndexSchema = z.object({
  index_item: z.string().optional(),
})

type AssignIndexFormData = z.infer<typeof assignIndexSchema>

interface AssignIndexModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  guideline: MedicalGuidelinesWithExpanded | null
  onSuccess: () => void
}

export function AssignIndexModal({
  open,
  onOpenChange,
  guideline,
  onSuccess,
}: AssignIndexModalProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)

  const form = useForm<AssignIndexFormData>({
    resolver: zodResolver(assignIndexSchema),
    defaultValues: {
      index_item: "",
    },
  })

  const { handleSubmit, setValue, watch, reset } = form

  // Reset form when modal opens or guideline changes
  React.useEffect(() => {
    if (open && guideline) {
      reset({
        index_item: guideline.index_item || "",
      })
    }
  }, [open, guideline, reset])

  const onSubmit = async (data: AssignIndexFormData) => {
    if (!guideline) return
    
    setIsSubmitting(true)
    try {
      const pb = getBackendClient()
      
      await pb.collection('medical_guidelines').update(guideline.id, {
        index_item: data.index_item || undefined,
      })
      
      const actionText = data.index_item ? "assigned to" : "removed from"
      showToast.success("Success", `Index ${actionText} guideline successfully`)
      onSuccess()
      onOpenChange(false)
    } catch (error) {
      showToast.error("Error", "Failed to update guideline index assignment")
      console.error("Failed to update guideline index:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!guideline) return null

  const currentIndexItem = guideline.expand?.index_item

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Assign Index Item</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Guideline Information */}
          <div className="space-y-2">
            <Label>Guideline</Label>
            <div className="p-3 bg-muted rounded-md">
              <p className="font-medium">{guideline.condition_name}</p>
              {guideline.icd10_code && (
                <p className="text-sm text-muted-foreground">
                  ICD-10: {guideline.icd10_code}
                </p>
              )}
            </div>
          </div>

          {/* Current Assignment */}
          {currentIndexItem && (
            <div className="space-y-2">
              <Label>Currently Assigned To</Label>
              <div className="p-3 bg-blue-50 rounded-md border border-blue-200">
                <p className="text-sm text-blue-800 font-medium">
                  {currentIndexItem.title}
                </p>
                {currentIndexItem.description && (
                  <p className="text-xs text-blue-600 mt-1">
                    {currentIndexItem.description}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Index Item Selector */}
          <div className="space-y-2">
            <Label htmlFor="index_item">
              {currentIndexItem ? "Change Assignment" : "Assign Index Item"}
            </Label>
            <GuidelineIndexSelector
              value={watch("index_item") || undefined}
              onValueChange={(value) => setValue("index_item", value || "")}
              placeholder="Select an index item"
              searchPlaceholder="Search index items..."
              showRootOption={true}
              rootOptionLabel="No Assignment (Root Level)"
              allowClear={true}
              className="w-full"
              disabled={isSubmitting}
            />
            <p className="text-xs text-muted-foreground">
              Choose an index item to categorize this guideline, or select &ldquo;Root Level&rdquo; to remove assignment
            </p>
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Updating..." : "Update Assignment"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}