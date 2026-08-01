"use client"

import * as React from "react"
import { Plus } from "lucide-react"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"

// Page-specific imports
import { abbreviationsColumns } from "./columns"
import { createAbbreviationRowActions, abbreviationBulkActions } from "./abbreviation-actions"
import { abbreviationsAvailableFields } from "./fields"
import { AbbreviationsWithExpanded } from "@/types/expanded"
import { AbbreviationCreateModal } from "./components/abbreviation-create-modal"
import { AbbreviationEditModal } from "./components/abbreviation-edit-modal"
import { AbbreviationViewModal } from "./components/abbreviation-view-modal"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { abbreviationService } from "@/services/guideline-content.service"

export default function AbbreviationsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const [createModalOpen, setCreateModalOpen] = React.useState(false)

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/guidelines")
    }
  }, [loading, hasPermission, router])
  const [editModalOpen, setEditModalOpen] = React.useState(false)
  const [viewModalOpen, setViewModalOpen] = React.useState(false)
  const [editingAbbreviation, setEditingAbbreviation] = React.useState<AbbreviationsWithExpanded | null>(null)
  const [viewingAbbreviation, setViewingAbbreviation] = React.useState<AbbreviationsWithExpanded | null>(null)

  const openEditModal = React.useCallback((abbreviation: AbbreviationsWithExpanded) => {
    setEditingAbbreviation(abbreviation)
    setEditModalOpen(true)
  }, [])

  // Create row actions with modal handlers
  const abbreviationRowActions = React.useMemo(() =>
    createAbbreviationRowActions(
      (abbreviation) => openEditModal(abbreviation),
      (abbreviation) => {
        setViewingAbbreviation(abbreviation)
        setViewModalOpen(true)
      }
    ),
    [openEditModal]
  )

  // Handle successful operations
  const handleSuccess = React.useCallback(() => {
    // This will trigger a refetch of the data table
    // The EnhancedBackendDataTable handles this automatically
  }, [])

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Medical Abbreviations"
        description="Comprehensive database of medical abbreviations and their meanings for quick reference"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Abbreviation",
            onClick: () => setCreateModalOpen(true),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<AbbreviationsWithExpanded>
        collection="abbreviations"
		loadPage={abbreviationService.listTable}
        columns={abbreviationsColumns}
        searchFields={["abbreviation", "meaning", "description"]}
        rowActions={abbreviationRowActions}
        bulkActions={abbreviationBulkActions}
        availableFields={abbreviationsAvailableFields}
        ui={{
          exportable: true
        }}
      />

      {/* Create Modal */}
      <AbbreviationCreateModal
        open={createModalOpen}
        onOpenChange={setCreateModalOpen}
        onSuccess={handleSuccess}
      />

      {/* Edit Modal */}
      <AbbreviationEditModal
        open={editModalOpen}
        onOpenChange={setEditModalOpen}
        abbreviation={editingAbbreviation}
        onSuccess={handleSuccess}
      />

      {/* View Modal */}
      <AbbreviationViewModal
        open={viewModalOpen}
        onOpenChange={setViewModalOpen}
        abbreviation={viewingAbbreviation}
        onEdit={openEditModal}
      />
    </div>
  )
}
