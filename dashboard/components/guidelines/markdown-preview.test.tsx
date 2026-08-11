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

  it("shows a clear empty Markdown state", () => {
    render(<MarkdownPreview content={`  
 `} />)

    expect(screen.getByText("Nothing to preview yet.")).toBeInTheDocument()
  })
})
