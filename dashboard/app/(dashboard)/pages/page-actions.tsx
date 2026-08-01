"use client"

import { 
  Eye, 
  Edit, 
  Trash2, 
  FileText, 
  Download,
} from "lucide-react"

import { GenericPagesService } from "@/services/generic-pages.service"
import { showToast } from "@/lib/toast"
import { RowAction, BulkAction } from "@/types/data-table"
import { GenericPage } from "./columns"

// Helper function to delete a page
const deletePage = async (page: GenericPage) => {
  try {
    await GenericPagesService.deletePage(page.id)
    showToast.success("Page Deleted", `Page "${page.title}" has been deleted successfully`)
  } catch (error) {
    console.error('Error deleting page:', error)
    showToast.error("Delete Failed", error instanceof Error ? error.message : "Failed to delete page")
    throw error
  }
}

// Helper function to export pages data
const exportPagesData = async (pages: GenericPage[], format: 'csv' | 'json' = 'csv') => {
  try {
    const exportData = pages.map(page => ({
      title: page.title,
      key: page.key,
      description: page.description || '',
      hasContent: page.content !== null && page.content !== undefined,
      contentType: typeof page.content === 'object' ? 'structured' : 'simple',
      created: page.created,
      updated: page.updated,
    }))

    const filename = `pages-export-${new Date().toISOString().split('T')[0]}`
    
    if (format === 'json') {
      const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${filename}.json`
      a.click()
      URL.revokeObjectURL(url)
    } else {
      // CSV format
      const headers = ['Title', 'Key', 'Description', 'Has Content', 'Content Type', 'Created', 'Updated']
      const csvContent = [
        headers.join(','),
        ...exportData.map(page => [
          `"${page.title.replace(/"/g, '""')}"`,
          `"${page.key}"`,
          `"${page.description.replace(/"/g, '""')}"`,
          page.hasContent ? 'Yes' : 'No',
          page.contentType,
          page.created,
          page.updated,
        ].join(','))
      ].join('\n')
      
      const blob = new Blob([csvContent], { type: 'text/csv' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${filename}.csv`
      a.click()
      URL.revokeObjectURL(url)
    }

    showToast.success("Export Complete", `Successfully exported ${pages.length} pages`)
  } catch (error) {
    console.error('Error exporting pages:', error)
    showToast.error("Export Failed", "Failed to export pages data")
  }
}

// Factory function to create page row actions with navigation
export const createPageRowActions = (navigate: (path: string) => void): RowAction<GenericPage>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (page) => {
      navigate(`/pages/${page.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit Page",
    icon: Edit,
    onClick: async (page) => {
      navigate(`/pages/${page.id}/edit`)
    },
  },
  {
    id: "manage-content",
    label: "Manage Content",
    icon: FileText,
    onClick: async (page) => {
      // Navigate to the existing content management system
      navigate(`/generic-pages/${page.key}/content/create?returnTo=/pages`)
    },
    separator: true,
  },
  {
    id: "delete",
    label: "Delete Page",
    icon: Trash2,
    variant: "destructive",
    onClick: async (page) => {
      await deletePage(page)
    },
    confirmMessage: `Are you sure you want to delete this page? This action cannot be undone and will remove all associated content.`,
    separator: true,
  },
]

// Bulk actions for selected pages
export const pageBulkActions: BulkAction<GenericPage>[] = [
  {
    id: "bulk-export-csv",
    label: "Export as CSV",
    icon: Download,
    onClick: async (pages) => {
      await exportPagesData(pages, 'csv')
    },
    description: "Download selected pages data as CSV file",
  },
  {
    id: "bulk-export-json",
    label: "Export as JSON",
    icon: Download,
    variant: "outline",
    onClick: async (pages) => {
      await exportPagesData(pages, 'json')
    },
    description: "Download selected pages data as JSON file",
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (pages) => {
      try {
        await Promise.all(pages.map(page => GenericPagesService.deletePage(page.id)))
        
        showToast.success("Pages Deleted", `Successfully deleted ${pages.length} pages`)
      } catch (error) {
        console.error('Error deleting pages:', error)
        showToast.error("Delete Failed", "Failed to delete some pages")
        throw error
      }
    },
    disabled: (pages) => pages.length === 0,
    description: "Permanently delete all selected pages and their content",
    separator: true,
    requiresConfirmation: true,
  },
]
