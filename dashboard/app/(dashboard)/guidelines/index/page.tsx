"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"

// Page-specific imports
import { guidelineIndexColumns, GuidelineIndexType } from "./columns"
import { createGuidelineIndexRowActions, guidelineIndexBulkActions } from "./index-actions"
import { guidelineIndexAvailableFields } from "./fields"
import { CreateIndexModal } from "./components/create-index-modal"
import { EditIndexModal } from "./components/edit-index-modal"
import { ExtendedColumnDef } from "@/types/data-table"
import { usePermissionContext } from "@/lib/permission-context"

export default function GuidelineIndexPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/guidelines")
    }
  }, [loading, hasPermission, router])
  const [refreshKey, setRefreshKey] = React.useState(0)
  const [createModalOpen, setCreateModalOpen] = React.useState(false)
  const [editModalOpen, setEditModalOpen] = React.useState(false)
  const [editingItem, setEditingItem] = React.useState<GuidelineIndexType | null>(null)
  const [allIndexItems, setAllIndexItems] = React.useState<GuidelineIndexType[]>([])
  
  // Force refresh of the datatable
  const handleRefresh = React.useCallback(() => {
    setRefreshKey(prev => prev + 1)
  }, [])

  // Create row actions with navigation and refresh callback
  const indexRowActions = React.useMemo(() => 
    createGuidelineIndexRowActions(
      (path) => router.push(path),
      handleRefresh,
      allIndexItems,
      setCreateModalOpen,
      setEditModalOpen,
      setEditingItem
    ), 
    [router, handleRefresh, allIndexItems]
  )

  // Handle opening create modal
  const handleCreateClick = () => {
    setCreateModalOpen(true)
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Guideline Index"
        description="Organize and manage the hierarchical structure of clinical guidelines"
        showBackButton={true}
        onBack={() => router.push('/guidelines')}
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Create Index Item",
            onClick: handleCreateClick,
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Enhanced DataTable */}
      <EnhancedBackendDataTable<GuidelineIndexType>
        key={refreshKey}
        collectionName="guideline_index"
        columns={guidelineIndexColumns as ExtendedColumnDef<GuidelineIndexType>[]}
        expand="parent"
        expandable={true}
        searchable={true}
        searchFields={["title", "description"]}
        selectable={true}
        exportable={true}
        availableFields={guidelineIndexAvailableFields}
        rowActions={indexRowActions}
        bulkActions={guidelineIndexBulkActions}
        persistColumnConfig={true}
        tableContext="guideline-index-management"
        onDataChange={setAllIndexItems}
      />

      {/* Create Modal */}
      <CreateIndexModal
        open={createModalOpen}
        onOpenChange={setCreateModalOpen}
        allIndexItems={allIndexItems}
        onSuccess={handleRefresh}
      />

      {/* Edit Modal */}
      <EditIndexModal
        open={editModalOpen}
        onOpenChange={setEditModalOpen}
        indexItem={editingItem}
        allIndexItems={allIndexItems}
        onSuccess={handleRefresh}
      />
    </div>
  )
}