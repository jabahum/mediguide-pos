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
import { Label } from "@/components/ui/label"
import { Skeleton } from "@/components/ui/skeleton"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { RichTextEditor } from "@/components/ui/rich-text-editor"
import { LoadingState } from "@/components/ui/loading-state"
import { FaqTagSelector, SelectedTagsList } from "@/components/ui/faq-tag-selector"
import { FaqService } from "@/services/faq.service"
import { FaqTagsService } from "@/services/faq-tags.service"
import { showToast } from "@/lib/toast"
import type { FaqUpdateData } from "@/types/faq"
import type { FaqsWithExpanded } from "@/types/expanded"
import type { FaqTagsResponse, FaqsStatusOptions, FaqsPriorityOptions, FaqsTargetAudienceOptions } from "@/types/backend-types"
import { FAQ_STATUS_OPTIONS, FAQ_PRIORITY_OPTIONS, TARGET_AUDIENCE_OPTIONS } from "@/types/faq"

// Form validation schema
const faqFormSchema = z.object({
  question: z.string().min(10, "Question must be at least 10 characters"),
  answer: z.string().min(50, "Answer must be at least 50 characters"),
  tags: z.array(z.string()).optional(),
  status: z.enum(['draft', 'review', 'published', 'archived']).optional(),
  priority: z.enum(['low', 'normal', 'high', 'critical']).optional(),
  target_audience: z.enum(['all', 'admin', 'health_worker', 'patient']).optional(),
  keywords: z.string().optional(),
  is_featured: z.boolean().optional(),
  sort_order: z.number().optional(),
})

type FaqFormData = z.infer<typeof faqFormSchema>

interface EditFAQPageProps {
  params: Promise<{ id: string }>
}

