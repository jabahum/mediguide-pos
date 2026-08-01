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
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"
import { guidelineTagService } from "@/services/guideline-content.service"
import { showToast } from "@/lib/toast"
import type { GuidelineTagsResponse } from "@/types/backend-types"

// Form validation schema
const tagFormSchema = z.object({
  name: z.string().min(1, "Tag name is required").max(100, "Tag name must be less than 100 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
})

type TagFormValues = z.infer<typeof tagFormSchema>

interface TagEditModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tag: GuidelineTagsResponse | null
  onSuccess?: () => void
}

export function TagEditModal({ 
  open, 
  onOpenChange, 
  tag,
  onSuccess 
}: TagEditModalProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)

  const form = useForm<TagFormValues>({
    resolver: zodResolver(tagFormSchema),
    defaultValues: {
      name: "",
      description: "",
    },
  })

  // Update form values when tag changes
  React.useEffect(() => {
    if (tag && open) {
      form.reset({
        name: tag.name || "",
        description: tag.description || "",
      })
    }
  }, [tag, open, form])

  // Reset form when modal closes
  React.useEffect(() => {
    if (!open) {
      form.reset()
    }
  }, [open, form])

  const onSubmit = async (values: TagFormValues) => {
    if (!tag) return
    
    setIsSubmitting(true)
    
    try {
      
      const tagData = {
        name: values.name.trim(),
        description: values.description?.trim() || "",
      }

      await guidelineTagService.update(tag.id, tagData)

      showToast.success("Tag updated", "Guideline tag has been updated successfully")
      
      onOpenChange(false)
      onSuccess?.()
      
    } catch (error) {
      console.error("Failed to update tag:", error)
      
      const message = error instanceof Error ? error.message : 'Unknown error occurred'
      showToast.error("Failed to update tag", message)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!tag) return null

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit Tag</DialogTitle>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Tag Name</FormLabel>
                  <FormControl>
                    <Input 
                      placeholder="Enter tag name..." 
                      {...field}
                      autoFocus
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description (Optional)</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Enter tag description..."
                      className="min-h-[80px]"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="flex justify-end space-x-2 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => onOpenChange(false)}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button 
                type="submit" 
                disabled={isSubmitting}
              >
                {isSubmitting ? "Updating..." : "Update Tag"}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}
