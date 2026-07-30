import { z } from "zod"
import { RolesResponse } from "@/types/backend-types"

/**
 * Role type from legacy collection API
 */
export type Role = RolesResponse

/**
 * Role statistics for dashboard
 */
export interface RoleStats {
  totalRoles: number
  activeRoles: number
  totalUsers: number
  mostAssignedRole: {
    name: string
    count: number
  } | null
}

/**
 * Role form data interfaces
 */
export interface CreateRoleFormData {
  name: string
  description?: string
  isActive?: boolean
}

export interface EditRoleFormData {
  description?: string
  isActive?: boolean
}

/**
 * Modal states
 */
export interface RoleModalStates {
  createOpen: boolean
  editOpen: boolean
  deleteOpen: boolean
  selectedRole: Role | null
}

/**
 * Validation schemas using Zod
 */
export const createRoleSchema = z.object({
  name: z.string().min(1, "Role name is required").max(100, "Role name too long"),
  description: z.string().max(500, "Description too long").optional().or(z.literal("")),
  isActive: z.boolean().default(true),
})

export const editRoleSchema = z.object({
  description: z.string().max(500, "Description too long").optional().or(z.literal("")),
  isActive: z.boolean().default(true),
})

/**
 * Role operations result types
 */
export interface RoleOperationResult {
  success: boolean
  message?: string
  role?: Role
}

/**
 * Role assignment info (for delete warnings)
 */
export interface RoleAssignmentInfo {
  roleId: string
  userCount: number
  canDelete: boolean
  affectedUsers?: Array<{
    id: string
    name: string
    email: string
  }>
}

/**
 * Utility functions
 */
export function generateRoleKey(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '') // Remove special characters
    .replace(/\s+/g, '_') // Replace spaces with underscores
    .replace(/_{2,}/g, '_') // Replace multiple underscores with single
    .replace(/^_|_$/g, '') // Remove leading/trailing underscores
    .slice(0, 50) // Limit length
}

/**
 * Hook return types
 */
export interface UseRolesReturn {
  // Data
  roles: Role[]
  stats: RoleStats | null
  loading: {
    roles: boolean
    stats: boolean
    operation: boolean
  }
  error: Error | null

  // CRUD Operations
  createRole: (data: CreateRoleFormData & { key: string }) => Promise<RoleOperationResult>
  updateRole: (id: string, data: EditRoleFormData) => Promise<RoleOperationResult>
  deleteRole: (id: string) => Promise<RoleOperationResult>
  getRoleAssignmentInfo: (roleId: string) => Promise<RoleAssignmentInfo>

  // Utilities
  refresh: () => Promise<void>
  getRoleByKey: (key: string) => Role | undefined
  getRoleById: (id: string) => Role | undefined
}