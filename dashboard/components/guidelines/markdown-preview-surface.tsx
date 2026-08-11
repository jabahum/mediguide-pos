"use client"

import { BookOpen, FileText } from "lucide-react"

import { MarkdownPreview } from "./markdown-preview"
import { markdownHeadings } from "./markdown-authoring"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import type { GuidelineAsset } from "@/services/guideline-assets.service"

export type MarkdownPreviewPresentation =
  | "rendered"
  | "public-reader"
  | "structured-reader"
  | "print"

interface MarkdownPreviewSurfaceProps {
  content: string
  title: string
  versionLabel: string
  presentation: MarkdownPreviewPresentation
  className?: string
  assets?: GuidelineAsset[]
}

export function MarkdownPreviewSurface({
  content,
  title,
  versionLabel,
  presentation,
  className,
  assets = [],
}: MarkdownPreviewSurfaceProps) {
  const headings = markdownHeadings(content)

  if (presentation === "rendered") {
    return <MarkdownPreview content={content} className={className} assets={assets} />
  }

  if (presentation === "public-reader") {
    return (
      <section
        aria-label="Public reader preview"
        className={cn("overflow-hidden rounded-xl border bg-background shadow-sm", className)}
      >
        <header className="border-b bg-muted/30 px-5 py-4">
          <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
            <BookOpen className="h-4 w-4" />
            <span>MediGuide Clinical Guidelines</span>
            <Badge variant="secondary">Draft preview</Badge>
          </div>
          <h1 className="mt-3 text-2xl font-bold tracking-tight">{title}</h1>
          <p className="mt-1 text-sm text-muted-foreground">Version {versionLabel}</p>
        </header>
        <div className="px-5 py-6 sm:px-8">
          <MarkdownPreview content={content} assets={assets} />
        </div>
      </section>
    )
  }

  if (presentation === "structured-reader") {
    return (
      <section
        aria-label="Structured reader preview"
        className={cn("overflow-hidden rounded-xl border bg-background", className)}
      >
        <header className="border-b px-5 py-4">
          <div className="flex flex-wrap items-center gap-2">
            <FileText className="h-4 w-4 text-primary" />
            <span className="font-semibold">{title}</span>
            <Badge variant="secondary">Draft layout</Badge>
          </div>
          <p className="mt-2 text-xs text-muted-foreground">
            This layout is generated from the current Markdown. Canonical structured content changes only after regeneration.
          </p>
        </header>
        <div className="grid md:grid-cols-[190px_minmax(0,1fr)]">
          <nav aria-label="Structured preview contents" className="hidden border-r bg-muted/20 p-4 md:block">
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Contents</p>
            <ol className="space-y-2 text-xs">
              {headings.map((heading, index) => (
                <li key={`${heading.id}-${index}`} style={{ paddingLeft: `${(heading.level - 1) * 8}px` }}>
                  {heading.text}
                </li>
              ))}
            </ol>
          </nav>
          <div className="min-w-0 p-5 sm:p-8">
            <MarkdownPreview content={content} assets={assets} />
          </div>
        </div>
      </section>
    )
  }

  return (
    <article
      aria-label="Print preview"
      className={cn("mx-auto max-w-[210mm] bg-white px-[16mm] py-[14mm] text-black shadow-sm print:max-w-none print:p-0 print:shadow-none", className)}
    >
      <header className="mb-8 border-b border-black/20 pb-5">
        <p className="text-xs font-semibold uppercase tracking-wide">MediGuide clinical guideline · Draft preview</p>
        <h1 className="mt-2 text-3xl font-bold">{title}</h1>
        <p className="mt-1 text-sm">Version {versionLabel}</p>
      </header>
      <MarkdownPreview content={content} className="text-black" assets={assets} />
    </article>
  )
}
