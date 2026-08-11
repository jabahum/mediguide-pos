import { RowAction, BulkAction } from "@/types/data-table"
import { MedicalGuidelinesWithExpanded } from "@/types/expanded"
import { Eye, Edit, Copy, Trash2, Globe, Archive, ArchiveRestore, Download, Mail, CheckCircle, XCircle, FolderTree, Plus, ShieldCheck, Upload, FileText } from "lucide-react"
import { medicalGuidelineService } from "@/services/guideline-content.service"
import { showToast } from "@/lib/toast"

type MaybeAsync = void | Promise<void>

interface GuidelineRowActionsOptions {
  navigate: (path: string) => void
  canCreate?: boolean
  canUpdate?: boolean
  canDelete?: boolean
  onAssignIndex?: (guideline: MedicalGuidelinesWithExpanded) => void
  onMutationSuccess?: () => MaybeAsync
  onNewVersion?: (guideline: MedicalGuidelinesWithExpanded) => void
  onUploadSource?: (guideline: MedicalGuidelinesWithExpanded) => void
  onPublishVersion?: (guideline: MedicalGuidelinesWithExpanded) => void | Promise<void>
  onOpenMarkdown?: (guideline: MedicalGuidelinesWithExpanded) => void
  hasVersionDocument?: (guideline: MedicalGuidelinesWithExpanded) => boolean
  hasVersionRecord?: (guideline: MedicalGuidelinesWithExpanded) => boolean
  canPublishVersion?: (guideline: MedicalGuidelinesWithExpanded) => boolean
  versionActionsLoading?: boolean
}

/**
 * Row actions for medical guidelines table
 * Factory pattern to inject navigation, modal handlers, and post-mutation refresh
 */
