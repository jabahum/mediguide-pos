"use client"

import { use, useCallback, useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Skeleton } from "@/components/ui/skeleton"
import { Badge } from "@/components/ui/badge"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { LoadingState } from "@/components/ui/loading-state"
import { FaqTagsService } from "@/services/faq-tags.service"
import { showToast } from "@/lib/toast"
import type { FaqTagUpdateData } from "@/types/faq"
import type { FaqTagsResponse } from "@/types/backend-types"

// Available color options for tags
const TAG_COLOR_OPTIONS = [
  { value: "primary", label: "Primary", description: "Default blue theme color" },
  { value: "secondary", label: "Secondary", description: "Neutral gray color" },
  { value: "accent", label: "Accent", description: "Complementary theme color" },
  { value: "destructive", label: "Destructive", description: "Red warning color" },
  { value: "muted", label: "Muted", description: "Subtle gray color" },
  { value: "popover", label: "Popover", description: "Background variant" },
]

// Form validation schema
const tagFormSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters").max(50, "Name must be less than 50 characters"),
  description: z.string().max(200, "Description must be less than 200 characters").optional(),
  color: z.string().optional(),
  is_active: z.boolean().optional(),
})

type TagFormData = z.infer<typeof tagFormSchema>

interface EditTagPageProps {
  params: Promise<{ id: string }>
}

export default function EditTagPage({ params }: EditTagPageProps) {
  const { id } = use(params)
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/support/faqs/tags")
    }
  }, [permLoading, hasPermission, router])
  const [tag, setTag] = useState<FaqTagsResponse | null>(null)

  const form = useForm<TagFormData>({
    resolver: zodResolver(tagFormSchema),
    defaultValues: {
      name: "",
      description: "",
      color: "primary",
      is_active: true,
    }
  })

  // Load tag data
  const loadTag = useCallback(async () => {
    try {
      setIsLoading(true)
      const result = await FaqTagsService.getTag(id)
      
      if (result.success && result.data) {
        const tagData = result.data
        setTag(tagData)
        
        // Populate form with existing data
        form.reset({
          name: tagData.name,
          description: tagData.description || "",
          color: tagData.color || "primary",
          is_active: tagData.is_active ?? true,
        })
      } else {
        showToast.error("Error", result.error || "Tag not found")
        router.push('/support/faqs/tags')
      }
    } catch (error) {
      console.error('Error loading tag:', error)
      showToast.error("Error", "Failed to load tag")
      router.push('/support/faqs/tags')
    } finally {
      setIsLoading(false)
    }
  }, [id, form, router])

  // Load data on mount
  useEffect(() => {
    loadTag()
  }, [loadTag])

  // Auto-generate slug from name
  const generateSlug = useCallback((name: string) => {
    return name
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9\s-]/g, '') // Remove special chars
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/-+/g, '-') // Remove duplicate hyphens
      .replace(/^-|-$/g, '') // Remove leading/trailing hyphens
  }, [])


  const onSubmit = useCallback(async (data: TagFormData) => {
    setIsSubmitting(true)
    
    try {
      const updateData: FaqTagUpdateData = {
        name: data.name,
        slug: generateSlug(data.name),
        description: data.description,
        color: data.color,
        is_active: data.is_active,
      }

      const result = await FaqTagsService.updateTag(id, updateData)
      
      if (result.success) {
        showToast.success("Success", result.message || "Tag updated successfully")
        router.push('/support/faqs/tags')
      } else {
        showToast.error("Error", result.error || "Failed to update tag")
      }
    } catch (error: unknown) {
      console.error('Error updating tag:', error)
      showToast.error("Error", "Failed to update tag")
    } finally {
      setIsSubmitting(false)
    }
  }, [generateSlug, id, router])

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Skeleton className="h-8 w-8" />
          <div className="space-y-2">
            <Skeleton className="h-6 w-32" />
            <Skeleton className="h-4 w-48" />
          </div>
        </div>
        <LoadingState message="Loading tag..." />
      </div>
    )
  }

  if (!tag) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Tag Not Found"
          description="The requested tag could not be found"
          showBackButton={true}
          onBack={() => router.push('/support/faqs/tags')}
        />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit FAQ Tag"
        description={`Editing: ${tag.name}`}
        showBackButton={true}
        onBack={() => router.push('/support/faqs/tags')}
        actions={[
          {
            label: isSubmitting ? "Saving..." : "Save Changes",
            onClick: () => form.handleSubmit(onSubmit)(),
            disabled: isSubmitting
          }
        ]}
      />

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-3">
            {/* Main Content */}
            <div className="lg:col-span-2 space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Tag Information</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <FormField
                    control={form.control}
                    name="name"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Tag Name *</FormLabel>
                        <FormControl>
                          <Input 
                            placeholder="Enter tag name (e.g., 'Mobile App', 'Authentication')"
                            {...field} 
                          />
                        </FormControl>
                        <FormDescription>
                          The display name for this tag
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />


                  <FormField
                    control={form.control}
                    name="description"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Description</FormLabel>
                        <FormControl>
                          <Textarea 
                            placeholder="Optional description of what this tag represents"
                            rows={3}
                            {...field} 
                          />
                        </FormControl>
                        <FormDescription>
                          Optional description to help users understand this tag&apos;s purpose
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>
            </div>

            {/* Sidebar Settings */}
            <div className="space-y-6">
              {/* Current Tag Preview */}
              <Card>
                <CardHeader>
                  <CardTitle>Current Tag</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center gap-2">
                    <Badge
                      variant="outline"
                      style={{ 
                        borderColor: `hsl(var(--${tag.color || 'primary'}))`,
                        color: `hsl(var(--${tag.color || 'primary'}))`
                      }}
                    >
                      {tag.name}
                    </Badge>
                    {tag.usage_count !== undefined && (
                      <span className="text-sm text-muted-foreground">
                        Used by {tag.usage_count} FAQ{tag.usage_count !== 1 ? 's' : ''}
                      </span>
                    )}
                  </div>
                  {tag.description && (
                    <p className="text-sm text-muted-foreground mt-2">
                      {tag.description}
                    </p>
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Display Settings</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={form.control}
                    name="color"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Color Theme</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Select color theme" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {TAG_COLOR_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>
                                <div className="flex items-center gap-2">
                                  <div 
                                    className="w-3 h-3 rounded-full border"
                                    style={{ 
                                      backgroundColor: `hsl(var(--${option.value}))`,
                                      borderColor: `hsl(var(--${option.value}))`
                                    }}
                                  />
                                  <div>
                                    <div className="font-medium">{option.label}</div>
                                    <div className="text-xs text-muted-foreground">{option.description}</div>
                                  </div>
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormDescription>
                          Color theme for this tag in the UI
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="is_active"
                    render={({ field }) => (
                      <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                        <div className="space-y-0.5">
                          <FormLabel className="text-base">Active Tag</FormLabel>
                          <FormDescription className="text-sm">
                            Active tags are available for selection when creating/editing FAQs
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
                </CardContent>
              </Card>

            </div>
          </div>
        </form>
      </Form>
    </div>
  )
}