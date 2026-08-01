"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus, Tags, Edit, Trash2, Eye } from "lucide-react"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"

// Dialogs
import { TagCreateDialog } from "@/components/dialogs/tag-create-dialog"
import { TagEditDialog } from "@/components/dialogs/tag-edit-dialog"
import { TagViewDialog } from "@/components/dialogs/tag-view-dialog"

// Types
import { DrugTagsResponse } from "@/types/backend-types"
import { RowAction, BulkAction, FieldOption } from "@/types/data-table"
import { useDomainCrud } from "@/hooks/use-domain-crud"
import { drugReferenceService, drugTagCrud } from "@/services/drug.service"

// Page-specific imports
import { tagColumns } from "../columns"
import { usePermissionContext } from "@/lib/permission-context"


// Row actions for tags
const createTagRowActions = (
  onView: (tag: DrugTagsResponse) => void,
  onEdit: (tag: DrugTagsResponse) => void,
  onDelete: (tag: DrugTagsResponse) => void
): RowAction<DrugTagsResponse>[] => [
  {
    id: "view",
    label: "View Tag",
    icon: Eye,
    onClick: async (tag) => {
      onView(tag)
    },
  },
  {
    id: "edit",
    label: "Edit Tag",
    icon: Edit,
    onClick: async (tag) => {
      onEdit(tag)
    },
  },
  {
    id: "delete",
    label: "Delete Tag",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tag) => {
      onDelete(tag)
    },
    confirmMessage: `Are you sure you want to delete this tag? This will remove the tag from all associated drugs.`,
    separator: true,
  },
]

// Bulk actions for tags
const tagBulkActions: BulkAction<DrugTagsResponse>[] = [
  {
    id: "bulk-activate",
    label: "Activate Tags",
    icon: Tags,
    onClick: async (tags) => {
      console.log("Activate tags:", tags.map(t => t.name))
    },
    disabled: (tags) => tags.every(tag => tag.status === 'active'),
    description: "Change status to active for selected tags",
  },
  {
    id: "bulk-clinical",
    label: "Set as Clinical",
    icon: Tags,
    variant: "outline",
    onClick: async (tags) => {
      console.log("Set as clinical:", tags.map(t => t.name))
    },
    disabled: (tags) => tags.every(tag => tag.tag_category === 'clinical'),
    description: "Change category to clinical for selected tags",
  },
  {
    id: "bulk-safety",
    label: "Set as Safety",
    icon: Tags,
    variant: "outline",
    onClick: async (tags) => {
      console.log("Set as safety:", tags.map(t => t.name))
    },
    disabled: (tags) => tags.every(tag => tag.tag_category === 'safety'),
    description: "Change category to safety for selected tags",
    separator: true,
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tags) => {
      console.log("Delete tags:", tags.map(t => t.name))
    },
    description: "Permanently delete selected tags",
    confirmMessage: `Are you sure you want to delete the selected tags? This will remove them from all associated drugs.`,
    separator: true,
  },
]

// Available fields for filtering
const tagAvailableFields: FieldOption[] = [
  { label: "Name", value: "name", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Tag Category", value: "tag_category", type: "select" },
  { label: "Status", value: "status", type: "select" },
  { label: "Sort Order", value: "sort_order", type: "number" },
  { label: "Color", value: "color", type: "text" },
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]

export default function DrugTagsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/drugs")
    }
  }, [loading, hasPermission, router])

  // Dialog state
  const [createDialogOpen, setCreateDialogOpen] = React.useState(false)
  const [editDialogOpen, setEditDialogOpen] = React.useState(false)
  const [viewDialogOpen, setViewDialogOpen] = React.useState(false)
  const [selectedTag, setSelectedTag] = React.useState<DrugTagsResponse | null>(null)
  const [refreshTrigger, setRefreshTrigger] = React.useState(0)

  // Delete functionality
  const { deleteRecord } = useDomainCrud("drug_tags", drugTagCrud, () => setRefreshTrigger(prev => prev + 1))

  // Dialog handlers
  const handleView = React.useCallback((tag: DrugTagsResponse) => {
    setSelectedTag(tag)
    setViewDialogOpen(true)
  }, [])

  const handleEdit = React.useCallback((tag: DrugTagsResponse) => {
    setSelectedTag(tag)
    setEditDialogOpen(true)
  }, [])

  const handleDelete = React.useCallback(async (tag: DrugTagsResponse) => {
    await deleteRecord(tag.id)
  }, [deleteRecord])

  const handleDialogSuccess = () => {
    setRefreshTrigger(prev => prev + 1)
  }

  // Create row actions with dialog handlers
  const tagRowActions = React.useMemo(() => 
    createTagRowActions(handleView, handleEdit, handleDelete), 
    [handleView, handleEdit, handleDelete]
  )

  // Event handlers
  // Removed unused handlers

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Drug Tags"
        description="Manage flexible tagging system for drugs including clinical, administrative, regulatory, and safety tags"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Tag",
            onClick: () => setCreateDialogOpen(true),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<DrugTagsResponse>
        collection="drug_tags"
        loadPage={drugReferenceService.listTagsTable}
        columns={tagColumns}
        searchFields={["name", "description"]}
        rowActions={tagRowActions}
        bulkActions={tagBulkActions}
        availableFields={tagAvailableFields}
        ui={{
          exportable: true,
          importable: true
        }}
        key={refreshTrigger}
      />

      {/* Dialogs */}
      <TagCreateDialog
        open={createDialogOpen}
        onOpenChange={setCreateDialogOpen}
        onSuccess={handleDialogSuccess}
      />

      {selectedTag && (
        <>
          <TagEditDialog
            open={editDialogOpen}
            onOpenChange={setEditDialogOpen}
            tag={selectedTag}
            onSuccess={handleDialogSuccess}
          />

          <TagViewDialog
            open={viewDialogOpen}
            onOpenChange={setViewDialogOpen}
            tag={selectedTag}
          />
        </>
      )}
    </div>
  )
}
