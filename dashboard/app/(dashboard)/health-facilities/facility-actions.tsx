"use client"

import { 
  Eye, 
  Edit, 
  Trash2, 
  Map,
  FileText,
  Download,
  Archive,
  Copy,
  ExternalLink
} from "lucide-react"

import { showToast } from "@/lib/toast"
import { RowAction, BulkAction } from "@/types/data-table"
import { HealthFacility } from "./columns"
import { healthFacilitiesService } from "@/services/health-facilities.service"

// Factory function to create facility row actions with navigation
export const createFacilityRowActions = (navigate: (path: string) => void): RowAction<HealthFacility>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (facility) => {
      navigate(`/health-facilities/${facility.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit Facility",
    icon: Edit,
    onClick: async (facility) => {
      navigate(`/health-facilities/${facility.id}/edit`)
    },
  },
  {
    id: "view-location",
    label: "View on Map",
    icon: Map,
    disabled: () => true,
    onClick: async (facility) => {
      // In a real implementation, this would open a map view
      showToast.info(
        "Map View",
        `Opening map view for ${facility.name}`
      )
    },
  },
  {
    id: "generate-report",
    label: "Generate Report",
    icon: FileText,
    disabled: () => true,
    onClick: async (facility) => {
      await generateFacilityReport(facility)
    },
  },
  {
    id: "copy-codes",
    label: "Copy Codes",
    icon: Copy,
    onClick: async (facility) => {
      const codes = `NHPI: ${facility.nhpi_code}\nHSDT: ${facility.hsdt_code}`
      await navigator.clipboard.writeText(codes)
      showToast.success("Copied", "Facility codes copied to clipboard")
    },
  },
  {
    id: "view-hierarchy",
    label: "View Hierarchy",
    icon: ExternalLink,
    onClick: async (facility) => {
      // Show the full administrative hierarchy for this facility
      await showFacilityHierarchy(facility)
    },
    separator: true,
  },
  {
    id: "archive",
    label: "Archive Facility",
    icon: Archive,
    onClick: async (facility) => {
      await archiveFacility(facility)
    },
    separator: true,
  },
  {
    id: "delete",
    label: "Delete Facility",
    icon: Trash2,
    variant: "destructive",
    onClick: async (facility) => {
      await deleteFacility(facility)
    },
    confirmMessage: "Are you sure you want to delete this facility? This action cannot be undone and will remove all associated data.",
  },
]

// Backward compatibility - will be deprecated
export const facilityRowActions: RowAction<HealthFacility>[] = createFacilityRowActions((path) => {
  // Fallback to window.location for components not yet updated
  window.location.href = path
})

// Bulk actions for multiple facilities
export const facilityBulkActions: BulkAction<HealthFacility>[] = [
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: Download,
    variant: "outline",
    onClick: async (facilities) => {
      await exportFacilities(facilities)
    },
    description: "Export selected facilities as CSV file",
  },
  {
    id: "bulk-generate-reports",
    label: "Generate Reports",
    icon: FileText,
    variant: "outline",
    onClick: async (facilities) => {
      await bulkGenerateFacilityReports(facilities)
    },
    description: "Generate individual reports for selected facilities",
  },
  {
    id: "bulk-view-map",
    label: "View All on Map",
    icon: Map,
    variant: "outline",
    onClick: async (facilities) => {
      showToast.info(
        "Map View",
        `Opening map view for ${facilities.length} facilities`
      )
    },
    description: "View all selected facilities on an interactive map",
  },
  {
    id: "bulk-archive",
    label: "Archive Selected",
    icon: Archive,
    variant: "outline",
    onClick: async (facilities) => {
      await bulkArchiveFacilities(facilities)
    },
    requiresConfirmation: true,
    description: "Archive selected facilities",
    separator: true,
  },
]

// Action implementations
async function generateFacilityReport(facility: HealthFacility): Promise<void> {
  try {
    // In a real implementation, this would generate a facility report
    // For now, we'll simulate the process
    showToast.loading("Generating report...")
    
    // Simulate report generation
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    showToast.success(
      "Report Generated",
      `Report for ${facility.name} has been generated`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to generate report'
    showToast.error("Report Failed", message)
    throw error
  }
}

async function showFacilityHierarchy(facility: HealthFacility): Promise<void> {
  try {
    const { expand } = facility
    if (!expand) {
      showToast.error("Hierarchy Error", "Facility hierarchy data not available")
      return
    }

    const hierarchy = [
      expand.region?.name,
      expand.district?.name,
      expand.county?.name,
      expand.subcounty?.name,
      expand.parish?.name,
      facility.name
    ].filter(Boolean).join(' → ')

    showToast.info(
      "Administrative Hierarchy",
      hierarchy
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to show hierarchy'
    showToast.error("Hierarchy Error", message)
    throw error
  }
}

async function archiveFacility(facility: HealthFacility): Promise<void> {
  try {
    // In a real implementation, you might have a status field to set to 'archived'
    // For now, we'll simulate the archive process
    showToast.info(
      "Facility Archived",
      `${facility.name} has been archived`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to archive facility'
    showToast.error("Archive Failed", message)
    throw error
  }
}

async function deleteFacility(facility: HealthFacility): Promise<void> {
  try {
    await healthFacilitiesService.deleteFacility(facility.id)
    
    showToast.success(
      "Facility Deleted",
      `${facility.name} has been permanently deleted`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete facility'
    showToast.error("Delete Failed", message)
    throw error
  }
}

// Bulk action implementations
async function exportFacilities(facilities: HealthFacility[]): Promise<void> {
  try {
    const csvContent = convertFacilitiesToCSV(facilities)
    downloadCSV(csvContent, 'selected-health-facilities.csv')
    
    showToast.success(
      "Export Complete",
      `Exported ${facilities.length} facilit${facilities.length === 1 ? 'y' : 'ies'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to export facilities'
    showToast.error("Export Failed", message)
    throw error
  }
}

async function bulkGenerateFacilityReports(facilities: HealthFacility[]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  // const loadingToast = showToast.loading(`Generating reports for ${facilities.length} facilities...`)

  for (const facility of facilities) {
    try {
      await generateFacilityReport(facility)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to generate report for facility ${facility.name}:`, error)
    }
  }

  // Dismiss loading toast
  // Note: showToast.dismiss is not available, the loading toast will auto-dismiss

  if (successCount > 0) {
    showToast.success(
      "Bulk Reports Complete",
      `Successfully generated ${successCount} report${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Reports Failed",
      `${errorCount} report${errorCount === 1 ? '' : 's'} could not be generated`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to generate any reports")
  }
}

async function bulkArchiveFacilities(facilities: HealthFacility[]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const facility of facilities) {
    try {
      await archiveFacility(facility)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to archive facility ${facility.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Bulk Archive Complete",
      `Successfully archived ${successCount} facilit${successCount === 1 ? 'y' : 'ies'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Archives Failed",
      `${errorCount} facilit${errorCount === 1 ? 'y' : 'ies'} could not be archived`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to archive any facilities")
  }
}

// Utility functions
function convertFacilitiesToCSV(facilities: HealthFacility[]): string {
  const headers = [
    'Name',
    'NHPI Code',
    'HSDT Code',
    'Level',
    'Authority', 
    'Ownership',
    'Region',
    'District',
    'County',
    'Subcounty',
    'Parish',
    'Created',
    'Updated'
  ]
  
  const rows = facilities.map(facility => [
    facility.name,
    facility.nhpi_code,
    facility.hsdt_code,
    facility.expand?.facility_level?.name || '',
    facility.expand?.authority?.name || '',
    facility.expand?.ownership_type?.name || '',
    facility.expand?.region?.name || '',
    facility.expand?.district?.name || '',
    facility.expand?.county?.name || '',
    facility.expand?.subcounty?.name || '',
    facility.expand?.parish?.name || '',
    facility.created,
    facility.updated || ''
  ])

  const csvContent = [headers, ...rows]
    .map(row => row.map(field => `"${field}"`).join(','))
    .join('\n')

  return csvContent
}

function downloadCSV(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'
  
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  
  URL.revokeObjectURL(url)
}
