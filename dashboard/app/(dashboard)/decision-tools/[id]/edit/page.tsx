"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DecisionToolForm } from "@/components/forms/decision-tool-form"
import { CalculatorsResponse, CalculatorsTypeOptions } from "@/types/backend-types"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { getBackendClient } from "@/lib/backend-client"
import { usePermissionContext } from "@/lib/permission-context"

interface DecisionToolEditPageProps {
  params: Promise<{ id: string }>
  searchParams: Promise<{ duplicate?: string }>
}

type CalculatorWithRelations = CalculatorsResponse<{
  addedBy: unknown[]
}>

export default function DecisionToolEditPage({ params, searchParams }: DecisionToolEditPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [tool, setTool] = React.useState<CalculatorWithRelations | null>(null)
  const [loadingData, setLoadingData] = React.useState(true)
  const [resolvedParams, setResolvedParams] = React.useState<{ id: string } | null>(null)
  const [resolvedSearchParams, setResolvedSearchParams] = React.useState<{ duplicate?: string }>({})

  const isDuplicate = !!resolvedSearchParams.duplicate

  const getListPath = (type?: string) => {
    switch (type) {
      case CalculatorsTypeOptions.checklist:
        return "/decision-tools/checklists"
      case CalculatorsTypeOptions.calculator:
        return "/decision-tools/calculators"
      default:
        return "/decision-tools"
    }
  }
  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/decision-tools")
    }
  }, [permLoading, hasPermission, router])

  // Resolve the params and searchParams Promises
  React.useEffect(() => {
    params.then(setResolvedParams)
    searchParams.then(setResolvedSearchParams)
  }, [params, searchParams])

  const { update, create, loading } = useBackendCrud({
    collectionName: "calculators",
    onSuccess: () => {
      if (resolvedParams?.id && !isDuplicate) {
        router.push(`/decision-tools/${resolvedParams.id}`)
      } else {
        router.push(getListPath(tool?.type))
      }
    }
  })

  React.useEffect(() => {
    const fetchData = async () => {
      if (!resolvedParams?.id) return
      
      try {
        const backend = getBackendClient()
        const toolData = await backend.resource("calculators").getOne(resolvedParams.id, {
          expand: "addedBy"
        }) as CalculatorWithRelations
        
        setTool(toolData)
      } catch (error: unknown) {
        console.error("Failed to fetch data:", error)
        if ((error as { status?: number })?.status === 404) {
          notFound()
        }
      } finally {
        setLoadingData(false)
      }
    }

    fetchData()
  }, [resolvedParams?.id])

  const handleSubmit = async (data: Record<string, unknown>) => {
    if (!resolvedParams?.id) return

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
      
      // Handle addedBy field
      if (isDuplicate) {
        // For duplicating, set current user as addedBy
        formData.append('addedBy', currentUser.id)
      } else {
        // For editing, preserve existing addedBy unless it's empty
        const addedByUsers = tool?.addedBy
        const addedByList = Array.isArray(addedByUsers)
          ? addedByUsers
          : addedByUsers
          ? [addedByUsers]
          : [currentUser.id]
        addedByList.forEach((userId: string) => {
          formData.append('addedBy', userId)
        })
      }

      if (isDuplicate) {
        // If duplicating, create a new record
        await create(formData)
      } else {
        // If editing, update the existing record
        await update(resolvedParams.id, formData)
      }
    } catch (error) {
      console.error("Failed to submit form:", error)
      throw error
    }
  }

  const handleCancel = () => {
    router.push(getListPath(tool?.type))
  }

  if (loadingData) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          showBackButton={true}
          onBack={() => router.push(getListPath(tool?.type))}
        />
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading decision tool data...</div>
        </div>
      </div>
    )
  }

  if (!tool) {
    notFound()
  }

  // Prepare initial data with expanded relations
  const initialData = {
    ...tool
  }

  // If duplicating, modify some fields
  if (isDuplicate) {
    initialData.name = `${tool.name} (Copy)`
  }

  const pageTitle = isDuplicate ? `Duplicate "${tool.name}"` : `Edit "${tool.name}"`
  const pageDescription = isDuplicate 
    ? "Create a new decision tool based on this existing tool" 
    : "Update the decision tool information and configuration"

  return (
    <div className="space-y-6">
      <PageHeader
        title={pageTitle}
        description={pageDescription}
        showBackButton={true}
        onBack={() => router.push(getListPath(tool?.type))}
      />

      <div className="bg-card rounded-lg border p-6">
        <DecisionToolForm
          mode={isDuplicate ? "create" : "edit"}
          initialData={initialData}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          loading={loading}
        />
      </div>
    </div>
  )
}
