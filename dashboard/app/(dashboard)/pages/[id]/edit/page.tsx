"use client"

import { useState, useEffect, use } from "react"
import { useRouter } from "next/navigation"
import { useQueryClient } from "@tanstack/react-query"
import { usePermissionContext } from "@/lib/permission-context"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { Save } from "lucide-react"
import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
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
import { LoadingState } from "@/components/ui/loading-state"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { backendRecordKeyPrefix } from "@/hooks/use-backend-record"
import { GenericPagesResponse } from "@/types/backend-types"

const editPageSchema = z.object({
  title: z.string().min(1, "Title is required").max(255, "Title is too long"),
  key: z.string()
    .min(1, "Key is required")
    .max(100, "Key is too long")
    .regex(/^[a-z0-9-_]+$/, "Key can only contain lowercase letters, numbers, hyphens, and underscores"),
  description: z.string().max(500, "Description is too long").optional(),
})

type FormData = z.infer<typeof editPageSchema>

export default function EditPagePage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter()
  const resolvedParams = use(params)
  const queryClient = useQueryClient()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [loading, setLoading] = useState(false)
  const [initialLoading, setInitialLoading] = useState(true)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/pages")
    }
  }, [permLoading, hasPermission, router])
  const [page, setPage] = useState<GenericPagesResponse | null>(null)

  const form = useForm<FormData>({
    resolver: zodResolver(editPageSchema),
    defaultValues: {
      title: "",
      key: "",
      description: "",
    },
  })

  // Load existing page data
  useEffect(() => {
    const loadPage = async () => {
      try {
        const pb = getBackendClient()
        const pageData = await pb.collection('generic_pages').getOne(resolvedParams.id) as GenericPagesResponse
        
        setPage(pageData)
        form.reset({
          title: pageData.title,
          key: pageData.key,
          description: pageData.description || "",
        })
      } catch (error) {
        console.error('Error loading page:', error)
        showToast.error("Load Failed", "Failed to load page data")
        router.push('/pages')
      } finally {
        setInitialLoading(false)
      }
    }
    
    loadPage()
  }, [resolvedParams.id, form, router])

  const onSubmit = async (data: FormData) => {
    if (!page) return
    
    setLoading(true)
    try {
      const pb = getBackendClient()
      await pb.collection('generic_pages').update(page.id, {
        title: data.title,
        key: data.key,
        description: data.description || "",
      })

      await queryClient.invalidateQueries({ queryKey: backendRecordKeyPrefix('generic_pages', page.id) })

      showToast.success("Page Updated", `Page "${data.title}" has been updated successfully`)
      router.push(`/pages/${page.id}`)
    } catch (error) {
      showToast.error("Update Failed", error instanceof Error ? error.message : "Failed to update page")
    } finally {
      setLoading(false)
    }
  }

  if (initialLoading) return <LoadingState message="Loading page..." />

  if (!page) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Page Not Found"
          description="The requested page does not exist"
          showBackButton={true}
          onBack={() => router.push('/pages')}
        />
        <Card>
          <CardContent className="text-center py-8">
            <p className="text-muted-foreground">
              The page you&apos;re looking for doesn&apos;t exist or has been deleted.
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Edit "${page.title}"`}
        description="Update page information and settings"
        showBackButton={true}
        onBack={() => router.push(`/pages/${page.id}`)}
        actions={[
          {
            label: loading ? "Updating..." : "Update Page",
            onClick: () => form.handleSubmit(onSubmit)(),
            disabled: loading,
            icon: <Save className="h-4 w-4" />
          }
        ]}
      />

      <Card>
        <CardHeader>
          <CardTitle>Page Information</CardTitle>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <FormField
                control={form.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Title</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="Enter page title"
                        {...field}
                        disabled={loading}
                      />
                    </FormControl>
                    <FormDescription>
                      The display title for this page
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="key"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Key</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="page-key"
                        {...field}
                        disabled={loading}
                      />
                    </FormControl>
                    <FormDescription>
                      Unique identifier for this page. Used in URLs and references. Only lowercase letters, numbers, hyphens, and underscores allowed.
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
                        placeholder="Enter page description (optional)"
                        {...field}
                        disabled={loading}
                        rows={3}
                      />
                    </FormControl>
                    <FormDescription>
                      Optional description to help identify this page&apos;s purpose
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex justify-end space-x-4">
                <button
                  type="button"
                  onClick={() => router.push(`/pages/${page.id}`)}
                  className="px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground"
                  disabled={loading}
                >
                  Cancel
                </button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}