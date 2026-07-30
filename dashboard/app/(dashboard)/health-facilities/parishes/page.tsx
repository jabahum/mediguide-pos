"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { ParishesWithSubcounty } from "@/types/expanded"

import { parishesColumns } from "./columns"
import { parishesAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  {
    name: "subcounty",
    label: "Subcounty",
    type: "relation",
    relation: { collection: "subcounties", labelField: "name", sort: "name" },
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter parish name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., PAR001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., P/001", span: "half" },
]

export default function ParishesPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<ParishesWithSubcounty | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: ParishesWithSubcounty) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<ParishesWithSubcounty>({
        collection: "parishes",
        entityLabel: "Parish",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<ParishesWithSubcounty>({
        collection: "parishes",
        entityLabel: "Parish",
        entityLabelPlural: "Parishes",
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
        title="Parishes Management"
        description="Manage parishes - the smallest administrative units within subcounties"
        actions={[
          {
            label: "Add Parish",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<ParishesWithSubcounty>
        collectionName="parishes"
        columns={parishesColumns}
        expand="subcounty"
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={parishesAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="parishes-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="parishes"
        entityLabel="Parish"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
