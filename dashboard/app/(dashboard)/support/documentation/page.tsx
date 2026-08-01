"use client"

import { useMemo, useEffect } from "react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { EnhancedBackendDataTable } from "@/components/ui/enhanced-backend-data-table"
import { documentationColumns, DocumentationType } from "./columns"
import { createDocumentationRowActions, documentationBulkActions } from "./documentation-actions"
import { documentationAvailableFields } from "./fields"
import type { AdvancedFilter } from "@/types/data-table"
import { DocumentationService } from "@/services/documentation.service"

export default function DocumentationPage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/support")
    }
  }, [loading, hasPermission, router])

  // Create row actions with proper navigation
  const documentationRowActions = useMemo(() => 
    createDocumentationRowActions((path) => router.push(path)), 
    [router]
  )

  // Event handlers (React 19 automatically optimizes these)
  const handleAdvancedFilter = (filters: AdvancedFilter[]) => {
    console.log('Advanced filters applied:', filters)
    // Advanced filters are converted to typed query parameters by the domain service.
  }

  const handleSelectionChange = (selectedDocs: DocumentationType[]) => {
    console.log('Selected documentation:', selectedDocs)
  }

  const handleDataChange = (docs: DocumentationType[]) => {
    console.log('Documentation data updated:', docs.length, 'entries')
  }

  const handleError = (error: Error) => {
    console.error('Documentation table error:', error)
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Documentation"
        description="Manage system documentation, guides, and knowledge base articles"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Add Documentation",
            onClick: () => router.push('/support/documentation/create'),
            icon: <Plus className="h-4 w-4" />
          },
        ] : []}
      />

      {/* Enhanced DataTable */}
      <EnhancedBackendDataTable<DocumentationType>
        // Collection settings
        collection="help-documentation"
        loadPage={DocumentationService.loadPage.bind(DocumentationService)}
        columns={documentationColumns}
        // Pagination
        defaultPageSize={20}
        pageSizeOptions={[10, 20, 50, 100]}

        // Search
        searchable={true}
        searchFields={["title", "description", "content", "category", "tags"]}
        searchPlaceholder="Search documentation by title, description, content, category, or tags..."

        // Selection and actions
        selectable={true}
        enableSelectAll={true}
        rowActions={documentationRowActions}
        bulkActions={documentationBulkActions}

        // Export/Import
        exportable={true}
        importable={true}
        exportConfig={{
          formats: ['csv', 'json', 'xlsx'],
          filename: 'mediguide-documentation',
          includeHeaders: true,
        }}
        importConfig={{
          formats: ['csv', 'json'],
          validateData: async (data: unknown[]) => {
            // Basic validation for imported documentation data
            const valid: Record<string, unknown>[] = []
            const errors: string[] = []

            data.forEach((item: unknown, index: number) => {
              const record = item as Record<string, unknown>
              if (!record.title) {
                errors.push(`Row ${index + 1}: Title is required`)
                return
              }
              if (!record.content) {
                errors.push(`Row ${index + 1}: Content is required`)
                return
              }

              valid.push({
                ...record,
                title: record.title,
                description: record.description || "",
                content: record.content,
                category: record.category || "",
                tags: record.tags || "",
                status: record.status || "draft"
              })
            })

            return { valid, errors }
          },
        }}

        // UI customization
        toolbar={true}
        columnVisibility={true}
        availableFields={documentationAvailableFields}

        // Column persistence (will remember user's column preferences)
        persistColumnConfig={true}
        tableContext="documentation-management"

        // Event handlers
        onSelectionChange={handleSelectionChange}
        onDataChange={handleDataChange}
        onError={handleError}
        onAdvancedFilter={handleAdvancedFilter}
      />
    </div>
  )
}
