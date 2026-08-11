"use client"

import {
  Bold,
  Braces,
  CheckSquare,
  Code2,
  Columns2,
  Eye,
  FileDown,
  FilePenLine,
  Fullscreen,
  Heading,
  Image,
  Italic,
  Link,
  List,
  ListOrdered,
  Maximize2,
  Minus,
  Pilcrow,
  Quote,
  Redo2,
  RefreshCw,
  RotateCcw,
  Save,
  Search,
  Strikethrough,
  Table2,
  Undo2,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { cn } from "@/lib/utils"

export type MarkdownViewMode = "edit" | "preview" | "split"
export type MarkdownFormatAction =
  | "bold"
  | "italic"
  | "strikethrough"
  | "inline-code"
  | "code-block"
  | "quote"
  | "ordered-list"
  | "unordered-list"
  | "task-list"
  | "link"
  | "image"
  | "horizontal-rule"
  | "table"
  | "footnote"
  | "reference"
  | "format"
  | `heading-${1 | 2 | 3 | 4 | 5 | 6}`
  | `callout-${string}`

interface MarkdownEditorToolbarProps {
  mode: MarkdownViewMode
  canEdit: boolean
  dirty: boolean
  saving: boolean
  offline?: boolean
  autosave?: boolean
  fullscreen?: boolean
  words: number
  characters: number
  onModeChange: (mode: MarkdownViewMode) => void
  onSave: () => void
  onRevert: () => void
  onFormat: (action: MarkdownFormatAction) => void
  onUndo: () => void
  onRedo: () => void
  onSearch: () => void
  onFullscreen: () => void
  onRegenerate?: () => void
  onDownload?: () => void
}

const actionButtons: Array<{
  action: MarkdownFormatAction
  label: string
  title: string
  icon: typeof Bold
}> = [
  { action: "bold", label: "Bold", title: "Bold (Ctrl/Cmd+B)", icon: Bold },
  { action: "italic", label: "Italic", title: "Italic (Ctrl/Cmd+I)", icon: Italic },
  { action: "strikethrough", label: "Strikethrough", title: "Strikethrough", icon: Strikethrough },
  { action: "inline-code", label: "Inline code", title: "Inline code", icon: Code2 },
  { action: "quote", label: "Block quote", title: "Block quote", icon: Quote },
  { action: "unordered-list", label: "Bulleted list", title: "Bulleted list", icon: List },
  { action: "ordered-list", label: "Numbered list", title: "Numbered list", icon: ListOrdered },
  { action: "task-list", label: "Task list", title: "Task list", icon: CheckSquare },
  { action: "link", label: "Link", title: "Insert link", icon: Link },
  { action: "image", label: "Image", title: "Insert image", icon: Image },
  { action: "table", label: "Table", title: "Insert table", icon: Table2 },
  { action: "code-block", label: "Code block", title: "Insert code block", icon: Braces },
  { action: "horizontal-rule", label: "Horizontal rule", title: "Insert horizontal rule", icon: Minus },
  { action: "footnote", label: "Footnote", title: "Insert footnote", icon: Pilcrow },
]

export function MarkdownEditorToolbar({
  mode,
  canEdit,
  dirty,
  saving,
  offline,
  autosave,
  fullscreen,
  words,
  characters,
  onModeChange,
  onSave,
  onRevert,
  onFormat,
  onUndo,
  onRedo,
  onSearch,
  onFullscreen,
  onRegenerate,
  onDownload,
}: MarkdownEditorToolbarProps) {
  return (
    <div className="border-b bg-card">
      <div className="flex flex-col gap-3 p-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-wrap items-center gap-2">
          <Tabs value={mode} onValueChange={(value) => onModeChange(value as MarkdownViewMode)}>
            <TabsList aria-label="Markdown view mode">
              {canEdit && <TabsTrigger value="edit"><FilePenLine className="mr-2 h-4 w-4" />Edit</TabsTrigger>}
              <TabsTrigger value="preview"><Eye className="mr-2 h-4 w-4" />Preview</TabsTrigger>
              {canEdit && <TabsTrigger value="split"><Columns2 className="mr-2 h-4 w-4" />Split</TabsTrigger>}
            </TabsList>
          </Tabs>
          <Badge variant={offline ? "destructive" : dirty ? "secondary" : "outline"}>
            {offline ? "Offline draft" : saving ? "Saving…" : dirty ? "Unsaved changes" : "All changes saved"}
          </Badge>
          {!canEdit && <Badge variant="secondary">Read-only access</Badge>}
          {autosave && <Badge variant="outline">Autosave</Badge>}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span className="mr-1 text-xs text-muted-foreground">
            {words.toLocaleString()} words · {characters.toLocaleString()} characters
          </span>
          {onDownload && <Button variant="outline" size="sm" onClick={onDownload}><FileDown className="mr-2 h-4 w-4" />Download</Button>}
          {onRegenerate && <Button variant="outline" size="sm" onClick={onRegenerate} disabled={dirty || saving}><RefreshCw className="mr-2 h-4 w-4" />Regenerate</Button>}
          {canEdit && <Button variant="outline" size="sm" onClick={onRevert} disabled={!dirty || saving}><RotateCcw className="mr-2 h-4 w-4" />Revert</Button>}
          {canEdit && <Button size="sm" onClick={onSave} disabled={!dirty || saving || offline}><Save className="mr-2 h-4 w-4" />{saving ? "Saving…" : "Save draft"}</Button>}
        </div>
      </div>

      {canEdit && (mode === "edit" || mode === "split") && (
        <div className="flex items-center gap-1 overflow-x-auto border-t px-3 py-2" role="toolbar" aria-label="Markdown formatting">
          <Button type="button" variant="ghost" size="icon" aria-label="Undo" title="Undo" onClick={onUndo}><Undo2 className="h-4 w-4" /></Button>
          <Button type="button" variant="ghost" size="icon" aria-label="Redo" title="Redo" onClick={onRedo}><Redo2 className="h-4 w-4" /></Button>
          <Button type="button" variant="ghost" size="icon" aria-label="Find and replace" title="Find and replace" onClick={onSearch}><Search className="h-4 w-4" /></Button>
          <span className="mx-1 h-5 w-px shrink-0 bg-border" />
          <label className="sr-only" htmlFor="markdown-heading-level">Heading level</label>
          <select
            id="markdown-heading-level"
            aria-label="Heading level"
            className="h-8 rounded-md border bg-background px-2 text-xs"
            defaultValue=""
            onChange={(event) => {
              if (event.target.value) onFormat(event.target.value as MarkdownFormatAction)
              event.target.value = ""
            }}
          >
            <option value="">Heading</option>
            {[1, 2, 3, 4, 5, 6].map((level) => <option key={level} value={`heading-${level}`}>H{level}</option>)}
          </select>
          {actionButtons.map(({ action, label, title, icon: Icon }) => (
            <Button key={action} type="button" variant="ghost" size="icon" aria-label={label} title={title} onClick={() => onFormat(action)}>
              <Icon className="h-4 w-4" />
            </Button>
          ))}
          <label className="sr-only" htmlFor="markdown-clinical-callout">Clinical callout</label>
          <select
            id="markdown-clinical-callout"
            aria-label="Clinical callout"
            className="h-8 rounded-md border bg-background px-2 text-xs"
            defaultValue=""
            onChange={(event) => {
              if (event.target.value) onFormat(`callout-${event.target.value}`)
              event.target.value = ""
            }}
          >
            <option value="">Clinical callout</option>
            {[
              "recommendation", "warning", "caution", "key-point", "contraindication",
              "dosage", "evidence", "definition", "procedure", "algorithm-reference",
              "clinical-note", "referral-criteria",
            ].map((value) => <option key={value} value={value}>{value.replaceAll("-", " ")}</option>)}
          </select>
          <Button type="button" variant="ghost" size="icon" aria-label="Format document" title="Format document" onClick={() => onFormat("format")}><Heading className="h-4 w-4" /></Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            aria-label={fullscreen ? "Exit fullscreen" : "Enter fullscreen"}
            title={fullscreen ? "Exit fullscreen" : "Fullscreen (F11)"}
            onClick={onFullscreen}
            className={cn(fullscreen && "bg-muted")}
          >
            {fullscreen ? <Fullscreen className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
          </Button>
        </div>
      )}
    </div>
  )
}
