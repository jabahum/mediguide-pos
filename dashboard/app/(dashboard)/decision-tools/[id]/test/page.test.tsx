import { render } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { renderPreview } from "./page"

describe("contained legacy clinical-tool preview", () => {
  it("uses an opaque sandbox without forms, popups, or same-origin privileges", () => {
    const { container } = render(renderPreview({
      html: "<!doctype html><html><head></head><body>Tool</body></html>",
      previewError: null,
      title: "Reviewed tool",
    }))

    const frame = container.querySelector("iframe")
    expect(frame).not.toBeNull()
    expect(frame).toHaveAttribute("sandbox", "allow-scripts")
    expect(frame).toHaveAttribute("referrerpolicy", "no-referrer")
    expect(frame?.getAttribute("sandbox")).not.toContain("allow-same-origin")
    expect(frame?.getAttribute("sandbox")).not.toContain("allow-popups")
    expect(frame?.getAttribute("sandbox")).not.toContain("allow-forms")
  })
})
