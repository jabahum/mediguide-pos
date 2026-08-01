"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { AuthoritiesWithOwnershipType } from "@/types/expanded"

import { authoritiesColumns } from "./columns"
import { authoritiesAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"
import { facilityRelationOptions, healthFacilitiesService } from "@/services/health-facilities.service"

const FIELDS: AdminFieldDef[] = [
  { name: "name", label: "Name", type: "text", placeholder: "e.g., Ministry of Health" },
  { name: "code", label: "Code", type: "text", placeholder: "e.g., MOH" },
  {
    name: "ownership_type",
    label: "Ownership Type",
    type: "relation",
    relation: facilityRelationOptions.ownershipTypes,
  },
]

export default function AuthoritiesPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<AuthoritiesWithOwnershipType | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: AuthoritiesWithOwnershipType) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<AuthoritiesWithOwnershipType>({
        deleteRecord: healthFacilitiesService.deleteAuthority,
        entityLabel: "Authority",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<AuthoritiesWithOwnershipType>({
        deleteRecord: healthFacilitiesService.deleteAuthority,
        entityLabel: "Authority",
        entityLabelPlural: "Authorities",
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
        title="Authorities Management"
        description="Manage health facility authorities (MOH, Medical Bureaus, NGOs, etc.)"
        actions={[
          {
            label: "Add Authority",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<AuthoritiesWithOwnershipType>
        collectionName="authorities"
        loadPage={healthFacilitiesService.listAuthorities}
        columns={authoritiesColumns}
        expandable={true}
        searchable={true}
        searchFields={["name", "code"]}
        selectable={true}
        exportable={true}
        availableFields={authoritiesAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="authorities-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        createRecord={healthFacilitiesService.createAuthority}
        updateRecord={healthFacilitiesService.updateAuthority}
        entityLabel="Authority"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
