"use client"

import * as React from "react"
import { useQuery } from "@tanstack/react-query"
import { BookOpen, Check, FileText, LayoutTemplate, Loader2, Upload } from "lucide-react"
import { useRouter } from "next/navigation"

import { GuidelineDocumentForm } from "../components/guideline-document-form"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { FileUpload } from "@/components/ui/file-upload"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { PageHeader } from "@/components/ui/page-header"
import { usePermissionContext } from "@/lib/permission-context"
import { showToast } from "@/lib/toast"
import {
  GuidelineDocumentInput,
  guidelineDocumentsQueryKey,
  GuidelineDocumentRecord,
  GuidelineDocumentsService,
  GuidelineVersionRecord,
} from "@/services/guideline-documents.service"
import { contentDiseaseService } from "@/services/content-hubs.service"

const stages = [
  "Create guideline",
  "Create version",
  "Upload version",
  "Review and edit",
] as const

export default function CreateGuidelinePage() {
  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()
  const [stage, setStage] = React.useState(0)
  const [document, setDocument] = React.useState<GuidelineDocumentRecord | null>(null)
  const [version, setVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [versionNumber, setVersionNumber] = React.useState("")
  const [publicationDate, setPublicationDate] = React.useState("")
  const [reviewDate, setReviewDate] = React.useState("")
  const [file, setFile] = React.useState<File | null>(null)
  const [submitting, setSubmitting] = React.useState(false)

  React.useEffect(() => {
    if (!loading && !hasPermission("content", "create:any")) router.replace("/guidelines")
  }, [hasPermission, loading, router])

  const reviewDocumentQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, document?.id, "create-review"],
    queryFn: () => GuidelineDocumentsService.getDocument(document!.id),
    enabled: stage === 3 && Boolean(document),
    refetchInterval: (query) => {
      const refreshed = query.state.data
      const refreshedVersion = refreshed?.versions.find((item) => item.id === version?.id)
      return refreshedVersion?.markdown_file_key ? false : 5000
    },
  })

  const reviewedVersion = reviewDocumentQuery.data?.versions.find((item) => item.id === version?.id)
  const extractionReady = Boolean(reviewedVersion?.markdown_file_key && reviewedVersion?.html_file_key)

  async function createDocument(payload: GuidelineDocumentInput) {
    setSubmitting(true)
    try {
      const { disease_ids = [], primary_disease_id, ...documentPayload } = payload
      const created = await GuidelineDocumentsService.createDocument(documentPayload)
      if (disease_ids.length) {
        await contentDiseaseService.replace("guideline", created.id, disease_ids, primary_disease_id)
      }
      setDocument({ ...created, versions: created.versions || [] })
      setStage(1)
      showToast.success("Guideline created", "Now add the first version.")
    } catch (error) {
      showToast.error("Create failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function createVersion() {
    if (!document || !versionNumber.trim()) return
    setSubmitting(true)
    try {
      const created = await GuidelineDocumentsService.createVersion(document.id, {
        version: versionNumber.trim(),
        publication_date: publicationDate || undefined,
        review_date: reviewDate || undefined,
      })
      setVersion(created)
      setStage(2)
      showToast.success("Version created", "Upload its PDF or Markdown source.")
    } catch (error) {
      showToast.error("Version failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function uploadVersion() {
    if (!version || !file) return
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.uploadVersionSource(version.id, file)
      setStage(3)
      showToast.success("Source uploaded", "Extraction and indexing are running. This page will refresh automatically.")
    } catch (error) {
      showToast.error("Upload failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create Guideline"
        description="Create the document, attach its first version, upload PDF or Markdown, and review the extraction."
      />

      <nav aria-label="Guideline creation progress" className="grid gap-2 md:grid-cols-4">
        {stages.map((label, index) => (
          <div
            key={label}
            className={`flex items-center gap-3 rounded-lg border p-3 ${
              index === stage ? "border-primary bg-primary/5" : ""
            }`}
          >
            <div
              className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-semibold ${
                index < stage
                  ? "bg-primary text-primary-foreground"
                  : index === stage
                    ? "border border-primary text-primary"
                    : "bg-muted text-muted-foreground"
              }`}
            >
              {index < stage ? <Check className="h-4 w-4" /> : index + 1}
            </div>
            <span className={index <= stage ? "font-medium" : "text-muted-foreground"}>{label}</span>
          </div>
        ))}
      </nav>

      {stage === 0 && (
        <GuidelineDocumentForm
          submitting={submitting}
          submitLabel="Create and Continue"
          onCancel={() => router.push("/guidelines")}
          onSubmit={createDocument}
        />
      )}

      {stage === 1 && (
        <Card>
          <CardHeader>
            <CardTitle>Create first version</CardTitle>
            <CardDescription>Add version metadata for {document?.title}.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <div className="space-y-2">
              <Label htmlFor="version">Version</Label>
              <Input
                id="version"
                value={versionNumber}
                onChange={(event) => setVersionNumber(event.target.value)}
                placeholder="2026.1"
              />
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="publication-date">Publication date</Label>
                <Input
                  id="publication-date"
                  type="date"
                  value={publicationDate}
                  onChange={(event) => setPublicationDate(event.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="review-date">Review date</Label>
                <Input
                  id="review-date"
                  type="date"
                  value={reviewDate}
                  onChange={(event) => setReviewDate(event.target.value)}
                />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}`)}>
                Finish Later
              </Button>
              <Button disabled={submitting || !versionNumber.trim()} onClick={createVersion}>
                {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileText className="h-4 w-4" />}
                Create Version
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {stage === 2 && (
        <Card>
          <CardHeader>
            <CardTitle>Upload guideline source</CardTitle>
            <CardDescription>Upload PDF or UTF-8 Markdown for version {version?.version} to begin extraction and indexing.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <FileUpload
              value={file || undefined}
              onValueChange={setFile}
              accept="application/pdf,text/markdown,.pdf,.md,.markdown"
              maxSize={100}
              placeholder="Choose guideline PDF or Markdown file"
            />
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}`)}>
                Finish Later
              </Button>
              <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}/versions/${version?.id}/markdown`)}>
                <BookOpen className="h-4 w-4" /> Start with blank Markdown
              </Button>
              <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}/versions/${version?.id}/markdown?start=template`)}>
                <LayoutTemplate className="h-4 w-4" /> Start from template
              </Button>
              <Button disabled={submitting || !file} onClick={uploadVersion}>
                {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Upload className="h-4 w-4" />}
                Upload and Review
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {stage === 3 && (
        <Card>
          <CardHeader>
            <CardTitle>Review and edit guideline</CardTitle>
            <CardDescription>
              {extractionReady
                ? "Review the complete extracted Markdown and make corrections before publishing."
                : "The worker is extracting and indexing the uploaded source. This page checks for updates every five seconds."}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            {!extractionReady ? (
              <div className="flex min-h-72 flex-col items-center justify-center gap-4 rounded-lg border border-dashed">
                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                <div className="text-center">
                  <div className="font-medium">Extraction in progress</div>
                  <div className="text-sm text-muted-foreground">
                    You may finish later and return to the guideline detail page.
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex min-h-72 flex-col items-center justify-center gap-4 rounded-lg border border-dashed text-center">
                <BookOpen className="h-9 w-9 text-primary" />
                <div>
                  <div className="font-medium">Your source is ready for authoring</div>
                  <div className="mt-1 text-sm text-muted-foreground">Continue in the full Markdown workspace to edit, preview, save revisions, and regenerate explicitly.</div>
                </div>
                <Button onClick={() => router.push(`/guidelines/${document?.id}/versions/${reviewedVersion?.id}/markdown`)}>
                  Open Markdown workspace
                </Button>
              </div>
            )}
            <div className="flex flex-wrap justify-end gap-2">
              <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}`)}>
                {extractionReady ? "View Guideline" : "Finish Later"}
              </Button>
              {extractionReady && <Button variant="outline" onClick={() => router.push(`/guidelines/${document?.id}/edit`)}>Edit Metadata</Button>}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
