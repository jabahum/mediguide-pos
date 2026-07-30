"use client"

import { useState, useEffect, useCallback } from "react"
import { showToast } from "@/lib/toast"
import { rolesService, usersService } from "@/services/user-management.service"
import { 
  Role, 
  RoleStats, 
  CreateRoleFormData, 
  EditRoleFormData, 
  RoleOperationResult,
  RoleAssignmentInfo,
  UseRolesReturn 
} from "../types"

export function useRoles(): UseRolesReturn {
  // State management
  const [roles, setRoles] = useState<Role[]>([])
  const [stats, setStats] = useState<RoleStats | null>(null)
  const [loading, setLoading] = useState({
    roles: true,
    stats: true,
    operation: false,
  })
  const [error, setError] = useState<Error | null>(null)

  // Fetch all roles
  const fetchRoles = useCallback(async () => {
    try {
      setLoading(prev => ({ ...prev, roles: true }))
      setError(null)

      const rolesList = await rolesService.all<Role>()

      setRoles(rolesList)
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to fetch roles')
      setError(error)
      showToast.error("Fetch Failed", error.message)
    } finally {
      setLoading(prev => ({ ...prev, roles: false }))
    }
  }, [])

  // Fetch role statistics
  const fetchStats = useCallback(async () => {
    try {
      setLoading(prev => ({ ...prev, stats: true }))
      
      // Get roles count
      const rolesData = await rolesService.list<Role>({ page: 1, per_page: 1 })
      const totalRoles = rolesData.total_items
      const activeRoles = roles.filter(role => role.isActive).length

      // Get users count
      const usersData = await usersService.list<{ role?: string }>({ page: 1, per_page: 1 })
      const totalUsers = usersData.total_items

      // Get most assigned role
      let mostAssignedRole: { name: string; count: number } | null = null
      
      // Count users by role
      if (roles.length > 0) {
        const roleCounts = new Map<string, number>()
        
        // Get all users with their roles
        const allUsers = await usersService.all<{ role?: string }>()
        
        allUsers.forEach(user => {
          if (!user.role) return
          const count = roleCounts.get(user.role) || 0
          roleCounts.set(user.role, count + 1)
        })

        // Find the most assigned role
        let maxCount = 0
        let topRoleKey = ""
        
        for (const [roleKey, count] of roleCounts) {
          if (count > maxCount) {
            maxCount = count
            topRoleKey = roleKey
          }
        }

        if (topRoleKey) {
          const topRole = roles.find(role => role.key === topRoleKey)
          if (topRole) {
            mostAssignedRole = {
              name: topRole.name,
              count: maxCount
            }
          }
        }
      }

      const statsData: RoleStats = {
        totalRoles,
        activeRoles,
        totalUsers,
        mostAssignedRole,
      }

      setStats(statsData)
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to fetch statistics')
      setError(error)
      console.error('Failed to fetch role statistics:', error)
    } finally {
      setLoading(prev => ({ ...prev, stats: false }))
    }
  }, [roles])

  // Create new role
  const createRole = useCallback(async (data: CreateRoleFormData & { key: string }): Promise<RoleOperationResult> => {
    try {
      setLoading(prev => ({ ...prev, operation: true }))

      // Check if role key already exists
      const existingRole = (await rolesService.all<Role>({ search: data.key }))
        .find(role => role.key === data.key)

      if (existingRole) {
        const errorMsg = `Role with key "${data.key}" already exists`
        showToast.error("Creation Failed", errorMsg)
        return { success: false, message: errorMsg }
      }

      const newRole = await rolesService.create<Role>(data)
      
      // Update local state
      setRoles(prev => [newRole, ...prev])
      
      showToast.success("Success", `Role "${data.name}" created successfully`)
      
      // Refresh stats
      fetchStats()
      
      return { success: true, role: newRole }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to create role')
      showToast.error("Creation Failed", error.message)
      return { success: false, message: error.message }
    } finally {
      setLoading(prev => ({ ...prev, operation: false }))
    }
  }, [fetchStats])

  // Update existing role
  const updateRole = useCallback(async (id: string, data: EditRoleFormData): Promise<RoleOperationResult> => {
    try {
      setLoading(prev => ({ ...prev, operation: true }))

      const updatedRole = await rolesService.update<Role>(id, data)
      
      // Update local state
      setRoles(prev => prev.map(role => 
        role.id === id ? updatedRole : role
      ))
      
      showToast.success("Success", `Role "${updatedRole.name}" updated successfully`)
      
      // Refresh stats
      fetchStats()
      
      return { success: true, role: updatedRole }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to update role')
      showToast.error("Update Failed", error.message)
      return { success: false, message: error.message }
    } finally {
      setLoading(prev => ({ ...prev, operation: false }))
    }
  }, [fetchStats])

  // Get role assignment information
  const getRoleAssignmentInfo = useCallback(async (roleId: string): Promise<RoleAssignmentInfo> => {
    try {
      const role = roles.find(r => r.id === roleId)
      if (!role) {
        throw new Error('Role not found')
      }

      // Count users assigned to this role
      const usersWithRole = (await usersService.all<{
        id: string
        name?: string
        email: string
        role?: string
      }>()).filter(user => user.role === role.key)

      const userCount = usersWithRole.length
      const canDelete = userCount === 0

      return {
        roleId,
        userCount,
        canDelete,
        affectedUsers: usersWithRole.map(user => ({
          id: user.id,
          name: user.name || user.email,
          email: user.email,
        })),
      }
    } catch (err) {
      console.error('Failed to get role assignment info:', err)
      return {
        roleId,
        userCount: 0,
        canDelete: false,
      }
    }
  }, [roles])

  // Delete role
  const deleteRole = useCallback(async (id: string): Promise<RoleOperationResult> => {
    try {
      setLoading(prev => ({ ...prev, operation: true }))

      // Check if any users are assigned to this role
      const assignmentInfo = await getRoleAssignmentInfo(id)
      
      if (!assignmentInfo.canDelete) {
        const errorMsg = `Cannot delete role. ${assignmentInfo.userCount} users are currently assigned to this role.`
        showToast.error("Delete Failed", errorMsg)
        return { success: false, message: errorMsg }
      }

      await rolesService.delete(id)
      
      // Update local state
      setRoles(prev => prev.filter(role => role.id !== id))
      
      showToast.success("Success", "Role deleted successfully")
      
      // Refresh stats
      fetchStats()
      
      return { success: true }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to delete role')
      showToast.error("Delete Failed", error.message)
      return { success: false, message: error.message }
    } finally {
      setLoading(prev => ({ ...prev, operation: false }))
    }
  }, [fetchStats, getRoleAssignmentInfo])

  // Refresh all data
  const refresh = useCallback(async () => {
    await fetchRoles()
    await fetchStats()
  }, [fetchRoles, fetchStats])

  // Utility functions
  const getRoleByKey = useCallback((key: string) => {
    return roles.find(role => role.key === key)
  }, [roles])

  const getRoleById = useCallback((id: string) => {
    return roles.find(role => role.id === id)
  }, [roles])

  // Initial data fetch
  useEffect(() => {
    fetchRoles()
  }, [fetchRoles])

  // Fetch stats when roles change
  useEffect(() => {
    if (roles.length > 0) {
      fetchStats()
    }
  }, [roles, fetchStats])

  return {
    // Data
    roles,
    stats,
    loading,
    error,

    // CRUD Operations
    createRole,
    updateRole,
    deleteRole,
    getRoleAssignmentInfo,

    // Utilities
    refresh,
    getRoleByKey,
    getRoleById,
  }
}
