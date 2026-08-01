"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { useQueryClient } from "@tanstack/react-query"
import { PageHeader } from "@/components/ui/page-header"
import { emergencyProtocolService } from "@/services/emergency-protocol.service"
import { showToast } from "@/lib/toast"
import {
  EmergencyProtocolForm,
  EmergencyProtocolPayload,
} from "../../components/emergency-protocol-form"
import { EmergencyProtocolRecord } from "../../protocol-helpers"
import { usePermissionContext } from "@/lib/permission-context"

interface EmergencyProtocolEditPageProps {
  params: Promise<{ id: string }>
}

export default function EmergencyProtocolEditPage({
  params,
}: EmergencyProtocolEditPageProps) {
  const router = useRouter()
  const queryClient = useQueryClient()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const { id } = React.use(params)
  const [protocol, setProtocol] = React.useState<EmergencyProtocolRecord | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [saving, setSaving] = React.useState(false)

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/emergency-protocols")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    const fetchProtocol = async () => {
      try {
        setProtocol(await emergencyProtocolService.get(id) as EmergencyProtocolRecord)
      } catch (error) {
        console.error("Failed to load emergency protocol for editing:", error)
        showToast.error("Load Failed", "Could not load this emergency protocol")
        router.push("/emergency-protocols")
      } finally {
        setLoading(false)
      }
    }

    fetchProtocol()
  }, [id, router])

  const handleSubmit = async (data: EmergencyProtocolPayload) => {
    try {
      setSaving(true)
      await emergencyProtocolService.update(id, data)
      await queryClient.invalidateQueries({ queryKey: ["emergency-protocols",id] })
      showToast.success("Protocol Updated", "Emergency protocol changes were saved")
      router.push(`/emergency-protocols/${id}`)
    } catch (error) {
      console.error("Failed to update emergency protocol:", error)
      showToast.error(
        "Update Failed",
        error instanceof Error ? error.message : "Could not update emergency protocol"
      )
      throw error
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          description="Fetching emergency protocol"
          showBackButton={true}
          onBack={() => router.push("/emergency-protocols")}
        />
      </div>
    )
  }

  if (!protocol) {
    return null
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Edit ${protocol.title}`}
        description="Update protocol details and structured workflow data"
        showBackButton={true}
        onBack={() => router.push(`/emergency-protocols/${protocol.id}`)}
      />

      <div className="rounded-lg border bg-card p-6">
        <EmergencyProtocolForm
          mode="edit"
          initialData={protocol}
          onSubmit={handleSubmit}
          onCancel={() => router.push(`/emergency-protocols/${protocol.id}`)}
          loading={saving}
        />
      </div>
    </div>
  )
}
