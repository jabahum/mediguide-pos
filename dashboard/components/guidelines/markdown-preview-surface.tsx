"use client"

import { BookOpen, FileText, Search } from "lucide-react"

import { MarkdownPreview } from "./markdown-preview"
import { markdownHeadings } from "./markdown-authoring"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import type { GuidelineAsset } from "@/services/guideline-assets.service"

export type MarkdownPreviewPresentation =
  | "rendered"
  | "public-reader"
  | "structured-reader"
  | "mobile-reader"
  | "search-result"
  | "rag-chunks"
  | "citations"
  | "table-of-contents"
  | "original-pdf"
  | "print"

interface MarkdownPreviewSurfaceProps {
  content: string
  title: string
  versionLabel: string
  presentation: MarkdownPreviewPresentation
  className?: string
  assets?: GuidelineAsset[]
}

function textOnly(markdown: string) {
  return markdown
    .replace(/```[\s\S]*?```/gu, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/gu, " ")
    .replace(/\[([^\]]+)\]\([^)]*\)/gu, "$1")
    .replace(/^[#>|*+\-\d.\s]+/gmu, "")
    .replace(/[*_`~]/gu, "")
    .replace(/\s+/gu, " ")
    .trim()
}

function draftChunks(content: string) {
  const sections = content.split(/(?=^#{1,6}\s+)/gmu).filter((value) => value.trim())
  return sections.map((value, index) => ({
    index: index + 1,
    content: textOnly(value).slice(0, 700),
  })).filter((item) => item.content)
}

export function MarkdownPreviewSurface({
  content,
  title,
  versionLabel,
  presentation,
  className,
  assets = [],
}: MarkdownPreviewSurfaceProps) {
  const originalPDF = assets.find((asset) => asset.type === "original_pdf" && asset.url)

  if (presentation === "rendered") {
    return <MarkdownPreview content={content} className={className} assets={assets} />
  }

  const headings = markdownHeadings(content)

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

  if (presentation === "mobile-reader") {
    return (
      <section aria-label="Flutter mobile reader preview" className={cn("mx-auto max-w-[390px] overflow-hidden rounded-[28px] border-8 border-foreground/90 bg-background shadow-xl", className)}>
        <header className="border-b px-5 py-4">
          <div className="flex items-center justify-between gap-2 text-xs text-muted-foreground"><span>MediGuide reader</span><Badge variant="secondary">Draft</Badge></div>
          <h1 className="mt-3 text-xl font-bold">{title}</h1>
          <p className="mt-1 text-xs text-muted-foreground">Version {versionLabel}</p>
        </header>
        <div className="max-h-[680px] overflow-y-auto px-5 py-5"><MarkdownPreview content={content} assets={assets} /></div>
      </section>
    )
  }

  if (presentation === "search-result") {
    const excerpt = textOnly(content).slice(0, 360)
    return (
      <section aria-label="Search result preview" className={cn("mx-auto max-w-2xl rounded-xl border bg-background p-5 shadow-sm", className)}>
        <div className="flex items-center gap-2 text-xs text-muted-foreground"><Search className="h-4 w-4" />Clinical guidelines <Badge variant="secondary">Draft preview</Badge></div>
        <h2 className="mt-3 text-lg font-semibold text-primary">{title}</h2>
        <p className="mt-1 text-xs text-muted-foreground">Version {versionLabel}</p>
        <p className="mt-3 text-sm leading-6">{excerpt || "No searchable content in this draft."}{excerpt.length === 360 ? "…" : ""}</p>
      </section>
    )
  }

  if (presentation === "rag-chunks") {
    const chunks = draftChunks(content)
    return (
      <section aria-label="RAG chunk preview" className={cn("space-y-3", className)}>
        <div className="rounded border border-amber-500/40 bg-amber-500/10 p-3 text-sm"><strong>Draft simulation.</strong> These are deterministic preview segments; production RAG is regenerated and reviewed before publication.</div>
        {chunks.length === 0 && <p className="text-sm text-muted-foreground">No chunkable content is present.</p>}
        {chunks.map((chunk) => <article key={chunk.index} className="rounded-lg border bg-background p-4"><div className="mb-2 text-xs font-medium text-muted-foreground">Draft chunk {chunk.index}</div><p className="text-sm leading-6">{chunk.content}</p></article>)}
      </section>
    )
  }

  if (presentation === "citations") {
    const links = [...content.matchAll(/\[([^\]]+)\]\(([^)]+)\)/gu)].filter((match) => !match[0].startsWith("!["))
    return (
      <section aria-label="Citation preview" className={cn("rounded-xl border bg-background p-5", className)}>
        <div className="flex items-center gap-2"><h2 className="font-semibold">Draft citations</h2><Badge variant="secondary">Not public</Badge></div>
        {!originalPDF && <p className="mt-3 text-sm text-muted-foreground">Page citations are unavailable because this version has no PDF provenance.</p>}
        {links.length === 0 ? <p className="mt-3 text-sm text-muted-foreground">No Markdown links or references were found.</p> : <ol className="mt-4 list-decimal space-y-2 pl-5 text-sm">{links.map((match, index) => <li key={`${match[2]}-${index}`}><span className="font-medium">{match[1]}</span><span className="block break-all text-xs text-muted-foreground">{match[2]}</span></li>)}</ol>}
      </section>
    )
  }

  if (presentation === "table-of-contents") {
    return (
      <nav aria-label="Table of contents preview" className={cn("rounded-xl border bg-background p-5", className)}>
        <div className="flex items-center gap-2"><h2 className="font-semibold">On this page</h2><Badge variant="secondary">Draft</Badge></div>
        {headings.length === 0 ? <p className="mt-3 text-sm text-muted-foreground">Add headings to create a table of contents.</p> : <ol className="mt-4 space-y-2 text-sm">{headings.map((heading, index) => <li key={`${heading.id}-${index}`} className="rounded border px-3 py-2" style={{ marginLeft: `${Math.max(0, heading.level - 1) * 12}px` }}>{heading.text}</li>)}</ol>}
      </nav>
    )
  }

  if (presentation === "original-pdf") {
    if (!originalPDF) return <div className={cn("rounded-xl border p-6 text-sm text-muted-foreground", className)}>Original-PDF comparison is unavailable for this Markdown-only version.</div>
    return (
      <section aria-label="Original PDF comparison" className={cn("grid min-h-[680px] gap-3 lg:grid-cols-2", className)}>
        <div className="overflow-auto rounded border p-4"><div className="mb-3 flex items-center gap-2 text-sm font-medium">Draft Markdown <Badge variant="secondary">Draft</Badge></div><MarkdownPreview content={content} assets={assets} /></div>
        <div className="overflow-hidden rounded border"><div className="border-b p-3 text-sm font-medium">Original PDF</div><iframe className="h-[640px] w-full" src={originalPDF.url} title="Original guideline PDF" /></div>
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
