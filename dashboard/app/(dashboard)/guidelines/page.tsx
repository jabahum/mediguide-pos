"use client"

import * as React from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"

import { DataTable } from "@/components/ui/data-table"
import { LoadingState } from "@/components/ui/loading-state"
import { PageHeader } from "@/components/ui/page-header"
import { usePermissionContext } from "@/lib/permission-context"
import { hasBackendPermission } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import {
  CreateGuidelineVersionInput,
  getDocumentLatestVersion,
  GuidelineDocumentRecord,
  GuidelineDocumentsService,
  GuidelineVersionRecord,
  guidelineDocumentsQueryKey,
} from "@/services/guideline-documents.service"
import { createGuidelinesColumns } from "./columns"
import {
  CreateVersionDialog,
  UploadVersionDialog,
} from "./components/guideline-version-dialogs"
import { GuidelineNotificationDialog } from "./components/guideline-notification-dialog"

export default function GuidelinesPage() {
  const router = useRouter()
  const queryClient = useQueryClient()
  const { hasPermission, loading: permissionsLoading } = usePermissionContext()
  const canUpdate = hasPermission("content", "update:any")
  const canNotify = hasBackendPermission("notification.campaign.manage")
  const [versionDocument, setVersionDocument] = React.useState<GuidelineDocumentRecord | null>(null)
  const [uploadVersion, setUploadVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [notificationDocument, setNotificationDocument] = React.useState<GuidelineDocumentRecord | null>(null)
  const [submitting, setSubmitting] = React.useState(false)

  React.useEffect(() => {
    if (!permissionsLoading && !hasPermission("content", "read:any")) router.replace("/")
  }, [hasPermission, permissionsLoading, router])

  const documentsQuery = useQuery({
    queryKey: guidelineDocumentsQueryKey,
    queryFn: () => GuidelineDocumentsService.listDocuments(),
  })

  const refresh = React.useCallback(
    () => queryClient.invalidateQueries({ queryKey: guidelineDocumentsQueryKey }),
    [queryClient]
  )

  const columns = React.useMemo(
    () =>
      createGuidelinesColumns({
        canUpdate,
        canNotify,
        onView: (document) => router.push(`/guidelines/${document.id}`),
        onEdit: (document) => router.push(`/guidelines/${document.id}/edit`),
        onNewVersion: setVersionDocument,
        onUpload: (document) => {
          const version = getDocumentLatestVersion(document)
          if (version) setUploadVersion(version)
        },
        onNotify: setNotificationDocument,
      }),
    [canNotify, canUpdate, router]
  )

  async function createVersion(payload: CreateGuidelineVersionInput) {
    if (!versionDocument) return
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.createVersion(versionDocument.id, payload)
      setVersionDocument(null)
      await refresh()
      showToast.success("Version created", "The new version is ready for PDF or Markdown upload.")
    } catch (error) {
      showToast.error("Create version failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function uploadSource(file: File) {
    if (!uploadVersion) return
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.uploadVersionSource(uploadVersion.id, file)
      setUploadVersion(null)
      await refresh()
      showToast.success("Source uploaded", "Document extraction and indexing have been queued.")
    } catch (error) {
      showToast.error("Upload failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  if (permissionsLoading || documentsQuery.isLoading) {
    return <LoadingState message="Loading guideline documents..." />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Medical Guidelines"
        description="Manage v2 guideline documents, extracted assets, and publication versions."
        actions={
          hasPermission("content", "create:any")
            ? [{
                label: "Create Guideline",
                onClick: () => router.push("/guidelines/create"),
                icon: <Plus className="h-4 w-4" />,
              }]
            : []
        }
      />

      {documentsQuery.isError ? (
        <div className="rounded-md border border-destructive p-4 text-sm text-destructive">
          {documentsQuery.error instanceof Error
            ? documentsQuery.error.message
            : "Failed to load guideline documents"}
        </div>
      ) : (
        <DataTable
          columns={columns}
          data={documentsQuery.data?.items || []}
          searchKey="title"
          searchPlaceholder="Search guideline titles..."
          tableClassName="min-w-[1260px]"
        />
      )}

      <CreateVersionDialog
        document={versionDocument}
        open={Boolean(versionDocument)}
        submitting={submitting}
        onOpenChange={(open) => !open && setVersionDocument(null)}
        onSubmit={createVersion}
      />
      <UploadVersionDialog
        version={uploadVersion}
        open={Boolean(uploadVersion)}
        submitting={submitting}
        onOpenChange={(open) => !open && setUploadVersion(null)}
        onSubmit={uploadSource}
      />
      <GuidelineNotificationDialog
        document={notificationDocument}
        open={Boolean(notificationDocument)}
        onOpenChange={(open) => !open && setNotificationDocument(null)}
      />
    </div>
  )
}
