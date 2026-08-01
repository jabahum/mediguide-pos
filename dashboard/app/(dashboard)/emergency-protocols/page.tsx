"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { PageHeader } from "@/components/ui/page-header"
import { Phone, Plus, AlertTriangle, Heart, Zap, MoreVertical, Loader2 } from "lucide-react"
import type { EmergencyProtocolsResponse, EmergencyProtocolsCategoryOptions, EmergencyProtocolsPriorityOptions } from "@/types/backend-types"
import { emergencyProtocolService } from "@/services/emergency-protocol.service"
import { showToast } from "@/lib/toast"
import { usePermissionContext } from "@/lib/permission-context"

export default function EmergencyProtocolsPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [protocols, setProtocols] = React.useState<EmergencyProtocolsResponse[]>([])
  const [stats, setStats] = React.useState({
    total: 0,
    critical: 0,
    resuscitation: 0,
    trauma: 0
  })
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    fetchProtocols()
  }, [])

  const fetchProtocols = async () => {
    try {
      const result = await emergencyProtocolService.list({status:"active",sort:"priority",order:"asc"})
      setProtocols(result.items)

      // Calculate stats
      const total = result.total_items
      const critical = result.items.filter(p => p.priority === "critical").length
      const resuscitation = result.items.filter(p => p.category === "Resuscitation").length
      const trauma = result.items.filter(p => p.category === "Trauma").length

      setStats({ total, critical, resuscitation, trauma })
    } catch (error) {
      console.error("Failed to fetch protocols:", error)
      showToast.error("Error", "Failed to load emergency protocols")
    } finally {
      setLoading(false)
    }
  }

  const getPriorityBadge = (priority: EmergencyProtocolsPriorityOptions) => {
    const config = {
      critical: { variant: "destructive" as const, label: "Critical" },
      high: { variant: "default" as const, label: "High" },
      medium: { variant: "secondary" as const, label: "Medium" },
      low: { variant: "outline" as const, label: "Low" }
    }
    return config[priority] || { variant: "secondary" as const, label: priority }
  }

  const getCategoryIcon = (category: EmergencyProtocolsCategoryOptions) => {
    switch (category) {
      case "Resuscitation": return <Heart className="h-5 w-5 text-pink-500" />
      case "Trauma": return <Zap className="h-5 w-5 text-orange-500" />
      case "Emergency Medicine": return <AlertTriangle className="h-5 w-5 text-red-500" />
      case "Cardiac": return <Heart className="h-5 w-5 text-red-500" />
      case "Neurology": return <Phone className="h-5 w-5 text-blue-500" />
      default: return <Phone className="h-5 w-5 text-blue-500" />
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Emergency Protocols"
          description="Emergency procedures management"
        />
        <div className="flex items-center justify-center h-64">
          <Loader2 className="h-8 w-8 animate-spin" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Emergency Protocols"
        description="Emergency procedures management"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Create New Protocol",
            icon: <Plus className="h-4 w-4" />,
            onClick: () => router.push("/emergency-protocols/create"),
          },
        ] : []}
      />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Total Protocols</CardTitle>
            <Phone className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
            <p className="text-xs text-muted-foreground">
              Active protocols
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Critical</CardTitle>
            <AlertTriangle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.critical}</div>
            <p className="text-xs text-muted-foreground">
              Life-threatening
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Resuscitation</CardTitle>
            <Heart className="h-4 w-4 text-pink-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.resuscitation}</div>
            <p className="text-xs text-muted-foreground">
              CPR protocols
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Trauma</CardTitle>
            <Zap className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.trauma}</div>
            <p className="text-xs text-muted-foreground">
              Injury management
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4">
        {protocols.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center">
              <p className="text-muted-foreground">No emergency protocols found</p>
              <Button
                variant="outline"
                className="mt-4"
                onClick={() => router.push("/emergency-protocols/create")}
              >
                <Plus className="h-4 w-4 mr-2" />
                Create Protocol
              </Button>
            </CardContent>
          </Card>
        ) : (
          protocols.map((protocol) => {
            const priorityConfig = getPriorityBadge(protocol.priority)
            return (
              <Card key={protocol.id} className="hover:shadow-md transition-shadow cursor-pointer"
                onClick={() => router.push(`/emergency-protocols/${protocol.id}`)}>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="flex items-center space-x-2">
                        {getCategoryIcon(protocol.category)}
                        <span>{protocol.title}</span>
                      </CardTitle>
                      <CardDescription>{protocol.description}</CardDescription>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge variant={priorityConfig.variant}>{priorityConfig.label}</Badge>
                      <Button variant="ghost" size="sm" onClick={(e) => {
                        e.stopPropagation()
                        router.push(`/emergency-protocols/${protocol.id}/edit`)
                      }}>
                        <MoreVertical className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    Category: {protocol.category}
                    {protocol.timeframe && ` • Timeframe: ${protocol.timeframe}`}
                    {protocol.access_count ? ` • Accessed ${protocol.access_count} times` : ""}
                  </p>
                </CardContent>
              </Card>
            )
          })
        )}
      </div>
    </div>
  )
}
