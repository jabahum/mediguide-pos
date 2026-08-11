import { describe, expect, it } from "vitest"
import { emptyMarkdownTable, markdownTableAt, parseDelimitedTable, serializeMarkdownTable, tableToCsv, tableWarnings, type TableAlignment } from "./markdown-table"

describe("visual Markdown tables", () => {
  it("round-trips GFM tables with empty cells, alignment and metadata", () => {
    const table = { ...emptyMarkdownTable(), title: "Dose", caption: "Reviewed values", source: "National guideline", footnotes: ["Adult dose"], clinicallySensitive: true, headers: ["Medicine", "Dose"], alignments: ["left", "right"] as TableAlignment[], rows: [["A", "5 mg"], ["B", ""]] }
    const markdown = serializeMarkdownTable(table)
    const parsed = markdownTableAt(markdown, markdown.indexOf("5 mg"))
    expect(parsed?.table).toMatchObject(table)
  })

  it("imports quoted CSV and exports it without losing commas", () => {
    const rows = parseDelimitedTable('Name,Notes\r\nA,"one, two"')
    expect(rows).toEqual([["Name", "Notes"], ["A", "one, two"]])
    expect(tableToCsv({ ...emptyMarkdownTable(), headers: rows[0], rows: rows.slice(1) })).toContain('"one, two"')
  })

  it("warns but does not rewrite questionable clinical values", () => {
    const table = { ...emptyMarkdownTable(), headers: ["Drug", "Dose"], rows: [["A", "five-ish mg"]] }
    expect(tableWarnings(table)).toHaveLength(0)
    table.rows[0][1] = "5mgg?"
    expect(tableWarnings(table)[0]).toContain("5mgg?")
    expect(table.rows[0][1]).toBe("5mgg?")
  })
})
