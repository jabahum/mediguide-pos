/**
 * Permission Management Hook
 * React hook for managing permissions with AccessControl and backend integration
 */

import * as React from 'react'
import { getBackendClient, getUserRole } from '@/lib/backend-client'
import { showToast } from '@/lib/toast'
import { 
  permissionService,
  parsePermissionsFromDatabase,
  serializePermissionsForDatabase,
  getTemplatePermissions,
} from '@/lib/permissions'
import type { 
  RolePermissions, 
  PermissionCheck, 
  EffectivePermissions,
  PermissionAction,
  PermissionValidationResult,
  PermissionGrant
} from '@/types/permissions'
import { PERMISSION_TEMPLATES } from '@/types/permissions'
import type { RolesResponse } from '@/types/backend-types'

interface UsePermissionsReturn {
  // Permission checking
  hasPermission: (resource: string, action: PermissionAction) => boolean
  checkPermission: (resource: string, action: PermissionAction) => PermissionCheck
  getEffectivePermissions: (roleKey: string) => EffectivePermissions
  
  // Permission management
  updateRolePermissions: (roleId: string, permissions: RolePermissions) => Promise<{ success: boolean; error?: string }>
  applyPermissionTemplate: (roleId: string, templateKey: string) => Promise<{ success: boolean; error?: string }>
  validatePermissions: (permissions: RolePermissions) => PermissionValidationResult
  
  // Role management
  loadRolePermissions: (roleId: string) => Promise<RolePermissions | null>
  getRolePermissionsSummary: (roleKey: string) => string[]
  
  // State
  loading: boolean
  error: Error | null
  initialized: boolean
}

interface UsePermissionsOptions {
  currentUserRole?: string
  autoInitialize?: boolean
}

/**
 * Hook for managing permissions in React components
 */
