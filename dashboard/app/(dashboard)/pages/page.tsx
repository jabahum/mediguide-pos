"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus } from "lucide-react"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { usePermissionContext } from "@/lib/permission-context"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"

// Page-specific imports
import { columns, GenericPage } from "./columns"
import { createPageRowActions, pageBulkActions } from "./page-actions"
import { pagesAvailableFields } from "./fields"
import { AdvancedFilter } from "@/types/data-table"
import { GenericPagesService } from "@/services/generic-pages.service"

export default function PagesPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])

  // Create row actions with navigation dependency injection
  const pageRowActions = React.useMemo(() => 
    createPageRowActions((path) => router.push(path)), 
    [router]
  )

  // Event handlers
  const handleAdvancedFilter = React.useCallback((filters: AdvancedFilter[]) => {
    console.log("Advanced filters applied:", filters)
  }, [])

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Pages Management"
        description="Manage generic pages and their content throughout the system"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Create Page",
            onClick: () => router.push('/pages/create'),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Enhanced DataTable with responsive wrapper */}
      <div className="grid grid-cols-1">
        <EnhancedBackendDataTable<GenericPage>
          collectionName="generic_pages"
          loadPage={({ page, perPage, search }) =>
            GenericPagesService.list({ page, perPage, search })
          }
          columns={columns}
          searchable={true}
          searchFields={["title", "key", "description"]}
          selectable={true}
          enableSelectAll={true}
          exportable={true}
          availableFields={pagesAvailableFields}
          rowActions={pageRowActions}
          bulkActions={pageBulkActions}
          persistColumnConfig={true}
          tableContext="pages-management"
          onAdvancedFilter={handleAdvancedFilter}
        />
      </div>
    </div>
  )
}
