"use client"

import { Plus, RotateCcw } from "lucide-react"
import { useRouter } from "next/navigation"
import { useCallback, useEffect } from "react"
import { usePermissionContext } from "@/lib/permission-context"
import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { columns } from "./columns"
import { createTagRowActions, tagBulkActions } from "./tag-actions"
import { tagAvailableFields } from "./fields"
import type { FaqTagWithStats } from "@/types/faq"
import type { AdvancedFilter } from "@/types/data-table"
import { FaqTagsService } from "@/services/faq-tags.service"
import { showToast } from "@/lib/toast"

export default function FAQTagsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/support/faqs")
    }
  }, [loading, hasPermission, router])

  const tagRowActions = useCallback(() =>
    createTagRowActions((path: string) => router.push(path)), 
    [router]
  )

  const handleAdvancedFilter = useCallback((filters: AdvancedFilter[]) => {
    console.log('Tag filters applied:', filters)
  }, [])

  const handleRecalculateAll = useCallback(async () => {
    try {
      const result = await FaqTagsService.recalculateUsageCounts()
      if (result.success && result.data) {
        showToast.success("Success", 
          `Recalculated usage counts for ${result.data.updated} tags`)
      } else {
        showToast.error("Error", result.error || "Failed to recalculate")
      }
    } catch (error: unknown) {
      console.error('Error recalculating usage counts:', error)
      showToast.error("Error", "Failed to recalculate usage counts")
    }
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="FAQ Tags"
        description="Manage tags for organizing and categorizing FAQs"
        showBackButton={true}
        onBack={() => router.push('/support/faqs')}
        actions={[
          ...(hasPermission("content", "create:any") ? [{
            label: "Add Tag",
            onClick: () => router.push('/support/faqs/tags/create'),
            icon: <Plus className="h-4 w-4" />
          }] : []),
          {
            label: "Recalculate All",
            onClick: handleRecalculateAll,
            variant: "outline" as const,
            icon: <RotateCcw className="h-4 w-4" />
          }
        ]}
      />

      <EnhancedBackendDataTable<FaqTagWithStats>
        collectionName="faq_tags"
        columns={columns}
        searchable={true}
        searchFields={["name", "description", "slug"]}
        selectable={true}
        exportable={true}
        availableFields={tagAvailableFields}
        rowActions={tagRowActions()}
        bulkActions={tagBulkActions}
        persistColumnConfig={true}
        tableContext="faq-tags-management"
        onAdvancedFilter={handleAdvancedFilter}
      />
    </div>
  )
}