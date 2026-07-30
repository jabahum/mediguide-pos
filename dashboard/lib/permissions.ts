/**
 * Permission Management System
 * Core utilities for AccessControl integration with backend roles
 */

import { AccessControl, Permission } from 'accesscontrol'
import type {
  PermissionGrant,
  RolePermissions,
  PermissionCheck,
  EffectivePermissions,
  PermissionAction,
  PermissionValidationResult
} from '@/types/permissions'
import { SYSTEM_RESOURCES, PERMISSION_TEMPLATES } from '@/types/permissions'

/**
 * Permission Service Class
 * Manages AccessControl instance and provides utilities for permission management
 */
export class PermissionService {
  private ac: AccessControl
  private initialized: boolean = false

  constructor() {
    this.ac = new AccessControl()
  }

  /**
   * Initialize AccessControl with role permissions from database
   */
  async initialize(rolePermissions: Record<string, RolePermissions>): Promise<void> {
    try {
      // Clear existing grants
      this.ac = new AccessControl()

      // Convert role permissions to AccessControl grants
      const grants: PermissionGrant[] = []

      for (const [roleKey, permissions] of Object.entries(rolePermissions)) {
        for (const [resource, actions] of Object.entries(permissions)) {
          // Skip wildcard resources - we'll handle them separately
          if (resource === '*') {
            // For wildcard permissions, apply to all known resources
            for (const knownResource of Object.keys(SYSTEM_RESOURCES)) {
              for (const [action, attributes] of Object.entries(actions)) {
                grants.push({
                  role: roleKey,
                  resource: knownResource,
                  action: action as PermissionAction,
                  attributes: Array.isArray(attributes) ? attributes : [attributes]
                })
              }
            }
          } else {
            // Normal resource handling
            for (const [action, attributes] of Object.entries(actions)) {
              grants.push({
                role: roleKey,
                resource,
                action: action as PermissionAction,
                attributes: Array.isArray(attributes) ? attributes : [attributes]
              })
            }
          }
        }
      }

      // Set grants in AccessControl
      if (grants.length > 0) {
        this.ac.setGrants(grants)
      }

      this.initialized = true
    } catch (error) {
      console.error('Failed to initialize permission service:', error)
      throw new Error('Permission service initialization failed')
    }
  }

  /**
   * Check if a role has permission for a specific action on a resource
   */
  can(role: string, action: PermissionAction, resource: string): PermissionCheck {
    if (!this.initialized) {
      console.warn('Permission service not initialized')
      return { granted: false, attributes: [], filter: (data) => data }
    }

    // Role with no grants is a valid state (deny all), not an error
    if (!this.ac.getGrants()[role]) {
      return { granted: false, attributes: [], filter: (data) => data }
    }

    try {
      const query = this.ac.can(role)
      let permission: Permission

      // Use proper method names based on action
      switch (action) {
        case 'create:own':
          permission = query.createOwn(resource)
          break
        case 'create:any':
          permission = query.createAny(resource)
          break
        case 'read:own':
          permission = query.readOwn(resource)
          break
        case 'read:any':
          permission = query.readAny(resource)
          break
        case 'update:own':
          permission = query.updateOwn(resource)
          break
        case 'update:any':
          permission = query.updateAny(resource)
          break
        case 'delete:own':
          permission = query.deleteOwn(resource)
          break
        case 'delete:any':
          permission = query.deleteAny(resource)
          break
        default:
          return { granted: false, attributes: [], filter: (data) => data }
      }

      return {
        granted: permission.granted,
        attributes: permission.attributes,
        filter: (data) => permission.granted ? permission.filter(data) : {}
      }
    } catch (error) {
      console.error(`Permission check failed for ${role}:${action}:${resource}`, error)
      return { granted: false, attributes: [], filter: (data) => data }
    }
  }

  /**
   * Get effective permissions for a role across all resources
   */
  getEffectivePermissions(role: string): EffectivePermissions {
    const effective: EffectivePermissions = {}

    for (const resourceKey of Object.keys(SYSTEM_RESOURCES)) {
      effective[resourceKey] = {}

      for (const action of this.getValidActions()) {
        const permission = this.can(role, action, resourceKey)
        effective[resourceKey][action] = {
          granted: permission.granted,
          attributes: permission.attributes,
          source: role
        }
      }
    }

    return effective
  }

  /**
   * Grant permission to a role
   */
  grant(role: string, resource: string, action: PermissionAction, attributes: string[] = ['*']): this {
    try {
      const query = this.ac.grant(role)

      // Use proper method names based on action
      switch (action) {
        case 'create:own':
          query.createOwn(resource, attributes)
          break
        case 'create:any':
          query.createAny(resource, attributes)
          break
        case 'read:own':
          query.readOwn(resource, attributes)
          break
        case 'read:any':
          query.readAny(resource, attributes)
          break
        case 'update:own':
          query.updateOwn(resource, attributes)
          break
        case 'update:any':
          query.updateAny(resource, attributes)
          break
        case 'delete:own':
          query.deleteOwn(resource, attributes)
          break
        case 'delete:any':
          query.deleteAny(resource, attributes)
          break
      }

      return this
    } catch (error) {
      console.error(`Failed to grant permission ${role}:${action}:${resource}`, error)
      return this
    }
  }

