"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { TagCreateModal } from "./components/tag-create-modal"
import { TagEditModal } from "./components/tag-edit-modal"
import { TagViewModal } from "./components/tag-view-modal"
import { columns } from "./columns"
import { createTagRowActions, tagBulkActions } from "./tag-actions"
import { guidelineTagAvailableFields } from "./fields"
import type { GuidelineTagsResponse } from "@/types/backend-types"
import { useRouter } from "next/navigation"
import { guidelineTagService } from "@/services/guideline-content.service"
import { usePermissionContext } from "@/lib/permission-context"

export default function GuidelineTagsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const [createModalOpen, setCreateModalOpen] = React.useState(false)

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/guidelines")
    }
  }, [loading, hasPermission, router])
  const [editModalOpen, setEditModalOpen] = React.useState(false)
  const [viewModalOpen, setViewModalOpen] = React.useState(false)
  const [editingTag, setEditingTag] = React.useState<GuidelineTagsResponse | null>(null)
  const [viewingTag, setViewingTag] = React.useState<GuidelineTagsResponse | null>(null)

  const openEditModal = React.useCallback((tag: GuidelineTagsResponse) => {
    setEditingTag(tag)
    setEditModalOpen(true)
  }, [])

  // Create row actions with modal handlers
  const tagRowActions = React.useMemo(() =>
    createTagRowActions(
      (tag) => openEditModal(tag),
      (tag) => {
        setViewingTag(tag)
        setViewModalOpen(true)
      }
    ),
    [openEditModal]
  )

  // Handle successful operations
  const handleSuccess = React.useCallback(() => {
    // This will trigger a refetch of the data table
    // The EnhancedBackendDataTable handles this automatically
  }, [])

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Guideline Tags"
        description="Manage tags for organizing and categorizing clinical guidelines"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Tag",
            onClick: () => setCreateModalOpen(true),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Enhanced DataTable */}
      <EnhancedBackendDataTable<GuidelineTagsResponse>
        collectionName="guideline_tags"
		loadPage={guidelineTagService.listTable}
        columns={columns}
        searchable={true}
        searchFields={["name", "description"]}
        selectable={true}
        exportable={true}
        availableFields={guidelineTagAvailableFields}
        rowActions={tagRowActions}
        bulkActions={tagBulkActions}
        persistColumnConfig={true}
        tableContext="guideline-tags-management"
      />

      {/* Create Modal */}
      <TagCreateModal
        open={createModalOpen}
        onOpenChange={setCreateModalOpen}
        onSuccess={handleSuccess}
      />

      {/* Edit Modal */}
      <TagEditModal
        open={editModalOpen}
        onOpenChange={setEditModalOpen}
        tag={editingTag}
        onSuccess={handleSuccess}
      />

      {/* View Modal */}
      <TagViewModal
        open={viewModalOpen}
        onOpenChange={setViewModalOpen}
        tag={viewingTag}
        onEdit={openEditModal}
      />
    </div>
  )
}
