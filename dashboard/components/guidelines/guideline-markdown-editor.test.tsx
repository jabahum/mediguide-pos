import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { GuidelineMarkdownEditor } from "./guideline-markdown-editor"
import { GuidelineMarkdownService } from "@/services/guideline-markdown.service"

vi.mock("@/lib/toast", () => ({
  showToast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

describe("GuidelineMarkdownEditor", () => {
  afterEach(cleanup)

  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it("is preview-only without update permission", () => {
    render(
      <GuidelineMarkdownEditor
        versionId="version-1"
        initialContent="# Read only"
        editable={false}
        published={false}
      />,
    )

    expect(screen.getByRole("heading", { name: "Read only" })).toBeInTheDocument()
    expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Save" })).not.toBeInTheDocument()
    expect(screen.getByText("Read-only access")).toBeInTheDocument()
  })

  it("tracks edits and saves the current Markdown", async () => {
    const user = userEvent.setup()
    const update = vi
      .spyOn(GuidelineMarkdownService, "update")
      .mockResolvedValue({ updated: true, queued: true, size: 17, job_id: "job-1" })

    render(
      <GuidelineMarkdownEditor
        versionId="version-1"
        initialContent="# Original"
        editable
        published={false}
      />,
    )

    expect(screen.getByRole("button", { name: "Save" })).toBeDisabled()
    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    await user.clear(editor)
    await user.type(editor, "# Updated content")

    expect(screen.getByText("Unsaved changes")).toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Save" }))

    await waitFor(() => {
      expect(update).toHaveBeenCalledWith("version-1", "# Updated content")
    })
    expect(screen.getAllByText("All changes saved").length).toBeGreaterThan(0)
  })

  it("switches between edit, preview, and split modes", async () => {
    const user = userEvent.setup()
    render(
      <GuidelineMarkdownEditor
        versionId="version-modes"
        initialContent="# Mode preview"
        editable
        published={false}
      />,
    )

    expect(screen.getByRole("textbox", { name: "Markdown source" })).toBeInTheDocument()
    expect(screen.getByRole("article", { name: "Rendered Markdown preview" })).toBeInTheDocument()

    await user.click(screen.getByRole("tab", { name: "Preview" }))
    expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    expect(screen.getByRole("article", { name: "Rendered Markdown preview" })).toBeInTheDocument()

    await user.click(screen.getByRole("tab", { name: "Edit" }))
    expect(screen.getByRole("textbox", { name: "Markdown source" })).toBeInTheDocument()
    expect(
      screen.queryByRole("article", { name: "Rendered Markdown preview" }),
    ).not.toBeInTheDocument()
  })

  it("supports the keyboard save shortcut", async () => {
    const user = userEvent.setup()
    const update = vi
      .spyOn(GuidelineMarkdownService, "update")
      .mockResolvedValue({ updated: true, queued: true, size: 9, job_id: "job-2" })

    render(
      <GuidelineMarkdownEditor
        versionId="version-2"
        initialContent="# Initial"
        editable
        published={false}
      />,
    )

    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    await user.type(editor, " changed")
    fireEvent.keyDown(window, { key: "s", ctrlKey: true })

    await waitFor(() => {
      expect(update).toHaveBeenCalledWith("version-2", "# Initial changed")
    })
  })

  it("preserves edits when saving fails", async () => {
    const user = userEvent.setup()
    vi.spyOn(GuidelineMarkdownService, "update").mockRejectedValue(new Error("Network unavailable"))

    render(
      <GuidelineMarkdownEditor
        versionId="version-3"
        initialContent="# Initial"
        editable
        published={false}
      />,
    )

    const editor = screen.getByRole("textbox", { name: "Markdown source" })
    await user.clear(editor)
    await user.type(editor, "# Unsaved work")
    await user.click(screen.getByRole("button", { name: "Save" }))

    await waitFor(() => {
      expect(screen.getByText(/Your current edits have been preserved/)).toBeInTheDocument()
    })
    expect(editor).toHaveValue("# Unsaved work")
    expect(screen.getByText("Unsaved changes")).toBeInTheDocument()
  })

  it("keeps published versions immutable", () => {
    render(
      <GuidelineMarkdownEditor
        versionId="version-4"
        initialContent="# Published"
        editable
        published
      />,
    )

    expect(screen.getByText("Published version")).toBeInTheDocument()
    expect(screen.queryByRole("textbox", { name: "Markdown source" })).not.toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Save" })).not.toBeInTheDocument()
  })
})