export default function EditFAQPage({ params }: EditFAQPageProps) {
  const { id } = use(params)
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/support/faqs")
    }
  }, [permLoading, hasPermission, router])
  const [faq, setFaq] = useState<FaqsWithExpanded | null>(null)
  const [selectedTags, setSelectedTags] = useState<string[]>([])
  const [selectedTagObjects, setSelectedTagObjects] = useState<FaqTagsResponse[]>([])

  const form = useForm<FaqFormData>({
    resolver: zodResolver(faqFormSchema),
    defaultValues: {
      question: "",
      answer: "",
      tags: [],
      status: "draft",
      priority: "normal", 
      target_audience: "all",
      keywords: "",
      is_featured: false,
      sort_order: 0,
    }
  })

  // Load FAQ data
  const loadFaq = useCallback(async () => {
    try {
      setIsLoading(true)
      const result = await FaqService.getFaqWithRelations(id)
      
      if (result.success && result.data) {
        const faqData = result.data
        setFaq(faqData)
        
        // Populate form with existing data
        form.reset({
          question: faqData.question,
          answer: faqData.answer,
          tags: faqData.tags || [],
          status: faqData.status || 'draft',
          priority: faqData.priority || 'normal',
          target_audience: faqData.target_audience || 'all',
          keywords: faqData.keywords || '',
          is_featured: faqData.is_featured || false,
          sort_order: faqData.sort_order || 0,
        })
        
        setSelectedTags(faqData.tags || [])
      } else {
        showToast.error("Error", result.error || "FAQ not found")
        router.push('/support/faqs')
      }
    } catch (error) {
      console.error('Error loading FAQ:', error)
      showToast.error("Error", "Failed to load FAQ")
      router.push('/support/faqs')
    } finally {
      setIsLoading(false)
    }
  }, [id, form, router])

  // Load data on mount
  useEffect(() => {
    loadFaq()
  }, [loadFaq])

  // Handle tag selection changes
  const handleTagsChange = useCallback((newTags: string[]) => {
    setSelectedTags(newTags)
    form.setValue('tags', newTags)
  }, [form])

  // Load selected tag objects for display
  const loadSelectedTagObjects = useCallback(async () => {
    if (selectedTags.length === 0) {
      setSelectedTagObjects([])
      return
    }

    try {
      const result = await FaqTagsService.getTagsByIds(selectedTags)
      if (result.success && result.data) {
        setSelectedTagObjects(result.data as FaqTagsResponse[])
      }
    } catch (error) {
      console.error('Error loading selected tags:', error)
    }
  }, [selectedTags])

  useEffect(() => {
    loadSelectedTagObjects()
  }, [loadSelectedTagObjects])

  // Remove tag from selection
  const removeTag = useCallback((tagId: string) => {
    const newTags = selectedTags.filter(id => id !== tagId)
    handleTagsChange(newTags)
  }, [selectedTags, handleTagsChange])

  const onSubmit = useCallback(async (data: FaqFormData) => {
    setIsSubmitting(true)
    
    try {
      const updateData: FaqUpdateData = {
        question: data.question,
        answer: data.answer,
        status: data.status as FaqsStatusOptions,
        priority: data.priority as FaqsPriorityOptions,
        target_audience: data.target_audience as FaqsTargetAudienceOptions,
        keywords: data.keywords,
        is_featured: data.is_featured,
        sort_order: data.sort_order,
        tags: selectedTags,
      }

      const result = await FaqService.updateFaq(id, updateData)
      
      if (result.success) {
        showToast.success("Success", result.message || "FAQ updated successfully")
        router.push('/support/faqs')
      } else {
        showToast.error("Error", result.error || "Failed to update FAQ")
      }
    } catch (error: unknown) {
      console.error('Error updating FAQ:', error)
      showToast.error("Error", "Failed to update FAQ")
    } finally {
      setIsSubmitting(false)
    }
  }, [selectedTags, id, router])

  // Selected tag objects are loaded via useEffect

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
        <LoadingState message="Loading FAQ..." />
      </div>
    )
  }

  if (!faq) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="FAQ Not Found"
          description="The requested FAQ could not be found"
          showBackButton={true}
          onBack={() => router.push('/support/faqs')}
        />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit FAQ"
        description={`Editing: ${faq.question.slice(0, 80)}${faq.question.length > 80 ? '...' : ''}`}
        showBackButton={true}
        onBack={() => router.push('/support/faqs')}
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
                  <CardTitle>FAQ Content</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <FormField
                    control={form.control}
                    name="question"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Question *</FormLabel>
                        <FormControl>
                          <Input 
                            placeholder="What is the question users are asking?"
                            {...field} 
                          />
                        </FormControl>
                        <FormDescription>
                          Enter the question that users frequently ask
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="answer"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Answer *</FormLabel>
                        <FormControl>
                          <RichTextEditor
                            value={field.value}
                            onChange={field.onChange}
                            placeholder="Provide a comprehensive answer..."
                          />
                        </FormControl>
                        <FormDescription>
                          Write a detailed, helpful answer using the rich text editor
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="keywords"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Keywords</FormLabel>
                        <FormControl>
                          <Textarea 
                            placeholder="Additional search keywords (comma-separated)"
                            rows={2}
                            {...field} 
                          />
                        </FormControl>
                        <FormDescription>
                          Add extra keywords to help users find this FAQ
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
              <Card>
                <CardHeader>
                  <CardTitle>Settings</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={form.control}
                    name="status"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Status</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Select status" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {FAQ_STATUS_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>
                                {option.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="priority"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Priority</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Select priority" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {FAQ_PRIORITY_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>
                                {option.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="target_audience"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Target Audience</FormLabel>
                        <Select onValueChange={field.onChange} value={field.value}>
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Select audience" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {TARGET_AUDIENCE_OPTIONS.map((option) => (
                              <SelectItem key={option.value} value={option.value}>
                                {option.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="is_featured"
                    render={({ field }) => (
                      <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                        <div className="space-y-0.5">
                          <FormLabel className="text-base">Featured FAQ</FormLabel>
                          <FormDescription className="text-sm">
                            Mark this FAQ as featured for prominence
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

              <Card>
                <CardHeader>
                  <CardTitle>Tags</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label>Select Tags</Label>
                    <FaqTagSelector
                      value={selectedTags}
                      onValueChange={handleTagsChange}
                      placeholder="Search and select tags..."
                      searchPlaceholder="Search tags..."
                      maxSelection={10}
                      showSelectedInTrigger={false}
                      className="w-full"
                    />
                  </div>

                  {selectedTagObjects.length > 0 && (
                    <div>
                      <Label>Selected Tags ({selectedTagObjects.length})</Label>
                      <div className="mt-2">
                        <SelectedTagsList
                          tags={selectedTagObjects}
                          onRemoveTag={removeTag}
                        />
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>

            </div>
          </div>
        </form>
      </Form>
    </div>
  )
}