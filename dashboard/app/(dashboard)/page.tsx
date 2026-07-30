'use client'

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Activity,
  AlertTriangle,
  Building2,
  CheckCircle2,
  ClipboardCheck,
  Hospital,
  Stethoscope,
  Users,
} from "lucide-react"
import { useEffect, useState } from "react"
import { getBackendClient } from "@/lib/backend-client"
import type { OverviewData } from "@/types/overview"
import {
  OverviewEngagementChart,
  OverviewSeriesChart,
} from "@/components/dashboard/overview-charts"
import { StatCard } from "@/components/dashboard/stat-card"
import { PageHeader } from "@/components/ui/page-header"

// Loading components for better UX
function MetricsLoading() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {[...Array(4)].map((_, i) => (
        <Card key={i}>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <div className="h-4 w-20 bg-muted animate-pulse rounded" />
            <div className="h-4 w-4 bg-muted animate-pulse rounded" />
          </CardHeader>
          <CardContent>
            <div className="h-8 w-16 bg-muted animate-pulse rounded mb-1" />
            <div className="h-3 w-24 bg-muted animate-pulse rounded" />
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

// Client Components using hooks for data fetching
function DashboardMetrics({
  data,
  loading,
}: {
  data: OverviewData | null
  loading: boolean
}) {
  if (loading || !data) return <MetricsLoading />

  const { metrics } = data
  
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Users"
        value={metrics.totalUsers}
        helper={`${metrics.activeUsers.toLocaleString()} active users`}
        icon={Users}
      />

      <StatCard
        title="Drugs"
        value={metrics.totalDrugs}
        helper={`${metrics.activeDrugs.toLocaleString()} active`}
        icon={Hospital}
      />

      <StatCard
        title="Facilities"
        value={metrics.totalFacilities}
        helper="Total facilities"
        icon={Building2}
      />

      <StatCard
        title="Consultants"
        value={metrics.totalConsultants}
        helper={`${metrics.activeConsultants.toLocaleString()} active`}
        icon={Stethoscope}
      />
    </div>
  )
}

function OverviewState({
  data,
  loading,
}: {
  data: OverviewData | null
  loading: boolean
}) {
  if (loading || !data) return <MetricsLoading />

  const { pipeline } = data
  const items = [
    {
      title: "Users Pending Activation",
      value: pipeline.usersPendingActivation,
      icon: Users,
      tone: "text-amber-500",
    },
    {
      title: "Drugs Under Review",
      value: pipeline.drugsUnderReview,
      icon: AlertTriangle,
      tone: "text-orange-500",
    },
    {
      title: "Drugs Pending Approval",
      value: pipeline.drugsPendingReview,
      icon: ClipboardCheck,
      tone: "text-blue-500",
    },
    {
      title: "Inactive Drugs",
      value: pipeline.drugsInactive,
      icon: Activity,
      tone: "text-muted-foreground",
    },
    {
      title: "Consultants Pending Approval",
      value: pipeline.consultantsPendingApproval,
      icon: Stethoscope,
      tone: "text-amber-500",
    },
    {
      title: "Verified Consultants",
      value: pipeline.consultantsVerified,
      icon: CheckCircle2,
      tone: "text-emerald-500",
    },
  ]

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {items.map((item) => {
        return (
          <StatCard
            key={item.title}
            title={item.title}
            value={item.value}
            helper="Current backlog"
            icon={item.icon}
            iconTone={item.tone}
          />
        )
      })}
    </div>
  )
}


function OverviewCharts({
  data,
  loading,
}: {
  data: OverviewData | null
  loading: boolean
}) {
  if (loading || !data) {
    return (
      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="h-[340px] animate-pulse bg-muted/40" />
        <Card className="h-[340px] animate-pulse bg-muted/40" />
      </div>
    )
  }

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <OverviewSeriesChart
        users={data.series.usersByDay}
        drugs={data.series.drugsByDay}
        facilities={data.series.facilitiesByDay}
      />
      <OverviewEngagementChart engagement={data.engagement} />
    </div>
  )
}

export default function DashboardPage() {
  const [data, setData] = useState<OverviewData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function loadData() {
      try {
        const pb = getBackendClient()
        const overview = await pb.send<OverviewData>("/api/overview", {
          method: "GET",
        })
        setData(overview)
      } catch (error) {
        console.error("Failed to load dashboard data:", error)
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Welcome to the MediGuide administrative dashboard"
      />

      {/* Key Metrics */}
      <DashboardMetrics data={data} loading={loading} />

      <div className="space-y-4">
        <h2 className="text-lg font-semibold">Operational State</h2>
        <OverviewState data={data} loading={loading} />
      </div>

      <OverviewCharts data={data} loading={loading} />

      <div className="grid gap-4">
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Content Health</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-3">
              <div>
                <p className="text-xs text-muted-foreground">Guidelines</p>
                <p className="text-2xl font-bold">
                  {loading || !data
                    ? "—"
                    : data.contentHealth.medicalGuidelinesTotal.toLocaleString()}
                </p>
                <p className="text-xs text-muted-foreground">
                  {loading || !data
                    ? "Published vs draft"
                    : `${data.contentHealth.medicalGuidelinesPublished.toLocaleString()} published · ${data.contentHealth.medicalGuidelinesDraft.toLocaleString()} draft`}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">FAQs</p>
                <p className="text-2xl font-bold">
                  {loading || !data
                    ? "—"
                    : data.contentHealth.faqsTotal.toLocaleString()}
                </p>
                <p className="text-xs text-muted-foreground">
                  {loading || !data
                    ? "Published vs draft"
                    : `${data.contentHealth.faqsPublished.toLocaleString()} published · ${data.contentHealth.faqsDraft.toLocaleString()} draft`}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Documentation</p>
                <p className="text-2xl font-bold">
                  {loading || !data
                    ? "—"
                    : data.contentHealth.documentationTotal.toLocaleString()}
                </p>
                <p className="text-xs text-muted-foreground">
                  {loading || !data
                    ? "Published content"
                    : `${data.contentHealth.documentationPublished.toLocaleString()} published`}
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
