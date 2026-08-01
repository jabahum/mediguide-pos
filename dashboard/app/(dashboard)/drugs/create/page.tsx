"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DrugForm } from "@/components/forms/drug-form"
import { DrugCategoriesResponse, DrugTagsResponse } from "@/types/backend-types"
import { useDomainCrud } from "@/hooks/use-domain-crud"
import { drugReferenceService, drugService } from "@/services/drug.service"
import { usePermissionContext } from "@/lib/permission-context"

export default function CreateDrugPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/drugs")
    }
  }, [permLoading, hasPermission, router])
  const [categories, setCategories] = React.useState<DrugCategoriesResponse[]>([])
  const [tags, setTags] = React.useState<DrugTagsResponse[]>([])

  const { create, loading } = useDomainCrud("drugs", drugService, () => {
      router.push("/drugs")
  })

  React.useEffect(() => {
    const fetchData = async () => {
      try {
        const [categoriesResult, tagsResult] = await Promise.all([
          drugReferenceService.allCategories(),
          drugReferenceService.allTags(),
        ])
        
        setCategories(categoriesResult as DrugCategoriesResponse[])
        setTags(tagsResult as DrugTagsResponse[])
      } catch (error) {
        console.error("Failed to fetch categories and tags:", error)
      }
    }

    fetchData()
  }, [])

  const handleSubmit = async (data: unknown) => {
    await create(data as Record<string, unknown>)
  }

  const handleCancel = () => {
    router.push("/drugs")
  }


  return (
    <div className="space-y-6">
      <PageHeader
        title="Create New Drug"
        description="Add a new drug to the medication database with comprehensive clinical information"
        showBackButton={true}
        onBack={() => router.push("/drugs")}
      />

      <div className="bg-card rounded-lg border p-6">
        <DrugForm
          mode="create"
          categories={categories}
          tags={tags}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          loading={loading}
        />
      </div>
    </div>
  )
}
