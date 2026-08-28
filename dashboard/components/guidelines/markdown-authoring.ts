export type MarkdownTemplateKey =
  | "general"
  | "emergency"
  | "medication"
  | "diagnostic"
  | "procedure"
  | "outbreak"

export interface MarkdownTemplate {
  key: MarkdownTemplateKey
  name: string
  description: string
  content: string
}

export interface MarkdownHeading {
  id: string
  text: string
  level: number
  line: number
  from: number
  to: number
  words: number
  end: number
  breadcrumb: string[]
}

export const clinicalCalloutTypes = [
  "recommendation", "warning", "caution", "key-point", "contraindication", "dosage",
  "evidence", "definition", "procedure", "algorithm-reference", "clinical-note", "referral-criteria",
] as const
export type ClinicalCalloutType = typeof clinicalCalloutTypes[number]

export interface ClinicalCallout {
  type: ClinicalCalloutType
  title?: string
  severity?: "standard" | "important" | "high" | "critical"
  evidenceGrade?: string
  source?: string
  content: string
  line: number
}

export interface MarkdownValidationIssue {
  code: string
  severity: "error" | "warning" | "info"
  message: string
  line: number
}

export interface MarkdownStats {
  words: number
  characters: number
  lines: number
  headings: number
  tables: number
  images: number
  callouts: number
  readingMinutes: number
}

export type MarkdownAnchorMetadata = Record<string, { id: string; title: string }>

const section = (title: string, body = "_Add reviewed clinical content._") =>
  `## ${title}\n\n${body}\n`

export const markdownTemplates: MarkdownTemplate[] = [
  {
    key: "general",
    name: "General clinical guideline",
    description: "Purpose, scope, assessment, management, referral, and references.",
    content: `# Guideline title\n\n${section("Purpose")}${section("Scope and intended audience")}${section("Clinical assessment")}${section("Management")}${section("Referral criteria")}${section("References")}`,
  },
  {
    key: "emergency",
    name: "Emergency protocol",
    description: "Immediate assessment, stabilization, escalation, and transfer.",
    content: `# Emergency protocol title\n\n${section("Recognition criteria")}${section("Immediate assessment")}${section("Stabilization")}${section("Escalation and referral")}${section("Monitoring")}${section("References")}`,
  },
  {
    key: "medication",
    name: "Medication guideline",
    description: "Indications, contraindications, administration, safety, and monitoring.",
    content: `# Medication guideline title\n\n${section("Indications")}${section("Contraindications and precautions")}${section("Administration")}${section("Monitoring")}${section("Adverse effects")}${section("References")}`,
  },
  {
    key: "diagnostic",
    name: "Diagnostic guideline",
    description: "Presentation, assessment, investigations, interpretation, and differentials.",
    content: `# Diagnostic guideline title\n\n${section("Clinical presentation")}${section("Assessment")}${section("Investigations")}${section("Interpretation")}${section("Differential diagnosis")}${section("References")}`,
  },
  {
    key: "procedure",
    name: "Procedure guideline",
    description: "Preparation, equipment, steps, aftercare, and complications.",
    content: `# Procedure title\n\n${section("Indications")}${section("Contraindications")}${section("Preparation and equipment")}${section("Procedure")}${section("Aftercare")}${section("Complications")}${section("References")}`,
  },
  {
    key: "outbreak",
    name: "Public health or outbreak guideline",
    description: "Case definition, surveillance, response, prevention, and reporting.",
    content: `# Public health guideline title\n\n${section("Situation and scope")}${section("Case definition")}${section("Surveillance and reporting")}${section("Clinical and public health response")}${section("Prevention and control")}${section("References")}`,
  },
]

