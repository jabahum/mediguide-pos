"use client"

import { 
  User, 
  Edit, 
  Trash2, 
  Shield, 
  Key, 
  Mail, 
  Archive, 
  Download,
} from "lucide-react"

import { usersService } from "@/services/user-management.service"
import { showToast } from "@/lib/toast"
import { RowAction, BulkAction } from "@/types/data-table"
import { User as UserType } from "./columns"

// Factory function to create user row actions with navigation
export const createUserRowActions = (navigate: (path: string) => void): RowAction<UserType>[] => [
  {
    id: "view",
    label: "View Profile",
    icon: User,
    onClick: async (user) => {
      // Navigate to user profile page using Next.js router
      navigate(`/users/${user.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit User",
    icon: Edit,
    onClick: async (user) => {
      // Navigate to edit user page using Next.js router
      navigate(`/users/${user.id}/edit`)
    },
  },
  {
    id: "toggle-status",
    label: "Toggle Status",
    icon: Shield,
    onClick: async (user) => {
      await toggleUserStatus(user)
    },
  },
  {
    id: "reset-password",
    label: "Reset Password",
    icon: Key,
    onClick: async (user) => {
      await resetUserPassword(user)
    },
  },
  {
    id: "send-verification",
    label: "Mark as Verified",
    icon: Mail,
    onClick: async (user) => {
      await sendVerificationEmail(user)
    },
    disabled: (user) => user.verified,
  },
  {
    id: "archive",
    label: "Archive User",
    icon: Archive,
    onClick: async (user) => {
      await archiveUser(user)
    },
    disabled: (user) => user.status === 'active',
    separator: true,
  },
  {
    id: "delete",
    label: "Delete User",
    icon: Trash2,
    variant: "destructive",
    onClick: async (user) => {
      await deleteUser(user)
    },
    disabled: (user) => user.status === 'active',
    confirmMessage: "Are you sure you want to delete this user? This action cannot be undone.",
  },
]

// Backward compatibility - will be deprecated
export const userRowActions: RowAction<UserType>[] = createUserRowActions((path) => {
  // Fallback to window.location for components not yet updated
  window.location.href = path
})

// Bulk actions for multiple users - focused on administrative tasks
export const userBulkActions: BulkAction<UserType>[] = [
  {
    id: "bulk-enable",
    label: "Enable Selected Users",
    icon: Shield,
    variant: "outline",
    onClick: async (users) => {
      await bulkUpdateUserStatus(users, 'active')
    },
    disabled: (users) => users.every(user => user.status === 'active'),
    description: "Activate selected users to allow system access",
  },
  {
    id: "bulk-disable",
    label: "Disable Selected Users",
    icon: Shield,
    variant: "outline",
    onClick: async (users) => {
      await bulkUpdateUserStatus(users, 'inactive')
    },
    disabled: (users) => users.every(user => user.status === 'inactive'),
    requiresConfirmation: true,
    confirmMessage: "Are you sure you want to disable these users? They will lose access to the system.",
    description: "Temporarily disable access for selected users",
  },
  {
    id: "bulk-send-verification",
    label: "Mark Selected as Verified",
    icon: Mail,
    variant: "outline",
    onClick: async (users) => {
      await bulkSendVerificationEmails(users)
    },
    disabled: (users) => users.every(user => user.verified),
    description: "Administratively verify the selected user accounts",
  },
  {
    id: "bulk-export",
    label: "Export Selected Users",
    icon: Download,
    variant: "outline",
    onClick: async (users) => {
      await exportUsers(users)
    },
    description: "Download selected users data as CSV",
  },
]

// Action implementations
async function toggleUserStatus(user: UserType): Promise<void> {
  try {
    const newStatus = user.status === 'active' ? 'inactive' : 'active'
    await usersService.update(user.id, { status: newStatus })
    
    showToast.success(
      "Status Updated",
      `User ${user.name} has been ${newStatus === 'active' ? 'activated' : 'deactivated'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update user status'
    showToast.error("Update Failed", message)
    throw error
  }
}

async function resetUserPassword(user: UserType): Promise<void> {
  try {
    const result = await usersService.requestPasswordReset(user.email)
    if (result.delivery_accepted) {
      showToast.success("Reset Requested", `The reset provider accepted a message for ${user.email}`)
    } else if (result.development_token) {
      showToast.info("Development Reset Token", result.development_token)
    } else {
      showToast.info(
        "Reset Requested",
        "No email provider is configured. The request was accepted, but no message was sent."
      )
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to reset password'
    showToast.error("Reset Failed", message)
    throw error
  }
}

async function sendVerificationEmail(user: UserType): Promise<void> {
  try {
    await usersService.verify(user.id)
    
    showToast.success(
      "User Verified",
      `${user.name} has been marked as verified`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to send verification email'
    showToast.error("Send Failed", message)
    throw error
  }
}

async function archiveUser(user: UserType): Promise<void> {
  try {
    await usersService.update(user.id, {
      status: 'archived',
      archivedAt: new Date().toISOString()
    })
    
    showToast.success(
      "User Archived",
      `${user.name} has been archived`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to archive user'
    showToast.error("Archive Failed", message)
    throw error
  }
}

async function deleteUser(user: UserType): Promise<void> {
  try {
    await usersService.delete(user.id)
    
    showToast.success(
      "User Deleted",
      `${user.name} has been permanently deleted`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete user'
    showToast.error("Delete Failed", message)
    throw error
  }
}

// Bulk action implementations
async function bulkUpdateUserStatus(users: UserType[], status: string): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const user of users) {
    try {
      await usersService.update(user.id, { status })
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to update status for user ${user.name}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Bulk Update Complete",
      `Successfully updated ${successCount} user${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Updates Failed",
      `${errorCount} user${errorCount === 1 ? '' : 's'} could not be updated`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to update any users")
  }
}

async function exportUsers(users: UserType[]): Promise<void> {
  try {
    const csvContent = convertUsersToCSV(users)
    downloadCSV(csvContent, 'selected-users.csv')
    
    showToast.success(
      "Export Complete",
      `Exported ${users.length} user${users.length === 1 ? '' : 's'}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to export users'
    showToast.error("Export Failed", message)
    throw error
  }
}

async function bulkSendVerificationEmails(users: UserType[]): Promise<void> {
  const unverifiedUsers = users.filter(user => !user.verified)
  
  if (unverifiedUsers.length === 0) {
    showToast.info("No Action Needed", "All selected users are already verified")
    return
  }
  
  let successCount = 0
  let errorCount = 0

  for (const user of unverifiedUsers) {
    try {
      await usersService.verify(user.id)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to verify ${user.email}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Users Verified",
      `Successfully verified ${successCount} user${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Verifications Failed",
      `${errorCount} user${errorCount === 1 ? '' : 's'} could not be verified`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to verify any users")
  }
}

function convertUsersToCSV(users: UserType[]): string {
  const headers = [
    'Name',
    'Email',
    'Role',
    'Status', 
    'City',
    'Verified',
    'Created',
    'Updated'
  ]
  
  const rows = users.map(user => [
    user.name,
    user.email,
    user.role || '',
    user.status,
    user.city || '',
    user.verified ? 'Yes' : 'No',
    user.created,
    user.updated || ''
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
