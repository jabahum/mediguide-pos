"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"
import { usePermissionContext } from "@/lib/permission-context"
import { createColumns, User } from "./columns"
import { createUserRowActions, userBulkActions } from "./user-actions"
import { createUsersAvailableFields } from "./fields"
import { useRoleOptions } from "@/hooks/use-roles-options"

export default function UsersPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const { roleOptions } = useRoleOptions()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("users", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])
  
  // Create columns with dynamic roles
  const columns = React.useMemo(() => createColumns(roleOptions), [roleOptions])
  
  // Create available fields with dynamic roles
  const usersAvailableFields = React.useMemo(() => createUsersAvailableFields(), [])

  // Create row actions with proper navigation
  const userRowActions = React.useMemo(() => 
    createUserRowActions((path) => router.push(path)), 
    [router]
  )

  const handleSelectionChange = React.useCallback((selectedUsers: User[]) => {
    console.log('Selected users:', selectedUsers)
  }, [])

  const handleError = React.useCallback((error: Error) => {
    console.error('Users table error:', error)
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="User Management"
        description="Manage frontline health workers and their access to the system"
        actions={hasPermission("users", "create:any") ? [
          {
            label: "Add User",
            onClick: () => router.push('/users/create'),
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<User>
        collection="users"
        columns={columns}
        searchFields={["name", "email", "phone", "organization", "jobTitle"]}
        searchPlaceholder="Search users by name, email, phone, organization, or job title..."
        rowActions={userRowActions}
        bulkActions={userBulkActions}
        availableFields={usersAvailableFields}
        query={{
          sort: "-created",
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
