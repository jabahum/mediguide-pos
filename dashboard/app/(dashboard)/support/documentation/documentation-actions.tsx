import { RowAction, BulkAction } from "@/types/data-table"
import { Eye, Edit, Trash2, Archive, FileText, Download, CheckCircle } from "lucide-react"
import { DocumentationResponse, DocumentationStatusOptions } from "@/types/backend-types"
import { DocumentationService } from "@/services/documentation.service"
import { showToast } from "@/lib/toast"

/**
 * Row Actions for Documentation Table
 * Factory pattern for dependency injection
 */
export const createDocumentationRowActions = (navigate: (path: string) => void): RowAction<DocumentationResponse>[] => [
  {
    id: "view",
    label: "View Documentation",
    icon: Eye,
    onClick: async (doc) => {
      navigate(`/support/documentation/${doc.id}`)
    },
  },
  {
    id: "edit", 
    label: "Edit Documentation",
    icon: Edit,
    onClick: async (doc) => {
      navigate(`/support/documentation/${doc.id}/edit`)
    },
  },
  {
    id: "toggle-status",
    label: "Change Status",
    icon: CheckCircle,
    onClick: async (doc) => {
      try {
        let newStatus: DocumentationStatusOptions
        
        switch (doc.status) {
          case DocumentationStatusOptions.draft:
            newStatus = DocumentationStatusOptions.published
            break
          case DocumentationStatusOptions.published:
            newStatus = DocumentationStatusOptions.archived
            break
          case DocumentationStatusOptions.archived:
            newStatus = DocumentationStatusOptions.draft
            break
          default:
            newStatus = DocumentationStatusOptions.published
        }

        await DocumentationService.update(doc.id, { status: newStatus })
        showToast.success("Status Updated", `Documentation status changed to ${newStatus}`)
      } catch (error) {
        showToast.error("Status Update Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    separator: true,
  },
  {
    id: "delete",
    label: "Delete Documentation",
    icon: Trash2,
    variant: "destructive",
    onClick: async (doc) => {
      try {
        await DocumentationService.delete(doc.id)
        showToast.success("Documentation Deleted", "Documentation entry has been deleted")
      } catch (error) {
        showToast.error("Delete Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    confirmMessage: "Are you sure you want to delete this documentation entry? This action cannot be undone.",
    separator: true,
  },
]

/**
 * Bulk Actions for Documentation Table
 */
export const documentationBulkActions: BulkAction<DocumentationResponse>[] = [
  {
    id: "bulk-publish",
    label: "Publish Selected",
    icon: CheckCircle,
    onClick: async (docs) => {
      try {
        const ids = docs.map(doc => doc.id)
        await DocumentationService.bulkUpdateStatus(ids, DocumentationStatusOptions.published)
        showToast.success("Documents Published", `Published ${docs.length} documentation entries`)
      } catch (error) {
        showToast.error("Bulk Publish Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    disabled: (docs) => docs.every(doc => doc.status === DocumentationStatusOptions.published),
    description: "Publish selected documentation entries",
  },
  {
    id: "bulk-draft",
    label: "Mark as Draft",
    icon: FileText,
    onClick: async (docs) => {
      try {
        const ids = docs.map(doc => doc.id)
        await DocumentationService.bulkUpdateStatus(ids, DocumentationStatusOptions.draft)
        showToast.success("Documents Marked as Draft", `Marked ${docs.length} entries as draft`)
      } catch (error) {
        showToast.error("Bulk Draft Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    disabled: (docs) => docs.every(doc => doc.status === DocumentationStatusOptions.draft),
    description: "Mark selected entries as draft",
  },
  {
    id: "bulk-archive",
    label: "Archive Selected",
    icon: Archive,
    onClick: async (docs) => {
      try {
        const ids = docs.map(doc => doc.id)
        await DocumentationService.bulkUpdateStatus(ids, DocumentationStatusOptions.archived)
        showToast.success("Documents Archived", `Archived ${docs.length} documentation entries`)
      } catch (error) {
        showToast.error("Bulk Archive Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    disabled: (docs) => docs.every(doc => doc.status === DocumentationStatusOptions.archived),
    description: "Archive selected documentation entries",
    separator: true,
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: Download,
    onClick: async (docs) => {
      try {
        // Create CSV content
        const headers = ["Title", "Description", "Category", "Status", "Tags", "Created", "Updated"]
        const csvContent = [
          headers.join(","),
          ...docs.map(doc => [
            `"${doc.title.replace(/"/g, '""')}"`,
            `"${(doc.description || '').replace(/"/g, '""')}"`,
            `"${(doc.category || '').replace(/"/g, '""')}"`,
            `"${doc.status || ''}"`,
            `"${(doc.tags || '').replace(/"/g, '""')}"`,
            `"${new Date(doc.created).toLocaleDateString()}"`,
            `"${new Date(doc.updated).toLocaleDateString()}"`
          ].join(","))
        ].join("\n")

        // Download CSV file
        const blob = new Blob([csvContent], { type: "text/csv" })
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement("a")
        a.href = url
        a.download = `documentation-export-${new Date().toISOString().split('T')[0]}.csv`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        window.URL.revokeObjectURL(url)

        showToast.success("Export Complete", `Exported ${docs.length} documentation entries`)
      } catch (error) {
        showToast.error("Export Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    description: "Export selected entries as CSV",
    variant: "outline",
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (docs) => {
      try {
        const ids = docs.map(doc => doc.id)
        await DocumentationService.bulkDelete(ids)
        showToast.success("Documents Deleted", `Deleted ${docs.length} documentation entries`)
      } catch (error) {
        showToast.error("Bulk Delete Failed", error instanceof Error ? error.message : "Unknown error")
      }
    },
    confirmMessage: "Are you sure you want to delete all selected documentation entries? This action cannot be undone.",
    description: "Permanently delete selected entries",
    separator: true,
    requiresConfirmation: true,
  },
]