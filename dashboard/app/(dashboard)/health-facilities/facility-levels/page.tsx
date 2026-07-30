"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { FacilityLevelsResponse } from "@/types/backend-types"

import { facilityLevelsColumns } from "./columns"
import { facilityLevelsAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"

const FIELDS: AdminFieldDef[] = [
  { name: "name", label: "Name", type: "text", placeholder: "e.g., Hospital" },
  { name: "code", label: "Code", type: "text", placeholder: "e.g., HC III" },
]

export default function FacilityLevelsPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<FacilityLevelsResponse | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: FacilityLevelsResponse) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<FacilityLevelsResponse>({
        collection: "facility_levels",
        entityLabel: "Facility Level",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<FacilityLevelsResponse>({
        collection: "facility_levels",
        entityLabel: "Facility Level",
        entityLabelPlural: "Facility Levels",
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
        title="Facility Levels Management"
        description="Manage health facility levels (Hospital, HC III, HC II, etc.)"
        actions={[
          {
            label: "Add Facility Level",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<FacilityLevelsResponse>
        collectionName="facility_levels"
        columns={facilityLevelsColumns}
        searchable={true}
        searchFields={["name", "code"]}
        selectable={true}
        exportable={true}
        availableFields={facilityLevelsAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="facility-levels-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        collection="facility_levels"
        entityLabel="Facility Level"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
