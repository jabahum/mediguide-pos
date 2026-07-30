import { RowAction, BulkAction } from "@/types/data-table"
import { DecisionToolWithRelations } from "./types"
import { CalculatorsStatusOptions } from "@/types/backend-types"
import {
  Eye,
  Edit,
  Copy,
  Trash2,
  FileDown,
  CheckCircle,
  Archive,
  Clock,
} from "lucide-react"
import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { downloadJson } from "@/lib/client-download"

const backend = getBackendClient()

function getExportFilename(prefix: string) {
  return `${prefix}-${new Date().toISOString().slice(0, 10)}.json`
}

async function updateToolStatus(
  tools: DecisionToolWithRelations[],
  status: CalculatorsStatusOptions,
  actionLabel: string
) {
  const results = await Promise.allSettled(
    tools.map((tool) => backend.resource("calculators").update(tool.id, { status }))
  )

  const successCount = results.filter((result) => result.status === "fulfilled").length
  const errorCount = results.length - successCount

  if (successCount > 0) {
    showToast.success(
      `${actionLabel} Complete`,
      errorCount > 0
        ? `${successCount} updated, ${errorCount} failed`
        : `${successCount} tools updated`
    )
  }

  if (errorCount > 0) {
    showToast.error("Some Updates Failed", `${errorCount} tools could not be updated`)
  }
}

async function deleteTool(tool: DecisionToolWithRelations) {
  await backend.resource("calculators").delete(tool.id)
  showToast.success("Decision Tool Deleted", `"${tool.name}" was deleted`)
}

async function deleteManyTools(tools: DecisionToolWithRelations[]) {
  const results = await Promise.allSettled(
    tools.map((tool) => backend.resource("calculators").delete(tool.id))
  )

  const successCount = results.filter((result) => result.status === "fulfilled").length
  const errorCount = results.length - successCount

  if (successCount > 0) {
    showToast.success(
      "Bulk Delete Complete",
      errorCount > 0
        ? `${successCount} deleted, ${errorCount} failed`
        : `${successCount} tools deleted`
    )
  }

  if (errorCount > 0) {
    showToast.error("Some Deletes Failed", `${errorCount} tools could not be deleted`)
  }
}

function openTestPages(tools: DecisionToolWithRelations[]) {
  const testableTools = tools.filter(
    (tool) => tool.status !== CalculatorsStatusOptions.archived
  )

  if (testableTools.length === 0) {
    showToast.warning("No Testable Tools", "Archived tools cannot be opened in test mode")
    return
  }

  let openedCount = 0
  testableTools.forEach((tool) => {
    const openedWindow = window.open(
      `/decision-tools/${tool.id}/test`,
      "_blank",
      "noopener,noreferrer"
    )

    if (openedWindow) {
      openedCount += 1
    }
  })

  if (openedCount === 0) {
    showToast.error("Popup Blocked", "Allow popups to open the tool test pages")
    return
  }

  showToast.success(
    "Test Pages Opened",
    `Opened ${openedCount} tool${openedCount === 1 ? "" : "s"} in test mode`
  )
}

/**
 * Row actions for individual decision tool records
 * Factory pattern for dependency injection
 */
export const createDecisionToolRowActions = (
  navigate: (path: string) => void
): RowAction<DecisionToolWithRelations>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (tool) => {
      navigate(`/decision-tools/${tool.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit Tool",
    icon: Edit,
    onClick: async (tool) => {
      navigate(`/decision-tools/${tool.id}/edit`)
    },
  },
  {
    id: "duplicate",
    label: "Duplicate Tool",
    icon: Copy,
    onClick: async (tool) => {
      navigate(`/decision-tools/create?duplicate=${tool.id}`)
    },
    separator: true,
  },
  {
    id: "test",
    label: "Test Tool",
    icon: CheckCircle,
    onClick: async (tool) => {
      navigate(`/decision-tools/${tool.id}/test`)
    },
    disabled: (tool) => tool.status === CalculatorsStatusOptions.archived,
    separator: true,
  },
  {
    id: "export",
    label: "Export Tool Data",
    icon: FileDown,
    onClick: async (tool) => {
      downloadJson(tool, getExportFilename(`decision-tool-${tool.id}`))
      showToast.success("Export Complete", `"${tool.name}" was exported`)
    },
  },
  {
    id: "delete",
    label: "Delete Tool",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tool) => {
      await deleteTool(tool)
    },
    disabled: (tool) => tool.status === CalculatorsStatusOptions.active,
    confirmMessage:
      "Are you sure you want to delete this decision tool? This action cannot be undone and will remove the tool and all its data.",
    separator: true,
  },
]

/**
 * Bulk actions for multiple selected decision tool records
 */
export const decisionToolBulkActions: BulkAction<DecisionToolWithRelations>[] = [
  {
    id: "bulk-activate",
    label: "Activate Tools",
    icon: CheckCircle,
    onClick: async (tools) => {
      await updateToolStatus(tools, CalculatorsStatusOptions.active, "Activation")
    },
    disabled: (tools) => tools.every((tool) => tool.status === CalculatorsStatusOptions.active),
    description: "Change status to active for selected tools",
  },
  {
    id: "bulk-draft",
    label: "Set as Draft",
    icon: Clock,
    variant: "outline",
    onClick: async (tools) => {
      await updateToolStatus(tools, CalculatorsStatusOptions.draft, "Draft Update")
    },
    disabled: (tools) => tools.every((tool) => tool.status === CalculatorsStatusOptions.draft),
    description: "Change status to draft for selected tools",
  },
  {
    id: "bulk-archive",
    label: "Archive Tools",
    icon: Archive,
    variant: "outline",
    onClick: async (tools) => {
      await updateToolStatus(tools, CalculatorsStatusOptions.archived, "Archiving")
    },
    disabled: (tools) => tools.every((tool) => tool.status === CalculatorsStatusOptions.archived),
    description: "Archive selected tools (removes from active use)",
    separator: true,
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: FileDown,
    variant: "outline",
    onClick: async (tools) => {
      downloadJson(tools, getExportFilename("decision-tools-export"))
      showToast.success("Export Complete", `Exported ${tools.length} tools`)
    },
    description: "Export selected tools with their configurations",
  },
  {
    id: "bulk-test",
    label: "Test Selected Tools",
    icon: CheckCircle,
    variant: "outline",
    onClick: async (tools) => {
      openTestPages(tools)
    },
    disabled: (tools) => tools.some((tool) => tool.status === CalculatorsStatusOptions.archived),
    description: "Open testing interface for selected active tools",
    separator: true,
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (tools) => {
      await deleteManyTools(tools)
    },
    disabled: (tools) => tools.some((tool) => tool.status === CalculatorsStatusOptions.active),
    description: "Permanently delete selected tools (only draft/archived tools)",
    confirmMessage:
      "Are you sure you want to delete the selected decision tools? This action cannot be undone and will remove all tool data.",
    separator: true,
  },
]
