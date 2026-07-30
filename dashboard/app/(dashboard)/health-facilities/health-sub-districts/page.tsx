"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { HealthSubDistrictsResponse } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

import { healthSubDistrictsColumns } from "./columns"
import { healthSubDistrictsAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  {
    name: "district",
    label: "District",
    type: "relation",
    relation: { collection: "districts", labelField: "name", sort: "name" },
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter health sub-district name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., HSD001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., HSD/001", span: "half" },
]

export default function HealthSubDistrictsPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<HealthSubDistrictsResponse | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: HealthSubDistrictsResponse) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<HealthSubDistrictsResponse>({
        collection: "health_sub_districts",
        entityLabel: "Health Sub-District",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<HealthSubDistrictsResponse>({
        collection: "health_sub_districts",
        entityLabel: "Health Sub-District",
        entityLabelPlural: "Health Sub-Districts",
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
        title="Health Sub-Districts Management"
        description="Manage health sub-districts within districts for health service delivery"
        actions={[
          {
            label: "Add Health Sub-District",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<HealthSubDistrictsResponse>
        collectionName="health_sub_districts"
        columns={healthSubDistrictsColumns as ExtendedColumnDef<HealthSubDistrictsResponse>[]}
        expand="district"
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={healthSubDistrictsAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="health-sub-districts-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="health_sub_districts"
        entityLabel="Health Sub-District"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
