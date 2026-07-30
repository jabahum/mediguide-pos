"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { useRouter } from "next/navigation"
import { useQuery, useQueryClient } from "@tanstack/react-query"

// Components
import { PageHeader } from "@/components/ui/page-header"
import { BackendDataTable } from "@/components/ui/backend-data-table"

// Page-specific imports
import { guidelinesColumns, MedicalGuidelineType } from "./columns"
import { createGuidelineRowActions, createGuidelineBulkActions } from "./guideline-actions"
import { medicalGuidelinesAvailableFields } from "./fields"
import { AssignIndexModal } from "./components/assign-index-modal"
import { CreateVersionDialog, UploadVersionDialog } from "./components/guideline-version-dialogs"
import { MedicalGuidelinesWithExpanded } from "@/types/expanded"
import { usePermissionContext } from "@/lib/permission-context"
import {
  buildGuidelineDocumentLookup,
  CreateGuidelineVersionInput,
  getDocumentCurrentVersion,
  GuidelineDocumentRecord,
  GuidelineDocumentsService,
  GuidelineVersionRecord,
  normalizeGuidelineDocumentKey,
} from "@/services/guideline-documents.service"
import { showToast } from "@/lib/toast"

const guidelineDocumentsQueryKey = ["v2-guideline-documents"]

