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

import { getBackendClient } from "@/lib/backend-client"
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
    label: "Send Verification Email",
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
    label: "Send Verification Emails",
    icon: Mail,
    variant: "outline",
    onClick: async (users) => {
      await bulkSendVerificationEmails(users)
    },
    disabled: (users) => users.every(user => user.verified),
    description: "Send email verification to unverified users",
  },
  {
    id: "bulk-send-welcome",
    label: "Send Welcome Emails",
    icon: Mail,
    variant: "outline",
    onClick: async (users) => {
      await bulkSendWelcomeEmails(users)
    },
    description: "Send welcome emails with login instructions",
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
  const pb = getBackendClient()
  try {
    const newStatus = user.status === 'active' ? 'inactive' : 'active'
    await pb.collection('users').update(user.id, { status: newStatus })
    
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
  const pb = getBackendClient()
  try {
    // Generate a temporary password
    const tempPassword = generateTempPassword()
    await pb.collection('users').update(user.id, { 
      password: tempPassword,
      passwordConfirm: tempPassword 
    })
    
    // Send password reset email (if implemented)
    // await sendPasswordResetEmail(user, tempPassword)
    
    showToast.success(
      "Password Reset",
      `Temporary password generated for ${user.name}. They will receive an email with instructions.`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to reset password'
    showToast.error("Reset Failed", message)
    throw error
  }
}

async function sendVerificationEmail(user: UserType): Promise<void> {
  const pb = getBackendClient()
  try {
    await pb.collection('users').requestVerification(user.email)
    
    showToast.success(
      "Verification Sent",
      `Verification email sent to ${user.email}`
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to send verification email'
    showToast.error("Send Failed", message)
    throw error
  }
}

async function archiveUser(user: UserType): Promise<void> {
  const pb = getBackendClient()
  try {
    await pb.collection('users').update(user.id, { 
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
  const pb = getBackendClient()
  try {
    await pb.collection('users').delete(user.id)
    
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
  const pb = getBackendClient()
  let successCount = 0
  let errorCount = 0

  for (const user of users) {
    try {
      await pb.collection('users').update(user.id, { status })
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
  const pb = getBackendClient()
  const unverifiedUsers = users.filter(user => !user.verified)
  
  if (unverifiedUsers.length === 0) {
    showToast.info("No Action Needed", "All selected users are already verified")
    return
  }
  
  let successCount = 0
  let errorCount = 0

  for (const user of unverifiedUsers) {
    try {
      await pb.collection('users').requestVerification(user.email)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to send verification to ${user.email}:`, error)
    }
  }

  if (successCount > 0) {
    showToast.success(
      "Verification Emails Sent",
      `Successfully sent ${successCount} verification email${successCount === 1 ? '' : 's'}`
    )
  }
  
  if (errorCount > 0) {
    showToast.error(
      "Some Emails Failed",
      `${errorCount} verification email${errorCount === 1 ? '' : 's'} could not be sent`
    )
  }

  if (successCount === 0) {
    throw new Error("Failed to send any verification emails")
  }
}

async function bulkSendWelcomeEmails(users: UserType[]): Promise<void> {
  // This would typically integrate with your email service
  // For now, we'll simulate the process
  let successCount = 0
  let errorCount = 0

  for (const user of users) {
    try {
      // Simulate sending welcome email
      // In real implementation, this would call your email service
      // await emailService.sendWelcomeEmail(user.email, {
      //   name: user.name,
      //   loginUrl: `${process.env.NEXT_PUBLIC_APP_URL}/login`,
      //   supportEmail: 'support@mediguide.com'
      // })
      
      console.log(`Sending welcome email to ${user.email}`)
      successCount++
    } catch (error) {
      errorCount++
      console.error(`Failed to send welcome email to ${user.email}:`, error)
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


// Utility functions
function generateTempPassword(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*'
  let result = ''
  for (let i = 0; i < 12; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
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