export function markdownHeadings(markdown: string): MarkdownHeading[] {
  const lines = markdown.split("\n")
  const headings: MarkdownHeading[] = []
  let offset = 0
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index]
    const match = /^(#{1,6})\s+(.+?)\s*#*\s*$/u.exec(line)
    if (match) {
      const nextHeading = lines.slice(index + 1).findIndex((candidate) => /^#{1,6}\s+/u.test(candidate))
      const end = nextHeading < 0 ? lines.length : index + 1 + nextHeading
      const words = lines.slice(index + 1, end).join(" ").trim().split(/\s+/u).filter(Boolean).length
      const parents = headings.filter((heading) => heading.level < match[1].length)
      const breadcrumb: string[] = []
      let parentLevel = match[1].length
      for (let parentIndex = parents.length - 1; parentIndex >= 0; parentIndex -= 1) {
        const parent = parents[parentIndex]
        if (parent.level < parentLevel) {
          breadcrumb.unshift(parent.text)
          parentLevel = parent.level
        }
      }
      headings.push({
        id: headingSlug(match[2]),
        text: match[2],
        level: match[1].length,
        line: index + 1,
        from: offset,
        to: offset + line.length,
        words,
        end: lines.slice(0, end).reduce((total, value) => total + value.length + 1, 0),
        breadcrumb: [...breadcrumb, match[2]],
      })
    }
    offset += line.length + 1
  }
  return headings
}

export function validateMarkdown(markdown: string): MarkdownValidationIssue[] {
  const issues: MarkdownValidationIssue[] = []
  const lines = markdown.split("\n")
  const headings = markdownHeadings(markdown)
  if (!markdown.trim()) {
    return [{ code: "empty_document", severity: "error", message: "The document is empty.", line: 1 }]
  }
  if (!headings.some((heading) => heading.level === 1)) {
    issues.push({ code: "missing_h1", severity: "warning", message: "Add a level-one document title.", line: 1 })
  }
  const seen = new Map<string, number>()
  let previousLevel = 0
  for (const heading of headings) {
    if (seen.has(heading.id)) {
      issues.push({
        code: "duplicate_heading_anchor",
        severity: "error",
        message: `Heading anchor “${heading.id}” duplicates line ${seen.get(heading.id)}.`,
        line: heading.line,
      })
    }
    seen.set(heading.id, heading.line)
    if (previousLevel && heading.level > previousLevel + 1) {
      issues.push({
        code: "skipped_heading_level",
        severity: "warning",
        message: `Heading level jumps from H${previousLevel} to H${heading.level}.`,
        line: heading.line,
      })
    }
    previousLevel = heading.level
  }
  lines.forEach((line, index) => {
    if (/<\s*script\b|\bon\w+\s*=|javascript\s*:/iu.test(line)) {
      issues.push({ code: "unsafe_html", severity: "error", message: "Executable HTML or JavaScript is not allowed.", line: index + 1 })
    }
    if (/!\[\s*\]\(/u.test(line)) {
      issues.push({ code: "missing_image_alt", severity: "error", message: "Images require meaningful alternative text.", line: index + 1 })
    }
    if (line.includes("|") && index + 1 < lines.length && /^\s*\|?\s*:?-+/u.test(lines[index + 1])) {
      const expected = markdownTableCells(line).length
      const separator = markdownTableCells(lines[index + 1]).length
      if (expected !== separator) {
        issues.push({ code: "malformed_table", severity: "error", message: "Table header and separator have different column counts.", line: index + 1 })
      }
      for (let rowIndex = index + 2; rowIndex < lines.length && lines[rowIndex].includes("|"); rowIndex += 1) {
        const columns = markdownTableCells(lines[rowIndex]).length
        if (columns !== expected) {
          issues.push({ code: "malformed_table", severity: "error", message: `Table row has ${columns} columns; expected ${expected}.`, line: rowIndex + 1 })
        }
      }
      issues.push({ code: "high_risk_table_review_required", severity: "warning", message: "Clinical tables require explicit publisher review after regeneration.", line: index + 1 })
    }
  })
  const calloutStarts = lines.filter((line) => /^:::[a-z_-]+(?:\s+.*)?$/iu.test(line) && !/^:::\s*$/u.test(line)).length
  const calloutEnds = lines.filter((line) => /^:::\s*$/u.test(line)).length
  if (calloutStarts !== calloutEnds) {
    issues.push({ code: "unclosed_callout", severity: "error", message: "A clinical callout is not closed.", line: 1 })
  }
  try {
    parseClinicalCallouts(markdown)
  } catch (error) {
    issues.push({ code: "invalid_callout", severity: "error", message: error instanceof Error ? error.message : "Invalid clinical callout.", line: 1 })
  }
  return issues
}

function markdownTableCells(line: string) {
  let value = line.trim()
  if (value.startsWith("|")) value = value.slice(1)
  if (value.endsWith("|") && !isEscapedMarkdownCharacter(value, value.length - 1)) value = value.slice(0, -1)

  const cells: string[] = []
  let start = 0
  let inCode = false
  for (let index = 0; index < value.length; index += 1) {
    if (value[index] === "`" && !isEscapedMarkdownCharacter(value, index)) {
      inCode = !inCode
    } else if (value[index] === "|" && !inCode && !isEscapedMarkdownCharacter(value, index)) {
      cells.push(value.slice(start, index))
      start = index + 1
    }
  }
  cells.push(value.slice(start))
  return cells
}

function isEscapedMarkdownCharacter(value: string, index: number) {
  let backslashes = 0
  for (let cursor = index - 1; cursor >= 0 && value[cursor] === "\\"; cursor -= 1) backslashes += 1
  return backslashes % 2 === 1
}

export function markdownStats(markdown: string): MarkdownStats {
  const words = markdown.trim().split(/\s+/u).filter(Boolean).length
  return {
    words,
    characters: markdown.length,
    lines: markdown ? markdown.split("\n").length : 0,
    headings: markdownHeadings(markdown).length,
    tables: markdown.split("\n").filter((line) => /^\s*\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?\s*$/u.test(line)).length,
    images: (markdown.match(/!\[[^\]]*\]\([^)]*\)/gu) || []).length,
    callouts: (markdown.match(/^:::[a-z_-]+(?:\s+.*)?$/gimu) || []).length,
    readingMinutes: Math.max(1, Math.ceil(words / 220)),
  }
}

