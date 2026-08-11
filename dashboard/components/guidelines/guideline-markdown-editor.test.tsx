import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { GuidelineMarkdownEditor } from "./guideline-markdown-editor"
import {
  GuidelineMarkdownError,
  GuidelineMarkdownService,
  MarkdownDraft,
} from "@/services/guideline-markdown.service"

const { routerPush } = vi.hoisted(() => ({ routerPush: vi.fn() }))

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: routerPush }),
}))

vi.mock("@uiw/react-codemirror", async () => {
  const React = await import("react")
  const MockCodeMirror = React.forwardRef<
    HTMLTextAreaElement,
    { value: string; onChange: (value: string) => void; "aria-label"?: string }
  >(({ value, onChange, "aria-label": ariaLabel }, ref) => (
    <textarea
      ref={ref}
      aria-label={ariaLabel}
      value={value}
      onChange={(event) => onChange(event.target.value)}
    />
  ))
  MockCodeMirror.displayName = "MockCodeMirror"
  return { default: MockCodeMirror }
})

vi.mock("@/lib/toast", () => ({
  showToast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

describe("GuidelineMarkdownEditor", () => {
  const savedDraft = (content: string): MarkdownDraft => ({
    content,
    etag: '"md-revision-checksum"',
    saved: true,
    revision: {
      id: "revision-1",
      document_id: "document-1",
      version_id: "version-1",
      revision_number: 1,
      checksum: "checksum",
      size_bytes: content.length,
      source_type: "manual_edit",
      checkpoint_name: "",
      change_summary: "",
      is_current: true,
      structured_content_status: "outdated",
      review_state: "draft",
      publication_state: "draft",
      created_at: "2026-08-11T08:00:00Z",
      updated_at: "2026-08-11T08:00:00Z",
    },
  })

  afterEach(cleanup)

  beforeEach(() => {
    vi.restoreAllMocks()
    routerPush.mockReset()
  })

  it("is preview-only without update permission", () => {
    render(
      <GuidelineMarkdownEditor
        versionId="version-1"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Read only"
        editable={false}
        published={false}
      />,
    )

    expect(screen.getByRole("heading", { name: "Read only" })).toBeInTheDocument()
    expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Save draft" })).not.toBeInTheDocument()
    expect(screen.getByText("Read-only access")).toBeInTheDocument()
  })

  it("tracks edits and saves the current Markdown", async () => {
    const user = userEvent.setup()
    const saveDraft = vi
      .spyOn(GuidelineMarkdownService, "saveDraft")
      .mockImplementation(async (_versionId, input) => savedDraft(input.content))

    render(
      <GuidelineMarkdownEditor
        versionId="version-1"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Original"
        editable
        published={false}
      />,
    )

    expect(screen.getByRole("button", { name: "Save draft" })).toBeDisabled()
    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    await user.clear(editor)
    await user.type(editor, "# Updated content")

    expect(screen.getByText("Unsaved changes")).toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Save draft" }))

    await waitFor(() => {
      expect(saveDraft).toHaveBeenCalledWith(
        "version-1",
        expect.objectContaining({ content: "# Updated content", source_type: "blank" }),
      )
    })
    expect(screen.getAllByText("All changes saved").length).toBeGreaterThan(0)
  })

  it("switches between edit, preview, and split modes", async () => {
    render(
      <GuidelineMarkdownEditor
        versionId="version-modes"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Mode preview"
        editable
        published={false}
      />,
    )

    expect(screen.getByRole("textbox", { name: "Markdown source" })).toBeInTheDocument()
    expect(screen.getByRole("article", { name: "Rendered Markdown preview" })).toBeInTheDocument()

    fireEvent.mouseDown(screen.getByRole("tab", { name: "Preview" }), { button: 0 })
    await waitFor(() => {
      expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    })
    expect(screen.getByRole("article", { name: "Rendered Markdown preview" })).toBeInTheDocument()

    fireEvent.mouseDown(screen.getByRole("tab", { name: "Edit" }), { button: 0 })
    expect(screen.getByRole("textbox", { name: "Markdown source" })).toBeInTheDocument()
    expect(
      screen.queryByRole("article", { name: "Rendered Markdown preview" }),
    ).not.toBeInTheDocument()
  })

  it("supports the keyboard save shortcut", async () => {
    const saveDraft = vi
      .spyOn(GuidelineMarkdownService, "saveDraft")
      .mockImplementation(async (_versionId, input) => savedDraft(input.content))

    render(
      <GuidelineMarkdownEditor
        versionId="version-2"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Initial"
        editable
        published={false}
      />,
    )

    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    fireEvent.change(editor, { target: { value: "# Initial changed" } })
    await screen.findByText("Unsaved changes")
    fireEvent.keyDown(window, { key: "s", ctrlKey: true })

    await waitFor(() => {
      expect(saveDraft).toHaveBeenCalledWith(
        "version-2",
        expect.objectContaining({ content: "# Initial changed" }),
      )
    })
  })

  it("preserves edits when saving fails", async () => {
    const user = userEvent.setup()
    vi.spyOn(GuidelineMarkdownService, "saveDraft").mockRejectedValue(new Error("Network unavailable"))

    render(
      <GuidelineMarkdownEditor
        versionId="version-3"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Initial"
        editable
        published={false}
      />,
    )

    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    await user.clear(editor)
    await user.type(editor, "# Unsaved work")
    await user.click(screen.getByRole("button", { name: "Save draft" }))

    await waitFor(() => {
      expect(screen.getByText(/Your edits remain available/)).toBeInTheDocument()
    })
    expect(editor).toHaveValue("# Unsaved work")
    expect(screen.getByText("Unsaved changes")).toBeInTheDocument()
  })

  it("preserves local text and offers explicit conflict choices", async () => {
    const user = userEvent.setup()
    const initialDraft = savedDraft("# Initial")
    const serverDraft = {
      ...savedDraft("# Server edit"),
      etag: '"md-server-checksum"',
      revision: { ...savedDraft("# Server edit").revision, id: "revision-server", revision_number: 2 },
    }
    vi.spyOn(GuidelineMarkdownService, "saveDraft").mockRejectedValue(
      new GuidelineMarkdownError("The Markdown draft changed", 409),
    )
    vi.spyOn(GuidelineMarkdownService, "loadDraft").mockResolvedValue(serverDraft)

    render(
      <GuidelineMarkdownEditor
        versionId="version-conflict"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent={initialDraft.content}
        initialDraft={initialDraft}
        editable
        published={false}
      />,
    )

    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    fireEvent.change(editor, { target: { value: "# Local unsaved edit" } })
    await user.click(screen.getByRole("button", { name: "Save draft" }))

    expect(await screen.findByText("Another editor saved this draft")).toBeInTheDocument()
    expect(editor).toHaveValue("# Local unsaved edit")
    expect(screen.getByRole("button", { name: "Keep local text" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Open diff" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Reload server draft" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Save local as checkpoint" })).toBeInTheDocument()
  })

  it("keeps published versions immutable", () => {
    render(
      <GuidelineMarkdownEditor
        versionId="version-4"
        documentTitle="Test guideline"
        versionLabel="1.0"
        initialContent="# Published"
        editable
        published
      />,
    )

    expect(screen.getByText("Published version")).toBeInTheDocument()
    expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Save draft" })).not.toBeInTheDocument()
  })

  it("provides rendered, public, structured, and print preview presentations", async () => {
    const user = userEvent.setup()
    const print = vi.spyOn(window, "print").mockImplementation(() => undefined)
    render(
      <GuidelineMarkdownEditor
        versionId="version-preview"
        documentTitle="Malaria management"
        versionLabel="3.0"
        initialContent="# Malaria management\n\n## Treatment"
        editable={false}
        published={false}
      />,
    )

    const presentation = screen.getByRole("combobox", { name: "Preview presentation" })
    await user.selectOptions(presentation, "public-reader")
    expect(screen.getByRole("region", { name: "Public reader preview" })).toBeInTheDocument()
    expect(screen.getByText("Draft preview")).toBeInTheDocument()

    await user.selectOptions(presentation, "structured-reader")
    expect(screen.getByRole("region", { name: "Structured reader preview" })).toBeInTheDocument()
    expect(screen.getByRole("navigation", { name: "Structured preview contents" })).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Print" }))
    await waitFor(() => expect(print).toHaveBeenCalled())
    expect(screen.getByRole("article", { name: "Print preview" })).toBeInTheDocument()
  })

  it("creates an independent draft version from a published version", async () => {
    const user = userEvent.setup()
    const source = savedDraft("# Published source")
    vi.spyOn(GuidelineMarkdownService, "duplicateVersion").mockResolvedValue({
      version: {
        id: "new-version",
        document_id: "document-1",
        version: "2.0",
        status: "draft",
        created_at: "2026-08-11T08:00:00Z",
        updated_at: "2026-08-11T08:00:00Z",
      },
      draft: {
        ...source,
        revision: { ...source.revision, id: "new-revision", version_id: "new-version", source_type: "duplicated" },
      },
    })

    render(
      <GuidelineMarkdownEditor
        versionId="published-version"
        documentTitle="Published guideline"
        versionLabel="1.0"
        initialContent="# Published source"
        initialDraft={source}
        editable
        published
      />,
    )

    await user.click(screen.getByRole("button", { name: "Create draft version" }))
    const dialog = screen.getByRole("dialog", { name: "Create a draft from this published version" })
    await user.type(within(dialog).getByLabelText("New version"), "2.0")
    await user.click(within(dialog).getByRole("button", { name: "Create draft version" }))

    await waitFor(() => {
      expect(GuidelineMarkdownService.duplicateVersion).toHaveBeenCalledWith(
        "published-version",
        expect.objectContaining({ version: "2.0" }),
      )
      expect(routerPush).toHaveBeenCalledWith("/guidelines/document-1/versions/new-version/markdown")
    })
  })
})
