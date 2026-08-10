"use client"

import * as React from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { useParams, useRouter } from "next/navigation"
import { BookOpen, ClipboardCheck, Download, FileCode2, FilePlus2, Pencil, Send, Upload } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { LoadingState } from "@/components/ui/loading-state"
import { PageHeader } from "@/components/ui/page-header"
import { RichContent } from "@/components/ui/rich-content"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { usePermissionContext } from "@/lib/permission-context"
import { showToast } from "@/lib/toast"
import {
  CreateGuidelineVersionInput,
  guidelineDocumentsQueryKey,
  GuidelineDocumentsService,
  GuidelineVersionRecord,
} from "@/services/guideline-documents.service"
import {
  CreateVersionDialog,
  EditMarkdownDialog,
  UploadVersionDialog,
} from "../components/guideline-version-dialogs"

export default function GuidelineDetailsPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const queryClient = useQueryClient()
  const { hasPermission, loading: permissionsLoading } = usePermissionContext()
  const canUpdate = hasPermission("content", "update:any")
  const [createVersionOpen, setCreateVersionOpen] = React.useState(false)
  const [uploadVersion, setUploadVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [markdownVersion, setMarkdownVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [markdown, setMarkdown] = React.useState("")
  const [viewVersion, setViewVersion] = React.useState<GuidelineVersionRecord | null>(null)
  const [loadingMarkdown, setLoadingMarkdown] = React.useState(false)
  const [submitting, setSubmitting] = React.useState(false)

  React.useEffect(() => {
    if (!permissionsLoading && !hasPermission("content", "read:any")) router.replace("/")
  }, [hasPermission, permissionsLoading, router])

  const documentQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, id],
    queryFn: () => GuidelineDocumentsService.getDocument(id),
    enabled: Boolean(id),
  })
  const sectionsQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, id, viewVersion?.id, "sections"],
    queryFn: () => GuidelineDocumentsService.listSections(viewVersion!.id),
    enabled: Boolean(viewVersion),
  })
  const fullMarkdownQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, id, viewVersion?.id, "markdown"],
    queryFn: () => GuidelineDocumentsService.getExtractedMarkdown(viewVersion!.id),
    enabled: Boolean(viewVersion?.markdown_file_key),
  })

  React.useEffect(() => {
    if (!viewVersion && documentQuery.data?.versions.length) {
      const current = documentQuery.data.current_version_id
        ? documentQuery.data.versions.find((version) => version.id === documentQuery.data?.current_version_id)
        : null
      setViewVersion(current || documentQuery.data.versions[0])
    }
  }, [documentQuery.data, viewVersion])

  const refresh = React.useCallback(async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: guidelineDocumentsQueryKey }),
      queryClient.invalidateQueries({ queryKey: [...guidelineDocumentsQueryKey, id] }),
    ])
  }, [id, queryClient])

  async function createVersion(payload: CreateGuidelineVersionInput) {
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.createVersion(id, payload)
      setCreateVersionOpen(false)
      await refresh()
      showToast.success("Version created", "Upload the source PDF to start extraction.")
    } catch (error) {
      showToast.error("Create failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function uploadPdf(file: File) {
    if (!uploadVersion) return
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.uploadVersionPdf(uploadVersion.id, file)
      setUploadVersion(null)
      await refresh()
      showToast.success("PDF uploaded", "Extraction has been queued.")
    } catch (error) {
      showToast.error("Upload failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function publish(version: GuidelineVersionRecord) {
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.publishVersion(version.id)
      await refresh()
      showToast.success("Version published", `${version.version} is now the current version.`)
    } catch (error) {
      showToast.error("Publish failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  async function openMarkdown(version: GuidelineVersionRecord) {
    setMarkdownVersion(version)
    setMarkdown("")
    setLoadingMarkdown(true)
    try {
      setMarkdown(await GuidelineDocumentsService.getExtractedMarkdown(version.id))
    } catch (error) {
      setMarkdownVersion(null)
      showToast.error("Load failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setLoadingMarkdown(false)
    }
  }

  async function saveMarkdown() {
    if (!markdownVersion) return
    setSubmitting(true)
    try {
      await GuidelineDocumentsService.updateExtractedMarkdown(markdownVersion.id, markdown)
      setMarkdownVersion(null)
      await refresh()
      showToast.success("Markdown updated", "The extracted Markdown file has been saved.")
    } catch (error) {
      showToast.error("Save failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  if (permissionsLoading || documentQuery.isLoading) return <LoadingState message="Loading guideline..." />
  if (!documentQuery.data) return <div className="p-6 text-destructive">Guideline not found.</div>
  const document = documentQuery.data

  return (
    <div className="space-y-6">
      <PageHeader
        title={document.title}
        description={document.description || "V2 guideline document and extraction versions."}
        actions={canUpdate ? [
          {
            label: "Edit Metadata",
            icon: <Pencil className="h-4 w-4" />,
            onClick: () => router.push(`/guidelines/${id}/edit`),
            variant: "outline",
          },
          {
            label: "New Version",
            icon: <FilePlus2 className="h-4 w-4" />,
            onClick: () => setCreateVersionOpen(true),
          },
        ] : []}
      />

      <div className="grid gap-4 md:grid-cols-4">
        {[
          ["Program area", document.program_area || "—"],
          ["Country", document.country || "—"],
          ["Source", document.source_org || "—"],
          ["Language", (document.language || "en").toUpperCase()],
        ].map(([label, value]) => (
          <Card key={label}>
            <CardContent className="pt-6">
              <div className="text-xs text-muted-foreground">{label}</div>
              <div className="mt-1 font-medium">{value}</div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader><CardTitle>Versions</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          {document.versions.length === 0 ? (
            <div className="rounded-md border border-dashed p-8 text-center text-muted-foreground">
              No versions yet. Create one before uploading a PDF.
            </div>
          ) : document.versions.map((version) => {
            const hasMarkdown = Boolean(version.markdown_file_key)
            const hasHtml = Boolean(version.html_file_key)
            const publishable = version.status !== "published" && Boolean(
              version.original_file_key && hasMarkdown && hasHtml
            )
            return (
              <div key={version.id} className="rounded-lg border p-4">
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-semibold">Version {version.version}</span>
                      <Badge variant={version.status === "published" ? "default" : "secondary"}>
                        {version.status}
                      </Badge>
                    </div>
                    <div className="mt-1 text-xs text-muted-foreground">
                      Published: {version.publication_date || "not set"} · Review: {version.review_date || "not set"}
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {canUpdate && (
                      <Button variant="outline" size="sm" onClick={() => setUploadVersion(version)}>
                        <Upload className="h-4 w-4" /> Upload PDF
                      </Button>
                    )}
                    {(hasMarkdown || hasHtml) && (
                      <Button variant="outline" size="sm" onClick={() => setViewVersion(version)}>
                        <BookOpen className="h-4 w-4" /> View Content
                      </Button>
                    )}
                    {canUpdate && version.original_file_key && version.status !== "published" && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => router.push(`/guidelines/${id}/versions/${version.id}/review`)}
                      >
                        <ClipboardCheck className="h-4 w-4" /> Editorial Review
                      </Button>
                    )}
                    {hasMarkdown && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => GuidelineDocumentsService.downloadExtractedAsset(
                          version.id, "md", `${document.title}-${version.version}.md`
                        )}
                      >
                        <Download className="h-4 w-4" /> Markdown
                      </Button>
                    )}
                    {hasHtml && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => GuidelineDocumentsService.downloadExtractedAsset(
                          version.id, "html", `${document.title}-${version.version}.html`
                        )}
                      >
                        <FileCode2 className="h-4 w-4" /> HTML
                      </Button>
                    )}
                    {canUpdate && hasMarkdown && version.status !== "published" && (
                      <Button variant="outline" size="sm" onClick={() => openMarkdown(version)}>
                        <Pencil className="h-4 w-4" /> Edit Markdown
                      </Button>
                    )}
                    {canUpdate && publishable && (
                      <Button size="sm" disabled={submitting} onClick={() => publish(version)}>
                        <Send className="h-4 w-4" /> Publish
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </CardContent>
      </Card>

      {viewVersion && (
        <Card>
          <CardHeader>
            <CardTitle>Version {viewVersion.version} content</CardTitle>
          </CardHeader>
          <CardContent>
            <Tabs defaultValue="sections">
              <TabsList>
                <TabsTrigger value="sections">Sections</TabsTrigger>
                <TabsTrigger value="markdown" disabled={!viewVersion.markdown_file_key}>
                  Entire Markdown
                </TabsTrigger>
              </TabsList>
              <TabsContent value="sections" className="mt-6">
                {sectionsQuery.isLoading ? (
                  <LoadingState size="sm" message="Loading extracted sections..." />
                ) : sectionsQuery.isError ? (
                  <div className="rounded-md border border-destructive p-4 text-sm text-destructive">
                    {sectionsQuery.error instanceof Error
                      ? sectionsQuery.error.message
                      : "Failed to load sections"}
                  </div>
                ) : sectionsQuery.data?.length ? (
                  <div className="space-y-4">
                    {sectionsQuery.data.map((section) => (
                      <article
                        key={section.id}
                        className="rounded-lg border p-5"
                        style={{ marginLeft: `${Math.max(0, section.level - 1) * 12}px` }}
                      >
                        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                          <h3 className="font-semibold">{section.title || "Untitled section"}</h3>
                          {(section.page_start || section.page_end) && (
                            <span className="text-xs text-muted-foreground">
                              Pages {section.page_start || section.page_end}
                              {section.page_end && section.page_end !== section.page_start
                                ? `–${section.page_end}`
                                : ""}
                            </span>
                          )}
                        </div>
                        {section.html ? (
                          <RichContent html={section.html} className="prose max-w-none dark:prose-invert" />
                        ) : (
                          <p className="whitespace-pre-wrap text-sm">{section.text}</p>
                        )}
                      </article>
                    ))}
                  </div>
                ) : (
                  <div className="rounded-md border border-dashed p-8 text-center text-muted-foreground">
                    No extracted sections are available for this version.
                  </div>
                )}
              </TabsContent>
              <TabsContent value="markdown" className="mt-6">
                {fullMarkdownQuery.isLoading ? (
                  <LoadingState size="sm" message="Loading complete Markdown..." />
                ) : fullMarkdownQuery.isError ? (
                  <div className="rounded-md border border-destructive p-4 text-sm text-destructive">
                    {fullMarkdownQuery.error instanceof Error
                      ? fullMarkdownQuery.error.message
                      : "Failed to load Markdown"}
                  </div>
                ) : (
                  <pre className="max-h-[70vh] overflow-auto whitespace-pre-wrap rounded-lg border bg-muted/30 p-5 font-mono text-sm">
                    {fullMarkdownQuery.data || "No Markdown content is available."}
                  </pre>
                )}
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      )}

      <CreateVersionDialog
        document={document}
        open={createVersionOpen}
        submitting={submitting}
        onOpenChange={setCreateVersionOpen}
        onSubmit={createVersion}
      />
      <UploadVersionDialog
        version={uploadVersion}
        open={Boolean(uploadVersion)}
        submitting={submitting}
        onOpenChange={(open) => !open && setUploadVersion(null)}
        onSubmit={uploadPdf}
      />
      <EditMarkdownDialog
        version={markdownVersion}
        open={Boolean(markdownVersion)}
        loading={loadingMarkdown}
        submitting={submitting}
        content={markdown}
        onContentChange={setMarkdown}
        onOpenChange={(open) => !open && setMarkdownVersion(null)}
        onSubmit={saveMarkdown}
      />
    </div>
  )
}
