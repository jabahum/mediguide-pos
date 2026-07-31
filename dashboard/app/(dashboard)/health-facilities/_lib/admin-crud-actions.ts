"use client"

import { Edit, Trash2 } from "lucide-react"

import { showToast } from "@/lib/toast"
import { BaseRecord, BulkAction, RowAction } from "@/types/data-table"

interface AdminRowActionsConfig<T extends BaseRecord> {
  entityLabel: string
  getDisplayName: (row: T) => string
  onEdit: (row: T) => void
  deleteRecord: (id: string) => Promise<unknown>
}

export function createAdminRowActions<T extends BaseRecord>(
  config: AdminRowActionsConfig<T>
): RowAction<T>[] {
  const { entityLabel, getDisplayName, onEdit, deleteRecord } = config
  return [
    {
      id: "edit",
      label: `Edit ${entityLabel}`,
      icon: Edit,
      onClick: (row) => onEdit(row),
    },
    {
      id: "delete",
      label: `Delete ${entityLabel}`,
      icon: Trash2,
      variant: "destructive",
      onClick: async (row) => {
        try {
          await deleteRecord(row.id)
          showToast.success(
            `${entityLabel} Deleted`,
            `${getDisplayName(row)} has been deleted`
          )
        } catch (error) {
          const message =
            error instanceof Error
              ? error.message
              : `Failed to delete ${entityLabel.toLowerCase()}`
          showToast.error("Delete Failed", message)
          throw error
        }
      },
      confirmMessage: `Are you sure you want to delete this ${entityLabel.toLowerCase()}? This action cannot be undone.`,
      separator: true,
    },
  ]
}

interface AdminBulkActionsConfig {
  entityLabel: string
  entityLabelPlural?: string
  deleteRecord: (id: string) => Promise<unknown>
}

export function createAdminBulkActions<T extends BaseRecord>(
  config: AdminBulkActionsConfig
): BulkAction<T>[] {
  const { entityLabel, entityLabelPlural = `${entityLabel}s`, deleteRecord } = config
  return [
    {
      id: "bulk-delete",
      label: "Delete Selected",
      icon: Trash2,
      variant: "destructive",
      requiresConfirmation: true,
      confirmMessage: `Delete all selected ${entityLabelPlural.toLowerCase()}? This action cannot be undone.`,
      description: `Permanently delete the selected ${entityLabelPlural.toLowerCase()}.`,
      onClick: async (rows) => {
        let successCount = 0
        let errorCount = 0

        for (const row of rows) {
          try {
            await deleteRecord(row.id)
            successCount++
          } catch (error) {
            errorCount++
            console.error(
              `Failed to delete ${entityLabel.toLowerCase()} ${row.id}:`,
              error
            )
          }
        }

        if (successCount > 0) {
          showToast.success(
            `${entityLabelPlural} Deleted`,
            `${successCount} ${successCount === 1 ? entityLabel.toLowerCase() : entityLabelPlural.toLowerCase()} deleted`
          )
        }
        if (errorCount > 0) {
          showToast.error(
            "Some Deletes Failed",
            `${errorCount} ${errorCount === 1 ? entityLabel.toLowerCase() : entityLabelPlural.toLowerCase()} could not be deleted`
          )
        }
        if (successCount === 0) {
          throw new Error(`Failed to delete any ${entityLabelPlural.toLowerCase()}`)
        }
      },
    },
  ]
}