  /**
   * Deny/revoke permission from a role
   */
  deny(role: string, resource: string, action: PermissionAction): this {
    try {
      const query = this.ac.deny(role)

      // Use proper method names based on action
      switch (action) {
        case 'create:own':
          query.createOwn(resource)
          break
        case 'create:any':
          query.createAny(resource)
          break
        case 'read:own':
          query.readOwn(resource)
          break
        case 'read:any':
          query.readAny(resource)
          break
        case 'update:own':
          query.updateOwn(resource)
          break
        case 'update:any':
          query.updateAny(resource)
          break
        case 'delete:own':
          query.deleteOwn(resource)
          break
        case 'delete:any':
          query.deleteAny(resource)
          break
      }

      return this
    } catch (error) {
      console.error(`Failed to deny permission ${role}:${action}:${resource}`, error)
      return this
    }
  }

  /**
   * Get all grants in AccessControl format
   */
  getGrants(): Record<string, unknown> {
    return this.ac.getGrants()
  }

  /**
   * Convert grants back to role permissions format for database storage
   */
  getRolePermissions(): Record<string, RolePermissions> {
    const grants = this.getGrants()
    const rolePermissions: Record<string, RolePermissions> = {}

    for (const [role, resources] of Object.entries(grants)) {
      rolePermissions[role] = {}

      for (const [resource, actions] of Object.entries(resources as Record<string, unknown>)) {
        rolePermissions[role][resource] = {}

        for (const [action, attributes] of Object.entries(actions as Record<string, unknown>)) {
          rolePermissions[role][resource][action] = attributes as string[]
        }
      }
    }

    return rolePermissions
  }

  /**
   * Validate role permissions structure
   */
  validatePermissions(permissions: RolePermissions): PermissionValidationResult {
    const result: PermissionValidationResult = {
      isValid: true,
      errors: [],
      warnings: []
    }

    try {
      for (const [resource, actions] of Object.entries(permissions)) {
        // Check if resource exists (allow wildcard for templates)
        if (resource !== '*' && !SYSTEM_RESOURCES[resource]) {
          result.warnings.push(`Unknown resource: ${resource}. Available resources: ${Object.keys(SYSTEM_RESOURCES).join(', ')}`)
        }

        for (const [action, attributes] of Object.entries(actions)) {
          // Check if action is valid
          if (!this.isValidAction(action as PermissionAction)) {
            result.errors.push(`Invalid action: ${action} for resource ${resource}. Valid actions: ${this.getValidActions().join(', ')}`)
            result.isValid = false
          }

          // Check attributes format
          if (!Array.isArray(attributes) && typeof attributes !== 'string') {
            result.errors.push(`Invalid attributes format for ${resource}:${action}. Must be string or array of strings.`)
            result.isValid = false
          }

          // Validate attribute values
          if (Array.isArray(attributes)) {
            for (const attr of attributes) {
              if (typeof attr !== 'string') {
                result.errors.push(`Invalid attribute value for ${resource}:${action}. All attributes must be strings.`)
                result.isValid = false
                break
              }
            }
          }
        }
      }
    } catch (error) {
      result.errors.push(`Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`)
      result.isValid = false
    }

    return result
  }

  /**
   * Apply permission template to role
   */
  applyTemplate(roleKey: string, templateKey: string): PermissionGrant[] {
    const template = PERMISSION_TEMPLATES[templateKey]
    if (!template) {
      throw new Error(`Permission template not found: ${templateKey}`)
    }

    // Clear existing permissions for this role
    this.clearRolePermissions(roleKey)

    // Apply template permissions
    const appliedGrants: PermissionGrant[] = []
    for (const grant of template) {
      const updatedGrant = { ...grant, role: roleKey }
      this.grant(roleKey, grant.resource, grant.action,
        Array.isArray(grant.attributes) ? grant.attributes : [grant.attributes])
      appliedGrants.push(updatedGrant)
    }

    return appliedGrants
  }

  /**
   * Clear all permissions for a role
   */
  clearRolePermissions(role: string): void {
    try {
      const grants = this.getGrants()
      if (grants[role]) {
        delete grants[role]
        this.ac.setGrants(grants)
      }
    } catch (error) {
      console.error(`Failed to clear permissions for role ${role}:`, error)
    }
  }

  /**
   * Get roles that have permission for a specific resource/action
   */
  getRolesWithPermission(resource: string, action: PermissionAction): string[] {
    const grants = this.getGrants()
    const rolesWithPermission: string[] = []

    for (const role of Object.keys(grants)) {
      if (this.can(role, action, resource).granted) {
        rolesWithPermission.push(role)
      }
    }

    return rolesWithPermission
  }

