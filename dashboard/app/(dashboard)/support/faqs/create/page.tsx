"use client"

import { useRouter } from "next/navigation"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { useCallback, useState } from "react"
import * as React from "react"
import { usePermissionContext } from "@/lib/permission-context"
import { z } from "zod"
import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
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
import { FaqTagSelector, SelectedTagsList } from "@/components/ui/faq-tag-selector"
import { FaqService } from "@/services/faq.service"
import { FaqTagsService } from "@/services/faq-tags.service"
import { showToast } from "@/lib/toast"
import type { FaqCreateData } from "@/types/faq"
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

export default function CreateFAQPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const [isSubmitting, setIsSubmitting] = useState(false)

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/support/faqs")
    }
  }, [loading, hasPermission, router])
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

  React.useEffect(() => {
    loadSelectedTagObjects()
  }, [loadSelectedTagObjects])

  const onSubmit = useCallback(async (data: FaqFormData) => {
    setIsSubmitting(true)
    
    try {
      const faqData: FaqCreateData = {
        question: data.question,
        answer: data.answer,
        status: (data.status || 'draft') as FaqsStatusOptions,
        priority: (data.priority || 'normal') as FaqsPriorityOptions,
        target_audience: (data.target_audience || 'all') as FaqsTargetAudienceOptions,
        keywords: data.keywords,
        is_featured: data.is_featured || false,
        sort_order: data.sort_order || 0,
        tags: selectedTags,
        // TODO: Set author to current user
        // author: currentUser?.id
      }

      const result = await FaqService.createFaq(faqData)
      
      if (result.success) {
        showToast.success("Success", result.message || "FAQ created successfully")
        router.push('/support/faqs')
      } else {
        showToast.error("Error", result.error || "Failed to create FAQ")
      }
    } catch (error: unknown) {
      console.error('Error creating FAQ:', error)
      showToast.error("Error", "Failed to create FAQ")
    } finally {
      setIsSubmitting(false)
    }
  }, [selectedTags, router])

  // Remove tag from selection
  const removeTag = useCallback((tagId: string) => {
    const newTags = selectedTags.filter(id => id !== tagId)
    handleTagsChange(newTags)
  }, [selectedTags, handleTagsChange])

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create FAQ"
        description="Add a new frequently asked question to the knowledge base"
        showBackButton={true}
        onBack={() => router.push('/support/faqs')}
        actions={[
          {
            label: isSubmitting ? "Creating..." : "Create FAQ",
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
                        <Select onValueChange={field.onChange} defaultValue={field.value}>
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
                        <Select onValueChange={field.onChange} defaultValue={field.value}>
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
                        <Select onValueChange={field.onChange} defaultValue={field.value}>
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