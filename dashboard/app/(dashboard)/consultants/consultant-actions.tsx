"use client"

import { 
  User, 
  Edit, 
  Trash2, 
  Shield, 
  Mail, 
  Archive, 
  Download,
  CheckCircle,
  XCircle,
  Calendar,
  UserCheck
} from "lucide-react"

import { consultantService } from "@/services/consultant.service"
import { showToast } from "@/lib/toast"
import { withDashboardBasePath } from "@/lib/dashboard-path"
import { RowAction, BulkAction } from "@/types/data-table"
import { Consultant } from "./columns"

// Factory function to create consultant row actions with navigation
export const createConsultantRowActions = (navigate: (path: string) => void): RowAction<Consultant>[] => [
  {
    id: "view",
    label: "View Profile",
    icon: User,
    onClick: async (consultant) => {
      // Navigate to consultant profile page using Next.js router
      navigate(`/consultants/${consultant.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit Consultant",
    icon: Edit,
    onClick: async (consultant) => {
      // Navigate to edit consultant page using Next.js router
      navigate(`/consultants/${consultant.id}/edit`)
    },
  },
  {
    id: "toggle-status",
    label: "Toggle Status",
    icon: Shield,
    onClick: async (consultant) => {
      await toggleConsultantStatus(consultant)
    },
    disabled: (consultant) => consultant.status === 'suspended',
  },
  {
    id: "verify-consultant",
    label: "Toggle Verification",
    icon: UserCheck,
    onClick: async (consultant) => {
      await toggleConsultantVerification(consultant)
    },
  },
  {
    id: "send-welcome",
    label: "Send Welcome Email",
    icon: Mail,
    onClick: async (consultant) => {
      await sendWelcomeEmail(consultant)
    },
    disabled: (consultant) => consultant.status !== 'active',
  },
  {
    id: "schedule-consultation",
    label: "Schedule Consultation",
    icon: Calendar,
    onClick: async () => {
      // This would integrate with a consultation scheduling system
      showToast.info("Coming Soon", "Consultation scheduling will be available soon")
    },
    disabled: (consultant) => consultant.status !== 'active' || !consultant.isVerified,
    separator: true,
  },
  {
    id: "archive",
    label: "Archive Consultant",
    icon: Archive,
    onClick: async (consultant) => {
      await archiveConsultant(consultant)
    },
    disabled: (consultant) => consultant.status === 'active',
    confirmMessage: "Are you sure you want to archive this consultant? They will no longer be available for consultations.",
  },
  {
    id: "delete",
    label: "Delete Consultant",
    icon: Trash2,
    variant: "destructive",
    onClick: async (consultant) => {
      await deleteConsultant(consultant)
    },
    disabled: (consultant) => consultant.status === 'active',
    confirmMessage: "Are you sure you want to delete this consultant? This action cannot be undone.",
  },
]

// Backward compatibility - will be deprecated
export const consultantRowActions: RowAction<Consultant>[] = createConsultantRowActions((path) => {
  // Fallback to window.location for components not yet updated
  window.location.href = withDashboardBasePath(path)
})

// Bulk actions for multiple consultants - focused on administrative tasks
export const consultantBulkActions: BulkAction<Consultant>[] = [
  {
    id: "bulk-approve",
    label: "Approve Selected",
    icon: CheckCircle,
    variant: "outline",
    onClick: async (consultants) => {
      await bulkUpdateConsultantStatus(consultants, 'active')
    },
    disabled: (consultants) => consultants.every(consultant => consultant.status === 'active'),
    description: "Approve and activate selected consultants",
  },
  {
    id: "bulk-suspend",
    label: "Suspend Selected",
    icon: XCircle,
    variant: "outline",
    onClick: async (consultants) => {
      await bulkUpdateConsultantStatus(consultants, 'suspended')
    },
    disabled: (consultants) => consultants.every(consultant => consultant.status === 'suspended'),
    requiresConfirmation: true,
    description: "Suspend selected consultants from providing consultations",
  },
  {
    id: "bulk-verify",
    label: "Verify Selected",
    icon: UserCheck,
    variant: "outline",
    onClick: async (consultants) => {
      await bulkVerifyConsultants(consultants)
    },
    disabled: (consultants) => consultants.every(consultant => consultant.isVerified),
    description: "Mark selected consultants as verified",
  },
  {
    id: "bulk-send-welcome",
    label: "Send Welcome Emails",
    icon: Mail,
    variant: "outline",
    onClick: async (consultants) => {
      await bulkSendWelcomeEmails(consultants)
    },
    disabled: (consultants) => consultants.every(consultant => consultant.status !== 'active'),
    description: "Send welcome emails to active consultants",
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: Download,
    variant: "outline",
    onClick: async (consultants) => {
      await exportConsultants(consultants)
    },
    description: "Download selected consultants data as CSV",
  },
]

// Action implementations
async function toggleConsultantStatus(consultant: Consultant): Promise<void> {
  try {
    const newStatus = consultant.status === 'active' ? 'inactive' : 'active'
    await consultantService.update(consultant.id, { status: newStatus })
    
    showToast.success(
      "Status Updated",
      `Consultant ${consultant.name} has been ${newStatus === 'active' ? 'activated' : 'deactivated'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update consultant status'
    showToast.error("Update Failed", message)
    throw error
  }
}

async function toggleConsultantVerification(consultant: Consultant): Promise<void> {
  try {
    const newVerificationStatus = !consultant.isVerified
    await consultantService.update(consultant.id, { isVerified: newVerificationStatus })
    
    showToast.success(
      "Verification Updated",
      `Consultant ${consultant.name} has been ${newVerificationStatus ? 'verified' : 'unverified'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update verification status'
    showToast.error("Update Failed", message)
    throw error
  }
}

async function sendWelcomeEmail(consultant: Consultant): Promise<void> {
  try {
    // This would typically integrate with your email service
    // For now, we'll simulate the process
    console.log(`Sending welcome email to ${consultant.email}`)
    
    showToast.success(
      "Welcome Email Sent",
      `Welcome email sent to ${consultant.email}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to send welcome email'
    showToast.error("Send Failed", message)
    throw error
  }
}

async function archiveConsultant(consultant: Consultant): Promise<void> {
  try {
    await consultantService.update(consultant.id, {
      status: 'inactive',
      notes: consultant.notes ? `${consultant.notes} [ARCHIVED: ${new Date().toISOString()}]` : `[ARCHIVED: ${new Date().toISOString()}]`
    })
    
    showToast.success(
      "Consultant Archived",
      `${consultant.name} has been archived`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to archive consultant'
    showToast.error("Archive Failed", message)
    throw error
  }
}

async function deleteConsultant(consultant: Consultant): Promise<void> {
  try {
    await consultantService.delete(consultant.id)
    
    showToast.success(
      "Consultant Deleted",
      `${consultant.name} has been permanently deleted`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete consultant'
    showToast.error("Delete Failed", message)
    throw error
  }
}

// Bulk action implementations
async function bulkUpdateConsultantStatus(consultants: Consultant[], status: Consultant["status"]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const consultant of consultants) {
    try {
      await consultantService.update(consultant.id, { status })
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to update status for consultant ${consultant.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Bulk Update Complete",
      `Successfully updated ${successCount} consultant${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Updates Failed",
      `${errorCount} consultant${errorCount === 1 ? '' : 's'} could not be updated`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to update any consultants")
  }
}

async function bulkVerifyConsultants(consultants: Consultant[]): Promise<void> {
  const unverifiedConsultants = consultants.filter(consultant => !consultant.isVerified)
  
  if (unverifiedConsultants.length === 0) {
    showToast.info("No Action Needed", "All selected consultants are already verified")
    return
  }
  
  let successCount = 0
  let errorCount = 0

  for (const consultant of unverifiedConsultants) {
    try {
      await consultantService.update(consultant.id, { isVerified: true })
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to verify consultant ${consultant.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Verification Complete",
      `Successfully verified ${successCount} consultant${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Verifications Failed",
      `${errorCount} consultant${errorCount === 1 ? '' : 's'} could not be verified`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to verify any consultants")
  }
}

async function bulkSendWelcomeEmails(consultants: Consultant[]): Promise<void> {
  const activeConsultants = consultants.filter(consultant => consultant.status === 'active')
  
  if (activeConsultants.length === 0) {
    showToast.info("No Action Needed", "No active consultants selected")
    return
  }
  
  let successCount = 0
  let errorCount = 0

  for (const consultant of activeConsultants) {
    try {
      // Simulate sending welcome email
      // In real implementation, this would call your email service
      console.log(`Sending welcome email to ${consultant.email}`)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to send welcome email to ${consultant.email}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Welcome Emails Sent",
      `Successfully sent ${successCount} welcome email${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Emails Failed",
      `${errorCount} welcome email${errorCount === 1 ? '' : 's'} could not be sent`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to send any welcome emails")
  }
}

async function exportConsultants(consultants: Consultant[]): Promise<void> {
  try {
    const csvContent = convertConsultantsToCSV(consultants)
    downloadCSV(csvContent, 'selected-consultants.csv')
    
    showToast.success(
      "Export Complete",
      `Exported ${consultants.length} consultant${consultants.length === 1 ? '' : 's'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to export consultants'
    showToast.error("Export Failed", message)
    throw error
  }
}

// Utility functions
function convertConsultantsToCSV(consultants: Consultant[]): string {
  const headers = [
    'Name',
    'Email',
    'Phone',
    'Specialty',
    'Organization',
    'City',
    'Country',
    'Status',
    'Verified',
    'Rating',
    'Total Consultations',
    'Years of Experience',
    'License Number',
    'Created'
  ]
  
  const rows = consultants.map(consultant => [
    consultant.name,
    consultant.email,
    consultant.phone,
    consultant.specialty,
    consultant.organization || '',
    consultant.city || '',
    consultant.country,
    consultant.status,
    consultant.isVerified ? 'Yes' : 'No',
    consultant.rating?.toString() || '',
    consultant.totalConsultations?.toString() || '',
    consultant.yearsOfExperience?.toString() || '',
    consultant.licenseNumber || '',
    consultant.created
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
