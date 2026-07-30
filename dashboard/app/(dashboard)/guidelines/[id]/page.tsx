"use client"

import * as React from "react"
import { use } from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"

// UI Components
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { PageHeader } from "@/components/ui/page-header"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Skeleton } from "@/components/ui/skeleton"
import { RichContent } from "@/components/ui/rich-content"

// Icons
import { Edit, Share2, Calendar, User, FileText, Pill, AlertTriangle, Shield } from "lucide-react"

// legacy collection API
import { Collections } from "@/types/backend-types"
import { useBackendRecord } from "@/hooks/use-backend-record"
import type { MedicalGuidelinesWithExpanded } from "@/types/expanded"

// Toast
import { showToast } from "@/lib/toast"
import { usePermissionContext } from "@/lib/permission-context"

interface GuidelineDetailPageProps {
  params: Promise<{
    id: string
  }>
}

export default function GuidelineDetailPage({ params }: GuidelineDetailPageProps) {
  const router = useRouter()
  const { id } = use(params)
  const { hasPermission, loading: permLoading } = usePermissionContext()

  const { record: guideline, loading, error } = useBackendRecord<MedicalGuidelinesWithExpanded>(
    Collections.MedicalGuidelines,
    id,
    { expand: "categories,tags" }
  )

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/guidelines")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    if (error) {
      console.error("Failed to fetch guideline:", error)
      notFound()
    }
  }, [error])

  const handleEdit = () => {
    router.push(`/guidelines/${id}/edit`)
  }

  const handleShare = () => {
    navigator.clipboard.writeText(window.location.href)
    showToast.success("Shared", "Link copied to clipboard")
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-12 w-3/4" />
        <Skeleton className="h-6 w-1/2" />
        <div className="grid gap-6">
          <Skeleton className="h-64" />
          <Skeleton className="h-64" />
        </div>
      </div>
    )
  }

  if (!guideline) {
    return notFound()
  }

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      draft: { variant: "secondary" as const, label: "Draft" },
      review: { variant: "outline" as const, label: "Under Review" },
      published: { variant: "default" as const, label: "Published" },
      archived: { variant: "destructive" as const, label: "Archived" },
    }

    const config = statusConfig[status as keyof typeof statusConfig] || {
      variant: "secondary" as const,
      label: status || "Unknown"
    }

    return <Badge variant={config.variant}>{config.label}</Badge>
  }

  const getPriorityBadge = (priority: string) => {
    const priorityConfig = {
      high: { variant: "destructive" as const, label: "High Priority" },
      medium: { variant: "outline" as const, label: "Medium Priority" },
      low: { variant: "secondary" as const, label: "Low Priority" },
    }

    const config = priorityConfig[priority as keyof typeof priorityConfig] || {
      variant: "secondary" as const,
      label: priority || "Not Set"
    }

    return <Badge variant={config.variant}>{config.label}</Badge>
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title={guideline.condition_name}
        description={`ICD-10: ${guideline.icd10_code || "N/A"} | Version ${guideline.version || "1.0"}`}
        showBackButton={true}
        onBack={() => router.push("/guidelines")}
        actions={[
          {
            label: "Share",
            onClick: handleShare,
            icon: <Share2 className="h-4 w-4" />,
            variant: "outline" as const
          },
          ...(hasPermission("content", "update:any") ? [{
            label: "Edit",
            onClick: handleEdit,
            icon: <Edit className="h-4 w-4" />
          }] : [])
        ]}
      />

      {/* Status and Metadata Row */}
      <div className="flex flex-wrap items-center gap-4 p-4 bg-muted/50 rounded-lg">
        <div className="flex items-center gap-2">
          <FileText className="h-4 w-4 text-muted-foreground" />
          {getStatusBadge(guideline.status || "")}
        </div>
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          {getPriorityBadge(guideline.priority || "")}
        </div>
        {guideline.is_published && (
          <div className="flex items-center gap-2">
            <Shield className="h-4 w-4 text-muted-foreground" />
            <Badge variant="default">Published</Badge>
          </div>
        )}
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <span className="text-sm text-muted-foreground">
            Created {new Date(guideline.created).toLocaleDateString()}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <span className="text-sm text-muted-foreground">
            Updated {new Date(guideline.updated).toLocaleDateString()}
          </span>
        </div>
        {guideline.target_population && (
          <div className="flex items-center gap-2">
            <User className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">
              Target: {guideline.target_population}
            </span>
          </div>
        )}
      </div>

      {/* Categories and Tags */}
      {(guideline.expand?.categories || guideline.expand?.tags) && (
        <Card>
          <CardContent className="p-6">
            <div className="space-y-4">
              {guideline.expand?.categories && guideline.expand.categories.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium mb-2">Categories</h4>
                  <div className="flex flex-wrap gap-2">
                    {guideline.expand.categories.map((category) => (
                      <Badge key={category.id} variant="secondary">
                        {category.name}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
              {guideline.expand?.tags && guideline.expand.tags.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium mb-2">Tags</h4>
                  <div className="flex flex-wrap gap-2">
                    {guideline.expand.tags.map((tag) => (
                      <Badge key={tag.id} variant="outline">
                        {tag.name}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Main Content Tabs */}
      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="classification">Classification</TabsTrigger>
          <TabsTrigger value="treatment">Treatment</TabsTrigger>
          <TabsTrigger value="safety">Safety & Prevention</TabsTrigger>
          <TabsTrigger value="metadata">Information</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Definition</CardTitle>
              <CardDescription>Medical definition and description of the condition</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.definition} fallback="No definition provided" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Causes & Risk Factors</CardTitle>
              <CardDescription>Etiology and contributing factors</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.causes} fallback="No causes listed" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Clinical Features</CardTitle>
              <CardDescription>Signs and symptoms presentation</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.clinical_features} fallback="No clinical features documented" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Differential Diagnosis</CardTitle>
              <CardDescription>Conditions to consider and rule out</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.differential_diagnosis} fallback="No differential diagnosis provided" />
            </CardContent>
          </Card>
        </TabsContent>

        {/* Classification Tab */}
        <TabsContent value="classification" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Disease Classification by Severity</CardTitle>
              <CardDescription>Clinical criteria for different severity levels</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {guideline.classification_mild && (
                <div className="border-l-4 border-green-500 pl-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span className="text-sm font-semibold text-green-700 dark:text-green-400">Mild Classification</span>
                  </div>
                  <RichContent html={guideline.classification_mild} />
                </div>
              )}
              {guideline.classification_moderate && (
                <div className="border-l-4 border-yellow-500 pl-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm font-semibold text-yellow-700 dark:text-yellow-400">Moderate Classification</span>
                  </div>
                  <RichContent html={guideline.classification_moderate} />
                </div>
              )}
              {guideline.classification_severe && (
                <div className="border-l-4 border-orange-500 pl-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                    <span className="text-sm font-semibold text-orange-700 dark:text-orange-400">Severe Classification</span>
                  </div>
                  <RichContent html={guideline.classification_severe} />
                </div>
              )}
              {guideline.classification_critical && (
                <div className="border-l-4 border-red-500 pl-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                    <span className="text-sm font-semibold text-red-700 dark:text-red-400">Critical Classification</span>
                  </div>
                  <RichContent html={guideline.classification_critical} />
                </div>
              )}
              {!guideline.classification_mild && !guideline.classification_moderate && !guideline.classification_severe && !guideline.classification_critical && (
                <p className="text-muted-foreground text-center py-8">No classification criteria defined</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Treatment Tab */}
        <TabsContent value="treatment" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>General Management</CardTitle>
              <CardDescription>Overall treatment approach and supportive care</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.general_management} fallback="No management guidelines provided" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Pill className="h-5 w-5 text-blue-600" />
                Primary Medication
              </CardTitle>
              <CardDescription>First-line treatment option</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <span className="text-sm font-medium">Medication</span>
                <p className="text-lg font-semibold">
                  {guideline.medication_primary || "Not specified"}
                </p>
              </div>
              <div className="space-y-3">
                <div>
                  <span className="text-sm font-medium text-blue-600">Adult Dosage</span>
                  <RichContent html={guideline.dosage_adult} fallback="Not specified" />
                </div>
                <div>
                  <span className="text-sm font-medium text-green-600">Pediatric Dosage</span>
                  <RichContent html={guideline.dosage_pediatric} fallback="Not specified" />
                </div>
              </div>
            </CardContent>
          </Card>

          {guideline.medication_secondary && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Pill className="h-5 w-5 text-purple-600" />
                  Alternative Medication
                </CardTitle>
                <CardDescription>Secondary treatment option</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <span className="text-sm font-medium">Medication</span>
                  <p className="text-lg font-semibold">
                    {guideline.medication_secondary}
                  </p>
                </div>
                <div className="space-y-3">
                  <div>
                    <span className="text-sm font-medium text-blue-600">Adult Dosage</span>
                    <RichContent html={guideline.dosage_secondary_adult} fallback="Not specified" />
                  </div>
                  <div>
                    <span className="text-sm font-medium text-green-600">Pediatric Dosage</span>
                    <RichContent html={guideline.dosage_secondary_pediatric} fallback="Not specified" />
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Administration Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <span className="text-sm font-medium">Route of Administration</span>
                <p className="text-muted-foreground">
                  {guideline.route_administration || "Not specified"}
                </p>
              </div>
              <div>
                <span className="text-sm font-medium">Healthcare Level Required</span>
                <p className="text-muted-foreground">
                  {guideline.healthcare_level_required || "Any level"}
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Safety & Prevention Tab */}
        <TabsContent value="safety" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-red-500" />
                Contraindications
              </CardTitle>
              <CardDescription>Important contraindications and precautions</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.contraindications} fallback="No contraindications specified" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5 text-blue-500" />
                Monitoring Requirements
              </CardTitle>
              <CardDescription>Patient monitoring and safety considerations</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.monitoring_requirements} fallback="No monitoring requirements specified" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5 text-green-500" />
                Prevention Measures
              </CardTitle>
              <CardDescription>Prevention strategies and measures</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.prevention_measures} fallback="No prevention measures specified" />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Special Notes</CardTitle>
              <CardDescription>Additional important considerations</CardDescription>
            </CardHeader>
            <CardContent>
              <RichContent html={guideline.special_notes} fallback="No special notes provided" />
            </CardContent>
          </Card>
        </TabsContent>

        {/* Metadata Tab */}
        <TabsContent value="metadata" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Guideline Information</CardTitle>
              <CardDescription>Document metadata and publication details</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-6">
                <div>
                  <span className="text-sm font-medium">Condition Name</span>
                  <p className="text-lg font-semibold">
                    {guideline.condition_name}
                  </p>
                </div>
                <div>
                  <span className="text-sm font-medium">ICD-10 Code</span>
                  <p className="font-mono">
                    {guideline.icd10_code || "Not specified"}
                  </p>
                </div>
                <div>
                  <span className="text-sm font-medium">Target Population</span>
                  <p className="text-muted-foreground">
                    {guideline.target_population || "Not specified"}
                  </p>
                </div>
                <div>
                  <span className="text-sm font-medium">Version</span>
                  <p className="font-semibold">
                    {guideline.version || "1.0"}
                  </p>
                </div>
              </div>

              <div className="border-t pt-6">
                <div className="space-y-4">
                  <div>
                    <span className="text-sm font-medium">Status</span>
                    <div className="mt-1">
                      {getStatusBadge(guideline.status || "")}
                    </div>
                  </div>
                  <div>
                    <span className="text-sm font-medium">Priority</span>
                    <div className="mt-1">
                      {getPriorityBadge(guideline.priority || "")}
                    </div>
                  </div>
                  <div>
                    <span className="text-sm font-medium">Published</span>
                    <div className="mt-1">
                      <Badge variant={guideline.is_published ? "default" : "secondary"}>
                        {guideline.is_published ? "Yes" : "No"}
                      </Badge>
                    </div>
                  </div>
                </div>
              </div>

              <div className="border-t pt-6">
                <div className="space-y-4">
                  <div>
                    <span className="text-sm font-medium">Created Date</span>
                    <p className="text-muted-foreground">
                      {new Date(guideline.created).toLocaleDateString("en-US", {
                        year: "numeric",
                        month: "long",
                        day: "numeric"
                      })}
                    </p>
                  </div>
                  <div>
                    <span className="text-sm font-medium">Last Updated</span>
                    <p className="text-muted-foreground">
                      {new Date(guideline.updated).toLocaleDateString("en-US", {
                        year: "numeric",
                        month: "long",
                        day: "numeric"
                      })}
                    </p>
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