export function usePermissions(options: UsePermissionsOptions = {}): UsePermissionsReturn {
  const { currentUserRole, autoInitialize = true } = options
  
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState<Error | null>(null)
  const [initialized, setInitialized] = React.useState(false)
  
  /**
   * Initialize permission service with all roles from database
   */
  const initializePermissions = React.useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      
      const pb = getBackendClient()
      
      // Fetch all active roles with their permissions
      const roles = await pb.collection('roles').getFullList<RolesResponse>({
        filter: 'isActive = true',
        sort: 'name'
      })
      
      // Convert role permissions to the format expected by AccessControl
      const allRolePermissions: Record<string, RolePermissions> = {}
      
      for (const role of roles) {
        const parsedPermissions = parsePermissionsFromDatabase(role.permissions)
        const permissions =
          Object.keys(parsedPermissions).length > 0
            ? parsedPermissions
            : getTemplatePermissions(role.key)
        allRolePermissions[role.key] = permissions
      }
      
      // Initialize the permission service
      await permissionService.initialize(allRolePermissions)
      setInitialized(true)
      
    } catch (err) {
      console.error('Failed to initialize permissions:', err)
      const error = err instanceof Error ? err : new Error('Failed to initialize permissions')
      setError(error)
      showToast.error('Permission Error', 'Failed to load permissions')
    } finally {
      setLoading(false)
    }
  }, [])
  
  /**
   * Check if current user has permission for an action on a resource
   */
  const hasPermission = React.useCallback((resource: string, action: PermissionAction): boolean => {
    if (!initialized || !currentUserRole) return false
    
    try {
      return permissionService.can(currentUserRole, action, resource).granted
    } catch (err) {
      console.error('Permission check failed:', err)
      return false
    }
  }, [initialized, currentUserRole])
  
  /**
   * Get detailed permission check result
   */
  const checkPermission = React.useCallback((resource: string, action: PermissionAction): PermissionCheck => {
    if (!initialized || !currentUserRole) {
      return { granted: false, attributes: [], filter: (data) => data }
    }
    
    return permissionService.can(currentUserRole, action, resource)
  }, [initialized, currentUserRole])
  
  /**
   * Get effective permissions for a role
   */
  const getEffectivePermissions = React.useCallback((roleKey: string): EffectivePermissions => {
    if (!initialized) return {}
    return permissionService.getEffectivePermissions(roleKey)
  }, [initialized])
  
  /**
   * Load permissions for a specific role from database
   */
  const loadRolePermissions = React.useCallback(async (roleId: string): Promise<RolePermissions | null> => {
    try {
      setLoading(true)
      const pb = getBackendClient()
      
      const role = await pb.collection('roles').getOne<RolesResponse>(roleId)
      const parsedPermissions = parsePermissionsFromDatabase(role.permissions)
      const permissions =
        Object.keys(parsedPermissions).length > 0
          ? parsedPermissions
          : getTemplatePermissions(role.key)
      
      return permissions
    } catch (err) {
      console.error('Failed to load role permissions:', err)
      const error = err instanceof Error ? err : new Error('Failed to load role permissions')
      setError(error)
      return null
    } finally {
      setLoading(false)
    }
  }, [])
  
  /**
   * Update permissions for a role in the database
   */
  const updateRolePermissions = React.useCallback(async (
    roleId: string, 
    permissions: RolePermissions
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      setLoading(true)
      setError(null)
      
      // Validate permissions first
      const validation = permissionService.validatePermissions(permissions)
      if (!validation.isValid) {
        return { 
          success: false, 
          error: `Validation failed: ${validation.errors.join(', ')}` 
        }
      }
      
      const pb = getBackendClient()
      
      // Serialize permissions for database storage
      const serializedPermissions = serializePermissionsForDatabase(permissions)
      
      // Update role in database
      await pb.collection('roles').update(roleId, {
        permissions: serializedPermissions
      })
      
      // Re-initialize permissions to reflect changes
      await initializePermissions()
      
      showToast.success('Success', 'Role permissions updated successfully')
      return { success: true }
      
    } catch (err) {
      console.error('Failed to update role permissions:', err)
      const error = err instanceof Error ? err : new Error('Failed to update role permissions')
      setError(error)
      
      const errorMessage = error.message
      showToast.error('Update Failed', errorMessage)
      
      return { success: false, error: errorMessage }
    } finally {
      setLoading(false)
    }
  }, [initializePermissions])
  
  /**
   * Apply a permission template to a role
   */
  const applyPermissionTemplate = React.useCallback(async (
    roleId: string, 
    templateKey: string
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      setLoading(true)
      setError(null)
      
      // Check if template exists
      if (!PERMISSION_TEMPLATES[templateKey]) {
        return { success: false, error: `Template not found: ${templateKey}` }
      }
      
      const pb = getBackendClient()
      
      // Get the role to get its key
      const role = await pb.collection('roles').getOne<RolesResponse>(roleId)
      
      // Apply template to permission service
      const grants = permissionService.applyTemplate(role.key, templateKey)
      
      // Convert grants back to role permissions format
      const permissions: RolePermissions = {}
      
      for (const grant of grants) {
        if (!permissions[grant.resource]) {
          permissions[grant.resource] = {}
        }
        permissions[grant.resource][grant.action] = Array.isArray(grant.attributes) 
          ? grant.attributes 
          : [grant.attributes]
      }
      
      // Update in database
      const result = await updateRolePermissions(roleId, permissions)
      
      if (result.success) {
        showToast.success('Success', `Applied ${templateKey} template to role`)
      }
      
      return result
      
    } catch (err) {
      console.error('Failed to apply permission template:', err)
      const error = err instanceof Error ? err : new Error('Failed to apply permission template')
      setError(error)
      
      const errorMessage = error.message
      showToast.error('Template Failed', errorMessage)
      
      return { success: false, error: errorMessage }
    } finally {
      setLoading(false)
    }
  }, [updateRolePermissions])
  
  /**
   * Validate permissions structure
   */
  const validatePermissions = React.useCallback((permissions: RolePermissions): PermissionValidationResult => {
    return permissionService.validatePermissions(permissions)
  }, [])
  
  /**
   * Get human-readable summary of role permissions
   */
  const getRolePermissionsSummary = React.useCallback((roleKey: string): string[] => {
    if (!initialized) return []
    
    const effective = permissionService.getEffectivePermissions(roleKey)
    const summary: string[] = []
    
    for (const [resource, actions] of Object.entries(effective)) {
      const grantedActions = Object.entries(actions)
        .filter(([, permission]) => permission.granted)
        .map(([action]) => action)
      
      if (grantedActions.length > 0) {
        summary.push(`${resource}: ${grantedActions.join(', ')}`)
      }
    }
    
    return summary
  }, [initialized])
  
  // Auto-initialize on mount
  React.useEffect(() => {
    if (autoInitialize && !initialized && !loading) {
      initializePermissions()
    }
  }, [autoInitialize, initialized, loading, initializePermissions])
  
  return {
    // Permission checking
    hasPermission,
    checkPermission,
    getEffectivePermissions,
    
    // Permission management
    updateRolePermissions,
    applyPermissionTemplate,
    validatePermissions,
    
    // Role management
    loadRolePermissions,
    getRolePermissionsSummary,
    
    // State
    loading,
    error,
    initialized
  }
}

/**
 * Hook specifically for the current user's permissions
 */
export function useCurrentUserPermissions() {
  // This gets the current user's role from auth context
  const currentUserRole = getUserRole() ?? undefined

  return usePermissions({
    currentUserRole,
    autoInitialize: true
  })
}

/**
 * Hook for managing a specific role's permissions
 */
export function useRolePermissionManagement(roleId: string) {
  const baseHook = usePermissions({ autoInitialize: true })
  const [rolePermissions, setRolePermissions] = React.useState<RolePermissions>({})
  const [roleLoading, setRoleLoading] = React.useState(false)
  
  const { loadRolePermissions, initialized } = baseHook

  React.useEffect(() => {
    if (roleId && initialized) {
      setRoleLoading(true)
      loadRolePermissions(roleId)
        .then(permissions => {
          if (permissions) {
            setRolePermissions(permissions)
          }
        })
        .finally(() => setRoleLoading(false))
    }
  }, [roleId, initialized, loadRolePermissions])
  
  return {
    ...baseHook,
    rolePermissions,
    setRolePermissions,
    loading: baseHook.loading || roleLoading
  }
}
