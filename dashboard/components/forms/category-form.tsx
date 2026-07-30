"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ColorPicker } from "@/components/ui/color-picker"
import { DrugCategoriesResponse } from "@/types/backend-types"

const categorySchema = z.object({
  name: z.string().min(1, "Name is required").max(100, "Name must be less than 100 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
  parent_category: z.string().optional(),
  color: z.string().optional(),
  icon: z.string().optional(),
  sort_order: z.number().int().min(0).optional(),
  status: z.enum(["active", "inactive"]),
})

type CategoryFormData = z.infer<typeof categorySchema>

interface CategoryFormProps {
  initialData?: Partial<DrugCategoriesResponse>
  parentCategories?: DrugCategoriesResponse[]
  onSubmit: (data: Omit<CategoryFormData, 'parent_category'> & { parent_category: string[], sort_order: number }) => Promise<void>
  onCancel: () => void
  loading?: boolean
  mode: "create" | "edit"
}

export function CategoryForm({
  initialData,
  parentCategories = [],
  onSubmit,
  onCancel,
  loading = false,
  mode
}: CategoryFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm<CategoryFormData>({
    resolver: zodResolver(categorySchema),
    defaultValues: {
      name: initialData?.name || "",
      description: initialData?.description || "",
      parent_category: (initialData?.parent_category && initialData.parent_category.length > 0)
        ? initialData.parent_category[0]
        : "__none__",
      color: initialData?.color || "",
      icon: initialData?.icon || "",
      sort_order: initialData?.sort_order || 0,
      status: initialData?.status || "active",
    }
  })

  const watchedColor = watch("color")

  const handleFormSubmit = async (data: CategoryFormData) => {
    try {
      // Convert parent_category string to array format expected by legacy collection API
      // Handle the special "__none__" value for no parent category
      const parentCategory = data.parent_category === "__none__" ? undefined : data.parent_category
      const formattedData = {
        ...data,
        parent_category: parentCategory ? [parentCategory] : [],
        sort_order: data.sort_order || 0,
      }
      await onSubmit(formattedData)
    } catch {
      // Error handling is done in the parent component
    }
  }

  // Filter out the current category from parent options to prevent self-reference
  const availableParentCategories = parentCategories.filter(
    cat => cat.id !== initialData?.id
  )

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Name *</Label>
        <Input
          id="name"
          {...register("name")}
          placeholder="Enter category name"
          disabled={loading}
        />
        {errors.name && (
          <p className="text-sm text-destructive">{errors.name.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="description">Description</Label>
        <Textarea
          id="description"
          {...register("description")}
          placeholder="Enter category description"
          rows={3}
          disabled={loading}
        />
        {errors.description && (
          <p className="text-sm text-destructive">{errors.description.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label>Parent Category</Label>
        <Select
          value={watch("parent_category")}
          onValueChange={(value) => setValue("parent_category", value)}
          disabled={loading}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Select parent category (optional)" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="__none__">No parent (Root category)</SelectItem>
            {availableParentCategories.map((category) => (
              <SelectItem key={category.id} value={category.id}>
                <div className="flex items-center space-x-2">
                  {category.color && (
                    <div
                      className="w-3 h-3 rounded-full border"
                      style={{ backgroundColor: category.color }}
                    />
                  )}
                  <span>{category.name}</span>
                </div>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label>Color</Label>
        <ColorPicker
          value={watchedColor}
          onChange={(color) => setValue("color", color)}
          disabled={loading}
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="icon">Icon (Optional)</Label>
        <Input
          id="icon"
          {...register("icon")}
          placeholder="Enter emoji or icon character"
          disabled={loading}
        />
        {errors.icon && (
          <p className="text-sm text-destructive">{errors.icon.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="sort_order">Sort Order</Label>
        <Input
          id="sort_order"
          type="number"
          {...register("sort_order", { valueAsNumber: true })}
          placeholder="0"
          disabled={loading}
        />
        {errors.sort_order && (
          <p className="text-sm text-destructive">{errors.sort_order.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label>Status</Label>
        <Select
          value={watch("status")}
          onValueChange={(value) => setValue("status", value as "active" | "inactive")}
          disabled={loading}
        >
          <SelectTrigger className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="inactive">Inactive</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex justify-end space-x-2 pt-4">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={loading}
        >
          Cancel
        </Button>
        <Button type="submit" disabled={loading}>
          {loading ? "Saving..." : mode === "create" ? "Create Category" : "Update Category"}
        </Button>
      </div>
    </form>
  )
}