export default function GuidelinesPage() {
  const router = useRouter()
  const queryClient = useQueryClient()

  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])
  
  // Modal state
  const [assignIndexModalOpen, setAssignIndexModalOpen] = React.useState(false)
  const [selectedGuideline, setSelectedGuideline] = React.useState<MedicalGuidelinesWithExpanded | null>(null)
  const [refreshKey, setRefreshKey] = React.useState(0)
  const [createVersionDocument, setCreateVersionDocument] = React.useState<GuidelineDocumentRecord | null>(null)
  const [uploadVersion, setUploadVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [submittingAction, setSubmittingAction] = React.useState<string | null>(null)

  const guidelineDocumentsQuery = useQuery({
    queryKey: guidelineDocumentsQueryKey,
    queryFn: () => GuidelineDocumentsService.listDocuments(),
  })

  const guidelineDocumentLookup = React.useMemo(
    () => buildGuidelineDocumentLookup(guidelineDocumentsQuery.data?.items || []),
    [guidelineDocumentsQuery.data?.items]
  )

  const getDocumentForGuideline = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    return guidelineDocumentLookup.get(normalizeGuidelineDocumentKey(guideline.condition_name as string))
  }, [guidelineDocumentLookup])

  const getVersionForGuideline = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    return getDocumentCurrentVersion(getDocumentForGuideline(guideline))
  }, [getDocumentForGuideline])

  // Handle assign index modal
  const handleAssignIndex = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    setSelectedGuideline(guideline)
    setAssignIndexModalOpen(true)
  }, [])

  // After any guideline mutation (publish toggle, archive, delete, bulk), drop the
  // list cache so the table refetches the latest rows.
  const handleMutationSuccess = React.useCallback(async () => {
    await queryClient.invalidateQueries({ queryKey: ["backend", "medical_guidelines"] })
  }, [queryClient])

  const refreshGuidelineDocuments = React.useCallback(async () => {
    await queryClient.invalidateQueries({ queryKey: guidelineDocumentsQueryKey })
  }, [queryClient])

  const handleModalSuccess = React.useCallback(() => {
    setRefreshKey(prev => prev + 1)
  }, [])

  const handleOpenNewVersion = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    const document = getDocumentForGuideline(guideline)
    if (!document) {
      showToast.warning("No linked document", `No v2 guideline document matched "${guideline.condition_name}".`)
      return
    }
    setCreateVersionDocument(document)
  }, [getDocumentForGuideline])

  const handleCreateVersion = React.useCallback(async (payload: CreateGuidelineVersionInput) => {
    if (!createVersionDocument) return

    setSubmittingAction("create-version")
    try {
      await GuidelineDocumentsService.createVersion(createVersionDocument.id, payload)
      showToast.success("Version created", "The new guideline version is ready for PDF upload.")
      setCreateVersionDocument(null)
      await refreshGuidelineDocuments()
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to create guideline version"
      showToast.error("Create version failed", message)
    } finally {
      setSubmittingAction(null)
    }
  }, [createVersionDocument, refreshGuidelineDocuments])

  const handleOpenUploadPdf = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    const version = getVersionForGuideline(guideline)
    if (!version) {
      showToast.warning("No version found", "Create a version for this guideline before uploading the PDF.")
      return
    }
    setUploadVersion(version)
  }, [getVersionForGuideline])

  const handleUploadPdf = React.useCallback(async (file: File) => {
    if (!uploadVersion) return

    setSubmittingAction(`upload:${uploadVersion.id}`)
    try {
      const job = await GuidelineDocumentsService.uploadVersionPdf(uploadVersion.id, file)
      showToast.success(
        "PDF uploaded",
        `Ingestion job queued with status: ${job.status}. Publish after extraction completes.`
      )
      setUploadVersion(null)
      await refreshGuidelineDocuments()
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to upload PDF"
      showToast.error("Upload failed", message)
    } finally {
      setSubmittingAction(null)
    }
  }, [refreshGuidelineDocuments, uploadVersion])

  const handlePublishVersion = React.useCallback(async (guideline: MedicalGuidelinesWithExpanded) => {
    const version = getVersionForGuideline(guideline)
    if (!version) {
      showToast.warning("No version found", "Create a version and upload a PDF before publishing.")
      return
    }

    setSubmittingAction(`publish:${version.id}`)
    try {
      await GuidelineDocumentsService.publishVersion(version.id)
      showToast.success("Version published", `Guideline version ${version.version} is now published.`)
      await refreshGuidelineDocuments()
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to publish guideline version"
      showToast.error("Publish failed", message)
    } finally {
      setSubmittingAction(null)
    }
  }, [getVersionForGuideline, refreshGuidelineDocuments])

  const handleOpenMarkdown = React.useCallback((guideline: MedicalGuidelinesWithExpanded) => {
    const document = getDocumentForGuideline(guideline)
    const version = getVersionForGuideline(guideline)
    if (!document || !version?.markdown_file_key) {
      showToast.warning(
        "Markdown unavailable",
        "Upload and process a PDF for this guideline version before opening Markdown.",
      )
      return
    }
    router.push(`/guidelines/${document.id}/versions/${version.id}/markdown`)
  }, [getDocumentForGuideline, getVersionForGuideline, router])

  // Create row actions with navigation and modal handlers
  const guidelineRowActions = React.useMemo(
    () =>
      createGuidelineRowActions({
        navigate: (path) => router.push(path),
        canCreate: hasPermission("content", "create:any"),
        canUpdate: hasPermission("content", "update:any"),
        canDelete: hasPermission("content", "delete:any"),
        onAssignIndex: handleAssignIndex,
        onMutationSuccess: handleMutationSuccess,
        onNewVersion: handleOpenNewVersion,
        onUploadPDF: handleOpenUploadPdf,
        onPublishVersion: handlePublishVersion,
        onOpenMarkdown: handleOpenMarkdown,
        hasVersionDocument: (guideline) => Boolean(getDocumentForGuideline(guideline)),
        hasVersionRecord: (guideline) => Boolean(getVersionForGuideline(guideline)),
        canPublishVersion: (guideline) => {
          const version = getVersionForGuideline(guideline)
          return Boolean(
            version &&
            version.status !== "published" &&
            version.original_file_key &&
            version.html_file_key &&
            version.markdown_file_key
          )
        },
        versionActionsLoading: guidelineDocumentsQuery.isLoading,
      }),
    [
      router,
      handleAssignIndex,
      handleMutationSuccess,
      handleOpenNewVersion,
      handleOpenUploadPdf,
      handlePublishVersion,
      handleOpenMarkdown,
      getDocumentForGuideline,
      getVersionForGuideline,
      guidelineDocumentsQuery.isLoading,
      hasPermission,
    ]
  )

  const guidelineBulkActions = React.useMemo(
    () => createGuidelineBulkActions({
      onMutationSuccess: handleMutationSuccess,
      canUpdate: hasPermission("content", "update:any"),
    }),
    [handleMutationSuccess, hasPermission]
  )

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Medical Guidelines"
        description="Comprehensive clinical guidelines and treatment protocols for health workers"
        actions={hasPermission("content", "create:any") ? [
          {
            label: "Create Guideline",
            onClick: () => router.push('/guidelines/create'),
            icon: <Plus className="h-4 w-4" />
          }
        ] : []}
      />

      {/* Simplified DataTable */}
      <BackendDataTable<MedicalGuidelineType>
        collection="medical_guidelines"
        columns={guidelinesColumns}
        searchFields={["condition_name", "icd10_code", "target_population"]}
        rowActions={guidelineRowActions}
        bulkActions={guidelineBulkActions}
        availableFields={medicalGuidelinesAvailableFields}
        query={{
          expand: "categories,tags,index_item",
          fields: "id,condition_name,icd10_code,target_population,medication_primary,medication_secondary,healthcare_level_required,route_administration,status,is_published,priority,version,created,updated,categories,tags,index_item,usageCount,expand.categories.id,expand.categories.name,expand.tags.id,expand.tags.name,expand.index_item.id,expand.index_item.title"
        }}
        ui={{
          exportable: true
        }}
        key={refreshKey}
      />

      {/* Assign Index Modal */}
      <AssignIndexModal
        open={assignIndexModalOpen}
        onOpenChange={setAssignIndexModalOpen}
        guideline={selectedGuideline}
        onSuccess={handleModalSuccess}
      />

      <CreateVersionDialog
        document={createVersionDocument}
        open={Boolean(createVersionDocument)}
        submitting={submittingAction === "create-version"}
        onOpenChange={(open) => {
          if (!open) setCreateVersionDocument(null)
        }}
        onSubmit={handleCreateVersion}
      />

      <UploadVersionDialog
        version={uploadVersion}
        open={Boolean(uploadVersion)}
        submitting={Boolean(uploadVersion && submittingAction === `upload:${uploadVersion.id}`)}
        onOpenChange={(open) => {
          if (!open) setUploadVersion(null)
        }}
        onSubmit={handleUploadPdf}
      />
    </div>
  )
}
