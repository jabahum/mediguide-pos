"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { DistrictsWithExpanded } from "@/types/expanded"

import { districtsColumns } from "./columns"
import { districtsAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"
import { facilityRelationOptions, healthFacilitiesService } from "@/services/health-facilities.service"

const FIELDS: AdminFieldDef[] = [
  {
    name: "region",
    label: "Region",
    type: "relation",
    relation: facilityRelationOptions.regions,
  },
  {
    name: "health_sub_region",
    label: "Health Sub-Region",
    type: "relation",
    relation: facilityRelationOptions.healthSubRegions,
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter district name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., DIS001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., D/001", span: "half" },
]

export default function DistrictsPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<DistrictsWithExpanded | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: DistrictsWithExpanded) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<DistrictsWithExpanded>({
        deleteRecord: healthFacilitiesService.deleteDistrict,
        entityLabel: "District",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<DistrictsWithExpanded>({
        deleteRecord: healthFacilitiesService.deleteDistrict,
        entityLabel: "District",
        entityLabelPlural: "Districts",
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
        title="Districts Management"
        description="Manage administrative districts within regions and health sub-regions"
        actions={[
          {
            label: "Add District",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<DistrictsWithExpanded>
        collectionName="districts"
        loadPage={healthFacilitiesService.listDistricts}
        columns={districtsColumns}
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={districtsAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="districts-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        createRecord={healthFacilitiesService.createDistrict}
        updateRecord={healthFacilitiesService.updateDistrict}
        entityLabel="District"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
