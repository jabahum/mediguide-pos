"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

// UI Components
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { SimpleGuidelineCategorySelector } from "@/components/ui/guideline-category-selector"
import { MultiSelect } from "@/components/ui/multi-select"

// Hooks and utilities
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { useGuidelineTags } from "@/hooks/use-guideline-tags"
import { showToast } from "@/lib/toast"
import { AbbreviationsWithExpanded } from "@/types/expanded"

// Form schema
const abbreviationFormSchema = z.object({
  abbreviation: z.string().min(1, "Abbreviation is required").max(20, "Abbreviation too long"),
  meaning: z.string().min(1, "Meaning is required").max(200, "Meaning too long"),
  description: z.string().optional(),
  common_usage: z.boolean(),
  category: z.string().optional(),
  tags: z.array(z.string()),
})

type AbbreviationFormData = z.infer<typeof abbreviationFormSchema>

interface AbbreviationEditModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  abbreviation: AbbreviationsWithExpanded | null
  onSuccess?: () => void
}

export function AbbreviationEditModal({
  open,
  onOpenChange,
  abbreviation,
  onSuccess,
}: AbbreviationEditModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  
  // Load tags using the custom hook
  const { getMultiSelectOptions } = useGuidelineTags()

  const { update } = useBackendCrud({
    collectionName: "abbreviations",
    onSuccess: () => {
      // Success handled in onSubmit
    },
    onError: (error) => {
      console.error("CRUD error:", error)
    }
  })

  const form = useForm<AbbreviationFormData>({
    resolver: zodResolver(abbreviationFormSchema),
    defaultValues: {
      abbreviation: "",
      meaning: "",
      description: "",
      common_usage: false,
      category: "",
      tags: [],
    },
  })

  // Populate form when modal opens
  React.useEffect(() => {
    const populateForm = () => {
      if (!abbreviation) return

      form.reset({
        abbreviation: abbreviation.abbreviation,
        meaning: abbreviation.meaning,
        description: abbreviation.description || "",
        common_usage: abbreviation.common_usage || false,
        category: (typeof abbreviation.category === 'string' ? abbreviation.category : abbreviation.category?.[0]) || "",
        tags: abbreviation.tags || [],
      })
    }

    if (open && abbreviation) {
      populateForm()
    }
  }, [open, abbreviation, form])

  const onSubmit = async (data: AbbreviationFormData) => {
    if (!abbreviation) return

    setIsLoading(true)
    try {
      await update(abbreviation.id, {
        abbreviation: data.abbreviation.toUpperCase(),
        meaning: data.meaning,
        description: data.description || "",
        common_usage: data.common_usage,
        category: data.category || "",
        tags: data.tags,
      })

      showToast.success("Success", "Abbreviation updated successfully")
      onOpenChange(false)
      onSuccess?.()
    } catch (error: unknown) {
      console.error("Update abbreviation error:", error)
      const errorMessage = error instanceof Error ? error.message : "Failed to update abbreviation"
      showToast.error("Error", errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  if (!abbreviation) return null

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Abbreviation</DialogTitle>
          <DialogDescription>
            Update the abbreviation details and associations.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="abbreviation"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Abbreviation</FormLabel>
                    <FormControl>
                      <Input 
                        placeholder="BP, HTN, etc." 
                        {...field}
                        onChange={(e) => field.onChange(e.target.value.toUpperCase())}
                      />
                    </FormControl>
                    <FormDescription>
                      The short form (will be converted to uppercase)
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="meaning"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Meaning</FormLabel>
                    <FormControl>
                      <Input placeholder="Blood Pressure, Hypertension, etc." {...field} />
                    </FormControl>
                    <FormDescription>
                      The full expanded form or definition
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description (Optional)</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Additional context, usage notes, or clinical significance..."
                      rows={3}
                      {...field}
                    />
                  </FormControl>
                  <FormDescription>
                    Additional context or usage information
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="category"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Category (Optional)</FormLabel>
                  <FormControl>
                    <SimpleGuidelineCategorySelector
                      value={field.value}
                      onValueChange={field.onChange}
                      placeholder="Select a category"
                      className="w-full"
                    />
                  </FormControl>
                  <FormDescription>
                    Medical specialty or category
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="tags"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Tags (Optional)</FormLabel>
                  <FormControl>
                    <MultiSelect
                      options={getMultiSelectOptions()}
                      value={field.value}
                      onValueChange={field.onChange}
                      placeholder="Select tags..."
                      className="w-full"
                    />
                  </FormControl>
                  <FormDescription>
                    Select relevant tags for this abbreviation
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="common_usage"
              render={({ field }) => (
                <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                  <div className="space-y-0.5">
                    <FormLabel>Common Usage</FormLabel>
                    <FormDescription>
                      Mark if this abbreviation is frequently used in clinical practice
                    </FormDescription>
                  </div>
                  <FormControl>
                    <Switch
                      checked={field.value}
                      onCheckedChange={field.onChange}
                    />
                  </FormControl>
                </FormItem>
              )}
            />

            <div className="flex justify-end space-x-2">
              <Button 
                type="button" 
                variant="outline"
                onClick={() => onOpenChange(false)}
                disabled={isLoading}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isLoading}>
                {isLoading ? "Updating..." : "Update Abbreviation"}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}