export const createGuidelineRowActions = (
  options: GuidelineRowActionsOptions
): RowAction<MedicalGuidelinesWithExpanded>[] => {
  const {
    navigate,
    canCreate = false,
    canUpdate = false,
    canDelete = false,
    onAssignIndex,
    onMutationSuccess,
    onNewVersion,
    onUploadSource,
    onPublishVersion,
    onOpenMarkdown,
    hasVersionDocument,
    hasVersionRecord,
    canPublishVersion,
    versionActionsLoading,
  } = options
  const actions: RowAction<MedicalGuidelinesWithExpanded>[] = [
    {
      id: "view",
      label: "View Details",
      icon: Eye,
      onClick: async (guideline) => {
        navigate(`/guidelines/${guideline.id}`)
      },
    },
    {
      id: "edit",
      label: "Edit Guideline",
      icon: Edit,
      onClick: async (guideline) => {
        navigate(`/guidelines/${guideline.id}/edit`)
      },
    },
    {
      id: "assign-index",
      label: "Assign Index",
      icon: FolderTree,
      onClick: async (guideline) => {
        if (onAssignIndex) {
          onAssignIndex(guideline)
        } else {
          showToast.warning("Feature Not Available", "Index assignment is not configured")
        }
      },
    },
    {
      id: "duplicate",
      label: "Duplicate",
      icon: Copy,
      onClick: async (guideline) => {
        navigate(`/guidelines/create?duplicate=${guideline.id}`)
      },
      separator: true,
    },
    {
      id: "new-version",
      label: "New Version",
      icon: Plus,
      onClick: async (guideline) => {
        if (onNewVersion) {
          onNewVersion(guideline)
          return
        }
        showToast.warning("Version unavailable", "No linked guideline document was found for this row.")
      },
      disabled: (guideline) => versionActionsLoading || !hasVersionDocument?.(guideline),
    },
    {
      id: "upload-source",
      label: "Upload PDF or Markdown",
      icon: Upload,
      onClick: async (guideline) => {
        if (onUploadSource) {
          onUploadSource(guideline)
          return
        }
        showToast.warning(
          "Upload unavailable",
          "Create a version first, then upload its PDF or Markdown source.",
        )
      },
      disabled: (guideline) => versionActionsLoading || !hasVersionRecord?.(guideline),
    },
    {
      id: "markdown",
      label: canUpdate ? "Edit Markdown" : "Preview Markdown",
      icon: FileText,
      onClick: async (guideline) => {
        if (onOpenMarkdown) {
          onOpenMarkdown(guideline)
          return
        }
        showToast.warning("Markdown unavailable", "No extracted Markdown is linked to this row.")
      },
      disabled: (guideline) => versionActionsLoading || !hasVersionRecord?.(guideline),
    },
    {
      id: "publish-version",
      label: "Publish Version",
      icon: ShieldCheck,
      onClick: async (guideline) => {
        if (onPublishVersion) {
          await onPublishVersion(guideline)
          return
        }
        showToast.warning("Publish unavailable", "No publishable guideline version is linked to this row.")
      },
      disabled: (guideline) => versionActionsLoading || !canPublishVersion?.(guideline),
      separator: true,
    },
    {
      id: "toggle-publish",
      label: "Toggle Publish",
      icon: CheckCircle,
      onClick: async (guideline) => {
        const nextPublished = !guideline.is_published
        try {
          await medicalGuidelineService.update(guideline.id, {
            is_published: nextPublished,
            // When publishing, advance status to "published" unless already archived.
            // When unpublishing, leave status alone so reviewer/draft state survives.
            ...(nextPublished && guideline.status !== "archived"
              ? { status: "published" }
              : {}),
          })
          await onMutationSuccess?.()
          showToast.success(
            "Success",
            `Guideline ${nextPublished ? "published" : "unpublished"}`
          )
        } catch (error) {
          console.error("Failed to toggle publication:", error)
          showToast.error("Error", "Failed to update publication status")
        }
      },
      // Archived guidelines must be un-archived first before publishing.
      disabled: (guideline) =>
        guideline.status === "archived" && !guideline.is_published,
    },
    {
      id: "archive",
      label: "Archive",
      icon: Archive,
      onClick: async (guideline) => {
        try {
          await medicalGuidelineService.update(guideline.id, {
            status: "archived",
            is_published: false,
          })
          await onMutationSuccess?.()
          showToast.success("Success", "Guideline archived")
        } catch (error) {
          console.error("Failed to archive guideline:", error)
          showToast.error("Error", "Failed to archive guideline")
        }
      },
      disabled: (guideline) => guideline.status === "archived",
    },
    {
      id: "unarchive",
      label: "Unarchive",
      icon: ArchiveRestore,
      onClick: async (guideline) => {
        try {
          await medicalGuidelineService.update(guideline.id, {
            // Return to draft so it isn't auto-republished — user can publish explicitly.
            status: "draft",
          })
          await onMutationSuccess?.()
          showToast.success("Success", "Guideline restored to draft")
        } catch (error) {
          console.error("Failed to unarchive guideline:", error)
          showToast.error("Error", "Failed to unarchive guideline")
        }
      },
      disabled: (guideline) => guideline.status !== "archived",
      separator: true,
    },
    {
      id: "delete",
      label: "Delete Guideline",
      icon: Trash2,
      variant: "destructive",
      onClick: async (guideline) => {
        try {
          await medicalGuidelineService.delete(guideline.id)
          await onMutationSuccess?.()
          showToast.success("Success", "Guideline deleted")
        } catch (error) {
          console.error("Failed to delete guideline:", error)
          showToast.error("Error", "Failed to delete guideline")
        }
      },
      confirmMessage:
        "Are you sure you want to delete this guideline? This action cannot be undone.",
      disabled: (guideline) => guideline.is_published,
    },
  ]

  const createActions = new Set(["duplicate"])
  const updateActions = new Set([
    "edit",
    "assign-index",
    "new-version",
    "upload-pdf",
    "publish-version",
    "toggle-publish",
    "archive",
    "unarchive",
  ])

  return actions.filter((action) => {
    if (createActions.has(action.id)) return canCreate
    if (updateActions.has(action.id)) return canUpdate
    if (action.id === "delete") return canDelete
    return true
  })
}

interface GuidelineBulkActionsOptions {
  onMutationSuccess?: () => MaybeAsync
  canUpdate?: boolean
}

interface BulkResult {
  ok: number
  fail: number
}

async function runBulk<T extends MedicalGuidelinesWithExpanded>(
  rows: T[],
  fn: (row: T) => Promise<unknown>
): Promise<BulkResult> {
  let ok = 0
  let fail = 0
  for (const row of rows) {
    try {
      await fn(row)
      ok++
    } catch (error) {
      fail++
      console.error(`Bulk action failed for ${row.id}:`, error)
    }
  }
  return { ok, fail }
}

function reportBulk(
  { ok, fail }: BulkResult,
  successVerb: string,
  failureVerb: string
) {
  if (ok > 0) {
    showToast.success(
      "Bulk Action Complete",
      `${successVerb} ${ok} guideline${ok === 1 ? "" : "s"}`
    )
  }
  if (fail > 0) {
    showToast.error(
      "Some Failed",
      `${fail} guideline${fail === 1 ? "" : "s"} could not be ${failureVerb}`
    )
  }
  if (ok === 0 && fail > 0) {
    throw new Error(`Failed to ${failureVerb} any guidelines`)
  }
}

/**
 * Bulk actions for medical guidelines table
 */
