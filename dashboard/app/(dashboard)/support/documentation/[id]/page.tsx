"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { Eye, Edit, Calendar, Tag, FolderOpen, MoreVertical } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { PageHeader } from "@/components/ui/page-header"
import { LoadingState } from "@/components/ui/loading-state"
import { RichContent } from "@/components/ui/rich-content"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

import { DocumentationService } from "@/services/documentation.service"
import { DocumentationResponse, DocumentationStatusOptions } from "@/types/backend-types"
import { showToast } from "@/lib/toast"
import { ConfirmDialog } from "@/components/dialogs/confirm-dialog"

interface ViewDocumentationPageProps {
  params: Promise<{
    id: string
  }>
}

export default function ViewDocumentationPage({ params }: ViewDocumentationPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/support/documentation")
    }
  }, [permLoading, hasPermission, router])
  const [documentationData, setDocumentationData] = useState<DocumentationResponse | null>(null)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

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
      } catch {
        showToast.error("Loading Failed", "Failed to load documentation entry")
        router.push('/support/documentation')
      } finally {
        setIsLoading(false)
      }
    }

    loadDocumentation()
  }, [params, router])

  const handleStatusChange = async () => {
    if (!documentationData) return

    try {
      let newStatus: DocumentationStatusOptions
      
      switch (documentationData.status) {
        case DocumentationStatusOptions.draft:
          newStatus = DocumentationStatusOptions.published
          break
        case DocumentationStatusOptions.published:
          newStatus = DocumentationStatusOptions.archived
          break
        case DocumentationStatusOptions.archived:
          newStatus = DocumentationStatusOptions.draft
          break
        default:
          newStatus = DocumentationStatusOptions.published
      }

      await DocumentationService.update(documentationData.id, { status: newStatus })
      setDocumentationData({ ...documentationData, status: newStatus })
      showToast.success("Status Updated", `Documentation status changed to ${newStatus}`)
    } catch (error) {
      showToast.error("Status Update Failed", error instanceof Error ? error.message : "Unknown error")
    }
  }

  const handleDelete = async () => {
    if (!documentationData) return

    try {
      await DocumentationService.delete(documentationData.id)
      showToast.success("Documentation Deleted", "Documentation entry has been deleted")
      setShowDeleteConfirm(false)
      router.push('/support/documentation')
    } catch (error) {
      showToast.error("Delete Failed", error instanceof Error ? error.message : "Unknown error")
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case DocumentationStatusOptions.published:
        return "bg-green-500/10 text-green-700 border-green-500/20"
      case DocumentationStatusOptions.draft:
        return "bg-yellow-500/10 text-yellow-700 border-yellow-500/20"
      case DocumentationStatusOptions.archived:
        return "bg-gray-500/10 text-gray-700 border-gray-500/20"
      default:
        return "bg-gray-500/10 text-gray-700 border-gray-500/20"
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
        title={documentationData.title}
        description="Documentation Details"
        showBackButton={true}
        onBack={() => router.push('/support/documentation')}
        actions={[
          {
            label: "Edit",
            onClick: () => router.push(`/support/documentation/${documentationData.id}/edit`),
            icon: <Edit className="h-4 w-4" />,
            variant: "outline"
          },
        ]}
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-3">
          <Card>
            <CardHeader className="space-y-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <CardTitle className="text-2xl font-bold">
                    {documentationData.title}
                  </CardTitle>
                  {documentationData.description && (
                    <p className="text-muted-foreground">
                      {documentationData.description}
                    </p>
                  )}
                </div>
                
                {/* Actions Dropdown */}
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem 
                      onClick={() => router.push(`/support/documentation/${documentationData.id}/edit`)}
                    >
                      <Edit className="mr-2 h-4 w-4" />
                      Edit Documentation
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={handleStatusChange}>
                      <Eye className="mr-2 h-4 w-4" />
                      Change Status
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      onClick={() => setShowDeleteConfirm(true)}
                      className="text-destructive focus:text-destructive"
                    >
                      Delete Documentation
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>

              {/* Metadata */}
              <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                <div className="flex items-center gap-1">
                  <Calendar className="h-4 w-4" />
                  <span>Updated {new Date(documentationData.updated).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long', 
                    day: 'numeric'
                  })}</span>
                </div>
                {documentationData.category && (
                  <div className="flex items-center gap-1">
                    <FolderOpen className="h-4 w-4" />
                    <span>{documentationData.category}</span>
                  </div>
                )}
              </div>

              <Separator />
            </CardHeader>
            
            <CardContent>
              <RichContent html={documentationData.content} />
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Status */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Status</CardTitle>
            </CardHeader>
            <CardContent>
              <Badge 
                variant="secondary" 
                className={`capitalize ${getStatusColor(documentationData.status || 'draft')}`}
              >
                {documentationData.status || 'draft'}
              </Badge>
            </CardContent>
          </Card>

          {/* Tags */}
          {documentationData.tags && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <Tag className="h-4 w-4" />
                  Tags
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {documentationData.tags.split(',').map((tag, index) => (
                    <Badge key={index} variant="outline" className="text-xs">
                      {tag.trim()}
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Metadata */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div>
                <span className="font-medium">Created:</span>
                <div className="text-muted-foreground">
                  {new Date(documentationData.created).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
              </div>
              <div>
                <span className="font-medium">Last Updated:</span>
                <div className="text-muted-foreground">
                  {new Date(documentationData.updated).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
              </div>
              {documentationData.category && (
                <div>
                  <span className="font-medium">Category:</span>
                  <div className="text-muted-foreground">
                    {documentationData.category}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button 
                variant="outline" 
                size="sm" 
                className="w-full justify-start"
                onClick={() => router.push(`/support/documentation/${documentationData.id}/edit`)}
              >
                <Edit className="mr-2 h-4 w-4" />
                Edit Documentation
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                className="w-full justify-start"
                onClick={handleStatusChange}
              >
                <Eye className="mr-2 h-4 w-4" />
                Change Status
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Confirm Delete Dialog */}
      <ConfirmDialog
        open={showDeleteConfirm}
        onOpenChange={setShowDeleteConfirm}
        title="Delete Documentation"
        description="Are you sure you want to delete this documentation entry? This action cannot be undone."
        confirmText="Delete"
        cancelText="Cancel"
        variant="destructive"
        onConfirm={handleDelete}
      />
    </div>
  )
}
