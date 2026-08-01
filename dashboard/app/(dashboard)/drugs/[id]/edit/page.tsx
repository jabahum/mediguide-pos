"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DrugForm } from "@/components/forms/drug-form"
import { DrugsResponse, DrugCategoriesResponse, DrugTagsResponse } from "@/types/backend-types"
import { useDomainCrud } from "@/hooks/use-domain-crud"
import { drugReferenceService, drugService } from "@/services/drug.service"
import { usePermissionContext } from "@/lib/permission-context"

interface DrugEditPageProps {
  params: Promise<{ id: string }>
  searchParams: Promise<{ duplicate?: string }>
}

type DrugWithRelations = DrugsResponse<{
  categories: DrugCategoriesResponse[]
  tags: DrugTagsResponse[]
}>

export default function DrugEditPage({ params, searchParams }: DrugEditPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [drug, setDrug] = React.useState<DrugWithRelations | null>(null)
  const [categories, setCategories] = React.useState<DrugCategoriesResponse[]>([])
  const [tags, setTags] = React.useState<DrugTagsResponse[]>([])
  const [loadingData, setLoadingData] = React.useState(true)
  const [resolvedParams, setResolvedParams] = React.useState<{ id: string } | null>(null)
  const [resolvedSearchParams, setResolvedSearchParams] = React.useState<{ duplicate?: string }>({})

  const isDuplicate = !!resolvedSearchParams.duplicate

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/drugs")
    }
  }, [permLoading, hasPermission, router])

  // Resolve the params and searchParams Promises
  React.useEffect(() => {
    params.then(setResolvedParams)
    searchParams.then(setResolvedSearchParams)
  }, [params, searchParams])

  const { update, loading } = useDomainCrud("drugs", drugService, () => {
      if (resolvedParams?.id) {
        router.push(`/drugs/${resolvedParams.id}`)
      }
  })

  React.useEffect(() => {
    const fetchData = async () => {
      if (!resolvedParams?.id) return
      
      try {
        const [drugData, categoriesResult, tagsResult] = await Promise.all([
          drugService.get(resolvedParams.id) as Promise<DrugWithRelations>,
          drugReferenceService.allCategories(),
          drugReferenceService.allTags(),
        ])
        
        setDrug(drugData)
        setCategories(categoriesResult as DrugCategoriesResponse[])
        setTags(tagsResult as DrugTagsResponse[])
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

  const handleSubmit = async (data: unknown) => {
    if (resolvedParams?.id) {
      await update(resolvedParams.id, data as Record<string, unknown>)
    }
  }

  const handleCancel = () => {
    if (resolvedParams?.id) {
      router.push(`/drugs/${resolvedParams.id}`)
    }
  }

  if (loadingData) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          showBackButton={true}
          onBack={() => resolvedParams?.id && router.push(`/drugs/${resolvedParams.id}`)}
        />
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading drug data...</div>
        </div>
      </div>
    )
  }

  if (!drug) {
    notFound()
  }

  // Prepare initial data with expanded relations
  const initialData = {
    ...drug,
    categories: drug.categories || [],
    tags: drug.tags || []
  }

  const pageTitle = isDuplicate ? `Duplicate "${drug.name}"` : `Edit "${drug.name}"`
  const pageDescription = isDuplicate 
    ? "Create a new drug based on this existing drug" 
    : "Update the drug information and clinical details"

  return (
    <div className="space-y-6">
      <PageHeader
        title={pageTitle}
        description={pageDescription}
        showBackButton={true}
        onBack={() => resolvedParams?.id && router.push(`/drugs/${resolvedParams.id}`)}
      />

      <div className="max-w-4xl">
        <div className="bg-card rounded-lg border p-6">
          <DrugForm
            mode="edit"
            initialData={initialData}
            categories={categories}
            tags={tags}
            onSubmit={handleSubmit}
            onCancel={handleCancel}
            loading={loading}
          />
        </div>
      </div>
    </div>
  )
}