export function parseClinicalCallouts(markdown: string): ClinicalCallout[] {
  const lines = markdown.split("\n")
  const result: ClinicalCallout[] = []
  for (let index = 0; index < lines.length; index += 1) {
    const opening = /^:::([a-z][a-z-]*)(?:\s+(.*))?$/u.exec(lines[index].trim())
    if (!opening || !clinicalCalloutTypes.includes(opening[1] as ClinicalCalloutType)) continue
    const metadata: Record<string, string> = {}
    const raw = opening[2] || ""
    const metadataPattern = /([a-z_]+)=(?:"([^"]*)"|'([^']*)'|([^\s]+))/gu
    for (const match of raw.matchAll(metadataPattern)) {
      const key = match[1]
      if (!["title", "severity", "evidence_grade", "source"].includes(key)) throw new Error(`Unsupported callout field “${key}”.`)
      metadata[key] = match[2] ?? match[3] ?? match[4] ?? ""
    }
    if (raw.replace(metadataPattern, "").trim()) throw new Error("Callout metadata must use key=value syntax.")
    if (metadata.severity && !["standard", "important", "high", "critical"].includes(metadata.severity)) throw new Error("Callout severity is invalid.")
    const body: string[] = []
    const start = index
    index += 1
    while (index < lines.length && lines[index].trim() !== ":::") body.push(lines[index++])
    if (index >= lines.length) throw new Error(`Callout on line ${start + 1} is not closed.`)
    const content = body.join("\n").trim()
    if (!content) throw new Error(`Callout on line ${start + 1} requires content.`)
    result.push({
      type: opening[1] as ClinicalCalloutType,
      title: metadata.title,
      severity: metadata.severity as ClinicalCallout["severity"],
      evidenceGrade: metadata.evidence_grade,
      source: metadata.source,
      content,
      line: start + 1,
    })
  }
  return result
}

export function clinicalCalloutMarkdown(callout: Omit<ClinicalCallout, "line">) {
  if (!callout.content.trim()) throw new Error("Clinical callout content is required.")
  const quote = (value: string) => `"${value.replace(/["\\\n\r]/gu, " ").trim()}"`
  const metadata = [
    callout.title && `title=${quote(callout.title)}`,
    callout.severity && `severity=${callout.severity}`,
    callout.evidenceGrade && `evidence_grade=${quote(callout.evidenceGrade)}`,
    callout.source && `source=${quote(callout.source)}`,
  ].filter(Boolean).join(" ")
  return `:::${callout.type}${metadata ? ` ${metadata}` : ""}\n${callout.content.trim()}\n:::`
}

