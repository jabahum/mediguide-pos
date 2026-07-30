"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { CategoryCreateModal } from "./components/category-create-modal"
import { CategoryEditModal } from "./components/category-edit-modal"
import { CategoryViewModal } from "./components/category-view-modal"
import { columns } from "./columns"
import { createCategoryRowActions, categoryBulkActions } from "./category-actions"
import { guidelineCategoryAvailableFields } from "./fields"
import type { GuidelineCategoriesWithParent } from "@/types/expanded"
import { usePermissionContext } from "@/lib/permission-context"
import { useRouter } from "next/navigation"

export default function GuidelineCategoriesPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/guidelines")
    }
  }, [loading, hasPermission, router])
  const [createModalOpen, setCreateModalOpen] = React.useState(false)
  const [editModalOpen, setEditModalOpen] = React.useState(false)
  const [viewModalOpen, setViewModalOpen] = React.useState(false)
  const [editingCategory, setEditingCategory] = React.useState<GuidelineCategoriesWithParent | null>(null)
  const [viewingCategory, setViewingCategory] = React.useState<GuidelineCategoriesWithParent | null>(null)

  const openEditModal = React.useCallback((category: GuidelineCategoriesWithParent) => {
    setEditingCategory(category)
    setEditModalOpen(true)
  }, [])

  // Create row actions with modal handlers
  const categoryRowActions = React.useMemo(() =>
    createCategoryRowActions(
      (category) => openEditModal(category as GuidelineCategoriesWithParent),
      (category) => {
        setViewingCategory(category as GuidelineCategoriesWithParent)
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
        title="Guideline Categories"
        description="Organize clinical guidelines into hierarchical categories for easy navigation and discovery"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Category",
            onClick: () => setCreateModalOpen(true),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Enhanced DataTable */}
      <EnhancedBackendDataTable<GuidelineCategoriesWithParent>
        collectionName="guideline_categories"
        columns={columns}
        expand="parent_category"
        expandable={true}
        searchable={true}
        searchFields={["name", "description", "slug"]}
        selectable={true}
        exportable={true}
        availableFields={guidelineCategoryAvailableFields}
        rowActions={categoryRowActions}
        bulkActions={categoryBulkActions}
        persistColumnConfig={true}
        tableContext="guideline-categories-management"
      />

      {/* Create Modal */}
      <CategoryCreateModal
        open={createModalOpen}
        onOpenChange={setCreateModalOpen}
        onSuccess={handleSuccess}
      />

      {/* Edit Modal */}
      <CategoryEditModal
        open={editModalOpen}
        onOpenChange={setEditModalOpen}
        category={editingCategory}
        onSuccess={handleSuccess}
      />

      {/* View Modal */}
      <CategoryViewModal
        open={viewModalOpen}
        onOpenChange={setViewModalOpen}
        category={viewingCategory}
        onEdit={openEditModal}
      />
    </div>
  )
}
