"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DrugForm } from "@/components/forms/drug-form"
import { DrugCategoriesResponse, DrugTagsResponse } from "@/types/backend-types"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { getBackendClient } from "@/lib/backend-client"
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

  const { create, loading } = useBackendCrud({
    collectionName: "drugs",
    onSuccess: () => {
      router.push("/drugs")
    }
  })

  React.useEffect(() => {
    const fetchData = async () => {
      try {
        const backend = getBackendClient()
        const [categoriesResult, tagsResult] = await Promise.all([
          backend.resource("drug_categories").getFullList({
            filter: "status = 'active'",
            sort: "sort_order,name"
          }),
          backend.resource("drug_tags").getFullList({
            filter: "status = 'active'", 
            sort: "sort_order,name"
          })
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
    await create(data)
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