export function moveMarkdownSection(markdown: string, fromIndex: number, toIndex: number) {
  const headings = markdownHeadings(markdown)
  if (fromIndex === toIndex || !headings[fromIndex] || !headings[toIndex]) return markdown
  const source = headings[fromIndex]
  const endIndex = headings.findIndex((heading, index) => index > fromIndex && heading.level <= source.level)
  const sourceEnd = endIndex < 0 ? markdown.length : headings[endIndex].from
  const targetStart = headings[toIndex].from
  if (targetStart >= source.from && targetStart < sourceEnd) return markdown
  const section = markdown.slice(source.from, sourceEnd)
  const without = markdown.slice(0, source.from) + markdown.slice(sourceEnd)
  const insertion = targetStart > source.from ? targetStart - section.length : targetStart
  return without.slice(0, insertion) + section + without.slice(insertion)
}

export function formatMarkdown(markdown: string) {
  return markdown
    .replace(/\r\n?/gu, "\n")
    .split("\n")
    .map((line) => line.replace(/[ \t]+$/u, ""))
    .join("\n")
    .replace(/\n{4,}/gu, "\n\n\n")
    .trimEnd()
    .concat("\n")
}

export function headingSlug(value: string) {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^a-z0-9\s-]/gu, "")
    .trim()
    .replace(/\s+/gu, "-")
}

export function stableHeadingAnchors(markdown: string, previous: MarkdownAnchorMetadata = {}) {
  const used = new Set<string>()
  const headings = markdownHeadings(markdown)
  const previousValues = Object.values(previous)
  const sameShape = previousValues.length === headings.length
  return Object.fromEntries(headings.map((heading, index) => {
    const titleMatch = previousValues.find((item) => item.title === heading.text && !used.has(item.id))
    const positional = sameShape ? previous[String(index)] : undefined
    const retained = titleMatch?.id || (positional && !used.has(positional.id) ? positional.id : undefined)
    const base = retained || heading.id || `section-${index + 1}`
    let id = base
    let suffix = 2
    while (used.has(id)) id = `${base}-${suffix++}`
    used.add(id)
    return [String(index), { id, title: heading.text }]
  }))
}

export type DiffLine = { type: "same" | "added" | "removed"; text: string }
export type DiffWord = { type: "same" | "added" | "removed"; text: string }

export function wordDiff(before: string, after: string): DiffWord[] {
  const left = before.split(/(\s+)/u)
  const right = after.split(/(\s+)/u)
  const matrix = Array.from({ length: left.length + 1 }, () => Array(right.length + 1).fill(0))
  for (let i = left.length - 1; i >= 0; i -= 1) for (let j = right.length - 1; j >= 0; j -= 1) matrix[i][j] = left[i] === right[j] ? matrix[i + 1][j + 1] + 1 : Math.max(matrix[i + 1][j], matrix[i][j + 1])
  const result: DiffWord[] = []
  let i = 0
  let j = 0
  while (i < left.length && j < right.length) {
    if (left[i] === right[j]) { result.push({ type: "same", text: left[i++] }); j += 1 }
    else if (matrix[i + 1][j] >= matrix[i][j + 1]) result.push({ type: "removed", text: left[i++] })
    else result.push({ type: "added", text: right[j++] })
  }
  while (i < left.length) result.push({ type: "removed", text: left[i++] })
  while (j < right.length) result.push({ type: "added", text: right[j++] })
  return result
}

export function lineDiff(before: string, after: string): DiffLine[] {
  const left = before.split("\n")
  const right = after.split("\n")
  const matrix = Array.from({ length: left.length + 1 }, () => Array(right.length + 1).fill(0))
  for (let i = left.length - 1; i >= 0; i -= 1) {
    for (let j = right.length - 1; j >= 0; j -= 1) {
      matrix[i][j] = left[i] === right[j] ? matrix[i + 1][j + 1] + 1 : Math.max(matrix[i + 1][j], matrix[i][j + 1])
    }
  }
  const result: DiffLine[] = []
  let i = 0
  let j = 0
  while (i < left.length && j < right.length) {
    if (left[i] === right[j]) {
      result.push({ type: "same", text: left[i] }); i += 1; j += 1
    } else if (matrix[i + 1][j] >= matrix[i][j + 1]) {
      result.push({ type: "removed", text: left[i] }); i += 1
    } else {
      result.push({ type: "added", text: right[j] }); j += 1
    }
  }
  while (i < left.length) result.push({ type: "removed", text: left[i++] })
  while (j < right.length) result.push({ type: "added", text: right[j++] })
  return result
}
