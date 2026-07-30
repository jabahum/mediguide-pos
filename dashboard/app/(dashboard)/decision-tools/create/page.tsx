"use client"

import * as React from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DecisionToolForm } from "@/components/forms/decision-tool-form"
import { CalculatorsResponse } from "@/types/backend-types"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { getBackendClient } from "@/lib/backend-client"
import { usePermissionContext } from "@/lib/permission-context"

export default function CreateDecisionToolPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { hasPermission, loading: permLoading } = usePermissionContext()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/decision-tools")
    }
  }, [permLoading, hasPermission, router])
  const duplicateId = searchParams.get("duplicate")
  
  const [duplicateData, setDuplicateData] = React.useState<CalculatorsResponse | null>(null)
  const [loadingDuplicate, setLoadingDuplicate] = React.useState(!!duplicateId)

  const { create, loading } = useBackendCrud({
    collectionName: "calculators",
    onSuccess: () => {
      router.push("/decision-tools")
    }
  })

  // Fetch duplicate data if needed
  React.useEffect(() => {
    const fetchData = async () => {
      if (!duplicateId) {
        setLoadingDuplicate(false)
        return
      }

      try {
        const backend = getBackendClient()
        const duplicateResult = await backend.resource("calculators").getOne(duplicateId, {
          expand: "addedBy"
        }) as CalculatorsResponse
        
        setDuplicateData(duplicateResult)
      } catch (error) {
        console.error("Failed to fetch duplicate data:", error)
      } finally {
        setLoadingDuplicate(false)
      }
    }

    fetchData()
  }, [duplicateId])

  const handleSubmit = async (data: Record<string, unknown>) => {
    try {
      const backend = getBackendClient()
      const currentUser = backend.authStore.model
      
      if (!currentUser) {
        throw new Error("User not authenticated")
      }

      // Create FormData for file upload
      const formData = new FormData()
      
      // Add all form fields
      Object.keys(data).forEach(key => {
        const value = data[key]
        if (key === 'appFile' && value instanceof File) {
          // Handle file upload
          formData.append('appFile', value)
        } else if (value !== null && value !== undefined && value !== '') {
          formData.append(key, String(value))
        }
      })
      
      // Add current user as addedBy
      formData.append('addedBy', currentUser.id)

      await create(formData)
    } catch (error) {
      console.error("Failed to submit form:", error)
      throw error
    }
  }

  const handleCancel = () => {
    router.push("/decision-tools")
  }

  // Prepare initial data for duplicate mode
  const initialData = duplicateData ? {
    ...duplicateData,
    // Clear some fields that shouldn't be duplicated
    name: `${duplicateData.name} (Copy)`
  } : undefined

  const pageTitle = duplicateId 
    ? `Duplicate "${duplicateData?.name || 'Tool'}"` 
    : "Create Decision Tool"
  
  const pageDescription = duplicateId
    ? "Create a new decision tool based on an existing one"
    : "Add a new clinical calculator, decision tree, or assessment tool"

  if (loadingDuplicate) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          showBackButton={true}
          onBack={() => router.push("/decision-tools")}
        />
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading tool data...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={pageTitle}
        description={pageDescription}
        showBackButton={true}
        onBack={() => router.push("/decision-tools")}
      />

      <div className="bg-card rounded-lg border p-6">
        <DecisionToolForm
          mode="create"
          initialData={initialData}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          loading={loading}
        />
      </div>
    </div>
  )
}