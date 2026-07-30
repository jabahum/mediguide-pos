"use client"

import * as React from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import { Button } from "@/components/ui/button"
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { GuidelineCategorySelector } from "@/components/ui/guideline-category-selector"
// import { useGuidelineCategories } from "@/hooks/use-guideline-categories"
// import type { GuidelineCategoriesResponse } from "@/types/backend-types"

const categoryFormSchema = z.object({
  name: z.string().min(1, "Name is required").max(100, "Name must be less than 100 characters"),
  slug: z.string().max(100, "Slug must be less than 100 characters").optional(),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
  parent_category: z.string().optional(),
  sort_order: z.number().min(0, "Sort order must be 0 or greater").optional(),
  status: z.enum(["active", "inactive"]),
  color: z.string().optional(),
  icon: z.string().max(50, "Icon must be less than 50 characters").optional(),
})

export type GuidelineCategoryFormData = z.infer<typeof categoryFormSchema>

interface GuidelineCategoryFormProps {
  mode: "create" | "edit"
  defaultValues?: Partial<GuidelineCategoryFormData>
  onSubmit: (data: GuidelineCategoryFormData) => Promise<void>
  onCancel: () => void
  loading?: boolean
  editingCategoryId?: string
}

export function GuidelineCategoryForm({
  mode,
  defaultValues,
  onSubmit,
  onCancel,
  loading = false,
  editingCategoryId
}: GuidelineCategoryFormProps) {
  const form = useForm<GuidelineCategoryFormData>({
    resolver: zodResolver(categoryFormSchema),
    defaultValues: {
      name: "",
      slug: "",
      description: "",
      parent_category: "",
      sort_order: 0,
      status: "active",
      color: "",
      icon: "",
      ...defaultValues,
    },
  })

  // Auto-generate slug from name
  const watchedName = form.watch("name")
  React.useEffect(() => {
    if (watchedName) {
      const slug = watchedName
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9\s]+/g, "") // Remove special characters except spaces
        .replace(/\s+/g, "-") // Replace spaces with hyphens
        .replace(/-+/g, "-") // Replace multiple hyphens with single hyphen
        .replace(/(^-|-$)/g, "") // Remove leading/trailing hyphens
      form.setValue("slug", slug)
    }
  }, [watchedName, form])

  const handleSubmit = async (data: GuidelineCategoryFormData) => {
    try {
      // Remove empty strings and convert to proper types
      const cleanedData = {
        ...data,
        slug: data.slug?.trim() || undefined,
        description: data.description?.trim() || undefined,
        parent_category: data.parent_category?.trim() || undefined,
        color: data.color?.trim() || undefined,
        icon: data.icon?.trim() || undefined,
        sort_order: data.sort_order || 0,
      }

      await onSubmit(cleanedData)
    } catch (error) {
      console.error("Form submission error:", error)
    }
  }

  const commonColors = [
    { name: "Blue", value: "#3B82F6" },
    { name: "Green", value: "#10B981" },
    { name: "Red", value: "#EF4444" },
    { name: "Yellow", value: "#F59E0B" },
    { name: "Purple", value: "#8B5CF6" },
    { name: "Pink", value: "#EC4899" },
    { name: "Indigo", value: "#6366F1" },
    { name: "Gray", value: "#6B7280" },
  ]

  const commonIcons = [
    "📋", "📝", "🏥", "💊", "🩺", "🔬", "🧬", "⚕️", 
    "🫀", "🧠", "👁️", "🦷", "🦴", "🩸", "💉", "🧪"
  ]

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Name *</FormLabel>
                <FormControl>
                  <Input 
                    placeholder="Category name"
                    {...field} 
                  />
                </FormControl>
                <FormDescription>
                  A descriptive name for the category
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="parent_category"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Parent Category</FormLabel>
                <FormControl>
                  <GuidelineCategorySelector
                    value={field.value}
                    onValueChange={field.onChange}
                    placeholder="Select parent category (optional)"
                    allowEmpty={true}
                    excludeIds={editingCategoryId ? [editingCategoryId] : []}
                    showPath={true}
                  />
                </FormControl>
                <FormDescription>
                  Choose a parent category to create a hierarchy
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
              <FormLabel>Description</FormLabel>
              <FormControl>
                <Textarea 
                  placeholder="Brief description of the category"
                  className="min-h-[100px]"
                  {...field} 
                />
              </FormControl>
              <FormDescription>
                Optional description to explain the category&apos;s purpose
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <FormField
            control={form.control}
            name="status"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Status *</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="inactive">Inactive</SelectItem>
                  </SelectContent>
                </Select>
                <FormDescription>
                  Active categories are visible to users
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="sort_order"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Sort Order</FormLabel>
                <FormControl>
                  <Input 
                    type="number"
                    min="0"
                    placeholder="0"
                    {...field}
                    onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : 0)}
                  />
                </FormControl>
                <FormDescription>
                  Lower numbers appear first (0 = first)
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <FormField
            control={form.control}
            name="color"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Color</FormLabel>
                <FormControl>
                  <div className="space-y-3">
                    <div className="flex flex-wrap gap-2">
                      {commonColors.map((color) => (
                        <button
                          key={color.value}
                          type="button"
                          className={`w-10 h-10 rounded border-2 transition-all duration-200 ${
                            field.value === color.value 
                              ? 'border-primary border-4 scale-110' 
                              : 'border-border hover:border-primary hover:scale-105'
                          }`}
                          style={{ backgroundColor: color.value }}
                          onClick={() => field.onChange(color.value)}
                          title={color.name}
                        />
                      ))}
                    </div>
                    {field.value && (
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <div
                          className="w-4 h-4 rounded border"
                          style={{ backgroundColor: field.value }}
                        />
                        Selected: {field.value}
                      </div>
                    )}
                  </div>
                </FormControl>
                <FormDescription>
                  Choose a color for visual identification
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="icon"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Icon</FormLabel>
                <FormControl>
                  <div className="flex flex-wrap gap-2">
                    {commonIcons.map((icon) => (
                      <button
                        key={icon}
                        type="button"
                        className={`w-10 h-10 rounded border transition-colors flex items-center justify-center text-lg ${
                          field.value === icon 
                            ? 'border-primary border-2 bg-primary/10' 
                            : 'border-border hover:border-primary hover:bg-accent'
                        }`}
                        onClick={() => field.onChange(icon)}
                        title={`Select ${icon}`}
                      >
                        {icon}
                      </button>
                    ))}
                  </div>
                </FormControl>
                <FormDescription>
                  Choose an icon for visual representation
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <div className="flex justify-end space-x-4 pt-4 border-t">
          <Button 
            type="button" 
            variant="outline" 
            onClick={onCancel}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button 
            type="submit" 
            disabled={loading}
          >
            {loading ? "Saving..." : mode === "create" ? "Create Category" : "Update Category"}
          </Button>
        </div>
      </form>
    </Form>
  )
}