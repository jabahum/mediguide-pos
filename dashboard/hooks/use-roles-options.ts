"use client"

import { useState, useEffect, useMemo } from "react"
import { getBackendClient } from "@/lib/backend-client"
import { RolesResponse } from "@/types/backend-types"

export interface RoleOption {
  label: string
  value: string
}

interface UseRoleOptionsReturn {
  roleOptions: RoleOption[]
  loading: boolean
  error: Error | null
  refetch: () => void
}

/**
 * Hook to fetch active roles from the backend for use in dropdowns and forms
 */
export function useRoleOptions(): UseRoleOptionsReturn {
  const [roles, setRoles] = useState<RolesResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const pb = useMemo(() => getBackendClient(), [])

  const fetchRoles = async () => {
    try {
      setLoading(true)
      setError(null)

      // Fetch only active roles, sorted by name
      const rolesList = await pb.collection('roles').getFullList<RolesResponse>({
        filter: 'isActive = true',
        sort: 'name',
      })

      setRoles(rolesList)
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to fetch roles')
      setError(error)
      console.error('Failed to fetch roles for options:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchRoles()
  }, [])

  // Convert roles to options format
  const roleOptions: RoleOption[] = useMemo(() => 
    roles.map(role => ({
      label: role.name,
      value: role.key,
    })),
    [roles]
  )

  return {
    roleOptions,
    loading,
    error,
    refetch: fetchRoles,
  }
}

/**
 * Validate if a role key exists in the current active roles
 */
export function useRoleValidation() {
  const { roleOptions } = useRoleOptions()
  
  const validateRoleKey = (key: string): boolean => {
    return roleOptions.some(role => role.value === key)
  }

  const getRoleLabel = (key: string): string => {
    const role = roleOptions.find(role => role.value === key)
    return role?.label || key
  }

  return {
    validateRoleKey,
    getRoleLabel,
    availableRoles: roleOptions,
  }
}
