"use client"

import * as React from "react"

import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { cn } from "@/lib/utils"
import { DiffLine, lineDiff, markdownHeadings, wordDiff } from "./markdown-authoring"

interface MarkdownDiffViewerProps {
  before: string
  after: string
  beforeLabel: string
  afterLabel?: string
  onDownload: (content: string) => void
}

export function MarkdownDiffViewer({ before, after, beforeLabel, afterLabel = "Current draft", onDownload }: MarkdownDiffViewerProps) {
  const [sideBySide, setSideBySide] = React.useState(false)
  const [collapseUnchanged, setCollapseUnchanged] = React.useState(true)
  const [changeIndex, setChangeIndex] = React.useState(0)
  const scrollers = React.useRef<(HTMLDivElement | null)[]>([])
  const syncing = React.useRef(false)
  const diff = React.useMemo(() => lineDiff(before, after), [after, before])
  const changes = React.useMemo(() => diff.map((line, index) => line.type === "same" ? -1 : index).filter((index) => index >= 0), [diff])
  const headings = React.useMemo(() => markdownHeadings(after), [after])
  const visible = React.useMemo(() => collapseUnchanged ? collapseLines(diff) : diff.map((line, index) => ({ line, index })), [collapseUnchanged, diff])
  const summary = React.useMemo(() => ({
    added: diff.filter((line) => line.type === "added").length,
    removed: diff.filter((line) => line.type === "removed").length,
  }), [diff])

  const navigate = (direction: number) => {
    if (!changes.length) return
    const next = (changeIndex + direction + changes.length) % changes.length
    setChangeIndex(next)
    document.getElementById(`markdown-diff-${changes[next]}`)?.scrollIntoView({ block: "center" })
  }
  const synchronize = (source: HTMLDivElement, target?: HTMLDivElement | null) => {
    if (!target || syncing.current) return
    syncing.current = true
    const available = source.scrollHeight - source.clientHeight
    target.scrollTop = available <= 0 ? 0 : source.scrollTop / available * (target.scrollHeight - target.clientHeight)
    requestAnimationFrame(() => { syncing.current = false })
  }

  return <div className="space-y-3">
    <div className="flex flex-wrap items-center gap-2 text-xs">
      <Button size="sm" variant="outline" onClick={() => navigate(-1)} disabled={!changes.length}>Previous change</Button>
      <Button size="sm" variant="outline" onClick={() => navigate(1)} disabled={!changes.length}>Next change</Button>
      <span>{changes.length ? `${changeIndex + 1} of ${changes.length}` : "No changes"}</span>
      <span className="text-emerald-700">+{summary.added}</span><span className="text-red-700">−{summary.removed}</span>
      <label className="ml-auto flex items-center gap-2"><Switch checked={sideBySide} onCheckedChange={setSideBySide} />Side by side</label>
      <label className="flex items-center gap-2"><Switch checked={collapseUnchanged} onCheckedChange={setCollapseUnchanged} />Collapse unchanged</label>
    </div>
    {headings.length > 0 && <div className="flex items-center gap-2"><span className="text-xs text-muted-foreground">Go to heading</span><select className="h-8 max-w-xs rounded border bg-background px-2 text-xs" defaultValue="" onChange={(event) => document.querySelector(`[data-heading-id="markdown-diff-heading-${event.target.value}"]`)?.scrollIntoView({ block: "start" })}><option value="">Choose…</option>{headings.map((heading, index) => <option key={`${heading.id}-${index}`} value={index}>{heading.breadcrumb.join(" › ")}</option>)}</select></div>}
    {sideBySide ? <div className="grid max-h-[60vh] grid-cols-2 overflow-hidden rounded border font-mono text-xs">
      {[{ label: beforeLabel, content: before }, { label: afterLabel, content: after }].map((pane, paneIndex) => <div key={pane.label} className={cn("min-w-0", paneIndex === 1 && "border-l")}><div className="border-b bg-muted px-3 py-2 font-sans font-medium">{pane.label}</div><div ref={(node) => { scrollers.current[paneIndex] = node }} onScroll={(event) => synchronize(event.currentTarget, scrollers.current[paneIndex === 0 ? 1 : 0])} className="max-h-[52vh] overflow-auto p-2">{pane.content.split("\n").map((line, index) => <div key={index} className="whitespace-pre-wrap"><span className="mr-3 select-none text-muted-foreground">{index + 1}</span>{line || " "}</div>)}</div></div>)}
    </div> : <div className="max-h-[60vh] overflow-auto rounded border bg-muted/20 p-2 font-mono text-xs">{visible.map(({ line, index }) => line ? <DiffRow key={`${index}-${line.type}`} line={line} counterpart={line.type === "removed" && diff[index + 1]?.type === "added" ? diff[index + 1].text : line.type === "added" && diff[index - 1]?.type === "removed" ? diff[index - 1].text : undefined} index={index} headingIndex={headings.findIndex((heading) => heading.line === after.slice(0, diff.slice(0, index + 1).filter((item) => item.type !== "removed").map((item) => item.text).join("\n").length).split("\n").length)} /> : <div key={`collapsed-${index}`} className="px-2 py-1 text-center text-muted-foreground">⋯ unchanged lines collapsed ⋯</div>)}</div>}
    <div className="flex justify-end"><Button size="sm" variant="outline" onClick={() => onDownload(diff.map((line) => `${line.type === "added" ? "+" : line.type === "removed" ? "-" : " "}${line.text}`).join("\n"))}>Download diff</Button></div>
  </div>
}

function DiffRow({ line, counterpart, index, headingIndex }: { line: DiffLine; counterpart?: string; index: number; headingIndex: number }) {
  const words = counterpart ? wordDiff(line.type === "removed" ? line.text : counterpart, line.type === "added" ? line.text : counterpart) : null
  return <div id={`markdown-diff-${index}`} data-heading-id={headingIndex >= 0 ? `markdown-diff-heading-${headingIndex}` : undefined} className={cn("whitespace-pre-wrap px-2", counterpart && "border-l-2 border-violet-500", line.type === "added" && "bg-green-100 text-green-950 dark:bg-green-950 dark:text-green-100", line.type === "removed" && "bg-red-100 text-red-950 dark:bg-red-950 dark:text-red-100")}><span className="mr-3 select-none text-muted-foreground">{line.type === "added" ? "+" : line.type === "removed" ? "−" : " "}</span>{words ? words.filter((part) => part.type === "same" || part.type === line.type).map((part, wordIndex) => <span key={wordIndex} className={part.type === "same" ? undefined : "rounded bg-violet-300/60 px-0.5 dark:bg-violet-700/60"}>{part.text}</span>) : line.text || " "}</div>
}

function collapseLines(diff: DiffLine[]) {
  const context = 3
  const keep = new Set<number>()
  diff.forEach((line, index) => {
    if (line.type === "same") return
    for (let cursor = Math.max(0, index - context); cursor <= Math.min(diff.length - 1, index + context); cursor += 1) keep.add(cursor)
  })
  const result: { line: DiffLine | null; index: number }[] = []
  let collapsed = false
  diff.forEach((line, index) => {
    if (keep.has(index)) { result.push({ line, index }); collapsed = false }
    else if (!collapsed) { result.push({ line: null, index }); collapsed = true }
  })
  return result
}
