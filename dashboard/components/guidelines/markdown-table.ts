export type TableAlignment = "none" | "left" | "center" | "right"

export interface MarkdownTableModel {
  title: string
  caption: string
  source: string
  footnotes: string[]
  clinicallySensitive: boolean
  headers: string[]
  alignments: TableAlignment[]
  rows: string[][]
  structuralWarnings: string[]
}

export interface MarkdownTableSelection {
  from: number
  to: number
  table: MarkdownTableModel
}

export function emptyMarkdownTable(columns = 2): MarkdownTableModel {
  return { title: "", caption: "", source: "", footnotes: [], clinicallySensitive: false, headers: Array.from({ length: columns }, (_, i) => `Column ${i + 1}`), alignments: Array(columns).fill("none"), rows: [Array(columns).fill("")], structuralWarnings: [] }
}

export function markdownTableAt(source: string, position: number): MarkdownTableSelection | null {
  const lines = source.split("\n")
  const offsets: number[] = []
  let offset = 0
  for (const line of lines) { offsets.push(offset); offset += line.length + 1 }
  const cursorLine = Math.max(0, offsets.findLastIndex((value) => value <= position))
  let tableStart = cursorLine
  while (tableStart > 0 && isTableRow(lines[tableStart - 1])) tableStart -= 1
  if (!isTableRow(lines[tableStart]) && tableStart + 1 < lines.length && isTableRow(lines[tableStart + 1])) tableStart += 1
  let tableEnd = tableStart
  while (tableEnd + 1 < lines.length && isTableRow(lines[tableEnd + 1])) tableEnd += 1
  let delimiter = -1
  for (let index = Math.max(1, tableStart); index <= tableEnd; index += 1) {
    if (isDelimiterRow(lines[index]) && isTableRow(lines[index - 1])) { delimiter = index; break }
  }
  if (delimiter < 0) return null
  const headerLine = delimiter - 1
  let endLine = delimiter + 1
  while (endLine < lines.length && isTableRow(lines[endLine])) endLine += 1
  let startLine = headerLine
  let title = ""
  if (startLine > 0) {
    const match = /^\*\*Table:\s*(.*?)\*\*\s*$/u.exec(lines[startLine - 1])
    if (match) { title = match[1]; startLine -= 1 }
  }
  let caption = "", sourceValue = "", clinicallySensitive = false
  const footnotes: string[] = []
  while (endLine < lines.length) {
    const line = lines[endLine]
    const captionMatch = /^\*Caption:\s*(.*?)\*\s*$/u.exec(line)
    const sourceMatch = /^\*Source:\s*(.*?)\*\s*$/u.exec(line)
    const footnoteMatch = /^\[\^table-\d+\]:\s*(.*)$/u.exec(line)
    if (captionMatch) caption = captionMatch[1]
    else if (sourceMatch) sourceValue = sourceMatch[1]
    else if (footnoteMatch) footnotes.push(footnoteMatch[1])
    else if (line === "**Review status:** Clinical review required.") clinicallySensitive = true
    else break
    endLine += 1
  }
  const headers = parseGfmRow(lines[headerLine])
  const alignments = parseGfmRow(lines[delimiter]).map(parseAlignment)
  const rows = lines.slice(delimiter + 1, endLine).filter(isTableRow).map(parseGfmRow)
  const width = headers.length
  const structuralWarnings = rows.flatMap((row, index) => row.length === width ? [] : [`Row ${index + 1} has ${row.length} cells; expected ${width}.`])
  return {
    from: offsets[startLine], to: endLine < lines.length ? offsets[endLine] : source.length,
    table: { title, caption, source: sourceValue, footnotes, clinicallySensitive, headers, alignments: normalizeWidth(alignments, width, "none"), rows: rows.map((row) => normalizeWidth(row, width, "")), structuralWarnings },
  }
}

