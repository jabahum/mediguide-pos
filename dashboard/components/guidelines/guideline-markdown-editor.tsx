"use client"

import * as React from "react"
import CodeMirror, { ReactCodeMirrorRef } from "@uiw/react-codemirror"
import { markdown } from "@codemirror/lang-markdown"
import { foldAll, unfoldAll } from "@codemirror/language"
import { defaultKeymap, historyKeymap, indentWithTab, redo, undo } from "@codemirror/commands"
import { keymap, EditorView } from "@codemirror/view"
import { openSearchPanel, searchKeymap } from "@codemirror/search"
import { oneDark } from "@codemirror/theme-one-dark"
import { useTheme } from "next-themes"
import { useRouter } from "next/navigation"
import {
  AlertCircle,
  CheckCircle2,
  Clock3,
  CloudOff,
  Copy,
  FileClock,
  FilePlus2,
  GitCompareArrows,
  Info,
  Images,
  ListTree,
  Printer,
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
import {
  MarkdownPreviewPresentation,
  MarkdownPreviewSurface,
} from "./markdown-preview-surface"
import {
  formatMarkdown,
  clinicalCalloutMarkdown,
  ClinicalCalloutType,
  markdownHeadings,
  markdownStats,
  markdownTemplates,
  moveMarkdownSection,
  stableHeadingAnchors,
  validateMarkdown,
} from "./markdown-authoring"
import { MarkdownDiffViewer } from "./markdown-diff-viewer"
import { MarkdownTableEditor } from "./markdown-table-editor"
import { emptyMarkdownTable, markdownTableAt, type MarkdownTableModel } from "./markdown-table"
import { GuidelineAssetLibrary } from "./guideline-asset-library"
import { GuidelineAssetsService, type GuidelineAsset } from "@/services/guideline-assets.service"
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
import { Checkbox } from "@/components/ui/checkbox"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command"
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
  documentTitle: string
  versionLabel: string
  publishedVersionId?: string | null
  structuredRevisionId?: string | null
  publishedRevisionId?: string | null
  openTemplatesInitially?: boolean
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
  scrollSync: boolean
}

