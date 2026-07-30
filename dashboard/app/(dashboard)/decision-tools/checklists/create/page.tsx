"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { DecisionToolForm } from "@/components/forms/decision-tool-form"
import { CalculatorsTypeOptions } from "@/types/backend-types"
import { useBackendCrud } from "@/hooks/use-backend-crud"
import { getBackendClient } from "@/lib/backend-client"

export default function CreateChecklistPage() {
  const router = useRouter()

  const { create, loading } = useBackendCrud({
    collectionName: "calculators",
    onSuccess: () => {
      router.push("/decision-tools/checklists")
    },
  })

  const handleSubmit = async (data: Record<string, unknown>) => {
    const pb = getBackendClient()
    const currentUser = pb.authStore.model

    if (!currentUser) {
      throw new Error("User not authenticated")
    }

    const formData = new FormData()

    Object.keys(data).forEach((key) => {
      const value = data[key]
      if (key === "appFile" && value instanceof File) {
        formData.append("appFile", value)
      } else if (value !== null && value !== undefined && value !== "") {
        formData.append(key, String(value))
      }
    })

    formData.append("addedBy", currentUser.id)

    await create(formData)
  }

  const handleCancel = () => {
    router.push("/decision-tools/checklists")
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create Checklist"
        description="Add a new step-by-step clinical checklist"
        showBackButton={true}
        onBack={() => router.push("/decision-tools/checklists")}
      />

      <div className="bg-card rounded-lg border p-6">
        <DecisionToolForm
          mode="create"
          initialData={{ type: CalculatorsTypeOptions.checklist }}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          loading={loading}
        />
      </div>
    </div>
  )
}
