type AppFileMetadata = {
  name?: unknown
  path?: unknown
}

export function getAppFileLabel(value: unknown): string {
  if (typeof value === "string") {
    const trimmed = value.trim()
    if (!trimmed) return ""

    try {
      return getAppFileLabel(JSON.parse(trimmed))
    } catch {
      return trimmed
    }
  }

  if (value && typeof value === "object") {
    const file = value as AppFileMetadata
    if (typeof file.name === "string" && file.name.trim()) {
      return file.name.trim()
    }
    if (typeof file.path === "string" && file.path.trim()) {
      return file.path.trim()
    }
  }

  return ""
}

export function getBundledAppFileName(value: unknown): string {
  const label = getAppFileLabel(value)
  if (!label) return ""

  const fileName = label.split(/[\\/]/).pop() || ""
  if (!fileName.toLowerCase().endsWith(".html")) return ""

  const stem = fileName
    .slice(0, -5)
    .replace(/_[a-z0-9]{10}$/i, "")
    .replace(/[_\s]+/g, "-")
    .replace(/[^a-z0-9-]/gi, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .toLowerCase()

  return stem ? `${stem}.html` : ""
}

export function getBundledAppFileUrl(value: unknown): string {
  const fileName = getBundledAppFileName(value)
  return fileName
    ? `/decision-tools/samples/${encodeURIComponent(fileName)}`
    : ""
}
