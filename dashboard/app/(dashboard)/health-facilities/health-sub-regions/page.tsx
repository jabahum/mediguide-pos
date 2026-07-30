"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { HealthSubRegionsWithRegion } from "@/types/expanded"

import { healthSubRegionsColumns } from "./columns"
import { healthSubRegionsAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  {
    name: "region",
    label: "Region",
    type: "relation",
    relation: { collection: "regions", labelField: "name", sort: "name" },
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter health sub-region name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., HSR001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., HSR/001", span: "half" },
]

export default function HealthSubRegionsPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<HealthSubRegionsWithRegion | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: HealthSubRegionsWithRegion) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<HealthSubRegionsWithRegion>({
        collection: "health_sub_regions",
        entityLabel: "Health Sub-Region",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<HealthSubRegionsWithRegion>({
        collection: "health_sub_regions",
        entityLabel: "Health Sub-Region",
        entityLabelPlural: "Health Sub-Regions",
      }),
    []
  )
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/health-facilities")
    }
  }, [loading, hasPermission, router])

  return (
    <div className="space-y-6">
      <PageHeader
        title="Health Sub-Regions Management"
        description="Manage health sub-regions within administrative regions"
        actions={[
          {
            label: "Add Health Sub-Region",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<HealthSubRegionsWithRegion>
        collectionName="health_sub_regions"
        columns={healthSubRegionsColumns}
        expand="region"
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={healthSubRegionsAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="health-sub-regions-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="health_sub_regions"
        entityLabel="Health Sub-Region"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
