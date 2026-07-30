'use client'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { PageHeader } from "@/components/ui/page-header"
import { Skeleton } from "@/components/ui/skeleton"
import {
  CheckCircle2,
  Search,
  Plus,
  AlertTriangle,
  Clock,
  Users,
  Eye,
  Edit,
  Copy,
} from "lucide-react"
import { useCallback, useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { backendClient } from "@/lib/backend-client"
import {
  Collections,
  CalculatorsStatusOptions,
  CalculatorsTypeOptions,
  CalculatorsCategoryOptions,
} from "@/types/backend-types"
import type { CalculatorsResponse } from "@/types/backend-types"
import { showToast } from "@/lib/toast"
import { formatDistanceToNow } from "date-fns"
import * as React from "react"
import { usePermissionContext } from "@/lib/permission-context"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

const statusFilters = ["all", "active", "draft", "archived"] as const
type StatusFilter = (typeof statusFilters)[number]

const categoryFilterOptions: Array<{ value: "all" | CalculatorsCategoryOptions; label: string }> = [
  { value: "all", label: "All categories" },
  { value: CalculatorsCategoryOptions.surgical, label: "Surgical" },
  { value: CalculatorsCategoryOptions.emergency, label: "Emergency" },
  { value: CalculatorsCategoryOptions.maternal, label: "Maternal" },
  { value: CalculatorsCategoryOptions.pediatric, label: "Pediatric" },
  { value: CalculatorsCategoryOptions.cardiology, label: "Cardiology" },
  { value: CalculatorsCategoryOptions.neurology, label: "Neurology" },
  { value: CalculatorsCategoryOptions.pharmacy, label: "Pharmacy" },
  { value: CalculatorsCategoryOptions.nutrition, label: "Nutrition" },
  { value: CalculatorsCategoryOptions.infection_control, label: "Infection Control" },
  { value: CalculatorsCategoryOptions.safety, label: "Safety" },
  { value: CalculatorsCategoryOptions.general, label: "General" },
]
type CategoryFilter = (typeof categoryFilterOptions)[number]["value"]

export default function ChecklistsPage() {
  const router = useRouter()
  const [checklists, setChecklists] = useState<CalculatorsResponse[]>([])
  const { hasPermission, loading } = usePermissionContext()
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedStatus, setSelectedStatus] = useState<StatusFilter>("all")
  const [isFetching, setIsFetching] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState<CategoryFilter>("all")

  const fetchChecklists = useCallback(async () => {
    try {
      setIsFetching(true)
      const result = await backendClient.collection(Collections.Calculators).getList(1, 100, {
        filter: `type = "${CalculatorsTypeOptions.checklist}"`,
        sort: "-updated",
      })
      setChecklists(result.items as CalculatorsResponse[])
    } catch (error) {
      console.error("Failed to fetch checklists:", error)
      showToast.error("Error", "Failed to load checklists")
    } finally {
      setIsFetching(false)
    }
  }, [])

  useEffect(() => {
    fetchChecklists()
  }, [fetchChecklists])

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/decision-tools")
    }
  }, [loading, hasPermission, router])

  const filteredChecklists = checklists.filter((checklist) => {
    const term = searchTerm.toLowerCase()
    const matchesSearch =
      checklist.name.toLowerCase().includes(term) ||
      (checklist.description || "").toLowerCase().includes(term)
    const matchesStatus = selectedStatus === "all" || checklist.status === selectedStatus
    const matchesCategory = selectedCategory === "all" || checklist.category === selectedCategory
    return matchesSearch && matchesStatus && matchesCategory
  })

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "critical": return "text-red-600 dark:text-red-400"
      case "high": return "text-orange-600 dark:text-orange-400"
      case "medium": return "text-blue-600 dark:text-blue-400"
      case "low": return "text-gray-600 dark:text-gray-400"
      default: return "text-gray-600 dark:text-gray-400"
    }
  }

  const formatCategory = (category?: string) => {
    if (!category) return "—"
    return category
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ")
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active": return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
      case "draft": return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
      case "archived": return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
      default: return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    }
  }

  const activeCount = checklists.filter((c) => c.status === CalculatorsStatusOptions.active).length
  const draftCount = checklists.filter((c) => c.status === CalculatorsStatusOptions.draft).length
  const totalUsage = checklists.reduce((sum, c) => sum + (c.usageCount || 0), 0)

  return (
    <div className="space-y-6">
      <PageHeader
        title="Clinical Checklists"
        description="Standardized checklists for consistent clinical care delivery"
        actions={[
          {
            label: "Create Checklist",
            icon: <Plus className="h-4 w-4" />,
            onClick: () => router.push("/decision-tools/checklists/create"),
          },
        ]}
      />

      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Checklists</p>
                <p className="text-2xl font-bold">{loading ? "—" : checklists.length}</p>
              </div>
              <CheckCircle2 className="h-8 w-8 text-primary" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Active Checklists</p>
                <p className="text-2xl font-bold">{loading ? "—" : activeCount}</p>
              </div>
              <CheckCircle2 className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Total Usage</p>
                <p className="text-2xl font-bold">{loading ? "—" : totalUsage.toLocaleString()}</p>
              </div>
              <Users className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Drafts</p>
                <p className="text-2xl font-bold">{loading ? "—" : draftCount}</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-orange-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center space-x-2">
              <Search className="h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search checklists..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <Select
                value={selectedCategory}
                onValueChange={(v) => setSelectedCategory(v as CategoryFilter)}
              >
                <SelectTrigger className="w-full sm:w-[200px]">
                  <SelectValue placeholder="All categories" />
                </SelectTrigger>
                <SelectContent>
                  {categoryFilterOptions.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Tabs
                value={selectedStatus}
                onValueChange={(v) => setSelectedStatus(v as StatusFilter)}
                className="w-full sm:w-auto"
              >
                <TabsList className="grid w-full grid-cols-4">
                  {statusFilters.map((status) => (
                    <TabsTrigger key={status} value={status} className="text-xs">
                      {status.charAt(0).toUpperCase() + status.slice(1)}
                    </TabsTrigger>
                  ))}
                </TabsList>
              </Tabs>
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Checklists Grid */}
      {isFetching ? (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-5 w-3/4" />
                <Skeleton className="h-4 w-full mt-2" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-4 w-1/2 mb-3" />
                <Skeleton className="h-4 w-2/3 mb-3" />
                <Skeleton className="h-8 w-full" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : filteredChecklists.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12">
            <CheckCircle2 className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
            <h3 className="text-lg font-medium">No checklists found</h3>
            <p className="text-muted-foreground">
              {checklists.length === 0
                ? "Create your first checklist to get started"
                : "Try adjusting your search or filters"}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {filteredChecklists.map((checklist) => (
            <Card key={checklist.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <CardTitle className="text-lg">{checklist.name}</CardTitle>
                    {checklist.description && (
                      <CardDescription>{checklist.description}</CardDescription>
                    )}
                  </div>
                  <Badge className={getStatusColor(checklist.status)}>
                    {checklist.status}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">
                      Category: {formatCategory(checklist.category)}
                    </span>
                    {checklist.priority ? (
                      <span className={`font-medium ${getPriorityColor(checklist.priority)}`}>
                        {checklist.priority} priority
                      </span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Version: {checklist.version}</span>
                    <span className="text-muted-foreground">Usage: {checklist.usageCount || 0}</span>
                  </div>

                  <div className="flex items-center text-sm text-muted-foreground">
                    <Clock className="mr-1 h-3 w-3" />
                    Updated {formatDistanceToNow(new Date(checklist.updated), { addSuffix: true })}
                  </div>

                  <div className="flex space-x-2 pt-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => router.push(`/decision-tools/${checklist.id}`)}
                    >
                      <Eye className="mr-1 h-3 w-3" />
                      View
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => router.push(`/decision-tools/${checklist.id}/edit`)}
                    >
                      <Edit className="mr-1 h-3 w-3" />
                      Edit
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() =>
                        router.push(`/decision-tools/create?duplicate=${checklist.id}`)
                      }
                    >
                      <Copy className="mr-1 h-3 w-3" />
                      Clone
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