  // Private helper methods

  private isValidAction(action: PermissionAction): boolean {
    const validActions: PermissionAction[] = [
      'create:own', 'create:any',
      'read:own', 'read:any',
      'update:own', 'update:any',
      'delete:own', 'delete:any'
    ]
    return validActions.includes(action)
  }

  private getValidActions(): PermissionAction[] {
    return [
      'create:own', 'create:any',
      'read:own', 'read:any',
      'update:own', 'update:any',
      'delete:own', 'delete:any'
    ]
  }
}

// Global permission service instance
export const permissionService = new PermissionService()

function permissionGrantsToRolePermissions(grants: PermissionGrant[]): RolePermissions {
  const permissions: RolePermissions = {}

  for (const grant of grants) {
    if (!permissions[grant.resource]) {
      permissions[grant.resource] = {}
    }

    permissions[grant.resource][grant.action] = Array.isArray(grant.attributes)
      ? grant.attributes
      : [grant.attributes]
  }

  return permissions
}

/**
 * Utility Functions
 */

/**
 * Convert database permissions JSON to RolePermissions format
 */
export function parsePermissionsFromDatabase(permissionsJson: unknown): RolePermissions {
  if (!permissionsJson) {
    return {}
  }

  try {
    if (typeof permissionsJson === 'string') {
      const parsed = JSON.parse(permissionsJson)
      return parsed && typeof parsed === 'object' ? parsed as RolePermissions : {}
    }

    if (Array.isArray(permissionsJson)) {
      return permissionGrantsToRolePermissions(permissionsJson as PermissionGrant[])
    }

    if (typeof permissionsJson !== 'object') {
      return {}
    }

    return permissionsJson as RolePermissions
  } catch (error) {
    console.error('Failed to parse permissions from database:', error)
    return {}
  }
}

export function getTemplatePermissions(roleKey: string): RolePermissions {
  const template = PERMISSION_TEMPLATES[roleKey]
  if (!template) {
    return {}
  }

  return permissionGrantsToRolePermissions(template)
}

/**
 * Convert RolePermissions to database-storable JSON
 */
export function serializePermissionsForDatabase(permissions: RolePermissions): Record<string, unknown> {
  return JSON.parse(JSON.stringify(permissions))
}

/**
 * Merge multiple permission sets (for role inheritance)
 */
export function mergePermissions(
  basePermissions: RolePermissions,
  ...additionalPermissions: RolePermissions[]
): RolePermissions {
  const merged: RolePermissions = JSON.parse(JSON.stringify(basePermissions))

  for (const permissions of additionalPermissions) {
    for (const [resource, actions] of Object.entries(permissions)) {
      if (!merged[resource]) {
        merged[resource] = {}
      }

      for (const [action, attributes] of Object.entries(actions)) {
        // For now, later permissions override earlier ones
        // In future, could implement more sophisticated merging logic
        merged[resource][action] = attributes
      }
    }
  }

  return merged
}

/**
 * Get human-readable permission summary
 */
export function getPermissionSummary(permissions: RolePermissions): string[] {
  const summary: string[] = []

  for (const [resource, actions] of Object.entries(permissions)) {
    const resourceName = SYSTEM_RESOURCES[resource]?.name || resource
    const actionList = Object.keys(actions).join(', ')
    summary.push(`${resourceName}: ${actionList}`)
  }

  return summary
}

/**
 * Filter data based on permission attributes
 */
export function filterDataByPermission(
  data: unknown,
  attributes: string[],
  isArray: boolean = false
): unknown {
  if (attributes.includes('*')) {
    // Remove denied attributes (those starting with '!')
    const deniedAttrs = attributes
      .filter(attr => attr.startsWith('!'))
      .map(attr => attr.substring(1))

    if (deniedAttrs.length === 0) {
      return data // No restrictions
    }

    if (isArray && Array.isArray(data)) {
      return data.map(item => filterObject(item, deniedAttrs, false))
    } else {
      return filterObject(data, deniedAttrs, false)
    }
  } else {
    // Only include allowed attributes
    const allowedAttrs = attributes.filter(attr => !attr.startsWith('!'))

    if (isArray && Array.isArray(data)) {
      return data.map(item => filterObject(item, allowedAttrs, true))
    } else {
      return filterObject(data, allowedAttrs, true)
    }
  }
}

function filterObject(obj: unknown, attrs: string[], whitelist: boolean): unknown {
  if (!obj || typeof obj !== 'object') return obj

  const objRecord = obj as Record<string, unknown>
  const result: Record<string, unknown> = {}

  if (whitelist) {
    // Only include specified attributes
    for (const attr of attrs) {
      if (attr in objRecord) {
        result[attr] = objRecord[attr]
      }
    }
  } else {
    // Include all except denied attributes
    for (const [key, value] of Object.entries(objRecord)) {
      if (!attrs.includes(key)) {
        result[key] = value
      }
    }
  }

  return result
}
