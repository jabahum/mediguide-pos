"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { SubcountiesWithExpanded } from "@/types/expanded"

import { subcountiesColumns } from "./columns"
import { subcountiesAvailableFields } from "./fields"
import { AdminEntityModal, AdminFieldDef } from "../_lib/admin-entity-modal"
import { createAdminRowActions, createAdminBulkActions } from "../_lib/admin-crud-actions"
import { facilityRelationOptions, healthFacilitiesService } from "@/services/health-facilities.service"

const FIELDS: AdminFieldDef[] = [
  {
    name: "district",
    label: "District",
    type: "relation",
    relation: facilityRelationOptions.districts,
  },
  {
    name: "county",
    label: "County",
    type: "relation",
    relation: facilityRelationOptions.counties,
  },
  { name: "name", label: "Name", type: "text", placeholder: "Enter subcounty name" },
  { name: "nhpi_code", label: "NHPI Code", type: "text", placeholder: "e.g., SC001", span: "half" },
  { name: "hsdt_code", label: "HSDT Code", type: "text", placeholder: "e.g., S/001", span: "half" },
]

export default function SubcountiesPage() {
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<SubcountiesWithExpanded | null>(null)

  const openCreate = React.useCallback(() => {
    setEditing(null)
    setModalOpen(true)
  }, [])

  const openEdit = React.useCallback((row: SubcountiesWithExpanded) => {
    setEditing(row)
    setModalOpen(true)
  }, [])

  const closeModal = React.useCallback(() => {
    setModalOpen(false)
    setEditing(null)
  }, [])

  const rowActions = React.useMemo(
    () =>
      createAdminRowActions<SubcountiesWithExpanded>({
        deleteRecord: healthFacilitiesService.deleteSubcounty,
        entityLabel: "Subcounty",
        getDisplayName: (row) => row.name,
        onEdit: openEdit,
      }),
    [openEdit]
  )

  const bulkActions = React.useMemo(
    () =>
      createAdminBulkActions<SubcountiesWithExpanded>({
        deleteRecord: healthFacilitiesService.deleteSubcounty,
        entityLabel: "Subcounty",
        entityLabelPlural: "Subcounties",
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
        title="Subcounties Management"
        description="Manage subcounties within counties and districts"
        actions={[
          {
            label: "Add Subcounty",
            onClick: openCreate,
            icon: <Plus className="h-4 w-4" />,
          },
        ]}
      />

      <EnhancedBackendDataTable<SubcountiesWithExpanded>
        collectionName="subcounties"
        loadPage={healthFacilitiesService.listSubcounties}
        columns={subcountiesColumns}
        expandable={true}
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        selectable={true}
        exportable={true}
        availableFields={subcountiesAvailableFields}
        rowActions={rowActions}
        bulkActions={bulkActions}
        persistColumnConfig={true}
        tableContext="subcounties-management"
      />

      <AdminEntityModal
        open={modalOpen}
        onClose={closeModal}
        createRecord={healthFacilitiesService.createSubcounty}
        updateRecord={healthFacilitiesService.updateSubcounty}
        entityLabel="Subcounty"
        fields={FIELDS}
        record={editing}
      />
    </div>
  )
}
