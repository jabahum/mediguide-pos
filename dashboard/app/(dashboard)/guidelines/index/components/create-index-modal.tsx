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
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { GuidelineIndexSelector } from "@/components/ui/guideline-index-selector"
import { GuidelineIndexType } from "../columns"
import { showToast } from "@/lib/toast"
import { guidelineIndexService } from "@/services/guideline-content.service"

const createIndexSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title must be less than 200 characters"),
  description: z.string().optional(),
  parent: z.string().optional(),
})

type CreateIndexFormData = z.infer<typeof createIndexSchema>

interface CreateIndexModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  allIndexItems: GuidelineIndexType[]
  parentId?: string // Pre-select parent if creating a sub-item
  onSuccess: () => void
}

export function CreateIndexModal({
  open,
  onOpenChange,
  allIndexItems,
  parentId,
  onSuccess,
}: CreateIndexModalProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)

  const form = useForm<CreateIndexFormData>({
    resolver: zodResolver(createIndexSchema),
    defaultValues: {
      title: "",
      description: "",
      parent: parentId || "",
    },
  })

  const { register, handleSubmit, formState: { errors }, setValue, watch, reset } = form

  // Reset form when modal opens
  React.useEffect(() => {
    if (open) {
      reset({
        title: "",
        description: "",
        parent: parentId || "",
      })
    }
  }, [open, parentId, reset])


  const onSubmit = async (data: CreateIndexFormData) => {
    setIsSubmitting(true)
    try {
      const siblings = data.parent
        ? allIndexItems.filter(item => item.parent === data.parent)
        : allIndexItems.filter(item => !item.parent)
      const order = Math.max(0, ...siblings.map(item => item.order || 0)) + 1
      await guidelineIndexService.create({
        title: data.title,
        description: data.description || "",
        parent: data.parent || "",
        order,
      })
      
      showToast.success("Success", "Index item created successfully")
      onSuccess()
      onOpenChange(false)
    } catch (error) {
      showToast.error("Error", "Failed to create index item")
      console.error("Failed to create index item:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>
            {parentId ? "Create Sub-item" : "Create Index Item"}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              {...register("title")}
              placeholder="Enter index item title"
              disabled={isSubmitting}
              className={errors.title ? "border-destructive" : ""}
              autoFocus
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title.message}</p>
            )}
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              {...register("description")}
              placeholder="Optional description for this index item"
              disabled={isSubmitting}
              rows={3}
            />
          </div>

          {/* Parent */}
          {!parentId && (
            <div className="space-y-2">
              <Label htmlFor="parent">Parent Item</Label>
              <GuidelineIndexSelector
                value={watch("parent") || undefined}
                onValueChange={(value) => setValue("parent", value || "")}
                placeholder="Select parent (or leave as root)"
                searchPlaceholder="Search parent items..."
                showRootOption={true}
                rootOptionLabel="Root Level"
                className="w-full"
                disabled={isSubmitting}
                additionalItems={allIndexItems}
              />
              <p className="text-xs text-muted-foreground">
                Choose a parent item to create a sub-item, or leave as root level
              </p>
            </div>
          )}

          {/* Show parent info if pre-selected */}
          {parentId && (
            <div className="space-y-2">
              <Label>Parent Item</Label>
              <div className="p-3 bg-muted rounded-md">
                <p className="text-sm">
                  <span className="font-medium">
                    {allIndexItems.find(item => item.id === parentId)?.title || "Unknown"}
                  </span>
                </p>
                <p className="text-xs text-muted-foreground">
                  This item will be created as a sub-item
                </p>
              </div>
            </div>
          )}

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
              {isSubmitting ? "Creating..." : "Create Item"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
