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
import { LoadingState } from "@/components/ui/loading-state"
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
import { DocumentationResponse, DocumentationStatusOptions } from "@/types/backend-types"
import { showToast } from "@/lib/toast"

const editDocumentationSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title must be less than 200 characters"),
  description: z.string().max(500, "Description must be less than 500 characters").optional(),
  content: z.string().min(1, "Content is required"),
  category: z.string().optional(),
  tags: z.string().optional(),
  status: z.nativeEnum(DocumentationStatusOptions),
})

type EditDocumentationFormData = z.infer<typeof editDocumentationSchema>

interface EditDocumentationPageProps {
  params: Promise<{
    id: string
  }>
}

export default function EditDocumentationPage({ params }: EditDocumentationPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/support/documentation")
    }
  }, [permLoading, hasPermission, router])
  const [documentationData, setDocumentationData] = useState<DocumentationResponse | null>(null)

  const form = useForm<EditDocumentationFormData>({
    resolver: zodResolver(editDocumentationSchema),
    defaultValues: {
      title: "",
      description: "",
      content: "",
      category: "",
      tags: "",
      status: DocumentationStatusOptions.draft,
    },
  })

  // Load documentation data
  useEffect(() => {
    async function loadDocumentation() {
      try {
        setIsLoading(true)
        const resolvedParams = await params
        const doc = await DocumentationService.getById(resolvedParams.id)
        
        if (!doc) {
          showToast.error("Not Found", "Documentation entry not found")
          router.push('/support/documentation')
          return
        }

        setDocumentationData(doc)
        
        // Update form with loaded data
        form.reset({
          title: doc.title || "",
          description: doc.description || "",
          content: doc.content || "",
          category: doc.category || "",
          tags: doc.tags || "",
          status: doc.status || DocumentationStatusOptions.draft,
        })
      } catch {
        showToast.error("Loading Failed", "Failed to load documentation entry")
        router.push('/support/documentation')
      } finally {
        setIsLoading(false)
      }
    }

    loadDocumentation()
  }, [params, form, router])

  const onSubmit = async (data: EditDocumentationFormData) => {
    setIsSubmitting(true)
    
    try {
      const resolvedParams = await params
      await DocumentationService.update(resolvedParams.id, {
        title: data.title,
        description: data.description || "",
        content: data.content,
        category: data.category || "",
        tags: data.tags || "",
        status: data.status,
      })

      showToast.success("Documentation Updated", "Documentation entry has been updated successfully")
      // Stay on edit page after successful update
    } catch (error) {
      showToast.error("Update Failed", error instanceof Error ? error.message : "Unknown error")
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
      const resolvedParams = await params
      await DocumentationService.update(resolvedParams.id, {
        ...data,
        status: DocumentationStatusOptions.published
      })

      showToast.success("Documentation Published", "Documentation entry has been updated and published")
      router.push(`/support/documentation/${resolvedParams.id}`)
    } catch (error) {
      showToast.error("Update Failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isLoading) {
    return <LoadingState message="Loading documentation..." />
  }

  if (!documentationData) {
    return null
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit Documentation"
        description={`Editing: ${documentationData.title}`}
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
                    Update the basic details for this documentation entry
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
                    Update the main documentation content using the rich text editor
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
                        <Select onValueChange={field.onChange} value={field.value}>
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
                  {isSubmitting ? "Updating..." : "Update Documentation"}
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

              {/* Metadata */}
              <Card>
                <CardHeader>
                  <CardTitle>Metadata</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 text-sm text-muted-foreground">
                  <div>
                    <span className="font-medium">Created:</span>{" "}
                    {new Date(documentationData.created).toLocaleDateString('en-US', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </div>
                  <div>
                    <span className="font-medium">Updated:</span>{" "}
                    {new Date(documentationData.updated).toLocaleDateString('en-US', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </form>
      </Form>
    </div>
  )
}