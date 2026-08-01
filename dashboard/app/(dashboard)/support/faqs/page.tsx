"use client"

import { Plus, Settings } from "lucide-react"
import { useRouter } from "next/navigation"
import { useCallback, useEffect } from "react"
import { usePermissionContext } from "@/lib/permission-context"
import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { columns } from "./columns"
import { createFaqRowActions, faqBulkActions } from "./faq-actions"
import { faqAvailableFields } from "./fields"
import type { FaqsWithExpanded } from "@/types/expanded"
import type { AdvancedFilter } from "@/types/data-table"
import { FaqService } from "@/services/faq.service"

export default function FAQsPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/support")
    }
  }, [loading, hasPermission, router])

  const faqRowActions = useCallback(() =>
    createFaqRowActions((path: string) => router.push(path)), 
    [router]
  )

  const handleAdvancedFilter = useCallback((filters: AdvancedFilter[]) => {
    // Advanced filter handling is managed by the EnhancedBackendDataTable
    console.log('Advanced filters applied:', filters)
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="FAQ Management"
        description="Manage frequently asked questions and knowledge base"
        actions={[
          ...(hasPermission("content", "create:any") ? [{
            label: "Add FAQ",
            onClick: () => router.push('/support/faqs/create'),
            icon: <Plus className="h-4 w-4" />
          }] : []),
          {
            label: "Manage Tags",
            onClick: () => router.push('/support/faqs/tags'),
            variant: "outline" as const,
            icon: <Settings className="h-4 w-4" />
          }
        ]}
      />

      <EnhancedBackendDataTable<FaqsWithExpanded>
        collection="help-faqs"
        loadPage={FaqService.loadPage.bind(FaqService)}
        columns={columns}
        searchable={true}
        searchFields={["question", "answer", "keywords"]}
        selectable={true}
        exportable={true}
        availableFields={faqAvailableFields}
        rowActions={faqRowActions()}
        bulkActions={faqBulkActions}
        persistColumnConfig={true}
        tableContext="faq-management"
        onAdvancedFilter={handleAdvancedFilter}
      />
    </div>
  )
}
