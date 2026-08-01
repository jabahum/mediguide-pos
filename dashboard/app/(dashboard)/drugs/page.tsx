"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus } from "lucide-react"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"

// Page-specific imports
import { columns, DrugWithRelations } from "./columns"
import { createDrugRowActions, drugBulkActions } from "./drug-actions"
import { drugAvailableFields } from "./fields"
import { usePermissionContext } from "@/lib/permission-context"
import { drugService } from "@/services/drug.service"

export default function DrugsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])

  // Create row actions with navigation dependency injection
  const drugRowActions = React.useMemo(() =>
    createDrugRowActions((path) => router.push(path)),
    [router]
  )

  // Event handlers - removed unused handlers

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Drug Index"
        description="Comprehensive medication database management with categories, tags, and clinical information"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Drug",
            onClick: () => router.push('/drugs/create'),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<DrugWithRelations>
        collection="drugs"
        loadPage={drugService.listTable.bind(drugService)}
        columns={columns}
        searchFields={["name", "brand_names", "drug_class", "therapeutic_category", "search_keywords"]}
        rowActions={drugRowActions}
        bulkActions={drugBulkActions}
        availableFields={drugAvailableFields}
        ui={{
          exportable: true
        }}
      />
    </div>
  )
}
