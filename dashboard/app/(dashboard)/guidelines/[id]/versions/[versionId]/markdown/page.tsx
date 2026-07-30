"use client"

import * as React from "react"
import Link from "next/link"
import { useParams, useRouter } from "next/navigation"
import { AlertCircle, ArrowLeft, FileText, RefreshCw } from "lucide-react"

import { GuidelineMarkdownEditor } from "@/components/guidelines/guideline-markdown-editor"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { usePermissionContext } from "@/lib/permission-context"
import { BackendRequestError } from "@/lib/backend-client"
import {
  GuidelineDocumentRecord,
  GuidelineDocumentsService,
  GuidelineVersionRecord,
} from "@/services/guideline-documents.service"
import {
  GuidelineMarkdownError,
  GuidelineMarkdownService,
} from "@/services/guideline-markdown.service"

interface EditorData {
  document: GuidelineDocumentRecord
  version: GuidelineVersionRecord
  markdown: string
}

function EditorSkeleton() {
  return (
    <div className="space-y-5">
      <Skeleton className="h-5 w-72" />
      <div className="space-y-2">
        <Skeleton className="h-9 w-96 max-w-full" />
        <Skeleton className="h-5 w-64 max-w-full" />
      </div>
      <Skeleton className="h-[68vh] w-full rounded-lg" />
    </div>
  )
}

export default function GuidelineMarkdownPage() {
  const params = useParams<{ id: string; versionId: string }>()
  const router = useRouter()
  const { hasPermission, loading: permissionsLoading } = usePermissionContext()
  const [data, setData] = React.useState<EditorData | null>(null)
  const [error, setError] = React.useState<GuidelineMarkdownError | null>(null)
  const [loading, setLoading] = React.useState(true)
  const requestId = React.useRef(0)

  const canRead =
    hasPermission("content", "read:any") || hasPermission("content", "read:own")
  const canUpdate =
    hasPermission("content", "update:any") || hasPermission("content", "update:own")

  const load = React.useCallback(async () => {
    const currentRequest = ++requestId.current
    setLoading(true)
    setError(null)

    try {
      const document = await GuidelineDocumentsService.getDocument(params.id)
      const version = document.versions.find((item) => item.id === params.versionId)
      if (!version) {
        throw new GuidelineMarkdownError(
          "This guideline version does not belong to the requested document.",
          404,
        )
      }
      const markdown = await GuidelineMarkdownService.load(params.versionId)
      if (currentRequest === requestId.current) {
        setData({ document, version, markdown })
      }
    } catch (loadError) {
      if (currentRequest !== requestId.current) return
      setError(
        loadError instanceof GuidelineMarkdownError
          ? loadError
          : loadError instanceof BackendRequestError
            ? new GuidelineMarkdownError(loadError.message, loadError.status)
          : new GuidelineMarkdownError(
              loadError instanceof Error ? loadError.message : "Failed to load guideline Markdown",
            ),
      )
    } finally {
      if (currentRequest === requestId.current) setLoading(false)
    }
  }, [params.id, params.versionId])

  React.useEffect(() => {
    if (permissionsLoading || !canRead) {
      setLoading(false)
      return
    }
    void load()
    return () => {
      requestId.current += 1
    }
  }, [canRead, load, permissionsLoading])

  if (permissionsLoading || loading) return <EditorSkeleton />

  if (!canRead || error?.status === 403) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertTitle>Permission denied</AlertTitle>
        <AlertDescription>
          Your role does not have permission to read extracted guideline Markdown.
        </AlertDescription>
      </Alert>
    )
  }

  if (error) {
    const missing = error.status === 404
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => router.push("/guidelines")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to guidelines
        </Button>
        <Alert variant={missing ? "default" : "destructive"}>
          <FileText className="h-4 w-4" />
          <AlertTitle>{missing ? "Markdown is not available" : "Could not load Markdown"}</AlertTitle>
          <AlertDescription>
            {error.message}
            {missing && " Upload and process a PDF for this version before opening the editor."}
          </AlertDescription>
        </Alert>
        <Button variant="outline" onClick={() => void load()}>
          <RefreshCw className="mr-2 h-4 w-4" />
          Try again
        </Button>
      </div>
    )
  }

  if (!data) return null

  const published = data.version.status.toLowerCase() === "published"

  return (
    <div className="space-y-5">
      <Breadcrumb>
        <BreadcrumbList>
          <BreadcrumbItem>
            <BreadcrumbLink asChild>
              <Link href="/guidelines">Guidelines</Link>
            </BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator />
          <BreadcrumbItem>
            <span className="max-w-56 truncate text-muted-foreground">{data.document.title}</span>
          </BreadcrumbItem>
          <BreadcrumbSeparator />
          <BreadcrumbItem>
            <BreadcrumbPage>Markdown</BreadcrumbPage>
          </BreadcrumbItem>
        </BreadcrumbList>
      </Breadcrumb>

      <header className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <Badge variant="outline">Version {data.version.version}</Badge>
            <Badge variant={published ? "default" : "secondary"}>{data.version.status}</Badge>
          </div>
          <h1 className="text-2xl font-semibold tracking-tight">{data.document.title}</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {canUpdate && !published
              ? "Review, edit, and preview the extracted clinical Markdown."
              : "Preview the extracted clinical Markdown in read-only mode."}
          </p>
        </div>
        <Button variant="outline" asChild>
          <Link href="/guidelines">
            <ArrowLeft className="mr-2 h-4 w-4" />
            All guidelines
          </Link>
        </Button>
      </header>

      <GuidelineMarkdownEditor
        key={data.version.id}
        versionId={data.version.id}
        initialContent={data.markdown}
        editable={canUpdate}
        published={published}
      />
    </div>
  )
}
