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
import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"

// Form validation schema
const tagFormSchema = z.object({
  name: z.string().min(1, "Tag name is required").max(100, "Tag name must be less than 100 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
})

type TagFormValues = z.infer<typeof tagFormSchema>

interface TagCreateModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function TagCreateModal({ 
  open, 
  onOpenChange, 
  onSuccess 
}: TagCreateModalProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)

  const form = useForm<TagFormValues>({
    resolver: zodResolver(tagFormSchema),
    defaultValues: {
      name: "",
      description: "",
    },
  })

  // Reset form when modal closes
  React.useEffect(() => {
    if (!open) {
      form.reset()
    }
  }, [open, form])

  const onSubmit = async (values: TagFormValues) => {
    setIsSubmitting(true)
    
    try {
      const backend = getBackendClient()
      
      const tagData = {
        name: values.name.trim(),
        description: values.description?.trim() || "",
      }

      await backend.resource("guideline_tags").create(tagData)

      showToast.success("Tag created", "New guideline tag has been created successfully")
      
      onOpenChange(false)
      onSuccess?.()
      
    } catch (error) {
      console.error("Failed to create tag:", error)
      
      const message = error instanceof Error ? error.message : 'Unknown error occurred'
      showToast.error("Failed to create tag", message)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create New Tag</DialogTitle>
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
                {isSubmitting ? "Creating..." : "Create Tag"}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}