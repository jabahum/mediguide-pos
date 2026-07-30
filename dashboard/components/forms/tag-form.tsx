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
import { DrugTagsResponse } from "@/types/backend-types"

const tagSchema = z.object({
  name: z.string().min(1, "Name is required").max(100, "Name must be less than 100 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
  tag_category: z.enum(["clinical", "administrative", "regulatory", "safety"]),
  color: z.string().optional(),
  sort_order: z.number().int().min(0).optional(),
  status: z.enum(["active", "inactive"]),
})

type TagFormData = z.infer<typeof tagSchema>

interface TagFormProps {
  initialData?: Partial<DrugTagsResponse>
  onSubmit: (data: TagFormData) => Promise<void>
  onCancel: () => void
  loading?: boolean
  mode: "create" | "edit"
}

const tagCategoryOptions = [
  { value: "clinical", label: "Clinical", description: "Medical and therapeutic related tags" },
  { value: "administrative", label: "Administrative", description: "Management and operational tags" },
  { value: "regulatory", label: "Regulatory", description: "Legal and compliance related tags" },
  { value: "safety", label: "Safety", description: "Safety and risk related tags" },
]

export function TagForm({
  initialData,
  onSubmit,
  onCancel,
  loading = false,
  mode
}: TagFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm<TagFormData>({
    resolver: zodResolver(tagSchema),
    defaultValues: {
      name: initialData?.name || "",
      description: initialData?.description || "",
      tag_category: initialData?.tag_category || "clinical",
      color: initialData?.color || "",
      sort_order: initialData?.sort_order || 0,
      status: initialData?.status || "active",
    }
  })

  const watchedColor = watch("color")
  const watchedTagCategory = watch("tag_category")

  const handleFormSubmit = async (data: TagFormData) => {
    try {
      const formattedData = {
        ...data,
        sort_order: data.sort_order || 0,
      }
      await onSubmit(formattedData)
    } catch {
      // Error handling is done in the parent component
    }
  }

  // const selectedCategory = tagCategoryOptions.find(option => option.value === watchedTagCategory)

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Name *</Label>
        <Input
          id="name"
          {...register("name")}
          placeholder="Enter tag name"
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
          placeholder="Enter tag description"
          rows={3}
          disabled={loading}
        />
        {errors.description && (
          <p className="text-sm text-destructive">{errors.description.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label>Tag Category *</Label>
        <Select
          value={watchedTagCategory}
          onValueChange={(value) => setValue("tag_category", value as "clinical" | "administrative" | "regulatory" | "safety")}
          disabled={loading}
        >
          <SelectTrigger className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {tagCategoryOptions.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {errors.tag_category && (
          <p className="text-sm text-destructive">{errors.tag_category.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label>Color</Label>
        <ColorPicker
          value={watchedColor}
          onChange={(color) => setValue("color", color)}
          disabled={loading}
        />
        <p className="text-xs text-muted-foreground">
          This color will be used to display the tag in the interface
        </p>
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
        <p className="text-xs text-muted-foreground">
          Lower numbers appear first in lists
        </p>
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

      {/* Tag Preview */}
      {(watch("name") || watchedColor) && (
        <div className="space-y-2">
          <Label>Preview</Label>
          <div className="flex items-center space-x-2">
            <div
              className="px-2 py-1 rounded text-xs font-medium border"
              style={{
                backgroundColor: watchedColor ? `${watchedColor}20` : undefined,
                borderColor: watchedColor || "var(--border)",
                color: watchedColor || "var(--foreground)"
              }}
            >
              {watch("name") || "Tag Name"}
            </div>
          </div>
        </div>
      )}

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
          {loading ? "Saving..." : mode === "create" ? "Create Tag" : "Update Tag"}
        </Button>
      </div>
    </form>
  )
}