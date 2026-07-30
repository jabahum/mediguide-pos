"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Edit, Trash2 } from "lucide-react"
import { getBackendClient } from "@/lib/backend-client"
import { useBackendRecord } from "@/hooks/use-backend-record"
import { showToast } from "@/lib/toast"
import { EmergencyProtocolRecord, stringifyJsonField } from "../protocol-helpers"
import { usePermissionContext } from "@/lib/permission-context"

interface EmergencyProtocolViewPageProps {
  params: Promise<{ id: string }>
}

function JsonSection({
  title,
  value,
}: {
  title: string
  value: unknown
}) {
  if (value === null || value === undefined || value === "") {
    return null
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <pre className="overflow-x-auto whitespace-pre-wrap rounded-lg bg-muted p-4 text-sm">
          {stringifyJsonField(value)}
        </pre>
      </CardContent>
    </Card>
  )
}

export default function EmergencyProtocolViewPage({
  params,
}: EmergencyProtocolViewPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const { id } = React.use(params)
  const { record: protocol, loading, error } = useBackendRecord<EmergencyProtocolRecord>(
    "emergency_protocols",
    id
  )

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/emergency-protocols")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    if (!error) return
    console.error("Failed to fetch emergency protocol:", error)
    showToast.error("Load Failed", "Could not load this emergency protocol")
    router.push("/emergency-protocols")
  }, [error, router])

  const handleDelete = async () => {
    if (!protocol) {
      return
    }

    if (!window.confirm("Delete this emergency protocol permanently?")) {
      return
    }

    try {
      const backend = getBackendClient()
      await backend.resource("emergency_protocols").delete(protocol.id)
      showToast.success("Protocol Deleted", `"${protocol.title}" was deleted`)
      router.push("/emergency-protocols")
    } catch (error) {
      console.error("Failed to delete emergency protocol:", error)
      showToast.error(
        "Delete Failed",
        error instanceof Error ? error.message : "Could not delete emergency protocol"
      )
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          description="Fetching emergency protocol details"
          showBackButton={true}
          onBack={() => router.push("/emergency-protocols")}
        />
      </div>
    )
  }

  if (!protocol) {
    return null
  }

  const tags = Array.isArray(protocol.tags) ? protocol.tags : []

  return (
    <div className="space-y-6">
      <PageHeader
        title={protocol.title}
        description={protocol.description}
        showBackButton={true}
        onBack={() => router.push("/emergency-protocols")}
        actions={[
          ...(hasPermission("content", "update:any") ? [{
            label: "Edit",
            onClick: () => router.push(`/emergency-protocols/${protocol.id}/edit`),
            icon: <Edit className="h-4 w-4" />,
          }] : []),
          ...(hasPermission("content", "delete:any") ? [{
            label: "Delete",
            onClick: handleDelete,
            icon: <Trash2 className="h-4 w-4" />,
            variant: "outline" as const,
          }] : []),
        ]}
      />

      <div className="flex flex-wrap gap-3">
        <Badge variant="outline">{protocol.category}</Badge>
        <Badge>{protocol.priority}</Badge>
        <Badge variant="secondary">{protocol.status}</Badge>
        {protocol.timeframe ? <Badge variant="outline">{protocol.timeframe}</Badge> : null}
      </div>

      {tags.length > 0 ? (
        <div className="flex flex-wrap gap-2">
          {tags.map((tag) => (
            <Badge key={tag} variant="secondary">
              {tag}
            </Badge>
          ))}
        </div>
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle>Summary</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm text-muted-foreground">
          <p>Created: {new Date(protocol.created).toLocaleString()}</p>
          <p>Updated: {new Date(protocol.updated).toLocaleString()}</p>
          <p>Access Count: {protocol.access_count || 0}</p>
        </CardContent>
      </Card>

      <JsonSection title="Steps" value={protocol.steps} />
      <JsonSection title="Critical Actions" value={protocol.critical_actions} />
      <JsonSection title="Medications" value={protocol.medications} />
      <JsonSection title="Vital Signs" value={protocol.vital_signs} />
      <JsonSection title="Transfer Checklist" value={protocol.transfer_checklist} />
      <JsonSection title="Contact Info" value={protocol.contact_info} />

      {!protocol.steps &&
      !protocol.critical_actions &&
      !protocol.medications &&
      !protocol.vital_signs &&
      !protocol.transfer_checklist &&
      !protocol.contact_info ? (
        <Card>
          <CardContent className="py-10 text-center text-sm text-muted-foreground">
            This protocol does not have structured workflow data yet.
            <div className="mt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.push(`/emergency-protocols/${protocol.id}/edit`)}
              >
                Add Structured Data
              </Button>
            </div>
          </CardContent>
        </Card>
      ) : null}
    </div>
  )
}
