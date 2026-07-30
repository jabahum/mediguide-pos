"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { CountiesWithDistrict } from "@/types/expanded"

import { countiesColumns } from "./columns"
import { countiesAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  {
    name: "district",
    label: "District",
    type: "relation",
    relation: { collection: "districts", labelField: "name", sort: "name" },
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter county name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., CNT001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., C/001", span: "half" },
]

export default function CountiesPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<CountiesWithDistrict | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: CountiesWithDistrict) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<CountiesWithDistrict>({
        collection: "counties",
        entityLabel: "County",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<CountiesWithDistrict>({
        collection: "counties",
        entityLabel: "County",
        entityLabelPlural: "Counties",
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
        title="Counties Management"
        description="Manage counties within districts"
        actions={[
          {
            label: "Add County",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<CountiesWithDistrict>
        collectionName="counties"
        columns={countiesColumns}
        expand="district"
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={countiesAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="counties-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="counties"
        entityLabel="County"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
