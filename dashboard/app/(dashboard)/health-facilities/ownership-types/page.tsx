"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { OwnershipTypesResponse } from "@/types/backend-types"

import { ownershipTypesColumns } from "./columns"
import { ownershipTypesAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  { name: "name", label: "Name", type: "text", placeholder: "e.g., Government" },
  { name: "code", label: "Code", type: "text", placeholder: "e.g., Govt" },
]

export default function OwnershipTypesPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<OwnershipTypesResponse | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: OwnershipTypesResponse) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<OwnershipTypesResponse>({
        collection: "ownership_types",
        entityLabel: "Ownership Type",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<OwnershipTypesResponse>({
        collection: "ownership_types",
        entityLabel: "Ownership Type",
        entityLabelPlural: "Ownership Types",
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
        title="Ownership Types Management"
        description="Manage ownership types for health facilities (Government, Private, NGO, etc.)"
        actions={[
          {
            label: "Add Ownership Type",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<OwnershipTypesResponse>
        collectionName="ownership_types"
        columns={ownershipTypesColumns}
        searchable={true}
        searchFields={["name", "code"]}
        selectable={true}
        exportable={true}
        availableFields={ownershipTypesAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="ownership-types-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="ownership_types"
        entityLabel="Ownership Type"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
