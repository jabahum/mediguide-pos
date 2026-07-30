"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import {
  EmergencyProtocolForm,
  EmergencyProtocolPayload,
} from "../components/emergency-protocol-form"
import { usePermissionContext } from "@/lib/permission-context"

export default function CreateEmergencyProtocolPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/emergency-protocols")
    }
  }, [loading, hasPermission, router])

  const handleSubmit = async (data: EmergencyProtocolPayload) => {
    try {
      const backend = getBackendClient()
      const created = await backend.resource("emergency_protocols").create(data)
      showToast.success("Protocol Created", `"${created.title}" was created`)
      router.push(`/emergency-protocols/${created.id}`)
    } catch (error) {
      console.error("Failed to create emergency protocol:", error)
      showToast.error(
        "Create Failed",
        error instanceof Error ? error.message : "Could not create emergency protocol"
      )
      throw error
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create Emergency Protocol"
        description="Add a new emergency workflow with structured supporting data"
        showBackButton={true}
        onBack={() => router.push("/emergency-protocols")}
      />

      <div className="rounded-lg border bg-card p-6">
        <EmergencyProtocolForm
          mode="create"
          onSubmit={handleSubmit}
          onCancel={() => router.push("/emergency-protocols")}
        />
      </div>
    </div>
  )
}
