import { describe, expect, it } from "vitest"

import {
  formatMarkdown,
  lineDiff,
  markdownHeadings,
  markdownTemplates,
  validateMarkdown,
} from "./markdown-authoring"

describe("Markdown authoring utilities", () => {
  it("provides structure-only templates for each required clinical document type", () => {
    expect(markdownTemplates.map((template) => template.key)).toEqual([
      "general",
      "emergency",
      "medication",
      "diagnostic",
      "procedure",
      "outbreak",
    ])
    for (const template of markdownTemplates) {
      expect(template.content).toMatch(/^# /u)
      expect(template.content).toContain("_Add reviewed clinical content._")
    }
  })

  it("builds stable heading navigation with section word counts", () => {
    const headings = markdownHeadings("# Care\n\nIntro words.\n\n## Assessment\n\nCheck danger signs.")

    expect(headings).toEqual([
      expect.objectContaining({ id: "care", level: 1, line: 1, words: 2 }),
      expect.objectContaining({ id: "assessment", level: 2, line: 5, words: 3 }),
    ])
  })

  it("blocks executable Markdown and detects structural/callout errors", () => {
    const issues = validateMarkdown(
      "## Assessment\n\n#### Details\n\n<script>alert(1)</script>\n\n:::warning\nReview.",
    )

    expect(issues.map((issue) => issue.code)).toEqual(
      expect.arrayContaining([
        "missing_h1",
        "skipped_heading_level",
        "unsafe_html",
        "unclosed_callout",
      ]),
    )
    expect(issues.find((issue) => issue.code === "unsafe_html")?.severity).toBe("error")
  })

  it("formats line endings and creates a deterministic safe line diff", () => {
    expect(formatMarkdown("# Care\r\n\r\nOld.  \r\n")).toBe("# Care\n\nOld.\n")
    expect(lineDiff("# Care\nOld", "# Care\nNew")).toEqual([
      { type: "same", text: "# Care" },
      { type: "removed", text: "Old" },
      { type: "added", text: "New" },
    ])
  })
})
