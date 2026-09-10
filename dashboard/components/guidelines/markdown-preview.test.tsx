import { cleanup, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it } from "vitest"

import { MarkdownPreview } from "./markdown-preview"

describe("MarkdownPreview", () => {
  afterEach(cleanup)

  it("renders clinical Markdown and GFM tables", () => {
    render(
      <MarkdownPreview
        content={`# Malaria treatment

| Medicine | Dose |
| --- | --- |
| Artesunate | 2.4 mg/kg |

- [x] Confirm diagnosis`}
      />,
    )

    expect(screen.getByRole("heading", { name: "Malaria treatment" })).toBeInTheDocument()
    expect(screen.getByRole("table")).toBeInTheDocument()
    expect(screen.getByText("Artesunate")).toBeInTheDocument()
    expect(screen.getByRole("checkbox")).toBeChecked()
  })

  it("constrains wide tables to the preview width and wraps cell content", () => {
    render(
      <MarkdownPreview
        content={`| Test | Typical setting | Result | Recommendation |
| --- | --- | --- | --- |
| Microscopy | Laboratory | Parasite detection | Follow national algorithms |`}
      />,
    )

    const table = screen.getByRole("table")
    expect(table).toHaveClass("table-fixed")
    expect(table.parentElement).toHaveClass("max-w-full", "overflow-hidden")
    expect(screen.getByText("Follow national algorithms")).toHaveClass("break-words")
  })

  it("does not render raw HTML or executable elements", () => {
    const { container } = render(
      <MarkdownPreview content={'<script>alert("xss")</script><iframe src="bad"></iframe><b>unsafe</b>'} />,
    )

    expect(container.querySelector("script")).not.toBeInTheDocument()
    expect(container.querySelector("iframe")).not.toBeInTheDocument()
    expect(container.querySelector("b")).not.toBeInTheDocument()
  })

  it("secures external links", () => {
    render(<MarkdownPreview content="[Reference](https://example.org/guideline)" />)

    expect(screen.getByRole("link", { name: "Reference" })).toHaveAttribute(
      "rel",
      "noopener noreferrer",
    )
  })

  it("renders supported clinical callouts without enabling raw HTML", () => {
    render(
      <MarkdownPreview
        content={`:::warning
Confirm renal function before treatment.
:::`}
      />,
    )

    expect(screen.getByText("Warning")).toBeInTheDocument()
    expect(screen.getByText("Confirm renal function before treatment.")).toBeInTheDocument()
  })

  it("resolves governed image references and displays their caption", () => {
    render(
      <MarkdownPreview
        content={'![Treatment pathway](guideline-asset://3b9dfdf2-6ffc-42f4-bbd3-0bab9a6305fe "Treatment pathway caption")'}
        assets={[{
          id: "asset-id",
          version_id: "version-id",
          type: "figure",
          mime_type: "image/png",
          checksum: "checksum",
          size_bytes: 12,
          original_filename: "flow.png",
          alternative_text: "Treatment pathway",
          caption: "Treatment pathway caption",
          source: "UCG 2023",
          attribution: "Ministry of Health Uganda",
          license: "",
          clinically_sensitive: true,
          review_status: "draft",
          reference: "guideline-asset://3b9dfdf2-6ffc-42f4-bbd3-0bab9a6305fe",
          referenced: true,
          url: "https://example.test/flow.png",
          url_expires_at: "2026-09-10T12:00:00Z",
          created_at: "2026-09-10T10:00:00Z",
          updated_at: "2026-09-10T10:00:00Z",
        }]}
      />,
    )

    expect(screen.getByRole("img", { name: "Treatment pathway" })).toHaveAttribute(
      "src",
      "https://example.test/flow.png",
    )
    expect(screen.getByText("Treatment pathway caption")).toBeInTheDocument()
  })

  it("shows a clear empty Markdown state", () => {
    render(<MarkdownPreview content={`  
 `} />)

    expect(screen.getByText("Nothing to preview yet.")).toBeInTheDocument()
  })
})
