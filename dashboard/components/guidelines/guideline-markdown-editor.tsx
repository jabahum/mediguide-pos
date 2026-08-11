"use client"

import * as React from "react"
import CodeMirror, { ReactCodeMirrorRef } from "@uiw/react-codemirror"
import { markdown } from "@codemirror/lang-markdown"
import { defaultKeymap, historyKeymap, indentWithTab, redo, undo } from "@codemirror/commands"
import { keymap, EditorView } from "@codemirror/view"
import { openSearchPanel, searchKeymap } from "@codemirror/search"
import { oneDark } from "@codemirror/theme-one-dark"
import { useTheme } from "next-themes"
import {
  AlertCircle,
  CheckCircle2,
  Clock3,
  CloudOff,
  Copy,
  FileClock,
  Info,
  ListTree,
  RotateCcw,
  Settings2,
  ShieldAlert,
  Upload,
} from "lucide-react"

import {
  MarkdownEditorToolbar,
  MarkdownFormatAction,
  MarkdownViewMode,
} from "./markdown-editor-toolbar"
import { MarkdownPreview } from "./markdown-preview"
import {
  formatMarkdown,
  lineDiff,
  markdownHeadings,
  markdownStats,
  markdownTemplates,
  validateMarkdown,
} from "./markdown-authoring"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "@/components/ui/resizable"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { useUnsavedChanges } from "@/hooks/use-unsaved-changes"
import { showToast } from "@/lib/toast"
import { cn } from "@/lib/utils"
import {
  GuidelineMarkdownError,
  GuidelineMarkdownService,
  MarkdownDraft,
  MarkdownRevision,
} from "@/services/guideline-markdown.service"

interface GuidelineMarkdownEditorProps {
  versionId: string
  initialContent: string
  initialDraft?: MarkdownDraft | null
  editable: boolean
  published: boolean
}

interface EditorPreferences {
  autosave: boolean
  autosaveDelay: number
  lineWrapping: boolean
  fontSize: number
  previewWidth: "mobile" | "tablet" | "desktop"
  distractionFree: boolean
}

const defaultPreferences: EditorPreferences = {
  autosave: true,
  autosaveDelay: 2500,
  lineWrapping: true,
  fontSize: 14,
  previewWidth: "desktop",
  distractionFree: false,
}

const recoveryKey = (versionId: string) => `mediguide.markdown.recovery.${versionId}`
const preferencesKey = "mediguide.markdown.editor.preferences.v1"

function selectionReplacement(
  view: EditorView,
  before: string,
  after: string,
  placeholder: string,
) {
  const selection = view.state.selection.main
  const selected = view.state.sliceDoc(selection.from, selection.to) || placeholder
  const insert = `${before}${selected}${after}`
  view.dispatch({
    changes: { from: selection.from, to: selection.to, insert },
    selection: { anchor: selection.from + before.length, head: selection.from + before.length + selected.length },
    scrollIntoView: true,
  })
  view.focus()
}

function prefixLines(view: EditorView, prefix: string) {
  const selection = view.state.selection.main
  const start = view.state.doc.lineAt(selection.from)
  const end = view.state.doc.lineAt(selection.to)
  const changes = []
  for (let number = start.number; number <= end.number; number += 1) {
    changes.push({ from: view.state.doc.line(number).from, insert: prefix })
  }
  view.dispatch({ changes, scrollIntoView: true })
  view.focus()
}

const editorFormattingKeymap = [
  { key: "Mod-b", run: (view: EditorView) => { selectionReplacement(view, "**", "**", "bold text"); return true } },
  { key: "Mod-i", run: (view: EditorView) => { selectionReplacement(view, "_", "_", "emphasized text"); return true } },
  { key: "Mod-k", run: (view: EditorView) => { selectionReplacement(view, "[", "](https://)", "link text"); return true } },
  { key: "Mod-Shift-7", run: (view: EditorView) => { prefixLines(view, "1. "); return true } },
  { key: "Mod-Shift-8", run: (view: EditorView) => { prefixLines(view, "- "); return true } },
  { key: "Mod-Shift-.", run: (view: EditorView) => { prefixLines(view, "> "); return true } },
  ...([1, 2, 3, 4, 5, 6] as const).map((level) => ({
    key: `Mod-Alt-${level}`,
    run: (view: EditorView) => { prefixLines(view, `${"#".repeat(level)} `); return true },
  })),
]

function downloadText(filename: string, content: string) {
  const url = URL.createObjectURL(new Blob([content], { type: "text/markdown;charset=utf-8" }))
  const anchor = document.createElement("a")
  anchor.href = url
  anchor.download = filename
  anchor.click()
  URL.revokeObjectURL(url)
}

