"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { createColumns, HealthFacility } from "./columns"
import { createFacilityRowActions, facilityBulkActions } from "./facility-actions"
import { healthFacilitiesAvailableFields } from "./fields"
import { AdvancedFilter } from "@/types/data-table"
import { usePermissionContext } from "@/lib/permission-context"

export default function HealthFacilitiesPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])
  
  // Create columns for health facilities
  const columns = React.useMemo(() => createColumns(), [])

  // Create row actions with proper navigation
  const facilityRowActions = React.useMemo(() => 
    createFacilityRowActions((path) => router.push(path)), 
    [router]
  )

  const handleAdvancedFilter = React.useCallback((filters: AdvancedFilter[]) => {
    console.log('Advanced filters applied:', filters)
    // Here you would convert the advanced filters to legacy collection API filter syntax
    // and pass them to the data table hook
  }, [])

  const handleSelectionChange = React.useCallback((selectedFacilities: HealthFacility[]) => {
    console.log('Selected facilities:', selectedFacilities)
  }, [])

  const handleDataChange = React.useCallback((facilities: HealthFacility[]) => {
    console.log('Facilities data updated:', facilities.length, 'facilities')
  }, [])

  const handleError = React.useCallback((error: Error) => {
    console.error('Facilities table error:', error)
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="Health Facilities Management"
        description="Manage health facilities across Uganda's administrative hierarchy"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Health Facility",
            onClick: () => router.push('/health-facilities/create'),
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Enhanced DataTable */}
      <EnhancedBackendDataTable<HealthFacility>
        // Collection settings
        collectionName="health_facilities"
        columns={columns}
        expand="facility_level,authority,ownership_type,region,district,county,subcounty,parish,health_sub_region,health_sub_district"
        expandable={true}
        sort="-created"
        realtime={true}

        // Pagination
        defaultPageSize={20}
        pageSizeOptions={[10, 20, 50, 100]}

        // Search
        searchable={true}
        searchFields={["name", "nhpi_code", "hsdt_code"]}
        searchPlaceholder="Search facilities by name, NHPI code, or HSDT code..."

        // Selection and actions
        selectable={true}
        enableSelectAll={true}
        rowActions={facilityRowActions}
        bulkActions={facilityBulkActions}

        // Export/Import
        exportable={true}
        importable={true}
        exportConfig={{
          formats: ['csv', 'json', 'xlsx'],
          filename: 'health-facilities',
          includeHeaders: true,
        }}
        importConfig={{
          formats: ['csv', 'json'],
          validateData: async (data: unknown[]) => {
            // Basic validation for imported facility data
            const valid: Record<string, unknown>[] = []
            const errors: string[] = []

            data.forEach((item: unknown, index: number) => {
              const record = item as Record<string, unknown>
              if (!record.name) {
                errors.push(`Row ${index + 1}: Name is required`)
                return
              }
              if (!record.nhpi_code) {
                errors.push(`Row ${index + 1}: NHPI code is required`)
                return
              }
              if (!record.hsdt_code) {
                errors.push(`Row ${index + 1}: HSDT code is required`)
                return
              }

              valid.push({
                ...record,
              })
            })

            return { valid, errors }
          },
        }}

        // UI customization
        toolbar={true}
        columnVisibility={true}
        availableFields={healthFacilitiesAvailableFields}

        // Column persistence (will remember user's column preferences)
        persistColumnConfig={true}
        tableContext="health-facilities-management"

        // Event handlers
        onSelectionChange={handleSelectionChange}
        onDataChange={handleDataChange}
        onError={handleError}
        onAdvancedFilter={handleAdvancedFilter}
      />
    </div>
  )
}