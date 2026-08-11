"use client"

import * as React from "react"
import { AlertCircle, Clock3, Info } from "lucide-react"

import { MarkdownEditorToolbar, MarkdownViewMode } from "./markdown-editor-toolbar"
import { MarkdownPreview } from "./markdown-preview"
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
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Textarea } from "@/components/ui/textarea"
import { useUnsavedChanges } from "@/hooks/use-unsaved-changes"
import { showToast } from "@/lib/toast"
import { cn } from "@/lib/utils"
import {
  GuidelineMarkdownError,
  GuidelineMarkdownService,
} from "@/services/guideline-markdown.service"

interface GuidelineMarkdownEditorProps {
  versionId: string
  initialContent: string
  editable: boolean
  published: boolean
}

function countWords(value: string) {
  const trimmed = value.trim()
  return trimmed ? trimmed.split(/\s+/u).length : 0
}

export function GuidelineMarkdownEditor({
  versionId,
  initialContent,
  editable,
  published,
}: GuidelineMarkdownEditorProps) {
  const [content, setContent] = React.useState(initialContent)
  const [savedContent, setSavedContent] = React.useState(initialContent)
  const [mode, setMode] = React.useState<MarkdownViewMode>(editable ? "split" : "preview")
  const [saving, setSaving] = React.useState(false)
  const [saveError, setSaveError] = React.useState<string | null>(null)
  const [lastSavedAt, setLastSavedAt] = React.useState<Date | null>(null)
  const [revertOpen, setRevertOpen] = React.useState(false)

  const canEdit = editable && !published
  const dirty = canEdit && content !== savedContent
  useUnsavedChanges(dirty)

  const save = React.useCallback(async () => {
    if (!canEdit || !dirty || saving) return
    if (!content.trim()) {
      setSaveError("Markdown content cannot be empty.")
      return
    }

    setSaving(true)
    setSaveError(null)
    try {
      await GuidelineMarkdownService.update(versionId, content)
      setSavedContent(content)
      setLastSavedAt(new Date())
      showToast.success(
        "Markdown saved",
        "Structured content and the AI index are being regenerated.",
      )
    } catch (error) {
      const message =
        error instanceof GuidelineMarkdownError
          ? error.message
          : "The Markdown could not be saved. Your edits are still available."
      setSaveError(message)
      showToast.error("Save failed", message)
    } finally {
      setSaving(false)
    }
  }, [canEdit, content, dirty, saving, versionId])

  React.useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
        event.preventDefault()
        void save()
      }
    }
    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [save])

  const words = React.useMemo(() => countWords(content), [content])

  return (
    <>
      <section className="overflow-hidden rounded-lg border bg-card shadow-sm">
        <MarkdownEditorToolbar
          mode={mode}
          canEdit={canEdit}
          dirty={dirty}
          saving={saving}
          words={words}
          characters={content.length}
          onModeChange={setMode}
          onSave={() => void save()}
          onRevert={() => setRevertOpen(true)}
        />

        <div className="sr-only" role="status" aria-live="polite">
          {saving
            ? "Saving Markdown"
            : saveError
              ? `Save failed: ${saveError}`
              : dirty
                ? "Markdown has unsaved changes"
                : "All Markdown changes are saved"}
        </div>

        {published && (
          <Alert className="m-4 mb-0">
            <Info className="h-4 w-4" />
            <AlertTitle>Published version</AlertTitle>
            <AlertDescription>
              Published Markdown is immutable. Create a new guideline version to make revisions.
            </AlertDescription>
          </Alert>
        )}

        {!published && !editable && (
          <Alert className="m-4 mb-0">
            <Info className="h-4 w-4" />
            <AlertTitle>Read-only access</AlertTitle>
            <AlertDescription>
              You can preview this Markdown, but your dashboard role cannot update it.
            </AlertDescription>
          </Alert>
        )}

        {saveError && (
          <Alert variant="destructive" className="m-4 mb-0">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>Markdown was not saved</AlertTitle>
            <AlertDescription>{saveError} Your current edits have been preserved.</AlertDescription>
          </Alert>
        )}

        <div
          className={cn(
            "grid min-h-[65vh]",
            mode === "split" && "lg:grid-cols-2",
          )}
        >
          {canEdit && (mode === "edit" || mode === "split") && (
            <div
              className={cn(
                "flex min-h-[65vh] flex-col p-4",
                mode === "split" && "border-b lg:border-r lg:border-b-0",
              )}
            >
              <label htmlFor="guideline-markdown-editor" className="mb-2 text-sm font-medium">
                Markdown source
              </label>
              <Textarea
                id="guideline-markdown-editor"
                value={content}
                onChange={(event) => {
                  setContent(event.target.value)
                  setSaveError(null)
                }}
                spellCheck
                aria-describedby="markdown-editor-help"
                className="min-h-0 flex-1 resize-none whitespace-pre font-mono text-sm leading-6"
              />
              <p id="markdown-editor-help" className="mt-2 text-xs text-muted-foreground">
                Save with Command+S on macOS or Ctrl+S on Windows and Linux.
              </p>
            </div>
          )}

          {(mode === "preview" || mode === "split" || !canEdit) && (
            <div className="min-w-0 overflow-auto p-5 lg:p-8">
              <h2 className="sr-only">Markdown preview</h2>
              <MarkdownPreview content={content} />
            </div>
          )}
        </div>

        <footer className="flex min-h-11 items-center border-t px-4 text-xs text-muted-foreground">
          <Clock3 className="mr-2 h-3.5 w-3.5" />
          {lastSavedAt
            ? `Last saved at ${lastSavedAt.toLocaleTimeString()}`
            : "No changes saved during this session"}
          <span className="ml-auto hidden sm:inline">
            Concurrent editing detection is not currently available.
          </span>
        </footer>
      </section>

      <AlertDialog open={revertOpen} onOpenChange={setRevertOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Discard unsaved changes?</AlertDialogTitle>
            <AlertDialogDescription>
              The editor will return to the last successfully loaded or saved Markdown. This cannot
              be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Keep editing</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                setContent(savedContent)
                setSaveError(null)
                setRevertOpen(false)
              }}
            >
              Discard changes
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
