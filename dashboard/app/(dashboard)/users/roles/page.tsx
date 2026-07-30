"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"
import { usePermissionContext } from "@/lib/permission-context"

// Page-specific imports
import { columns } from "./columns"
import { createRoleRowActions } from "./role-actions"
import { rolesAvailableFields } from "./fields"
import { Role, RoleModalStates, CreateRoleFormData, EditRoleFormData } from "./types"
import { useRoles } from "./hooks/use-roles"

// Modal components
import { CreateRoleModal } from "./modals/create-role-modal"
import { EditRoleModal } from "./modals/edit-role-modal"

export default function RolesPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("roles", "read:any")) {
      router.replace("/users")
    }
  }, [permLoading, hasPermission, router])

  // Role data and operations
  const {
    loading,
    createRole,
    updateRole,
    deleteRole,
    getRoleAssignmentInfo,
  } = useRoles()

  // Modal states
  const [modalStates, setModalStates] = React.useState<RoleModalStates>({
    createOpen: false,
    editOpen: false,
    deleteOpen: false,
    selectedRole: null,
  })

  // Modal handlers
  const handleCreateRole = React.useCallback(() => {
    setModalStates(prev => ({ ...prev, createOpen: true }))
  }, [])

  const handleEditRole = React.useCallback((role: Role) => {
    setModalStates(prev => ({
      ...prev,
      editOpen: true,
      selectedRole: role,
    }))
  }, [])

  const handleDeleteRole = React.useCallback(async (role: Role) => {
    try {
      // Check if role can be deleted
      const assignmentInfo = await getRoleAssignmentInfo(role.id)
      
      if (!assignmentInfo.canDelete) {
        // Show warning - in a real app, you might show a confirmation dialog
        // with the list of affected users
        return
      }

      await deleteRole(role.id)
    } catch (error) {
      console.error('Failed to delete role:', error)
    }
  }, [deleteRole, getRoleAssignmentInfo])

  const handleToggleStatus = React.useCallback(async (role: Role) => {
    try {
      await updateRole(role.id, {
        description: role.description,
        isActive: !role.isActive,
      })
    } catch (error) {
      console.error('Failed to toggle role status:', error)
    }
  }, [updateRole])

  const handleManagePermissions = React.useCallback((role: Role) => {
    router.push(`/users/roles/${role.id}/permissions`)
  }, [router])

  // Form submission handlers
  const handleCreateSubmit = React.useCallback(async (data: CreateRoleFormData & { key: string }) => {
    const result = await createRole(data)
    if (result.success) {
      setModalStates(prev => ({ ...prev, createOpen: false }))
    }
  }, [createRole])

  const handleEditSubmit = React.useCallback(async (id: string, data: EditRoleFormData) => {
    const result = await updateRole(id, data)
    if (result.success) {
      setModalStates(prev => ({
        ...prev,
        editOpen: false,
        selectedRole: null,
      }))
    }
  }, [updateRole])

  // Create row actions with handlers
  const roleRowActions = React.useMemo(() => 
    createRoleRowActions({
      onEdit: handleEditRole,
      onDelete: handleDeleteRole,
      onToggleStatus: handleToggleStatus,
      onManagePermissions: handleManagePermissions,
    }), 
    [handleEditRole, handleDeleteRole, handleToggleStatus, handleManagePermissions]
  )


  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Roles & Permissions"
        description="Manage system roles and their permissions"
        actions={hasPermission("roles", "create:any") ? [
          {
            label: "Add Role",
            onClick: handleCreateRole,
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<Role>
        collection="roles"
        columns={columns}
        searchFields={["name", "key", "description"]}
        searchPlaceholder="Search roles by name, key, or description..."
        rowActions={roleRowActions}
        bulkActions={[]} // No bulk actions for roles
        availableFields={rolesAvailableFields}
        query={{
          sort: "-created"
        }}
        ui={{
          pageSize: 10,
          exportable: true,
        }}
        onError={(error) => console.error('Roles table error:', error)}
      />

      {/* Create Role Modal */}
      <CreateRoleModal
        open={modalStates.createOpen}
        onOpenChange={(open) => 
          setModalStates(prev => ({ ...prev, createOpen: open }))
        }
        onSubmit={handleCreateSubmit}
        loading={loading.operation}
      />

      {/* Edit Role Modal */}
      <EditRoleModal
        open={modalStates.editOpen}
        onOpenChange={(open) => 
          setModalStates(prev => ({ 
            ...prev, 
            editOpen: open,
            selectedRole: open ? prev.selectedRole : null
          }))
        }
        role={modalStates.selectedRole}
        onSubmit={handleEditSubmit}
        loading={loading.operation}
      />
    </div>
  )
}
