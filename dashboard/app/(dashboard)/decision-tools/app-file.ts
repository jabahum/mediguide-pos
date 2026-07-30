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
