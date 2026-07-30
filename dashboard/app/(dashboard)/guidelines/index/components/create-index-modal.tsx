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
import { getBackendClient } from "@/lib/backend-client"

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
      const pb = getBackendClient()
      
      let level = 0
      let order = 0
      
      if (data.parent) {
        // Creating under a parent
        const parent = allIndexItems.find(item => item.id === data.parent)
        level = (parent?.level || 0) + 1
        
        // Get next order under this parent
        const siblings = await pb.collection('guideline_index').getList(1, 50, {
          filter: `parent ~ "${data.parent}"`,
          sort: '-order'
        })
        order = (siblings.items[0]?.order || 0) + 1
        
        // Update parent to mark it has children
        await pb.collection('guideline_index').update(data.parent, {
          hasChildren: true
        })
      } else {
        // Creating at root level
        const rootItems = await pb.collection('guideline_index').getList(1, 1, {
          filter: 'parent = ""',
          sort: '-order'
        })
        order = (rootItems.items[0]?.order || 0) + 1
      }

      // Create the new index item
      await pb.collection('guideline_index').create({
        title: data.title,
        description: data.description || "",
        parent: data.parent ? [data.parent] : undefined,
        level,
        order,
        hasChildren: false,
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