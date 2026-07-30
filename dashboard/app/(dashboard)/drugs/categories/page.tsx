"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus, FolderTree, Edit, Trash2, Eye } from "lucide-react"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"

// Dialogs
import { CategoryCreateDialog } from "@/components/dialogs/category-create-dialog"
import { CategoryEditDialog } from "@/components/dialogs/category-edit-dialog"
import { CategoryViewDialog } from "@/components/dialogs/category-view-dialog"

// Types
import { DrugCategoriesResponse } from "@/types/backend-types"
import { RowAction, BulkAction, FieldOption } from "@/types/data-table"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { getBackendClient } from "@/lib/backend-client"

// Page-specific imports
import { categoryColumns, CategoryWithRelations } from "../columns"
import { usePermissionContext } from "@/lib/permission-context"



// Row actions for categories
const createCategoryRowActions = (
  onView: (category: CategoryWithRelations) => void,
  onEdit: (category: CategoryWithRelations) => void,
  onDelete: (category: CategoryWithRelations) => void
): RowAction<CategoryWithRelations>[] => [
  {
    id: "view",
    label: "View Category",
    icon: Eye,
    onClick: async (category) => {
      onView(category)
    },
  },
  {
    id: "edit",
    label: "Edit Category",
    icon: Edit,
    onClick: async (category) => {
      onEdit(category)
    },
  },
  {
    id: "delete",
    label: "Delete Category",
    icon: Trash2,
    variant: "destructive",
    onClick: async (category) => {
      onDelete(category)
    },
    confirmMessage: `Are you sure you want to delete this category? This will remove the category from all associated drugs.`,
    separator: true,
  },
]

// Bulk actions for categories
const categoryBulkActions: BulkAction<CategoryWithRelations>[] = [
  {
    id: "bulk-activate",
    label: "Activate Categories",
    icon: FolderTree,
    onClick: async (categories) => {
      console.log("Activate categories:", categories.map(c => c.name))
    },
    disabled: (categories) => categories.every(cat => cat.status === 'active'),
    description: "Change status to active for selected categories",
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (categories) => {
      console.log("Delete categories:", categories.map(c => c.name))
    },
    description: "Permanently delete selected categories",
    confirmMessage: `Are you sure you want to delete the selected categories? This will remove them from all associated drugs.`,
    separator: true,
  },
]

// Available fields for filtering
const categoryAvailableFields: FieldOption[] = [
  { label: "Name", value: "name", type: "text" },
  { label: "Description", value: "description", type: "text" },
  { label: "Status", value: "status", type: "select" },
  { label: "Sort Order", value: "sort_order", type: "number" },
  { label: "Color", value: "color", type: "text" },
  { label: "Icon", value: "icon", type: "text" },
  { label: "Created", value: "created", type: "date" },
  { label: "Updated", value: "updated", type: "date" },
]

export default function DrugCategoriesPage() {
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
  const [selectedCategory, setSelectedCategory] = React.useState<CategoryWithRelations | null>(null)
  const [allCategories, setAllCategories] = React.useState<DrugCategoriesResponse[]>([])
  const [refreshTrigger, setRefreshTrigger] = React.useState(0)

  // Delete functionality
  const { deleteRecord } = useBackendCrud({
    collectionName: "drug_categories",
    onSuccess: () => setRefreshTrigger(prev => prev + 1)
  })

  // Load all categories for parent selection
  React.useEffect(() => {
    const fetchAllCategories = async () => {
      try {
        const backend = getBackendClient()
        const categories = await backend.resource("drug_categories").getFullList({
          sort: "name"
        })
        setAllCategories(categories as DrugCategoriesResponse[])
      } catch (error) {
        console.error("Failed to fetch categories:", error)
      }
    }
    fetchAllCategories()
  }, [refreshTrigger])

  // Dialog handlers
  const handleView = React.useCallback((category: CategoryWithRelations) => {
    setSelectedCategory(category)
    setViewDialogOpen(true)
  }, [])

  const handleEdit = React.useCallback((category: CategoryWithRelations) => {
    setSelectedCategory(category)
    setEditDialogOpen(true)
  }, [])

  const handleDelete = React.useCallback(async (category: CategoryWithRelations) => {
    await deleteRecord(category.id)
  }, [deleteRecord])

  const handleDialogSuccess = () => {
    setRefreshTrigger(prev => prev + 1)
  }

  // Create row actions with dialog handlers
  const categoryRowActions = React.useMemo(() => 
    createCategoryRowActions(handleView, handleEdit, handleDelete), 
    [handleView, handleEdit, handleDelete]
  )

  // Event handlers - removed unused handlers


  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Drug Categories"
        description="Manage hierarchical drug categories for organizing medications by therapeutic class, mechanism, or clinical use"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Category",
            onClick: () => setCreateDialogOpen(true),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<CategoryWithRelations>
        collection="drug_categories"
        columns={categoryColumns}
        searchFields={["name", "description"]}
        rowActions={categoryRowActions}
        bulkActions={categoryBulkActions}
        availableFields={categoryAvailableFields}
        query={{
          expand: "parent_category"
        }}
        ui={{
          exportable: true,
          importable: true
        }}
        key={refreshTrigger}
      />

      {/* Dialogs */}
      <CategoryCreateDialog
        open={createDialogOpen}
        onOpenChange={setCreateDialogOpen}
        parentCategories={allCategories}
        onSuccess={handleDialogSuccess}
      />

      {selectedCategory && (
        <>
          <CategoryEditDialog
            open={editDialogOpen}
            onOpenChange={setEditDialogOpen}
            category={selectedCategory}
            parentCategories={allCategories}
            onSuccess={handleDialogSuccess}
          />

          <CategoryViewDialog
            open={viewDialogOpen}
            onOpenChange={setViewDialogOpen}
            category={selectedCategory}
            parentCategory={selectedCategory.expand?.parent_category}
          />
        </>
      )}
    </div>
  )
}