export function GuidelineMarkdownEditor({
  versionId,
  initialContent,
  initialDraft = null,
  editable,
  published,
}: GuidelineMarkdownEditorProps) {
  const { resolvedTheme } = useTheme()
  const editorRef = React.useRef<ReactCodeMirrorRef>(null)
  const uploadRef = React.useRef<HTMLInputElement>(null)
  const [content, setContent] = React.useState(initialContent)
  const [savedContent, setSavedContent] = React.useState(initialContent)
  const [draft, setDraft] = React.useState<MarkdownDraft | null>(initialDraft)
  const [mode, setMode] = React.useState<MarkdownViewMode>(editable ? "split" : "preview")
  const [saving, setSaving] = React.useState(false)
  const [saveError, setSaveError] = React.useState<string | null>(null)
  const [lastSavedAt, setLastSavedAt] = React.useState<Date | null>(null)
  const [revertOpen, setRevertOpen] = React.useState(false)
  const [fullscreen, setFullscreen] = React.useState(false)
  const [online, setOnline] = React.useState(true)
  const [recovery, setRecovery] = React.useState<string | null>(null)
  const [preferences, setPreferences] = React.useState(defaultPreferences)
  const [settingsOpen, setSettingsOpen] = React.useState(false)
  const [commandOpen, setCommandOpen] = React.useState(false)
  const [goToLine, setGoToLine] = React.useState("")
  const [templatesOpen, setTemplatesOpen] = React.useState(false)
  const [checkpointOpen, setCheckpointOpen] = React.useState(false)
  const [checkpointName, setCheckpointName] = React.useState("")
  const [checkpointSummary, setCheckpointSummary] = React.useState("")
  const [historyOpen, setHistoryOpen] = React.useState(false)
  const [historyLoading, setHistoryLoading] = React.useState(false)
  const [revisions, setRevisions] = React.useState<MarkdownRevision[]>([])
  const [compareOpen, setCompareOpen] = React.useState(false)
  const [compareContent, setCompareContent] = React.useState("")
  const [compareLabel, setCompareLabel] = React.useState("")
  const [conflictDraft, setConflictDraft] = React.useState<MarkdownDraft | null>(null)
  const [regenerating, setRegenerating] = React.useState(false)
  const [pendingSourceType, setPendingSourceType] = React.useState<"blank" | "template" | "uploaded_markdown" | null>(null)

  const canEdit = editable && !published
  const dirty = canEdit && content !== savedContent
  const headings = React.useMemo(() => markdownHeadings(content), [content])
  const issues = React.useMemo(() => validateMarkdown(content), [content])
  const stats = React.useMemo(() => markdownStats(content), [content])
  const diff = React.useMemo(() => lineDiff(compareContent, content), [compareContent, content])
  useUnsavedChanges(dirty)

  React.useEffect(() => {
    setOnline(navigator.onLine)
    const onlineListener = () => setOnline(true)
    const offlineListener = () => setOnline(false)
    window.addEventListener("online", onlineListener)
    window.addEventListener("offline", offlineListener)
    try {
      const storedPreferences = localStorage.getItem(preferencesKey)
      if (storedPreferences) setPreferences({ ...defaultPreferences, ...JSON.parse(storedPreferences) })
      const storedRecovery = localStorage.getItem(recoveryKey(versionId))
      if (storedRecovery && storedRecovery !== initialContent) setRecovery(storedRecovery)
    } catch {
      // Browser storage is optional; editing remains available without it.
    }
    return () => {
      window.removeEventListener("online", onlineListener)
      window.removeEventListener("offline", offlineListener)
    }
  }, [initialContent, versionId])

  React.useEffect(() => {
    try {
      localStorage.setItem(preferencesKey, JSON.stringify(preferences))
    } catch {
      // Ignore browsers where storage is disabled.
    }
  }, [preferences])

  React.useEffect(() => {
    if (!canEdit || !dirty) return
    try {
      localStorage.setItem(recoveryKey(versionId), content)
    } catch {
      // Recovery storage is best effort.
    }
  }, [canEdit, content, dirty, versionId])

  const applySavedDraft = React.useCallback((result: MarkdownDraft) => {
    setDraft(result)
    setSavedContent(result.content)
    setContent(result.content)
    setLastSavedAt(new Date(result.revision.updated_at))
    setSaveError(null)
    setPendingSourceType(null)
    try {
      localStorage.removeItem(recoveryKey(versionId))
    } catch {
      // Recovery storage is best effort.
    }
  }, [versionId])

  const keepLocalAgainstServerRevision = React.useCallback((serverDraft: MarkdownDraft) => {
    setDraft(serverDraft)
    setSavedContent(serverDraft.content)
    setConflictDraft(null)
    setSaveError(null)
  }, [])

  const save = React.useCallback(async (checkpoint?: { name: string; summary: string }) => {
    if (!canEdit || !dirty || saving || !online) return
    if (!content.trim()) {
      setSaveError("Markdown content cannot be empty.")
      return
    }
    setSaving(true)
    setSaveError(null)
    try {
      const input = {
        content,
        expected_revision: draft?.etag,
        source_type: pendingSourceType ?? (draft ? "manual_edit" as const : "blank" as const),
        checkpoint_name: checkpoint?.name,
        change_summary: checkpoint?.summary,
      }
      const result = checkpoint
        ? await GuidelineMarkdownService.createCheckpoint(versionId, input)
        : await GuidelineMarkdownService.saveDraft(versionId, input)
      applySavedDraft(result)
      showToast.success(
        checkpoint ? "Checkpoint saved" : "Draft saved",
        "Structured content remains unchanged until you choose Regenerate.",
      )
      setCheckpointOpen(false)
      setCheckpointName("")
      setCheckpointSummary("")
    } catch (error) {
      if (error instanceof GuidelineMarkdownError && error.conflict) {
        try {
          setConflictDraft(await GuidelineMarkdownService.loadDraft(versionId))
        } catch {
          setSaveError("The server draft changed. Reload before saving again.")
        }
      } else {
        const message = error instanceof Error ? error.message : "The Markdown draft could not be saved."
        setSaveError(message)
        showToast.error("Save failed", message)
      }
    } finally {
      setSaving(false)
    }
  }, [applySavedDraft, canEdit, content, dirty, draft, online, pendingSourceType, saving, versionId])

  React.useEffect(() => {
    if (!preferences.autosave || !dirty || !online || saving || conflictDraft) return
    const timer = window.setTimeout(() => void save(), preferences.autosaveDelay)
    return () => window.clearTimeout(timer)
  }, [conflictDraft, dirty, online, preferences.autosave, preferences.autosaveDelay, save, saving])

  React.useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
        event.preventDefault()
        void save()
      }
      if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === "p") {
        event.preventDefault()
        setCommandOpen(true)
      }
      if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === "v") {
        event.preventDefault()
        setMode((current) => current === "preview" ? (canEdit ? "split" : "preview") : "preview")
      }
      if (event.key === "F11") {
        event.preventDefault()
        setFullscreen((value) => !value)
      }
    }
    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [canEdit, save])

  React.useEffect(() => {
    if (!draft || !["queued", "processing"].includes(draft.revision.structured_content_status)) return
    const timer = window.setInterval(async () => {
      try {
        const refreshed = await GuidelineMarkdownService.loadDraft(versionId)
        setDraft(refreshed)
        if (!["queued", "processing"].includes(refreshed.revision.structured_content_status)) {
          showToast.success("Regeneration updated", `Structured content is ${refreshed.revision.structured_content_status}.`)
        }
      } catch {
        // Retain the last known status and retry on the next interval.
      }
    }, 5000)
    return () => window.clearInterval(timer)
  }, [draft, versionId])

  const view = () => editorRef.current?.view

  const format = (action: MarkdownFormatAction) => {
    const editor = view()
    if (!editor) return
    if (action.startsWith("heading-")) {
      prefixLines(editor, `${"#".repeat(Number(action.split("-")[1]))} `)
      return
    }
    if (action.startsWith("callout-")) {
      selectionReplacement(editor, `:::${action.slice(8)}\n`, "\n:::", "Add reviewed clinical content.")
      return
    }
    switch (action) {
      case "bold": selectionReplacement(editor, "**", "**", "bold text"); break
      case "italic": selectionReplacement(editor, "_", "_", "emphasized text"); break
      case "strikethrough": selectionReplacement(editor, "~~", "~~", "struck text"); break
      case "inline-code": selectionReplacement(editor, "`", "`", "code"); break
      case "code-block": selectionReplacement(editor, "```\n", "\n```", "code"); break
      case "quote": prefixLines(editor, "> "); break
      case "ordered-list": prefixLines(editor, "1. "); break
      case "unordered-list": prefixLines(editor, "- "); break
      case "task-list": prefixLines(editor, "- [ ] "); break
      case "link": selectionReplacement(editor, "[", "](https://)", "link text"); break
      case "image": selectionReplacement(editor, "![", "](asset-url)", "alternative text"); break
      case "horizontal-rule": selectionReplacement(editor, "\n---\n", "", ""); break
      case "table": selectionReplacement(editor, "", "", "| Column 1 | Column 2 |\n| --- | --- |\n| Value | Value |"); break
      case "footnote": selectionReplacement(editor, "[^", "]", "reference"); break
      case "reference": selectionReplacement(editor, "[", "]", "reference"); break
      case "format": setContent(formatMarkdown(content)); break
    }
  }

  const loadHistory = async () => {
    setHistoryOpen(true)
    setHistoryLoading(true)
    try {
      setRevisions((await GuidelineMarkdownService.revisions(versionId)).items)
    } catch (error) {
      showToast.error("History unavailable", error instanceof Error ? error.message : "Could not load revisions")
    } finally {
      setHistoryLoading(false)
    }
  }

  const compareRevision = async (revision: MarkdownRevision) => {
    try {
      const result = await GuidelineMarkdownService.revision(versionId, revision.id)
      setCompareContent(result.content)
      setCompareLabel(`Revision ${revision.revision_number}`)
      setCompareOpen(true)
    } catch (error) {
      showToast.error("Comparison failed", error instanceof Error ? error.message : "Could not load revision")
    }
  }

  const restoreRevision = async (revision: MarkdownRevision) => {
    if (!draft) return
    try {
      applySavedDraft(await GuidelineMarkdownService.restore(versionId, revision.id, draft.etag))
      setHistoryOpen(false)
      showToast.success("Revision restored", "A new draft revision was created from history.")
    } catch (error) {
      showToast.error("Restore failed", error instanceof Error ? error.message : "Could not restore revision")
    }
  }

  const regenerate = async () => {
    if (!draft || dirty || regenerating) return
    if (issues.some((issue) => issue.severity === "error")) {
      showToast.error("Fix validation errors", "Resolve blocking Markdown errors before regeneration.")
      return
    }
    setRegenerating(true)
    try {
      const result = await GuidelineMarkdownService.regenerate(versionId, draft.revision.id)
      setDraft({
        ...draft,
        revision: {
          ...draft.revision,
          regeneration_job_id: result.job.id,
          structured_content_status: "queued",
        },
      })
      showToast.success("Regeneration queued", "Sections, structured blocks, search chunks, and embeddings will be rebuilt.")
    } catch (error) {
      showToast.error("Regeneration failed", error instanceof Error ? error.message : "Could not queue regeneration")
    } finally {
      setRegenerating(false)
    }
  }

  const loadMarkdownFile = async (file: File) => {
    if (!/\.(md|markdown)$/iu.test(file.name)) {
      showToast.error("Unsupported file", "Choose a .md or .markdown document.")
      return
    }
    if (file.size > 100 * 1024 * 1024) {
      showToast.error("File is too large", "Markdown files may not exceed 100 MB.")
      return
    }
    try {
      setContent((await file.text()).replace(/\r\n?/gu, "\n"))
      setPendingSourceType("uploaded_markdown")
      setSaveError(null)
      showToast.success("Markdown loaded", "Review the content, then save the draft. No regeneration has started.")
    } catch {
      showToast.error("Upload failed", "The Markdown file could not be read.")
    }
  }

  const copyMarkdown = async () => {
    try {
      await navigator.clipboard.writeText(content)
      showToast.success("Markdown copied")
    } catch {
      showToast.error("Copy failed", "Clipboard access is unavailable in this browser.")
    }
  }

  const editorExtensions = React.useMemo(() => [
    markdown(),
    keymap.of([...editorFormattingKeymap, ...defaultKeymap, ...historyKeymap, ...searchKeymap, indentWithTab]),
    ...(preferences.lineWrapping ? [EditorView.lineWrapping] : []),
    EditorView.theme({
      "&": { fontSize: `${preferences.fontSize}px`, height: "100%" },
      ".cm-scroller": { fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace" },
      ".cm-content": { minHeight: "62vh", padding: "16px 0" },
    }),
  ], [preferences.fontSize, preferences.lineWrapping])

  const previewClass = preferences.previewWidth === "mobile"
    ? "mx-auto max-w-[430px]"
    : preferences.previewWidth === "tablet"
      ? "mx-auto max-w-[820px]"
      : "w-full"

  return (
    <>
      <section className={cn(
        "overflow-hidden rounded-lg border bg-card shadow-sm",
        fullscreen && "fixed inset-0 z-50 rounded-none",
      )}>
        <MarkdownEditorToolbar
          mode={mode}
          canEdit={canEdit}
          dirty={dirty}
          saving={saving}
          offline={!online}
          autosave={preferences.autosave}
          fullscreen={fullscreen}
          words={stats.words}
          characters={stats.characters}
          onModeChange={setMode}
          onSave={() => void save()}
          onRevert={() => setRevertOpen(true)}
          onFormat={format}
          onUndo={() => { const editor = view(); if (editor) undo(editor) }}
          onRedo={() => { const editor = view(); if (editor) redo(editor) }}
          onSearch={() => { const editor = view(); if (editor) openSearchPanel(editor) }}
          onFullscreen={() => setFullscreen((value) => !value)}
          onRegenerate={canEdit && draft ? () => void regenerate() : undefined}
          onDownload={() => downloadText(`guideline-revision-${draft?.revision.revision_number || "draft"}.md`, content)}
        />

        <div className="flex flex-wrap items-center gap-2 border-b px-3 py-2 text-xs">
          <input
            ref={uploadRef}
            type="file"
            className="hidden"
            accept=".md,.markdown,text/markdown,text/plain"
            onChange={(event) => {
              const file = event.target.files?.[0]
              if (file) void loadMarkdownFile(file)
              event.target.value = ""
            }}
          />
          <Button size="sm" variant="ghost" onClick={() => void loadHistory()}><FileClock className="mr-2 h-4 w-4" />History</Button>
          {canEdit && <Button size="sm" variant="ghost" onClick={() => setCheckpointOpen(true)} disabled={!dirty}><CheckCircle2 className="mr-2 h-4 w-4" />Checkpoint</Button>}
          {canEdit && !content.trim() && <Button size="sm" variant="ghost" onClick={() => setTemplatesOpen(true)}><ListTree className="mr-2 h-4 w-4" />Start from template</Button>}
          {canEdit && <Button size="sm" variant="ghost" onClick={() => uploadRef.current?.click()}><Upload className="mr-2 h-4 w-4" />Load Markdown</Button>}
          <Button size="sm" variant="ghost" onClick={() => void copyMarkdown()}><Copy className="mr-2 h-4 w-4" />Copy</Button>
          <Button size="sm" variant="ghost" onClick={() => setSettingsOpen(true)}><Settings2 className="mr-2 h-4 w-4" />Editor settings</Button>
          <Badge variant="outline">{stats.lines} lines</Badge>
          <Badge variant="outline">{stats.headings} headings</Badge>
          <Badge variant="outline">{stats.readingMinutes} min read</Badge>
          {draft && <Badge variant="secondary">Revision {draft.revision.revision_number}</Badge>}
          {draft && <Badge variant={draft.revision.structured_content_status === "failed" ? "destructive" : "outline"}>{draft.revision.structured_content_status.replaceAll("_", " ")}</Badge>}
          <span className="ml-auto">{issues.filter((issue) => issue.severity === "error").length} errors · {issues.filter((issue) => issue.severity === "warning").length} warnings</span>
        </div>

        <div className="sr-only" role="status" aria-live="polite">
          {saving ? "Saving Markdown" : saveError ? `Save failed: ${saveError}` : dirty ? "Markdown has unsaved changes" : "All Markdown changes are saved"}
        </div>

        {recovery && (
          <Alert className="m-4 mb-0">
            <RotateCcw className="h-4 w-4" />
            <AlertTitle>Recovered browser draft available</AlertTitle>
            <AlertDescription className="flex flex-wrap items-center gap-2">
              A newer unsaved local draft was found.
              <Button size="sm" variant="outline" onClick={() => { setContent(recovery); setRecovery(null) }}>Restore local draft</Button>
              <Button size="sm" variant="ghost" onClick={() => { localStorage.removeItem(recoveryKey(versionId)); setRecovery(null) }}>Discard</Button>
            </AlertDescription>
          </Alert>
        )}
        {!online && <Alert className="m-4 mb-0"><CloudOff className="h-4 w-4" /><AlertTitle>Working offline</AlertTitle><AlertDescription>Your text is retained locally. Server saving resumes after reconnection.</AlertDescription></Alert>}
        {published && <Alert className="m-4 mb-0"><Info className="h-4 w-4" /><AlertTitle>Published version</AlertTitle><AlertDescription>Published Markdown is immutable. Create a new version to revise it.</AlertDescription></Alert>}
        {saveError && <Alert variant="destructive" className="m-4 mb-0"><AlertCircle className="h-4 w-4" /><AlertTitle>Markdown was not saved</AlertTitle><AlertDescription className="flex flex-wrap items-center gap-2"><span>{saveError} Your edits remain available.</span><Button size="sm" variant="outline" disabled={saving || !online} onClick={() => void save()}>Retry save</Button></AlertDescription></Alert>}

        <div className={cn("grid", !preferences.distractionFree && "lg:grid-cols-[220px_minmax(0,1fr)]")}>
          {!preferences.distractionFree && (
            <aside className="hidden border-r lg:block">
              <div className="border-b p-3 text-sm font-medium">Document outline</div>
              <ScrollArea className="h-[65vh] p-2">
                {headings.length === 0 && <p className="p-2 text-xs text-muted-foreground">Add headings to build navigation.</p>}
                {headings.map((heading, index) => (
                  <button
                    key={`${heading.id}-${index}`}
                    type="button"
                    className="block w-full truncate rounded px-2 py-1.5 text-left text-xs hover:bg-muted"
                    style={{ paddingLeft: `${8 + (heading.level - 1) * 12}px` }}
                    title={`${heading.text} · ${heading.words} words`}
                    onClick={() => {
                      const editor = view()
                      editor?.dispatch({ selection: { anchor: heading.from }, scrollIntoView: true })
                      editor?.focus()
                    }}
                  >
                    {heading.text}
                  </button>
                ))}
                {issues.length > 0 && <div className="mt-4 border-t pt-3 text-xs font-medium">Validation</div>}
                {issues.map((issue, index) => (
                  <button
                    key={`${issue.code}-${index}`}
                    type="button"
                    className="mt-1 flex w-full gap-2 rounded px-2 py-1.5 text-left text-xs hover:bg-muted"
                    onClick={() => {
                      const editor = view()
                      if (!editor) return
                      const line = editor.state.doc.line(Math.min(issue.line, editor.state.doc.lines))
                      editor.dispatch({ selection: { anchor: line.from }, scrollIntoView: true })
                      editor.focus()
                    }}
                  >
                    {issue.severity === "error" ? <ShieldAlert className="h-3.5 w-3.5 shrink-0 text-destructive" /> : <AlertCircle className="h-3.5 w-3.5 shrink-0 text-amber-600" />}
                    <span>{issue.message}</span>
                  </button>
                ))}
              </ScrollArea>
            </aside>
          )}

          <div className="min-w-0">
            {mode === "split" && canEdit ? (
              <ResizablePanelGroup direction="horizontal" className="min-h-[65vh]">
                <ResizablePanel defaultSize={50} minSize={25}>
                  <CodeMirror
                    ref={editorRef}
                    value={content}
                    height="65vh"
                    theme={resolvedTheme === "dark" ? oneDark : "light"}
                    extensions={editorExtensions}
                    basicSetup={{ lineNumbers: true, foldGutter: true, bracketMatching: true, highlightActiveLine: true, autocompletion: true, history: true }}
                    onChange={(value) => { setContent(value); setSaveError(null) }}
                    aria-label="Markdown source"
                  />
                </ResizablePanel>
                <ResizableHandle withHandle />
                <ResizablePanel defaultSize={50} minSize={25}>
                  <div className="h-[65vh] overflow-auto p-5 lg:p-8"><div className={previewClass}><MarkdownPreview content={content} /></div></div>
                </ResizablePanel>
              </ResizablePanelGroup>
            ) : mode === "edit" && canEdit ? (
              <CodeMirror
                ref={editorRef}
                value={content}
                height="65vh"
                theme={resolvedTheme === "dark" ? oneDark : "light"}
                extensions={editorExtensions}
                basicSetup={{ lineNumbers: true, foldGutter: true, bracketMatching: true, highlightActiveLine: true, autocompletion: true, history: true }}
                onChange={(value) => { setContent(value); setSaveError(null) }}
                aria-label="Markdown source"
              />
            ) : (
              <div className="h-[65vh] overflow-auto p-5 lg:p-8"><div className={previewClass}><MarkdownPreview content={content} /></div></div>
            )}
          </div>
        </div>

        <footer className="flex min-h-11 items-center border-t px-4 text-xs text-muted-foreground">
          <Clock3 className="mr-2 h-3.5 w-3.5" />
          {lastSavedAt ? `Last saved at ${lastSavedAt.toLocaleTimeString()}` : draft ? `Saved ${new Date(draft.revision.updated_at).toLocaleString()}` : "No server draft yet"}
          <span className="ml-auto">Conflict protection: {draft ? "enabled" : "starts after first save"}</span>
        </footer>
      </section>

      <AlertDialog open={revertOpen} onOpenChange={setRevertOpen}>
        <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Discard unsaved changes?</AlertDialogTitle><AlertDialogDescription>The editor will return to the last server-saved Markdown.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter><AlertDialogCancel>Keep editing</AlertDialogCancel><AlertDialogAction onClick={() => { setContent(savedContent); setSaveError(null); setRevertOpen(false) }}>Discard changes</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
      </AlertDialog>

      <Dialog open={checkpointOpen} onOpenChange={setCheckpointOpen}>
        <DialogContent><DialogHeader><DialogTitle>Save named checkpoint</DialogTitle><DialogDescription>Create an immutable revision without regenerating structured content.</DialogDescription></DialogHeader><div className="space-y-4"><div><Label htmlFor="checkpoint-name">Checkpoint name</Label><Input id="checkpoint-name" value={checkpointName} onChange={(event) => setCheckpointName(event.target.value)} /></div><div><Label htmlFor="checkpoint-summary">Change summary</Label><Textarea id="checkpoint-summary" value={checkpointSummary} onChange={(event) => setCheckpointSummary(event.target.value)} /></div></div><DialogFooter><Button variant="outline" onClick={() => setCheckpointOpen(false)}>Cancel</Button><Button disabled={!checkpointName.trim() || saving} onClick={() => void save({ name: checkpointName, summary: checkpointSummary })}>Save checkpoint</Button></DialogFooter></DialogContent>
      </Dialog>

      <Dialog open={templatesOpen} onOpenChange={setTemplatesOpen}>
        <DialogContent className="max-w-2xl"><DialogHeader><DialogTitle>Start from a clinical template</DialogTitle><DialogDescription>Templates provide structure only and never invent clinical recommendations or dosage values.</DialogDescription></DialogHeader><div className="grid gap-3 sm:grid-cols-2">{markdownTemplates.map((template) => <button key={template.key} type="button" className="rounded-lg border p-4 text-left hover:bg-muted" onClick={() => { setContent(template.content); setPendingSourceType("template"); setTemplatesOpen(false) }}><span className="font-medium">{template.name}</span><span className="mt-1 block text-sm text-muted-foreground">{template.description}</span></button>)}</div></DialogContent>
      </Dialog>

      <Dialog open={settingsOpen} onOpenChange={setSettingsOpen}>
        <DialogContent><DialogHeader><DialogTitle>Editor settings</DialogTitle><DialogDescription>These preferences are stored only in this browser.</DialogDescription></DialogHeader><div className="space-y-5"><div className="flex items-center justify-between"><Label htmlFor="autosave">Autosave drafts</Label><Switch id="autosave" checked={preferences.autosave} onCheckedChange={(value) => setPreferences((current) => ({ ...current, autosave: value }))} /></div><div><Label htmlFor="autosave-delay">Autosave delay (milliseconds)</Label><Input id="autosave-delay" type="number" min={1000} max={30000} step={500} value={preferences.autosaveDelay} onChange={(event) => setPreferences((current) => ({ ...current, autosaveDelay: Math.min(30000, Math.max(1000, Number(event.target.value))) }))} /></div><div className="flex items-center justify-between"><Label htmlFor="line-wrap">Soft line wrapping</Label><Switch id="line-wrap" checked={preferences.lineWrapping} onCheckedChange={(value) => setPreferences((current) => ({ ...current, lineWrapping: value }))} /></div><div className="flex items-center justify-between"><Label htmlFor="distraction-free">Distraction-free mode</Label><Switch id="distraction-free" checked={preferences.distractionFree} onCheckedChange={(value) => setPreferences((current) => ({ ...current, distractionFree: value }))} /></div><div><Label htmlFor="font-size">Editor font size</Label><Input id="font-size" type="number" min={12} max={22} value={preferences.fontSize} onChange={(event) => setPreferences((current) => ({ ...current, fontSize: Math.min(22, Math.max(12, Number(event.target.value))) }))} /></div><div><Label htmlFor="preview-width">Preview width</Label><select id="preview-width" className="mt-1 h-9 w-full rounded-md border bg-background px-3" value={preferences.previewWidth} onChange={(event) => setPreferences((current) => ({ ...current, previewWidth: event.target.value as EditorPreferences["previewWidth"] }))}><option value="mobile">Mobile</option><option value="tablet">Tablet</option><option value="desktop">Desktop</option></select></div></div></DialogContent>
      </Dialog>

      <Dialog open={commandOpen} onOpenChange={setCommandOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Markdown commands</DialogTitle><DialogDescription>Open with Ctrl/Command+Shift+P. Commands act on the current draft and editor selection.</DialogDescription></DialogHeader>
          <div className="grid gap-2 sm:grid-cols-2">
            <Button variant="outline" disabled={!dirty || saving || !online} onClick={() => { setCommandOpen(false); void save() }}>Save draft</Button>
            <Button variant="outline" onClick={() => { setMode((current) => current === "preview" ? (canEdit ? "split" : "preview") : "preview"); setCommandOpen(false) }}>Toggle preview</Button>
            <Button variant="outline" onClick={() => { setFullscreen((value) => !value); setCommandOpen(false) }}>Toggle fullscreen</Button>
            <Button variant="outline" disabled={!canEdit} onClick={() => { setContent(formatMarkdown(content)); setCommandOpen(false) }}>Format document</Button>
            <Button variant="outline" disabled={!canEdit} onClick={() => { const editor = view(); if (editor) openSearchPanel(editor); setCommandOpen(false) }}>Find and replace</Button>
            <Button variant="outline" onClick={() => { setHistoryOpen(true); setCommandOpen(false); void loadHistory() }}>Revision history</Button>
          </div>
          {canEdit && <div className="flex items-end gap-2"><div className="flex-1"><Label htmlFor="go-to-line">Go to line</Label><Input id="go-to-line" type="number" min={1} value={goToLine} onChange={(event) => setGoToLine(event.target.value)} /></div><Button onClick={() => { const editor = view(); if (!editor) return; const number = Math.min(Math.max(1, Number(goToLine) || 1), editor.state.doc.lines); const line = editor.state.doc.line(number); editor.dispatch({ selection: { anchor: line.from }, scrollIntoView: true }); editor.focus(); setCommandOpen(false) }}>Go</Button></div>}
        </DialogContent>
      </Dialog>

      <Dialog open={historyOpen} onOpenChange={setHistoryOpen}>
        <DialogContent className="max-w-3xl"><DialogHeader><DialogTitle>Markdown revision history</DialogTitle><DialogDescription>Every entry is immutable. Restore creates a new draft revision.</DialogDescription></DialogHeader><ScrollArea className="max-h-[60vh]"><div className="space-y-2 pr-3">{historyLoading && <p className="text-sm text-muted-foreground">Loading revisions…</p>}{revisions.map((revision) => <div key={revision.id} className="flex flex-col gap-3 rounded-lg border p-3 sm:flex-row sm:items-center"><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium">Revision {revision.revision_number}</span>{revision.is_current && <Badge>Current</Badge>}{revision.publication_state === "published" && <Badge variant="secondary">Published</Badge>}<Badge variant="outline">{revision.source_type.replaceAll("_", " ")}</Badge></div><p className="mt-1 truncate text-sm">{revision.checkpoint_name || revision.change_summary || "Unnamed draft"}</p><p className="text-xs text-muted-foreground">{new Date(revision.created_at).toLocaleString()} · {revision.size_bytes.toLocaleString()} bytes · {revision.structured_content_status.replaceAll("_", " ")}</p></div><div className="flex gap-2"><Button size="sm" variant="outline" onClick={() => void compareRevision(revision)}>Compare</Button><Button size="sm" variant="outline" onClick={async () => { const item = await GuidelineMarkdownService.revision(versionId, revision.id); downloadText(`guideline-revision-${revision.revision_number}.md`, item.content) }}>Download</Button>{canEdit && !revision.is_current && <Button size="sm" onClick={() => void restoreRevision(revision)}>Restore</Button>}</div></div>)}</div></ScrollArea></DialogContent>
      </Dialog>

      <Dialog open={compareOpen} onOpenChange={setCompareOpen}>
        <DialogContent className="max-w-5xl"><DialogHeader><DialogTitle>Compare {compareLabel} with current draft</DialogTitle><DialogDescription>Removed lines are red and additions are green. Markdown is shown as text and is never executed.</DialogDescription></DialogHeader><ScrollArea className="max-h-[65vh] rounded border bg-muted/20 font-mono text-xs"><div className="min-w-max p-3">{diff.map((line, index) => <div key={`${index}-${line.type}`} className={cn("whitespace-pre px-2", line.type === "added" && "bg-green-100 text-green-950 dark:bg-green-950 dark:text-green-100", line.type === "removed" && "bg-red-100 text-red-950 dark:bg-red-950 dark:text-red-100")}><span className="mr-3 select-none text-muted-foreground">{line.type === "added" ? "+" : line.type === "removed" ? "−" : " "}</span>{line.text || " "}</div>)}</div></ScrollArea><DialogFooter><Button variant="outline" onClick={() => downloadText("guideline-diff.txt", diff.map((line) => `${line.type === "added" ? "+" : line.type === "removed" ? "-" : " "}${line.text}`).join("\n"))}>Download diff</Button></DialogFooter></DialogContent>
      </Dialog>

      <AlertDialog open={Boolean(conflictDraft)} onOpenChange={(open) => { if (!open) setConflictDraft(null) }}>
        <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Another editor saved this draft</AlertDialogTitle><AlertDialogDescription>Your local text has been preserved. Choose how to resolve the conflict.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter className="flex-wrap"><AlertDialogCancel onClick={() => { if (conflictDraft) keepLocalAgainstServerRevision(conflictDraft) }}>Keep local text</AlertDialogCancel><Button variant="outline" onClick={() => { if (!conflictDraft) return; setCompareContent(conflictDraft.content); setCompareLabel("server draft"); setCompareOpen(true) }}>Open diff</Button><Button variant="outline" onClick={() => { if (conflictDraft) applySavedDraft(conflictDraft); setConflictDraft(null) }}>Reload server draft</Button><AlertDialogAction onClick={async () => { if (!conflictDraft) return; keepLocalAgainstServerRevision(conflictDraft); setCheckpointName("Conflict recovery"); setCheckpointSummary("Local edits saved after a concurrent change"); setCheckpointOpen(true) }}>Save local as checkpoint</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
      </AlertDialog>
    </>
  )
}