export function serializeMarkdownTable(table: MarkdownTableModel): string {
  const width = Math.max(1, table.headers.length)
  const headers = normalizeWidth(table.headers, width, "")
  const alignments = normalizeWidth(table.alignments, width, "none")
  const rows = table.rows.length ? table.rows : [Array(width).fill("")]
  const lines = [
    ...(table.title.trim() ? [`**Table: ${table.title.trim()}**`] : []),
    gfmRow(headers),
    gfmRow(alignments.map(alignmentMarker)),
    ...rows.map((row) => gfmRow(normalizeWidth(row, width, ""))),
    ...(table.caption.trim() ? [`*Caption: ${table.caption.trim()}*`] : []),
    ...(table.source.trim() ? [`*Source: ${table.source.trim()}*`] : []),
    ...table.footnotes.filter((value) => value.trim()).map((value, index) => `[^table-${index + 1}]: ${value.trim()}`),
    ...(table.clinicallySensitive ? ["**Review status:** Clinical review required."] : []),
  ]
  return `${lines.join("\n")}\n`
}

export function tableWarnings(table: MarkdownTableModel): string[] {
  const warnings: string[] = [...table.structuralWarnings]
  const width = table.headers.length
  if (!width) warnings.push("The table needs at least one column.")
  table.rows.forEach((row, index) => { if (row.length !== width) warnings.push(`Row ${index + 1} has ${row.length} cells; expected ${width}.`) })
  table.headers.forEach((header, column) => {
    if (!/(dose|dosage|unit|amount|strength|concentration|weight|volume)/iu.test(header)) return
    table.rows.forEach((row, index) => {
      const value = row[column]?.trim() || ""
      if (value && /\d/u.test(value) && !/^[-+]?\d+(?:[.,]\d+)?(?:\s*(?:mg|g|kg|mcg|µg|ml|mL|L|mmol|IU|units?|%)(?:\/[a-zA-Z]+)?)?$/u.test(value)) {
        warnings.push(`Review ${header || `column ${column + 1}`}, row ${index + 1}: “${value}”. It may contain a malformed number or unit.`)
      }
    })
  })
  return warnings
}

export function parseDelimitedTable(source: string, delimiter?: string): string[][] {
  const separator = delimiter || (source.includes("\t") ? "\t" : ",")
  const rows: string[][] = []
  let row: string[] = [], cell = "", quoted = false
  for (let index = 0; index < source.length; index += 1) {
    const char = source[index]
    if (char === '"') {
      if (quoted && source[index + 1] === '"') { cell += '"'; index += 1 } else quoted = !quoted
    } else if (char === separator && !quoted) { row.push(cell); cell = "" }
    else if ((char === "\n" || char === "\r") && !quoted) {
      if (char === "\r" && source[index + 1] === "\n") index += 1
      row.push(cell); if (row.some((value) => value.length)) rows.push(row); row = []; cell = ""
    } else cell += char
  }
  row.push(cell); if (row.some((value) => value.length)) rows.push(row)
  return rows
}

export function tableToCsv(table: MarkdownTableModel): string {
  return [table.headers, ...table.rows].map((row) => row.map(csvCell).join(",")).join("\r\n")
}

function isTableRow(line: string) { return /^\s*\|.*\|\s*$/u.test(line) }
function isDelimiterRow(line: string) { const cells = parseGfmRow(line); return cells.length > 0 && cells.every((cell) => /^:?-{3,}:?$/u.test(cell.trim())) }
function parseGfmRow(line: string) { return line.trim().replace(/^\||\|$/gu, "").split(/(?<!\\)\|/u).map((cell) => cell.trim().replaceAll("\\|", "|")) }
function parseAlignment(value: string): TableAlignment { const cell = value.trim(); return cell.startsWith(":") && cell.endsWith(":") ? "center" : cell.endsWith(":") ? "right" : cell.startsWith(":") ? "left" : "none" }
function alignmentMarker(value: TableAlignment) { return value === "center" ? ":---:" : value === "right" ? "---:" : value === "left" ? ":---" : "---" }
function gfmRow(cells: string[]) { return `| ${cells.map((cell) => cell.replaceAll("|", "\\|").replaceAll("\n", "<br>")).join(" | ")} |` }
function normalizeWidth<T>(values: T[], width: number, fill: T) { return Array.from({ length: width }, (_, index) => values[index] ?? fill) }
function csvCell(value: string) { return /[",\r\n]/u.test(value) ? `"${value.replaceAll('"', '""')}"` : value }
