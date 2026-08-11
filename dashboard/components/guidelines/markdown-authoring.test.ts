import { describe, expect, it } from "vitest"

import {
  formatMarkdown,
  clinicalCalloutMarkdown,
  lineDiff,
  markdownHeadings,
  markdownTemplates,
  moveMarkdownSection,
  parseClinicalCallouts,
  stableHeadingAnchors,
  validateMarkdown,
  wordDiff,
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
    expect(wordDiff("Give 5 mg", "Give 10 mg").filter((part) => part.type !== "same")).toEqual([
      { type: "removed", text: "5" },
      { type: "added", text: "10" },
    ])
  })

  it("parses safe typed callouts without rewriting clinical values", () => {
    const source = clinicalCalloutMarkdown({ type: "dosage", title: "Reviewed dose", severity: "high", evidenceGrade: "A", content: "Give 5 mg/kg." })
    expect(source).toContain("Give 5 mg/kg.")
    expect(parseClinicalCallouts(source)).toEqual([
      expect.objectContaining({ type: "dosage", title: "Reviewed dose", severity: "high", evidenceGrade: "A", content: "Give 5 mg/kg." }),
    ])
  })

  it("moves a heading with its complete section content", () => {
    expect(moveMarkdownSection("# One\nBody one.\n\n# Two\nBody two.\n", 1, 0)).toBe("# Two\nBody two.\n# One\nBody one.\n\n")
    expect(moveMarkdownSection("# One\nIntro.\n## Child\nChild body.\n# Two\nOther.\n", 0, 2)).toBe("# One\nIntro.\n## Child\nChild body.\n# Two\nOther.\n")
    expect(moveMarkdownSection("# One\nIntro.\n## Child\nChild body.\n# Two\nOther.\n", 2, 0)).toBe("# Two\nOther.\n# One\nIntro.\n## Child\nChild body.\n")
  })

  it("retains stable anchors for renames and matches titles after insertion", () => {
    const original = stableHeadingAnchors("# Care\n## Assessment")
    expect(stableHeadingAnchors("# Clinical care\n## Assessment", original)["0"].id).toBe("care")
    const inserted = stableHeadingAnchors("# Preface\n# Care\n## Assessment", original)
    expect(inserted["1"].id).toBe("care")
    expect(inserted["2"].id).toBe("assessment")
  })
})
