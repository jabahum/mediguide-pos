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
      headings.push({
        id: headingSlug(match[2]),
        text: match[2],
        level: match[1].length,
        line: index + 1,
        from: offset,
        to: offset + line.length,
        words,
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
        code: "duplicate_heading",
        severity: "warning",
        message: `Duplicate heading anchor “${heading.id}”.`,
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
    if (/!\[\]\(/u.test(line)) {
      issues.push({ code: "missing_alt_text", severity: "warning", message: "Image alternative text is missing.", line: index + 1 })
    }
  })
  const calloutStarts = lines.filter((line) => /^:::[a-z_-]+\s*$/iu.test(line)).length
  const calloutEnds = lines.filter((line) => /^:::\s*$/u.test(line)).length
  if (calloutStarts !== calloutEnds) {
    issues.push({ code: "unclosed_callout", severity: "error", message: "A clinical callout is not closed.", line: 1 })
  }
  return issues
}

export function markdownStats(markdown: string): MarkdownStats {
  const words = markdown.trim().split(/\s+/u).filter(Boolean).length
  return {
    words,
    characters: markdown.length,
    lines: markdown ? markdown.split("\n").length : 0,
    headings: markdownHeadings(markdown).length,
    tables: markdown.split("\n").filter((line) => /^\s*\|?.*\|.*\|?\s*$/u.test(line)).length,
    images: (markdown.match(/!\[[^\]]*\]\([^)]*\)/gu) || []).length,
    callouts: (markdown.match(/^:::[a-z_-]+\s*$/gimu) || []).length,
    readingMinutes: Math.max(1, Math.ceil(words / 220)),
  }
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

export type DiffLine = { type: "same" | "added" | "removed"; text: string }

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
