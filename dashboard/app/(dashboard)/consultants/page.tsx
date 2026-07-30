"use client"

import * as React from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"
import { createColumns, Consultant } from "./columns"
import { createConsultantRowActions, consultantBulkActions } from "./consultant-actions"
import { consultantsAvailableFields } from "./fields"
import { usePermissionContext } from "@/lib/permission-context"

export default function ConsultantsPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])
  
  // Get initial filter from URL parameters
  const urlFilter = searchParams.get('filter')
  
  // Create columns
  const columns = React.useMemo(() => createColumns(), [])
  
  // Convert URL filter to legacy collection API filter syntax
  const getInitialFilter = React.useMemo(() => {
    switch (urlFilter) {
      case 'verified':
        return 'isVerified = true'
      case 'pending':
        return 'status = "pending_approval"'
      case 'active':
        return 'status = "active"'
      case 'inactive':
        return 'status = "inactive"'
      case 'suspended':
        return 'status = "suspended"'
      default:
        return undefined
    }
  }, [urlFilter])

  // Create row actions with proper navigation
  const consultantRowActions = React.useMemo(() => 
    createConsultantRowActions((path) => router.push(path)), 
    [router]
  )

  const handleSelectionChange = React.useCallback((selectedConsultants: Consultant[]) => {
    console.log('Selected consultants:', selectedConsultants)
  }, [])

  const handleError = React.useCallback((error: Error) => {
    console.error('Consultants table error:', error)
  }, [])

  // Dynamic page title and description based on filter
  const getPageTitleAndDescription = React.useMemo(() => {
    switch (urlFilter) {
      case 'verified':
        return {
          title: "Verified Consultants",
          description: "Medical consultants with verified credentials and qualifications"
        }
      case 'pending':
        return {
          title: "Pending Approval",
          description: "Consultants awaiting credential verification and approval"
        }
      case 'active':
        return {
          title: "Active Consultants",
          description: "Currently active medical consultants available for consultations"
        }
      case 'inactive':
        return {
          title: "Inactive Consultants",
          description: "Medical consultants who are currently inactive"
        }
      case 'suspended':
        return {
          title: "Suspended Consultants",
          description: "Medical consultants who have been suspended from the system"
        }
      default:
        return {
          title: "Consultant Management",
          description: "Manage medical consultants and specialists available for consultations"
        }
    }
  }, [urlFilter])

  return (
    <div className="space-y-6">
      <PageHeader
        title={getPageTitleAndDescription.title}
        description={getPageTitleAndDescription.description}
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Consultant",
            onClick: () => router.push('/consultants/create'),
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<Consultant>
        collection="consultants"
        columns={columns}
        searchFields={["name", "email", "specialty", "organization", "city", "country"]}
        searchPlaceholder="Search consultants by name, email, specialty, organization, or location..."
        rowActions={consultantRowActions}
        bulkActions={consultantBulkActions}
        availableFields={consultantsAvailableFields}
        query={{
          sort: "-created",
          filter: getInitialFilter,
        }}
        ui={{
          pageSize: 20,
          exportable: true,
          importable: true,
        }}
        onSelect={handleSelectionChange}
        onError={handleError}
      />
    </div>
  )
}