export const createGuidelineBulkActions = (
  options: GuidelineBulkActionsOptions = {}
): BulkAction<MedicalGuidelinesWithExpanded>[] => {
  const { onMutationSuccess, canUpdate = false } = options
  const actions: BulkAction<MedicalGuidelinesWithExpanded>[] = [
    {
      id: "bulk-publish",
      label: "Publish Selected",
      icon: Globe,
      onClick: async (guidelines) => {
        // Match the single-row Toggle Publish rule: an archived guideline must
        // be unarchived before it can be published. Mirror that here so the
        // bulk action can't leave rows in the inconsistent "archived + published" state.
        const candidates = guidelines.filter((g) => !g.is_published)
        const targets = candidates.filter((g) => g.status !== "archived")
        const skippedArchived = candidates.length - targets.length

        if (targets.length === 0) {
          showToast.warning(
            "No Action Needed",
            skippedArchived > 0
              ? `Skipped ${skippedArchived} archived guideline${skippedArchived === 1 ? "" : "s"} — unarchive first to publish`
              : "All selected guidelines are already published"
          )
          return
        }

        const result = await runBulk(targets, (g) =>
          medicalGuidelineService.update(g.id, { is_published: true, status: "published" })
        )
        await onMutationSuccess?.()
        reportBulk(result, "Published", "publish")
        if (skippedArchived > 0) {
          showToast.info(
            "Some Skipped",
            `${skippedArchived} archived guideline${skippedArchived === 1 ? "" : "s"} skipped — unarchive first to publish`
          )
        }
      },
      disabled: (guidelines) =>
        guidelines.every((g) => g.is_published || g.status === "archived"),
      description: "Publish all selected unpublished guidelines",
    },
    {
      id: "bulk-unpublish",
      label: "Unpublish Selected",
      icon: XCircle,
      onClick: async (guidelines) => {
        const targets = guidelines.filter((g) => g.is_published)
        if (targets.length === 0) {
          showToast.warning(
            "No Action Needed",
            "No published guidelines selected"
          )
          return
        }
        const result = await runBulk(targets, (g) =>
          medicalGuidelineService.update(g.id, { is_published: false })
        )
        await onMutationSuccess?.()
        reportBulk(result, "Unpublished", "unpublish")
      },
      disabled: (guidelines) => guidelines.every((g) => !g.is_published),
      description: "Unpublish all selected published guidelines",
    },
    {
      id: "bulk-archive",
      label: "Archive Selected",
      icon: Archive,
      onClick: async (guidelines) => {
        const targets = guidelines.filter((g) => g.status !== "archived")
        if (targets.length === 0) {
          showToast.warning(
            "No Action Needed",
            "All selected guidelines are already archived"
          )
          return
        }
        const result = await runBulk(targets, (g) =>
          medicalGuidelineService.update(g.id, { status: "archived", is_published: false })
        )
        await onMutationSuccess?.()
        reportBulk(result, "Archived", "archive")
      },
      disabled: (guidelines) => guidelines.every((g) => g.status === "archived"),
      description: "Archive all selected active guidelines",
      separator: true,
    },
    {
      id: "bulk-export",
      label: "Export Selected",
      icon: Download,
      onClick: async (guidelines) => {
        try {
          const data = guidelines.map((g) => ({
            condition_name: g.condition_name,
            icd10_code: g.icd10_code,
            status: g.status,
            is_published: g.is_published,
            priority: g.priority,
            created: g.created,
          }))

          const csv = [
            Object.keys(data[0]).join(","),
            ...data.map((row) => Object.values(row).join(",")),
          ].join("\n")

          const blob = new Blob([csv], { type: "text/csv" })
          const url = URL.createObjectURL(blob)
          const a = document.createElement("a")
          a.href = url
          a.download = `medical-guidelines-${new Date().toISOString().split("T")[0]}.csv`
          a.click()
          URL.revokeObjectURL(url)

          showToast.success("Success", `Exported ${guidelines.length} guidelines`)
        } catch {
          showToast.error("Error", "Failed to export guidelines")
        }
      },
      description: "Export selected guidelines as CSV file",
    },
    {
      id: "bulk-notify",
      label: "Send Notifications",
      icon: Mail,
      onClick: async (guidelines) => {
        const published = guidelines.filter((g) => g.is_published)
        if (published.length === 0) {
          showToast.warning(
            "No Action Needed",
            "No published guidelines selected for notification"
          )
          return
        }

        // Notification dispatch isn't wired yet — surface that clearly instead of faking success.
        showToast.info(
          "Not Implemented",
          "Sending notifications is not yet wired up"
        )
      },
      disabled: (guidelines) => guidelines.every((g) => !g.is_published),
      description: "Send update notifications for published guidelines",
    },
  ]

  const updateActions = new Set(["bulk-publish", "bulk-unpublish", "bulk-archive"])
  return actions.filter((action) => !updateActions.has(action.id) || canUpdate)
}
