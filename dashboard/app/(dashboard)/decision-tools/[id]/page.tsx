"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { Badge } from "@/components/ui/badge"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { DecisionToolWithRelations } from "../types"
import { CalculatorsStatusOptions, CalculatorsTypeOptions } from "@/types/backend-types"
import { calculatorService } from "@/services/calculator.service"
import { useDomainRecord } from "@/hooks/use-domain-record"
import { formatDistanceToNow } from "date-fns"
import { Edit, Copy, Trash2, Play, Calculator, Brain, CheckSquare, Info, Settings, Activity, Calendar } from "lucide-react"
import { usePermissionContext } from "@/lib/permission-context"
import { getAppFileLabel } from "../app-file"

interface DecisionToolViewPageProps {
  params: Promise<{ id: string }>
}

export default function DecisionToolViewPage({ params }: DecisionToolViewPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/decision-tools")
    }
  }, [permLoading, hasPermission, router])

  // Unwrap params using React.use()
  const { id } = React.use(params)

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

  const { record: tool, loading, error } = useDomainRecord<DecisionToolWithRelations>("calculators", id, calculatorService.get)

  const handleEdit = () => {
    router.push(`/decision-tools/${id}/edit`)
  }

  const handleDuplicate = () => {
    router.push(`/decision-tools/create?duplicate=${id}`)
  }

  const handleTest = () => {
    // Navigate to testing interface - this could be a separate route or modal
    router.push(`/decision-tools/${id}/test`)
  }

  const handleDelete = async () => {
    if (window.confirm("Are you sure you want to delete this decision tool? This action cannot be undone.")) {
      try {
        await calculatorService.delete(id)
        router.push(getListPath(tool?.type))
      } catch (error) {
        console.error("Failed to delete decision tool:", error)
      }
    }
  }

  const getTypeIcon = (type: CalculatorsTypeOptions) => {
    switch (type) {
      case CalculatorsTypeOptions.calculator:
        return <Calculator className="h-4 w-4" />
      case CalculatorsTypeOptions.decision_tool:
        return <Brain className="h-4 w-4" />
      case CalculatorsTypeOptions.checklist:
        return <CheckSquare className="h-4 w-4" />
      default:
        return <Calculator className="h-4 w-4" />
    }
  }

  const getStatusVariant = (status: CalculatorsStatusOptions) => {
    switch (status) {
      case CalculatorsStatusOptions.active:
        return "default"
      case CalculatorsStatusOptions.draft:
        return "secondary"
      case CalculatorsStatusOptions.archived:
        return "destructive"
      default:
        return "secondary"
    }
  }

  const getTypeDisplayName = (type: CalculatorsTypeOptions) => {
    return type === CalculatorsTypeOptions.decision_tool ? "Decision Tool" : 
           type.charAt(0).toUpperCase() + type.slice(1)
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          showBackButton={true}
          onBack={() => router.push(getListPath(tool?.type))}
        />
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading decision tool details...</div>
        </div>
      </div>
    )
  }

  if (!tool) {
    notFound()
  }

  const addedByUsers = tool.expand?.addedBy || []
  const appFileLabel = getAppFileLabel(tool.appFile)

  return (
    <div className="space-y-6">
      <PageHeader
        title={tool.name}
        description={tool.description}
        showBackButton={true}
        onBack={() => router.push(getListPath(tool?.type))}
        actions={[
          {
            label: "Test Tool",
            onClick: handleTest,
            icon: <Play className="h-4 w-4" />,
            disabled: tool.status === CalculatorsStatusOptions.archived
          },
          ...(hasPermission("content", "update:any") ? [{
            label: "Edit",
            onClick: handleEdit,
            icon: <Edit className="h-4 w-4" />
          }] : []),
          {
            label: "Duplicate",
            onClick: handleDuplicate,
            icon: <Copy className="h-4 w-4" />,
            variant: "outline" as const
          },
          ...(hasPermission("content", "delete:any") ? [{
            label: "Delete",
            onClick: handleDelete,
            icon: <Trash2 className="h-4 w-4" />,
            variant: "outline" as const,
            disabled: tool.status === CalculatorsStatusOptions.active
          }] : [])
        ]}
      />

      {/* Status Badges */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          {tool.icon ? (
            <span className="text-lg">{tool.icon}</span>
          ) : (
            getTypeIcon(tool.type)
          )}
          <Badge variant="outline">
            {getTypeDisplayName(tool.type)}
          </Badge>
        </div>
        <Badge variant={getStatusVariant(tool.status) as "default" | "secondary" | "destructive" | "outline"}>
          {(tool.status as string).charAt(0).toUpperCase() + (tool.status as string).slice(1)}
        </Badge>
        <Badge variant="secondary" className="font-mono">
          v{tool.version}
        </Badge>
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview" className="flex items-center gap-1">
            <Info className="h-4 w-4" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="configuration" className="flex items-center gap-1">
            <Settings className="h-4 w-4" />
            Configuration
          </TabsTrigger>
          <TabsTrigger value="usage" className="flex items-center gap-1">
            <Activity className="h-4 w-4" />
            Usage
          </TabsTrigger>
          <TabsTrigger value="metadata" className="flex items-center gap-1">
            <Calendar className="h-4 w-4" />
            Metadata
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-8">
          <div className="grid gap-8 md:grid-cols-2 xl:grid-cols-3">
            {/* Basic Information */}
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Tool Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Tool Type</Label>
                  <div className="flex items-center gap-2">
                    {tool.icon ? (
                      <span className="text-lg">{tool.icon}</span>
                    ) : (
                      getTypeIcon(tool.type)
                    )}
                    <span className="text-sm font-medium">
                      {getTypeDisplayName(tool.type)}
                    </span>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Version</Label>
                  <Badge variant="outline" className="font-mono">
                    v{tool.version}
                  </Badge>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Current Status</Label>
                  <Badge variant={getStatusVariant(tool.status) as "default" | "secondary" | "destructive" | "outline"}>
                    {(tool.status as string).charAt(0).toUpperCase() + (tool.status as string).slice(1)}
                  </Badge>
                </div>
              </CardContent>
            </Card>

            {/* Visual Properties */}
            {(tool.color || tool.backgroundColor) && (
              <Card>
                <CardHeader className="pb-4">
                  <CardTitle>Visual Design</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  {tool.color && (
                    <div className="space-y-2">
                      <Label className="text-sm font-medium text-muted-foreground">Primary Color</Label>
                      <div className="flex items-center gap-2">
                        <div
                          className="w-6 h-6 rounded border"
                          style={{ backgroundColor: tool.color }}
                          title={tool.color}
                        />
                        <span className="text-sm font-mono">{tool.color}</span>
                      </div>
                    </div>
                  )}
                  
                  {tool.backgroundColor && (
                    <div className="space-y-2">
                      <Label className="text-sm font-medium text-muted-foreground">Background Color</Label>
                      <div className="flex items-center gap-2">
                        <div
                          className="w-6 h-6 rounded border"
                          style={{ backgroundColor: tool.backgroundColor }}
                          title={tool.backgroundColor}
                        />
                        <span className="text-sm font-mono">{tool.backgroundColor}</span>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}

            {/* Contributors */}
            {addedByUsers.length > 0 && (
              <Card>
                <CardHeader className="pb-4">
                  <CardTitle>Contributors</CardTitle>
                  <CardDescription>Users who added or maintain this tool</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {addedByUsers.map((user) => (
                      <div key={user.id} className="flex items-center gap-2">
                        <div className="w-6 h-6 bg-muted rounded-full flex items-center justify-center text-xs font-medium">
                          {(user.name || user.email || user.username)?.charAt(0).toUpperCase()}
                        </div>
                        <span className="text-sm font-medium">
                          {user.name || user.email || user.username}
                        </span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}
          </div>

          {/* Description */}
          {tool.description && (
            <Card className="mt-8">
              <CardHeader className="pb-4">
                <CardTitle>Description</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="leading-relaxed">{tool.description}</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="configuration" className="mt-8 space-y-8">
          <Card>
            <CardHeader className="pb-4">
              <CardTitle>Technical Configuration</CardTitle>
              <CardDescription>Application file and technical details</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label className="text-sm font-medium text-muted-foreground">App File Path</Label>
                <div className="bg-muted p-3 rounded-md">
                  <code className="text-sm font-mono">
                    {appFileLabel || "—"}
                  </code>
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-sm font-medium text-muted-foreground">Tool ID</Label>
                <div className="bg-muted p-3 rounded-md">
                  <code className="text-sm font-mono">{tool.id}</code>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="usage" className="mt-8 space-y-8">
          <Card>
            <CardHeader className="pb-4">
              <CardTitle>Usage Statistics</CardTitle>
              <CardDescription>Usage metrics and analytics</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12 text-muted-foreground">
                <Activity className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Usage analytics will be available in a future update</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="metadata" className="mt-8 space-y-8">
          <Card>
            <CardHeader className="pb-4">
              <CardTitle>Record Metadata</CardTitle>
              <CardDescription>Database record information and timestamps</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Created</Label>
                  <p className="text-sm font-medium">
                    {formatDistanceToNow(new Date(tool.created), { addSuffix: true })}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {new Date(tool.created).toLocaleString()}
                  </p>
                </div>
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Last Updated</Label>
                  <p className="text-sm font-medium">
                    {formatDistanceToNow(new Date(tool.updated), { addSuffix: true })}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {new Date(tool.updated).toLocaleString()}
                  </p>
                </div>
              </div>

              <div className="pt-6 border-t">
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Tool ID</Label>
                  <div className="bg-muted p-3 rounded-md">
                    <code className="text-sm font-mono">{tool.id}</code>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
