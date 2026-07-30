"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Save, Eye } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { PageHeader } from "@/components/ui/page-header"
import { RichTextEditor } from "@/components/ui/rich-text-editor"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"

import { DocumentationService } from "@/services/documentation.service"
import { DocumentationStatusOptions } from "@/types/backend-types"
import { showToast } from "@/lib/toast"

const createDocumentationSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title must be less than 200 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
  content: z.string().min(1, "Content is required"),
  category: z.string().optional(),
  tags: z.string().optional(),
  status: z.nativeEnum(DocumentationStatusOptions),
})

type CreateDocumentationFormData = z.infer<typeof createDocumentationSchema>

export default function CreateDocumentationPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/support/documentation")
    }
  }, [loading, hasPermission, router])

  const form = useForm<CreateDocumentationFormData>({
    resolver: zodResolver(createDocumentationSchema),
    defaultValues: {
      title: "",
      description: "",
      content: "",
      category: "",
      tags: "",
      status: DocumentationStatusOptions.draft,
    },
  })

  const onSubmit = async (data: CreateDocumentationFormData) => {
    setIsSubmitting(true)
    
    try {
      const newDoc = await DocumentationService.create({
        title: data.title,
        description: data.description || "",
        content: data.content,
        category: data.category || "",
        tags: data.tags || "",
        status: data.status,
      })

      showToast.success("Documentation Created", "Documentation entry has been created successfully")
      router.push(`/support/documentation/${newDoc.id}/edit`)
    } catch (error) {
      showToast.error("Creation Failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleSaveAndView = async () => {
    const isValid = await form.trigger()
    if (!isValid) return

    const data = form.getValues()
    setIsSubmitting(true)
    
    try {
      const newDoc = await DocumentationService.create({
        ...data,
        status: DocumentationStatusOptions.published
      })

      showToast.success("Documentation Published", "Documentation entry has been created and published")
      router.push(`/support/documentation/${newDoc.id}`)
    } catch (error) {
      showToast.error("Creation Failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create Documentation"
        description="Add new documentation entry to the knowledge base"
        showBackButton={true}
        onBack={() => router.push('/support/documentation')}
        actions={[
          {
            label: "Save & View",
            onClick: handleSaveAndView,
            icon: <Eye className="h-4 w-4" />,
            variant: "outline",
            disabled: isSubmitting
          },
        ]}
      />

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Main Content */}
            <div className="lg:col-span-2 space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Basic Information</CardTitle>
                  <CardDescription>
                    Enter the basic details for this documentation entry
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={form.control}
                    name="title"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Title</FormLabel>
                        <FormControl>
                          <Input 
                            placeholder="Enter documentation title..." 
                            {...field} 
                          />
                        </FormControl>
                        <FormDescription>
                          Clear, descriptive title for the documentation entry
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
                        <FormLabel>Description (Optional)</FormLabel>
                        <FormControl>
                          <Textarea 
                            placeholder="Brief description of this documentation..."
                            className="resize-none"
                            rows={3}
                            {...field}
                          />
                        </FormControl>
                        <FormDescription>
                          Optional brief description that appears in listings
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Content</CardTitle>
                  <CardDescription>
                    Write the main documentation content using the rich text editor
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <FormField
                    control={form.control}
                    name="content"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Documentation Content</FormLabel>
                        <FormControl>
                          <div className="min-h-[400px]">
                            <RichTextEditor
                              value={field.value}
                              onChange={field.onChange}
                              placeholder="Enter the documentation content..."
                              height={400}
                              disabled={isSubmitting}
                            />
                          </div>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Publication</CardTitle>
                  <CardDescription>
                    Control the publication status of this documentation
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <FormField
                    control={form.control}
                    name="status"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Status</FormLabel>
                        <Select onValueChange={field.onChange} defaultValue={field.value}>
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select status" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            <SelectItem value="draft">Draft</SelectItem>
                            <SelectItem value="published">Published</SelectItem>
                            <SelectItem value="archived">Archived</SelectItem>
                          </SelectContent>
                        </Select>
                        <FormDescription>
                          Current publication status of the documentation
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Organization</CardTitle>
                  <CardDescription>
                    Categorize and tag this documentation entry
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={form.control}
                    name="category"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Category (Optional)</FormLabel>
                        <FormControl>
                          <Input 
                            placeholder="e.g., User Guide, API Reference"
                            {...field}
                          />
                        </FormControl>
                        <FormDescription>
                          Category to group related documentation
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
                          <Input 
                            placeholder="e.g., setup, troubleshooting, advanced"
                            {...field}
                          />
                        </FormControl>
                        <FormDescription>
                          Comma-separated tags for easier searching
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>

              <div className="flex flex-col gap-2">
                <Button 
                  type="submit" 
                  disabled={isSubmitting}
                  className="w-full"
                >
                  <Save className="h-4 w-4 mr-2" />
                  {isSubmitting ? "Creating..." : "Create Documentation"}
                </Button>
                
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => router.push('/support/documentation')}
                  disabled={isSubmitting}
                  className="w-full"
                >
                  Cancel
                </Button>
              </div>
            </div>
          </div>
        </form>
      </Form>
    </div>
  )
}