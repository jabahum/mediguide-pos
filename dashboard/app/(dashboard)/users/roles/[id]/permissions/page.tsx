/**
 * Role Permissions Management Page
 * Dedicated page for managing role permissions with AccessControl integration
 */

"use client"

import * as React from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Save, RotateCcw, AlertTriangle, CheckCircle } from 'lucide-react'

import { PageHeader } from '@/components/ui/page-header'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
// import { Button } from '@/components/ui/button'
// import { Separator } from '@/components/ui/separator'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

import { PermissionBuilder } from '@/components/ui/permission-builder'
import { PermissionPreview } from '@/components/ui/permission-preview'
import { showToast } from '@/lib/toast'
import { getBackendClient } from '@/lib/backend-client'
import { useRolePermissionManagement } from '@/hooks/use-permissions'
import { usePermissionContext } from '@/lib/permission-context'

import type { RolesResponse } from '@/types/backend-types'
import type { RolePermissions, PermissionValidationResult } from '@/types/permissions'

export default function RolePermissionsPage() {
  const params = useParams()
  const router = useRouter()
  const roleId = params.id as string
  const { hasPermission, loading: permLoading } = usePermissionContext()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("roles", "read:any")) {
      router.replace("/users/roles")
    }
  }, [permLoading, hasPermission, router])

  // Role data state
  const [role, setRole] = React.useState<RolesResponse | null>(null)
  const [roleLoading, setRoleLoading] = React.useState(true)
  const [roleError, setRoleError] = React.useState<string | null>(null)

  // Permission management
  const {
    rolePermissions,
    updateRolePermissions,
    applyPermissionTemplate,
    validatePermissions,
    getEffectivePermissions,
    error: permissionError,
    initialized
  } = useRolePermissionManagement(roleId)

  // Local permission state for editing
  const [editingPermissions, setEditingPermissions] = React.useState<RolePermissions>({})
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState(false)
  const [validationResult, setValidationResult] = React.useState<PermissionValidationResult | null>(null)
  const [saving, setSaving] = React.useState(false)

  // Load role data
  React.useEffect(() => {
    const loadRole = async () => {
      if (!roleId) return

      try {
        setRoleLoading(true)
        setRoleError(null)

        const pb = getBackendClient()
        const roleData = await pb.collection('roles').getOne<RolesResponse>(roleId)
        setRole(roleData)

      } catch (error) {
        console.error('Failed to load role:', error)
        const errorMessage = error instanceof Error ? error.message : 'Failed to load role'
        setRoleError(errorMessage)
        showToast.error('Load Failed', errorMessage)
      } finally {
        setRoleLoading(false)
      }
    }

    loadRole()
  }, [roleId])

  // Sync editing permissions with loaded permissions
  React.useEffect(() => {
    if (rolePermissions && !hasUnsavedChanges) {
      setEditingPermissions(JSON.parse(JSON.stringify(rolePermissions)))
    }
  }, [rolePermissions, hasUnsavedChanges])

  // Validate permissions on change
  React.useEffect(() => {
    if (Object.keys(editingPermissions).length > 0) {
      const result = validatePermissions(editingPermissions)
      setValidationResult(result as PermissionValidationResult)
    }
  }, [editingPermissions, validatePermissions])

  // Track unsaved changes
  React.useEffect(() => {
    const hasChanges = JSON.stringify(editingPermissions) !== JSON.stringify(rolePermissions)
    setHasUnsavedChanges(hasChanges)
  }, [editingPermissions, rolePermissions])

  // Handle permission changes
  const handlePermissionsChange = React.useCallback((newPermissions: RolePermissions) => {
    setEditingPermissions(newPermissions)
  }, [])

  // Handle template application
  const handleApplyTemplate = React.useCallback(async (templateKey: string) => {
    try {
      const result = await applyPermissionTemplate(roleId, templateKey)
      if (result.success) {
        // Reload permissions to get the new template
        setHasUnsavedChanges(false)
      }
    } catch (error) {
      console.error('Failed to apply template:', error)
    }
  }, [applyPermissionTemplate, roleId])

  // Handle save
  const handleSave = React.useCallback(async () => {
    if (!validationResult?.isValid) {
      showToast.error('Validation Failed', 'Please fix validation errors before saving')
      return
    }

    try {
      setSaving(true)
      const result = await updateRolePermissions(roleId, editingPermissions)

      if (result.success) {
        setHasUnsavedChanges(false)
        showToast.success('Success', 'Role permissions updated successfully')
      }
    } catch (error) {
      console.error('Failed to save permissions:', error)
    } finally {
      setSaving(false)
    }
  }, [roleId, editingPermissions, updateRolePermissions, validationResult])

  // Handle reset
  const handleReset = React.useCallback(() => {
    if (rolePermissions) {
      setEditingPermissions(JSON.parse(JSON.stringify(rolePermissions)))
      setHasUnsavedChanges(false)
    }
  }, [rolePermissions])

  // Handle back navigation
  const handleBack = React.useCallback(() => {
    if (hasUnsavedChanges) {
      if (window.confirm('You have unsaved changes. Are you sure you want to leave?')) {
        router.push('/users/roles')
      }
    } else {
      router.push('/users/roles')
    }
  }, [router, hasUnsavedChanges])

  // Loading state
  if (roleLoading || !initialized) {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-start">
          <div className="space-y-2">
            <Skeleton className="h-8 w-64" />
            <Skeleton className="h-4 w-96" />
          </div>
          <div className="flex space-x-2">
            <Skeleton className="h-9 w-20" />
            <Skeleton className="h-9 w-28" />
          </div>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <Skeleton className="h-6 w-48" />
            </CardHeader>
            <CardContent className="space-y-4">
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-32 w-full" />
            </CardContent>
          </Card>
        </div>
      </div>
    )
  }

  // Error state
  if (roleError || permissionError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Permission Management"
          description="Role permissions could not be loaded"
          showBackButton={true}
          onBack={handleBack}
        />

        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Error</AlertTitle>
          <AlertDescription>
            {roleError || permissionError?.message || 'An unexpected error occurred'}
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  // No role found
  if (!role) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Permission Management"
          description="Role not found"
          showBackButton={true}
          onBack={handleBack}
        />

        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Role Not Found</AlertTitle>
          <AlertDescription>
            The requested role could not be found or you don&apos;t have permission to access it.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  const effectivePermissions = role?.key ? getEffectivePermissions(role.key) : undefined

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title={`Manage Permissions: ${role.name}`}
        description={`Configure access control and permissions for the ${role.name} role`}
        showBackButton={true}
        onBack={handleBack}
        actions={[
          {
            label: "Reset Changes",
            onClick: handleReset,
            variant: "outline",
            disabled: !hasUnsavedChanges || saving,
            icon: <RotateCcw className="h-4 w-4" />
          },
          {
            label: saving ? "Saving..." : "Save Changes",
            onClick: handleSave,
            disabled: !hasUnsavedChanges || saving || !validationResult?.isValid,
            icon: <Save className="h-4 w-4" />
          }
        ]}
      />

      {/* Unsaved Changes Warning */}
      {hasUnsavedChanges && (
        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Unsaved Changes</AlertTitle>
          <AlertDescription>
            You have unsaved permission changes. Don&apos;t forget to save your work.
          </AlertDescription>
        </Alert>
      )}

      {/* Validation Errors */}
      {validationResult && !validationResult.isValid && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Validation Errors</AlertTitle>
          <AlertDescription>
            <ul className="list-disc list-inside space-y-1">
              {validationResult.errors.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      {/* Validation Warnings */}
      {validationResult && validationResult.warnings.length > 0 && (
        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Warnings</AlertTitle>
          <AlertDescription>
            <ul className="list-disc list-inside space-y-1">
              {validationResult.warnings.map((warning, index) => (
                <li key={index}>{warning}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      {/* Role Info Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>Role Information</span>
            <div className="flex items-center gap-2">
              {role.isActive ? (
                <>
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  <span className="text-sm text-green-600">Active</span>
                </>
              ) : (
                <>
                  <AlertTriangle className="h-4 w-4 text-orange-600" />
                  <span className="text-sm text-orange-600">Inactive</span>
                </>
              )}
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div>
              <strong>Role Key:</strong>
              <code className="ml-2 px-2 py-1 bg-muted rounded text-xs">
                {role.key}
              </code>
            </div>
            <div>
              <strong>Created:</strong> {new Date(role.created).toLocaleDateString()}
            </div>
            <div>
              <strong>Updated:</strong> {new Date(role.updated).toLocaleDateString()}
            </div>
          </div>
          {role.description && (
            <div className="mt-2">
              <strong>Description:</strong> {role.description}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Permission Management Tabs */}
      <Tabs defaultValue="builder" className="space-y-4">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="builder">Permission Builder</TabsTrigger>
          <TabsTrigger value="preview">Permission Preview</TabsTrigger>
        </TabsList>

        <TabsContent value="builder" className="space-y-4">
          <PermissionBuilder
            permissions={editingPermissions}
            onChange={handlePermissionsChange}
            disabled={saving}
            showTemplates={true}
            onApplyTemplate={handleApplyTemplate}
          />
        </TabsContent>

        <TabsContent value="preview" className="space-y-4">
          <PermissionPreview
            permissions={editingPermissions}
            effectivePermissions={effectivePermissions}
            roleKey={role.key}
          />
        </TabsContent>
      </Tabs>

      {/* Help Text */}
      <Card>
        <CardHeader>
          <CardTitle>Permission Management Help</CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-muted-foreground space-y-2">
          <p>
            <strong>Resources:</strong> System components like users, roles, content, etc. that can be accessed.
          </p>
          <p>
            <strong>Actions:</strong> What can be done with resources (create, read, update, delete).
          </p>
          <p>
            <strong>Own vs Any:</strong> &quot;Own&quot; means user can only access resources they created/own, &quot;Any&quot; means access to all resources of that type.
          </p>
          <p>
            <strong>Attributes:</strong> Fine-grained control over which fields can be accessed. Use &quot;*&quot; for all fields, &quot;!field&quot; to deny specific fields.
          </p>
          <p>
            <strong>Templates:</strong> Pre-configured permission sets for common roles. Apply a template to quickly set up permissions.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}