const defaultPreferences: EditorPreferences = {
  autosave: true,
  autosaveDelay: 2500,
  lineWrapping: true,
  fontSize: 14,
  previewWidth: "desktop",
  distractionFree: false,
  scrollSync: true,
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

function reorderAnchorMetadata(metadata: ReturnType<typeof stableHeadingAnchors>, headings: ReturnType<typeof markdownHeadings>, fromIndex: number, toIndex: number) {
  const source = headings[fromIndex]
  if (!source || !headings[toIndex]) return metadata
  const endIndex = headings.findIndex((heading, index) => index > fromIndex && heading.level <= source.level)
  const count = (endIndex < 0 ? headings.length : endIndex) - fromIndex
  const values = headings.map((_, index) => metadata[String(index)])
  const moved = values.splice(fromIndex, count)
  const insertion = toIndex > fromIndex ? Math.max(0, toIndex - count) : toIndex
  values.splice(insertion, 0, ...moved)
  return Object.fromEntries(values.map((value, index) => [String(index), value]))
}

export function GuidelineMarkdownEditor({
  versionId,
  documentTitle,
  versionLabel,
  publishedVersionId,
  structuredRevisionId,
  publishedRevisionId,
  openTemplatesInitially = false,
  initialContent,
  initialDraft = null,
  editable,
  published,
}: GuidelineMarkdownEditorProps) {
  const router = useRouter()
  const { resolvedTheme } = useTheme()
  const editorRef = React.useRef<ReactCodeMirrorRef>(null)
  const previewScrollRef = React.useRef<HTMLDivElement>(null)
  const scrollSyncLock = React.useRef(false)
  const editorPosition = React.useRef({ anchor: 0, head: 0, scrollTop: 0 })
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
  const [templatesOpen, setTemplatesOpen] = React.useState(openTemplatesInitially && editable && !published && !initialContent.trim())
  const [checkpointOpen, setCheckpointOpen] = React.useState(false)
  const [checkpointName, setCheckpointName] = React.useState("")
  const [checkpointSummary, setCheckpointSummary] = React.useState("")
  const [historyOpen, setHistoryOpen] = React.useState(false)
  const [historyLoading, setHistoryLoading] = React.useState(false)
  const [revisions, setRevisions] = React.useState<MarkdownRevision[]>([])
  const [historyPage, setHistoryPage] = React.useState(1)
  const [historyTotalPages, setHistoryTotalPages] = React.useState(1)
  const [historySource, setHistorySource] = React.useState("")
  const [historyEditor, setHistoryEditor] = React.useState("")
  const [historyFrom, setHistoryFrom] = React.useState("")
  const [historyTo, setHistoryTo] = React.useState("")
  const [selectedRevisionIds, setSelectedRevisionIds] = React.useState<string[]>([])
  const [revisionPreview, setRevisionPreview] = React.useState<MarkdownDraft | null>(null)
  const [pendingRestore, setPendingRestore] = React.useState<MarkdownRevision | null>(null)
  const [compareOpen, setCompareOpen] = React.useState(false)
  const [compareContent, setCompareContent] = React.useState("")
  const [compareCurrentContent, setCompareCurrentContent] = React.useState("")
  const [compareLabel, setCompareLabel] = React.useState("")
  const [conflictDraft, setConflictDraft] = React.useState<MarkdownDraft | null>(null)
  const [regenerating, setRegenerating] = React.useState(false)
  const [pendingSourceType, setPendingSourceType] = React.useState<"blank" | "template" | "uploaded_markdown" | null>(null)
  const [previewPresentation, setPreviewPresentation] = React.useState<MarkdownPreviewPresentation>("rendered")
  const [duplicateOpen, setDuplicateOpen] = React.useState(false)
  const [duplicateVersion, setDuplicateVersion] = React.useState("")
  const [duplicatePublicationDate, setDuplicatePublicationDate] = React.useState("")
  const [duplicateReviewDate, setDuplicateReviewDate] = React.useState("")
  const [duplicating, setDuplicating] = React.useState(false)
  const [outlineSearch, setOutlineSearch] = React.useState("")
  const [activeHeading, setActiveHeading] = React.useState(0)
  const [draggedHeading, setDraggedHeading] = React.useState<number | null>(null)
  const [collapsedHeadingIndexes, setCollapsedHeadingIndexes] = React.useState<Set<number>>(() => new Set())
  const [calloutOpen, setCalloutOpen] = React.useState(false)
  const [calloutType, setCalloutType] = React.useState<ClinicalCalloutType>("recommendation")
  const [calloutTitle, setCalloutTitle] = React.useState("")
  const [calloutSeverity, setCalloutSeverity] = React.useState<"" | "standard" | "important" | "high" | "critical">("")
  const [calloutEvidence, setCalloutEvidence] = React.useState("")
  const [calloutSource, setCalloutSource] = React.useState("")
  const [calloutContent, setCalloutContent] = React.useState("")
  const [tableOpen, setTableOpen] = React.useState(false)
  const [tableInitial, setTableInitial] = React.useState<MarkdownTableModel>(() => emptyMarkdownTable())
  const [tableRange, setTableRange] = React.useState<{ from: number; to: number } | null>(null)
  const [assetLibraryOpen, setAssetLibraryOpen] = React.useState(false)
  const [assets, setAssets] = React.useState<GuidelineAsset[]>([])
  const [anchorMetadata, setAnchorMetadata] = React.useState(() => stableHeadingAnchors(initialContent, initialDraft?.revision.anchor_metadata))

  const canEdit = editable && !published
  const dirty = canEdit && content !== savedContent
  const headings = React.useMemo(() => markdownHeadings(content), [content])
  const issues = React.useMemo(() => validateMarkdown(content), [content])
  const stats = React.useMemo(() => markdownStats(content), [content])
  const visibleHeadings = React.useMemo(() => headings.filter((heading, index) => {
    if (!heading.text.toLowerCase().includes(outlineSearch.toLowerCase())) return false
    if (outlineSearch.trim()) return true
    for (const collapsedIndex of collapsedHeadingIndexes) {
      const parent = headings[collapsedIndex]
      if (!parent || collapsedIndex >= index) continue
      const nextPeer = headings.findIndex((candidate, candidateIndex) => candidateIndex > collapsedIndex && candidate.level <= parent.level)
      if (nextPeer < 0 || index < nextPeer) return false
    }
    return true
  }), [collapsedHeadingIndexes, headings, outlineSearch])
  const renamedAnchors = React.useMemo(() => headings.filter((heading, index) => anchorMetadata[String(index)] && anchorMetadata[String(index)].title !== heading.text), [anchorMetadata, headings])
  useUnsavedChanges(dirty)

  const view = () => editorRef.current?.view

  const captureEditorPosition = React.useCallback(() => {
    const editor = editorRef.current?.view
    if (!editor) return
    editorPosition.current = {
      anchor: editor.state.selection.main.anchor,
      head: editor.state.selection.main.head,
      scrollTop: editor.scrollDOM.scrollTop,
    }
  }, [])

  const changeMode = React.useCallback((nextMode: MarkdownViewMode) => {
    captureEditorPosition()
    setMode(nextMode)
  }, [captureEditorPosition])

  const restoreEditorPosition = React.useCallback((editor: EditorView) => {
    const saved = editorPosition.current
    window.requestAnimationFrame(() => {
      const anchor = Math.min(saved.anchor, editor.state.doc.length)
      const head = Math.min(saved.head, editor.state.doc.length)
      editor.dispatch({ selection: { anchor, head } })
      editor.scrollDOM.scrollTop = saved.scrollTop
    })
  }, [])

  const synchronizeScroll = React.useCallback((source: HTMLElement, target?: HTMLElement | null) => {
    if (!target || !preferences.scrollSync || mode !== "split" || scrollSyncLock.current) return
    const available = source.scrollHeight - source.clientHeight
    const targetAvailable = target.scrollHeight - target.clientHeight
    if (available <= 0 || targetAvailable <= 0) return
    scrollSyncLock.current = true
    target.scrollTop = (source.scrollTop / available) * targetAvailable
    window.requestAnimationFrame(() => {
      scrollSyncLock.current = false
    })
  }, [mode, preferences.scrollSync])

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
    let active = true
    void GuidelineAssetsService.list(versionId).then((result) => { if (active) setAssets(result.items) }).catch(() => { /* The editor remains usable when the asset service is unavailable. */ })
    return () => { active = false }
  }, [versionId])

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
    setAnchorMetadata(result.revision.anchor_metadata || stableHeadingAnchors(result.content, anchorMetadata))
    try {
      localStorage.removeItem(recoveryKey(versionId))
    } catch {
      // Recovery storage is best effort.
    }
  }, [anchorMetadata, versionId])

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
        anchor_metadata: stableHeadingAnchors(content, anchorMetadata),
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
  }, [anchorMetadata, applySavedDraft, canEdit, content, dirty, draft, online, pendingSourceType, saving, versionId])

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
        changeMode(mode === "preview" ? (canEdit ? "split" : "preview") : "preview")
      }
      if (event.key === "F11") {
        event.preventDefault()
        setFullscreen((value) => !value)
      }
    }
    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [canEdit, changeMode, mode, save])

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

  const format = (action: MarkdownFormatAction) => {
    const editor = view()
    if (!editor) return
    if (action.startsWith("heading-")) {
      prefixLines(editor, `${"#".repeat(Number(action.split("-")[1]))} `)
      return
    }
    if (action.startsWith("callout-")) {
      const type = action.slice(8) as ClinicalCalloutType
      const selection = editor.state.selection.main
      setCalloutType(type)
      setCalloutContent(editor.state.sliceDoc(selection.from, selection.to))
      setCalloutOpen(true)
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
      case "image": setAssetLibraryOpen(true); break
      case "horizontal-rule": selectionReplacement(editor, "\n---\n", "", ""); break
      case "table": {
        const selection = editor.state.selection.main
        const existing = markdownTableAt(editor.state.doc.toString(), selection.head)
        setTableInitial(existing?.table || emptyMarkdownTable())
        setTableRange(existing ? { from: existing.from, to: existing.to } : { from: selection.from, to: selection.to })
        setTableOpen(true)
        break
      }
      case "footnote": selectionReplacement(editor, "[^", "]", "reference"); break
      case "reference": selectionReplacement(editor, "[", "]", "reference"); break
      case "format": setContent(formatMarkdown(content)); break
    }
  }

  const loadHistory = async (page = historyPage) => {
    setHistoryOpen(true)
    setHistoryLoading(true)
    try {
      const result = await GuidelineMarkdownService.revisions(versionId, {
        page,
        per_page: 20,
        source_type: historySource as never,
        created_by: historyEditor.trim() || undefined,
        from: historyFrom ? new Date(`${historyFrom}T00:00:00`).toISOString() : undefined,
        to: historyTo ? new Date(`${historyTo}T23:59:59`).toISOString() : undefined,
      })
      setHistoryPage(result.page)
      setHistoryTotalPages(result.total_pages)
      setRevisions(result.items.map((revision) => ({
        ...revision,
        change_summary: [
          revision.change_summary,
          revision.id === structuredRevisionId ? "Current structured-content source" : "",
          revision.id === publishedRevisionId ? "Currently published revision" : "",
        ].filter(Boolean).join(" · "),
      })))
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
      setCompareCurrentContent(content)
      setCompareLabel(`Revision ${revision.revision_number}`)
      setCompareOpen(true)
    } catch (error) {
      showToast.error("Comparison failed", error instanceof Error ? error.message : "Could not load revision")
    }
  }

  const compareSelectedRevisions = async () => {
    if (selectedRevisionIds.length !== 2) return
    try {
      const [before, after] = await Promise.all(selectedRevisionIds.map((id) => GuidelineMarkdownService.revision(versionId, id)))
      setCompareContent(before.content)
      setCompareCurrentContent(after.content)
      setCompareLabel(`revision ${before.revision.revision_number} with revision ${after.revision.revision_number}`)
      setCompareOpen(true)
    } catch (error) {
      showToast.error("Comparison failed", error instanceof Error ? error.message : "Could not load revisions")
    }
  }

  const previewRevision = async (revision: MarkdownRevision) => {
    try { setRevisionPreview(await GuidelineMarkdownService.revision(versionId, revision.id)) }
    catch (error) { showToast.error("Preview failed", error instanceof Error ? error.message : "Could not load revision") }
  }

  const compareSpecialRevision = async (kind: "saved" | "regenerated") => {
    if (kind === "saved") {
      setCompareContent(savedContent); setCompareCurrentContent(content); setCompareLabel("last saved revision"); setCompareOpen(true); return
    }
    const result = await GuidelineMarkdownService.revisions(versionId, { page: 1, per_page: 100 })
    const revision = result.items.find((item) => Boolean(item.regeneration_job_id) && ["review_required", "approved"].includes(item.structured_content_status))
    if (!revision) { showToast.error("No regenerated revision", "No completed regenerated Markdown revision is available."); return }
    await compareRevision(revision)
    setCompareLabel(`last regenerated revision ${revision.revision_number}`)
  }

  const insertClinicalCallout = () => {
    const editor = view()
    if (!editor || !calloutContent.trim()) return
    const selection = editor.state.selection.main
    const markdown = clinicalCalloutMarkdown({ type: calloutType, title: calloutTitle || undefined, severity: calloutSeverity || undefined, evidenceGrade: calloutEvidence || undefined, source: calloutSource || undefined, content: calloutContent })
    editor.dispatch({ changes: { from: selection.from, to: selection.to, insert: markdown }, selection: { anchor: selection.from + markdown.length }, scrollIntoView: true })
    setCalloutOpen(false)
    setCalloutTitle(""); setCalloutSeverity(""); setCalloutEvidence(""); setCalloutSource(""); setCalloutContent("")
    editor.focus()
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

  const compareWithPublished = async () => {
    if (!publishedVersionId || publishedVersionId === versionId) return
    try {
      const publishedDraft = await GuidelineMarkdownService.loadDraft(publishedVersionId)
      setCompareContent(publishedDraft.content)
      setCompareCurrentContent(content)
      setCompareLabel("published revision")
      setCompareOpen(true)
    } catch (error) {
      showToast.error("Published comparison unavailable", error instanceof Error ? error.message : "Could not load published Markdown")
    }
  }

  const duplicateAsDraft = async () => {
    if (!duplicateVersion.trim() || duplicating) return
    setDuplicating(true)
    try {
      const result = await GuidelineMarkdownService.duplicateVersion(versionId, {
        version: duplicateVersion.trim(),
        publication_date: duplicatePublicationDate || undefined,
        review_date: duplicateReviewDate || undefined,
      })
      showToast.success(
        published ? "Draft created from published version" : "Draft duplicated",
        "The new version has an independent immutable Markdown draft.",
      )
      setDuplicateOpen(false)
      router.push(`/guidelines/${result.version.document_id}/versions/${result.version.id}/markdown`)
    } catch (error) {
      showToast.error("Draft creation failed", error instanceof Error ? error.message : "Could not create the draft version")
    } finally {
      setDuplicating(false)
    }
  }

  const openPrintPreview = () => {
    changeMode("preview")
    setPreviewPresentation("print")
    window.requestAnimationFrame(() => window.print())
  }

  const editorExtensions = React.useMemo(() => [
    markdown(),
    keymap.of([...editorFormattingKeymap, ...defaultKeymap, ...historyKeymap, ...searchKeymap, indentWithTab]),
    EditorView.domEventHandlers({
      scroll: (_event, editor) => synchronizeScroll(editor.scrollDOM, previewScrollRef.current),
    }),
    EditorView.updateListener.of((update) => {
      if (!update.selectionSet && !update.docChanged) return
      const cursor = update.state.selection.main.head
      const next = markdownHeadings(update.state.doc.toString()).findLastIndex((heading) => heading.from <= cursor)
      setActiveHeading(Math.max(0, next))
    }),
    ...(preferences.lineWrapping ? [EditorView.lineWrapping] : []),
    EditorView.theme({
      "&": { fontSize: `${preferences.fontSize}px`, height: "100%" },
      ".cm-scroller": { fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace" },
      ".cm-content": { minHeight: "62vh", padding: "16px 0" },
    }),
  ], [preferences.fontSize, preferences.lineWrapping, synchronizeScroll])

  const previewClass = preferences.previewWidth === "mobile"
    ? "mx-auto max-w-[430px]"
    : preferences.previewWidth === "tablet"
      ? "mx-auto max-w-[820px]"
      : "w-full"

  const renderPreviewPane = () => (
    <div
      ref={previewScrollRef}
      className="h-[65vh] overflow-auto p-5 print:h-auto print:overflow-visible print:p-0 lg:p-8 lg:print:p-0"
      onScroll={(event) => synchronizeScroll(event.currentTarget, view()?.scrollDOM)}
    >
      <div className={previewPresentation === "print" ? "w-full" : previewClass}>
        <MarkdownPreviewSurface
          content={content}
          title={documentTitle}
          versionLabel={versionLabel}
          presentation={previewPresentation}
          assets={assets}
        />
      </div>
    </div>
  )

  return (
    <>
      <section className={cn(
        "overflow-hidden rounded-lg border bg-card shadow-sm print:fixed print:inset-0 print:z-[100] print:overflow-visible print:rounded-none print:border-0 print:bg-white print:shadow-none",
        fullscreen && "fixed inset-0 z-50 rounded-none",
      )}>
        <div className="print:hidden"><MarkdownEditorToolbar
          mode={mode}
          canEdit={canEdit}
          dirty={dirty}
          saving={saving}
          offline={!online}
          autosave={preferences.autosave}
          fullscreen={fullscreen}
          words={stats.words}
          characters={stats.characters}
          onModeChange={changeMode}
          onSave={() => void save()}
          onRevert={() => setRevertOpen(true)}
          onFormat={format}
          onUndo={() => { const editor = view(); if (editor) undo(editor) }}
          onRedo={() => { const editor = view(); if (editor) redo(editor) }}
          onSearch={() => { const editor = view(); if (editor) openSearchPanel(editor) }}
          onFullscreen={() => setFullscreen((value) => !value)}
          onRegenerate={canEdit && draft ? () => void regenerate() : undefined}
          onDownload={() => downloadText(`guideline-revision-${draft?.revision.revision_number || "draft"}.md`, content)}
        /></div>

        <div className="flex flex-wrap items-center gap-2 border-b px-3 py-2 text-xs print:hidden">
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
          <Button size="sm" variant="ghost" onClick={() => setAssetLibraryOpen(true)}><Images className="mr-2 h-4 w-4" />Assets</Button>
          {draft && <Button size="sm" variant="ghost" onClick={() => setDuplicateOpen(true)}><FilePlus2 className="mr-2 h-4 w-4" />{published ? "Create draft version" : "Duplicate draft"}</Button>}
          {publishedVersionId && publishedVersionId !== versionId && <Button size="sm" variant="ghost" onClick={() => void compareWithPublished()}><GitCompareArrows className="mr-2 h-4 w-4" />Compare published</Button>}
          {dirty && <Button size="sm" variant="ghost" onClick={() => void compareSpecialRevision("saved")}><GitCompareArrows className="mr-2 h-4 w-4" />Compare saved</Button>}
          <Button size="sm" variant="ghost" onClick={() => void compareSpecialRevision("regenerated")}><GitCompareArrows className="mr-2 h-4 w-4" />Compare regenerated</Button>
          <Button size="sm" variant="ghost" onClick={() => void copyMarkdown()}><Copy className="mr-2 h-4 w-4" />Copy</Button>
          <Button size="sm" variant="ghost" onClick={() => setSettingsOpen(true)}><Settings2 className="mr-2 h-4 w-4" />Editor settings</Button>
          {(mode === "preview" || mode === "split") && (
            <>
              <Label className="sr-only" htmlFor="markdown-preview-presentation">Preview presentation</Label>
              <select
                id="markdown-preview-presentation"
                aria-label="Preview presentation"
                className="h-8 rounded-md border bg-background px-2 text-xs"
                value={previewPresentation}
                onChange={(event) => setPreviewPresentation(event.target.value as MarkdownPreviewPresentation)}
              >
                <option value="rendered">Rendered Markdown</option>
                <option value="public-reader">Public reader</option>
                <option value="structured-reader">Structured reader</option>
                <option value="print">Print layout</option>
              </select>
              <Button size="sm" variant="ghost" onClick={openPrintPreview}><Printer className="mr-2 h-4 w-4" />Print</Button>
            </>
          )}
          <Badge variant="outline">{stats.lines} lines</Badge>
          <Badge variant="outline">{stats.headings} headings</Badge>
          <Badge variant="outline">{stats.readingMinutes} min read</Badge>
          {draft && <Badge variant="secondary">Revision {draft.revision.revision_number}</Badge>}
          {draft?.revision.id === structuredRevisionId && <Badge variant="outline">Current structured source</Badge>}
          {draft?.revision.id === publishedRevisionId && <Badge variant="secondary">Published revision</Badge>}
          {draft && <Badge variant={draft.revision.structured_content_status === "failed" ? "destructive" : "outline"}>{draft.revision.structured_content_status.replaceAll("_", " ")}</Badge>}
          <span className="ml-auto">{issues.filter((issue) => issue.severity === "error").length} errors · {issues.filter((issue) => issue.severity === "warning").length} warnings</span>
        </div>

        <div className="sr-only" role="status" aria-live="polite">
          {saving ? "Saving Markdown" : saveError ? `Save failed: ${saveError}` : dirty ? "Markdown has unsaved changes" : "All Markdown changes are saved"}
        </div>

        <div className="print:hidden">{recovery && (
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
        {renamedAnchors.length > 0 && <Alert className="m-4 mb-0"><Info className="h-4 w-4" /><AlertTitle>Stable section anchor retained</AlertTitle><AlertDescription>{renamedAnchors.length} renamed heading{renamedAnchors.length === 1 ? "" : "s"} will retain revision metadata anchors. Review inbound links before publication.</AlertDescription></Alert>}
        {saveError && <Alert variant="destructive" className="m-4 mb-0"><AlertCircle className="h-4 w-4" /><AlertTitle>Markdown was not saved</AlertTitle><AlertDescription className="flex flex-wrap items-center gap-2"><span>{saveError} Your edits remain available.</span><Button size="sm" variant="outline" disabled={saving || !online} onClick={() => void save()}>Retry save</Button></AlertDescription></Alert>}</div>

        <div className={cn("grid", !preferences.distractionFree && "lg:grid-cols-[220px_minmax(0,1fr)]")}>
          {!preferences.distractionFree && (
            <aside className="hidden border-r print:hidden lg:block">
              <div className="space-y-2 border-b p-3"><div className="text-sm font-medium">Document outline</div><Input aria-label="Search headings" placeholder="Search headings…" className="h-8 text-xs" value={outlineSearch} onChange={(event) => setOutlineSearch(event.target.value)} /><div className="flex gap-1"><Button size="sm" variant="ghost" className="h-7 px-2 text-[11px]" onClick={() => { const editor = view(); if (editor) foldAll(editor) }}>Collapse source</Button><Button size="sm" variant="ghost" className="h-7 px-2 text-[11px]" onClick={() => { const editor = view(); if (editor) unfoldAll(editor) }}>Expand source</Button></div>{headings[activeHeading] && <p className="truncate text-[11px] text-muted-foreground">{headings[activeHeading].breadcrumb.join(" › ")}</p>}</div>
              <ScrollArea className="h-[65vh] p-2">
                {headings.length === 0 && <p className="p-2 text-xs text-muted-foreground">Add headings to build navigation.</p>}
                {visibleHeadings.map((heading) => {
                  const index = headings.indexOf(heading)
                  const sectionIssues = issues.filter((issue) => issue.line >= heading.line && issue.line < (headings[index + 1]?.line ?? Number.MAX_SAFE_INTEGER))
                  return (
                  <button
                    key={`${heading.id}-${index}`}
                    type="button"
                    draggable={canEdit}
                    onDragStart={() => setDraggedHeading(index)}
                    onDragOver={(event) => event.preventDefault()}
                    onDrop={() => { if (draggedHeading === null) return; setContent(moveMarkdownSection(content, draggedHeading, index)); setAnchorMetadata(reorderAnchorMetadata(anchorMetadata, headings, draggedHeading, index)); setDraggedHeading(null) }}
                    className={cn("flex w-full items-center gap-1 truncate rounded px-2 py-1.5 text-left text-xs hover:bg-muted", activeHeading === index && "bg-muted font-medium")}
                    style={{ paddingLeft: `${8 + (heading.level - 1) * 12}px` }}
                    title={`${heading.text} · ${heading.words} words · Double-click to ${collapsedHeadingIndexes.has(index) ? "expand" : "collapse"} descendants · review ${draft?.revision.review_state || "draft"}`}
                    onDoubleClick={() => setCollapsedHeadingIndexes((current) => { const next = new Set(current); if (next.has(index)) next.delete(index); else next.add(index); return next })}
                    onKeyDown={(event) => { if (!event.altKey || !["ArrowLeft", "ArrowRight"].includes(event.key)) return; event.preventDefault(); setCollapsedHeadingIndexes((current) => { const next = new Set(current); if (event.key === "ArrowLeft") next.add(index); else next.delete(index); return next }) }}
                    onClick={() => {
                      const editor = view()
                      editor?.dispatch({ selection: { anchor: heading.from }, scrollIntoView: true })
                      editor?.focus()
                    }}
                  >
                    <span aria-hidden="true" className="w-3 shrink-0">{collapsedHeadingIndexes.has(index) ? "▸" : "▾"}</span><span className="truncate">{heading.text}</span><span className="ml-auto shrink-0 text-[10px] text-muted-foreground">{heading.words}w</span>{sectionIssues.length > 0 && <Badge variant={sectionIssues.some((issue) => issue.severity === "error") ? "destructive" : "outline"} className="h-4 px-1 text-[9px]">{sectionIssues.length}</Badge>}
                  </button>
                )})}
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
                    onCreateEditor={restoreEditorPosition}
                    aria-label="Markdown source"
                  />
                </ResizablePanel>
                <ResizableHandle withHandle />
                <ResizablePanel defaultSize={50} minSize={25}>
                  {renderPreviewPane()}
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
                onCreateEditor={restoreEditorPosition}
                aria-label="Markdown source"
              />
            ) : (
              renderPreviewPane()
            )}
          </div>
        </div>

        <footer className="flex min-h-11 items-center border-t px-4 text-xs text-muted-foreground print:hidden">
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

      <Dialog
        open={duplicateOpen}
        onOpenChange={(open) => {
          setDuplicateOpen(open)
          if (!open && !duplicating) {
            setDuplicateVersion("")
            setDuplicatePublicationDate("")
            setDuplicateReviewDate("")
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{published ? "Create a draft from this published version" : "Duplicate this draft"}</DialogTitle>
            <DialogDescription>
              The exact immutable Markdown revision is copied into a new draft version. Structured content is marked outdated and regeneration does not start automatically.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="duplicate-version-number">New version</Label>
              <Input id="duplicate-version-number" placeholder="2026.2" value={duplicateVersion} onChange={(event) => setDuplicateVersion(event.target.value)} />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="duplicate-publication-date">Planned publication date</Label>
                <Input id="duplicate-publication-date" type="date" value={duplicatePublicationDate} onChange={(event) => setDuplicatePublicationDate(event.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="duplicate-review-date">Review date</Label>
                <Input id="duplicate-review-date" type="date" value={duplicateReviewDate} onChange={(event) => setDuplicateReviewDate(event.target.value)} />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" disabled={duplicating} onClick={() => setDuplicateOpen(false)}>Cancel</Button>
            <Button disabled={duplicating || !duplicateVersion.trim()} onClick={() => void duplicateAsDraft()}>
              {duplicating ? "Creating…" : published ? "Create draft version" : "Duplicate draft"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={settingsOpen} onOpenChange={setSettingsOpen}>
        <DialogContent><DialogHeader><DialogTitle>Editor settings</DialogTitle><DialogDescription>These preferences are stored only in this browser.</DialogDescription></DialogHeader><div className="space-y-5"><div className="flex items-center justify-between"><Label htmlFor="autosave">Autosave drafts</Label><Switch id="autosave" checked={preferences.autosave} onCheckedChange={(value) => setPreferences((current) => ({ ...current, autosave: value }))} /></div><div><Label htmlFor="autosave-delay">Autosave delay (milliseconds)</Label><Input id="autosave-delay" type="number" min={1000} max={30000} step={500} value={preferences.autosaveDelay} onChange={(event) => setPreferences((current) => ({ ...current, autosaveDelay: Math.min(30000, Math.max(1000, Number(event.target.value))) }))} /></div><div className="flex items-center justify-between"><Label htmlFor="line-wrap">Soft line wrapping</Label><Switch id="line-wrap" checked={preferences.lineWrapping} onCheckedChange={(value) => setPreferences((current) => ({ ...current, lineWrapping: value }))} /></div><div className="flex items-center justify-between"><Label htmlFor="scroll-sync">Synchronize editor and preview scrolling</Label><Switch id="scroll-sync" checked={preferences.scrollSync} onCheckedChange={(value) => setPreferences((current) => ({ ...current, scrollSync: value }))} /></div><div className="flex items-center justify-between"><Label htmlFor="distraction-free">Distraction-free mode</Label><Switch id="distraction-free" checked={preferences.distractionFree} onCheckedChange={(value) => setPreferences((current) => ({ ...current, distractionFree: value }))} /></div><div><Label htmlFor="font-size">Editor font size</Label><Input id="font-size" type="number" min={12} max={22} value={preferences.fontSize} onChange={(event) => setPreferences((current) => ({ ...current, fontSize: Math.min(22, Math.max(12, Number(event.target.value))) }))} /></div><div><Label htmlFor="preview-width">Preview width</Label><select id="preview-width" className="mt-1 h-9 w-full rounded-md border bg-background px-3" value={preferences.previewWidth} onChange={(event) => setPreferences((current) => ({ ...current, previewWidth: event.target.value as EditorPreferences["previewWidth"] }))}><option value="mobile">Mobile</option><option value="tablet">Tablet</option><option value="desktop">Desktop</option></select></div></div></DialogContent>
      </Dialog>

      <Dialog open={commandOpen} onOpenChange={setCommandOpen}>
        <DialogContent className="overflow-hidden p-0">
          <DialogHeader><DialogTitle>Markdown commands</DialogTitle><DialogDescription>Open with Ctrl/Command+Shift+P. Commands act on the current draft and editor selection.</DialogDescription></DialogHeader>
          <Command><CommandInput placeholder="Search document commands or headings…" /><CommandList><CommandEmpty>No command or heading found.</CommandEmpty><CommandGroup heading="Commands">
            <CommandItem disabled={!dirty || saving || !online} onSelect={() => { setCommandOpen(false); void save() }}>Save draft</CommandItem>
            <CommandItem onSelect={() => { changeMode(mode === "preview" ? (canEdit ? "split" : "preview") : "preview"); setCommandOpen(false) }}>Toggle preview</CommandItem>
            <CommandItem onSelect={() => { setFullscreen((value) => !value); setCommandOpen(false) }}>Toggle fullscreen</CommandItem>
            <CommandItem disabled={!canEdit} onSelect={() => { setContent(formatMarkdown(content)); setCommandOpen(false) }}>Format document / normalize line endings / remove trailing whitespace</CommandItem>
            <CommandItem disabled={!canEdit} onSelect={() => { const editor = view(); if (editor) openSearchPanel(editor); setCommandOpen(false) }}>Find and replace</CommandItem>
            <CommandItem onSelect={() => { setCommandOpen(false); void loadHistory() }}>Revision history</CommandItem>
          </CommandGroup><CommandGroup heading="Go to heading">{headings.map((heading, index) => <CommandItem key={`${heading.id}-${index}`} value={`heading ${heading.breadcrumb.join(" ")}`} onSelect={() => { const editor = view(); editor?.dispatch({ selection: { anchor: heading.from }, scrollIntoView: true }); editor?.focus(); setCommandOpen(false) }}>{heading.breadcrumb.join(" › ")}</CommandItem>)}</CommandGroup></CommandList></Command>
          {canEdit && <div className="flex items-end gap-2 border-t p-4"><div className="flex-1"><Label htmlFor="go-to-line">Go to line</Label><Input id="go-to-line" type="number" min={1} value={goToLine} onChange={(event) => setGoToLine(event.target.value)} /></div><Button onClick={() => { const editor = view(); if (!editor) return; const number = Math.min(Math.max(1, Number(goToLine) || 1), editor.state.doc.lines); const line = editor.state.doc.line(number); editor.dispatch({ selection: { anchor: line.from }, scrollIntoView: true }); editor.focus(); setCommandOpen(false) }}>Go</Button></div>}
        </DialogContent>
      </Dialog>

      <Dialog open={historyOpen} onOpenChange={setHistoryOpen}>
        <DialogContent className="max-w-5xl"><DialogHeader><DialogTitle>Markdown revision history</DialogTitle><DialogDescription>Every entry is immutable. Select two revisions for an exact comparison; restore always creates a new revision.</DialogDescription></DialogHeader>
          <div className="grid gap-2 sm:grid-cols-4"><Input aria-label="Filter by editor UUID" placeholder="Editor UUID" value={historyEditor} onChange={(event) => setHistoryEditor(event.target.value)} /><select aria-label="Filter by source type" className="h-9 rounded-md border bg-background px-3 text-sm" value={historySource} onChange={(event) => setHistorySource(event.target.value)}><option value="">All sources</option>{["blank", "template", "uploaded_markdown", "pdf_generated", "manual_edit", "restored", "duplicated"].map((source) => <option key={source} value={source}>{source.replaceAll("_", " ")}</option>)}</select><Input aria-label="Created from" type="date" value={historyFrom} onChange={(event) => setHistoryFrom(event.target.value)} /><Input aria-label="Created to" type="date" value={historyTo} onChange={(event) => setHistoryTo(event.target.value)} /></div>
          <div className="flex flex-wrap gap-2"><Button size="sm" onClick={() => void loadHistory(1)}>Apply filters</Button><Button size="sm" variant="outline" disabled={selectedRevisionIds.length !== 2} onClick={() => void compareSelectedRevisions()}>Compare selected ({selectedRevisionIds.length}/2)</Button></div>
          <ScrollArea className="max-h-[55vh]"><div className="space-y-2 pr-3">{historyLoading && <p className="text-sm text-muted-foreground">Loading revisions…</p>}{revisions.map((revision) => <div key={revision.id} className="flex flex-col gap-3 rounded-lg border p-3 sm:flex-row sm:items-center"><Checkbox aria-label={`Select revision ${revision.revision_number}`} checked={selectedRevisionIds.includes(revision.id)} onCheckedChange={(checked) => setSelectedRevisionIds((current) => checked ? [...current.filter((id) => id !== revision.id), revision.id].slice(-2) : current.filter((id) => id !== revision.id))} /><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium">Revision {revision.revision_number}</span>{revision.is_current && <Badge>Current draft</Badge>}{revision.publication_state === "published" && <Badge variant="secondary">Published source</Badge>}{revision.regeneration_job_id && <Badge variant="outline">Generated structured content</Badge>}<Badge variant="outline">{revision.source_type.replaceAll("_", " ")}</Badge></div><p className="mt-1 truncate text-sm">{revision.checkpoint_name || revision.change_summary || "Unnamed draft"}</p><p className="text-xs text-muted-foreground">{new Date(revision.created_at).toLocaleString()} · editor {revision.created_by || "system"} · {revision.size_bytes.toLocaleString()} bytes · {revision.structured_content_status.replaceAll("_", " ")}</p>{revision.change_summary && <p className="mt-1 text-xs text-muted-foreground">{revision.change_summary}</p>}</div><div className="flex flex-wrap gap-2"><Button size="sm" variant="outline" onClick={() => void previewRevision(revision)}>Preview</Button><Button size="sm" variant="outline" onClick={() => void compareRevision(revision)}>Compare current</Button><Button size="sm" variant="outline" onClick={async () => { const item = await GuidelineMarkdownService.revision(versionId, revision.id); downloadText(`guideline-revision-${revision.revision_number}.md`, item.content) }}>Download</Button>{canEdit && !revision.is_current && <Button size="sm" onClick={() => setPendingRestore(revision)}>Restore</Button>}</div></div>)}</div></ScrollArea>
          <DialogFooter className="items-center"><span className="mr-auto text-xs text-muted-foreground">Page {historyPage} of {Math.max(1, historyTotalPages)}</span><Button variant="outline" disabled={historyPage <= 1 || historyLoading} onClick={() => void loadHistory(historyPage - 1)}>Previous</Button><Button variant="outline" disabled={historyPage >= historyTotalPages || historyLoading} onClick={() => void loadHistory(historyPage + 1)}>Next</Button></DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={compareOpen} onOpenChange={(open) => { setCompareOpen(open); if (!open) setCompareCurrentContent("") }}>
        <DialogContent className="max-w-6xl"><DialogHeader><DialogTitle>Compare {compareLabel}</DialogTitle><DialogDescription>Markdown is compared as inert text. Raw HTML is never executed.</DialogDescription></DialogHeader><MarkdownDiffViewer before={compareContent} after={compareCurrentContent || content} beforeLabel={compareLabel} onDownload={(value) => downloadText("guideline-diff.txt", value)} /></DialogContent>
      </Dialog>

      <Dialog open={Boolean(revisionPreview)} onOpenChange={(open) => { if (!open) setRevisionPreview(null) }}><DialogContent className="max-w-4xl"><DialogHeader><DialogTitle>Revision {revisionPreview?.revision.revision_number} preview</DialogTitle><DialogDescription>Read-only safe Markdown preview.</DialogDescription></DialogHeader><ScrollArea className="max-h-[70vh] p-4">{revisionPreview && <MarkdownPreviewSurface content={revisionPreview.content} title={documentTitle} versionLabel={versionLabel} presentation="rendered" />}</ScrollArea></DialogContent></Dialog>

      <AlertDialog open={Boolean(pendingRestore)} onOpenChange={(open) => { if (!open) setPendingRestore(null) }}><AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Restore revision {pendingRestore?.revision_number}?</AlertDialogTitle><AlertDialogDescription>This does not overwrite history. A new current draft revision will reference the selected immutable revision.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter><AlertDialogCancel>Cancel</AlertDialogCancel><AlertDialogAction onClick={() => { if (pendingRestore) void restoreRevision(pendingRestore); setPendingRestore(null) }}>Create restored draft</AlertDialogAction></AlertDialogFooter></AlertDialogContent></AlertDialog>

      <Dialog open={calloutOpen} onOpenChange={setCalloutOpen}><DialogContent><DialogHeader><DialogTitle>Insert clinical callout</DialogTitle><DialogDescription>Enter only reviewed clinical content. The editor will preserve values and units exactly; high-risk callouts require reviewer approval before publication.</DialogDescription></DialogHeader><div className="space-y-4"><div><Label htmlFor="callout-type">Callout type</Label><select id="callout-type" className="mt-1 h-9 w-full rounded border bg-background px-3" value={calloutType} onChange={(event) => setCalloutType(event.target.value as ClinicalCalloutType)}>{["recommendation", "warning", "caution", "key-point", "contraindication", "dosage", "evidence", "definition", "procedure", "algorithm-reference", "clinical-note", "referral-criteria"].map((type) => <option key={type} value={type}>{type.replaceAll("-", " ")}</option>)}</select></div><div><Label htmlFor="callout-title">Title (optional)</Label><Input id="callout-title" value={calloutTitle} onChange={(event) => setCalloutTitle(event.target.value)} /></div><div className="grid gap-4 sm:grid-cols-2"><div><Label htmlFor="callout-severity">Severity</Label><select id="callout-severity" className="mt-1 h-9 w-full rounded border bg-background px-3" value={calloutSeverity} onChange={(event) => setCalloutSeverity(event.target.value as typeof calloutSeverity)}><option value="">Not specified</option>{["standard", "important", "high", "critical"].map((value) => <option key={value} value={value}>{value}</option>)}</select></div><div><Label htmlFor="callout-evidence">Evidence grade</Label><Input id="callout-evidence" value={calloutEvidence} onChange={(event) => setCalloutEvidence(event.target.value)} /></div></div><div><Label htmlFor="callout-source">Source or reference</Label><Input id="callout-source" value={calloutSource} onChange={(event) => setCalloutSource(event.target.value)} /></div><div><Label htmlFor="callout-content">Clinical content</Label><Textarea id="callout-content" rows={7} value={calloutContent} onChange={(event) => setCalloutContent(event.target.value)} placeholder="Enter reviewed content exactly as approved." /></div>{["recommendation", "warning", "caution", "contraindication", "dosage", "procedure", "algorithm-reference", "referral-criteria"].includes(calloutType) && <Alert><ShieldAlert className="h-4 w-4" /><AlertTitle>Clinical review required</AlertTitle><AlertDescription>This high-risk block cannot be published until an authorized reviewer approves the regenerated structured block.</AlertDescription></Alert>}</div><DialogFooter><Button variant="outline" onClick={() => setCalloutOpen(false)}>Cancel</Button><Button disabled={!calloutContent.trim()} onClick={insertClinicalCallout}>Insert without rewriting</Button></DialogFooter></DialogContent></Dialog>

      <MarkdownTableEditor open={tableOpen} initialTable={tableInitial} onOpenChange={setTableOpen} onApply={(markdown) => { const editor = view(); if (!editor || !tableRange) return; editor.dispatch({ changes: { from: tableRange.from, to: tableRange.to, insert: markdown }, selection: { anchor: tableRange.from + markdown.length }, scrollIntoView: true }); editor.focus(); setTableRange(null) }} />

      <GuidelineAssetLibrary open={assetLibraryOpen} versionId={versionId} editable={canEdit} onOpenChange={setAssetLibraryOpen} onAssetsChange={setAssets} onInsert={(asset) => { const editor = view(); if (!editor) return; const selection = editor.state.selection.main; const alt = asset.alternative_text || "Describe this image"; const caption = asset.caption ? `\n*${asset.caption}*` : ""; const source = asset.source ? `\n*Source: ${asset.source}*` : ""; const markdown = `![${alt}](${asset.reference})${caption}${source}`; editor.dispatch({ changes: { from: selection.from, to: selection.to, insert: markdown }, selection: { anchor: selection.from + markdown.length }, scrollIntoView: true }); editor.focus(); setAssetLibraryOpen(false) }} onReplaceReference={(reference, replacement) => setContent((current) => current.replaceAll(reference, replacement.reference))} />

      <AlertDialog open={Boolean(conflictDraft)} onOpenChange={(open) => { if (!open) setConflictDraft(null) }}>
        <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Another editor saved this draft</AlertDialogTitle><AlertDialogDescription>Your local text has been preserved. Choose how to resolve the conflict.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter className="flex-wrap"><AlertDialogCancel onClick={() => { if (conflictDraft) keepLocalAgainstServerRevision(conflictDraft) }}>Keep local text</AlertDialogCancel><Button variant="outline" onClick={() => { if (!conflictDraft) return; setCompareContent(conflictDraft.content); setCompareLabel("server draft"); setCompareOpen(true) }}>Open diff</Button><Button variant="outline" onClick={() => { if (conflictDraft) applySavedDraft(conflictDraft); setConflictDraft(null) }}>Reload server draft</Button><AlertDialogAction onClick={async () => { if (!conflictDraft) return; keepLocalAgainstServerRevision(conflictDraft); setCheckpointName("Conflict recovery"); setCheckpointSummary("Local edits saved after a concurrent change"); setCheckpointOpen(true) }}>Save local as checkpoint</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
      </AlertDialog>
    </>
  )
}
