import { EmergencyProtocolsResponse } from "@/types/backend-types"

export type EmergencyProtocolRecord = EmergencyProtocolsResponse<
  unknown,
  unknown,
  unknown,
  unknown,
  unknown,
  unknown,
  unknown
>

export function stringifyJsonField(value: unknown): string {
  if (value === null || value === undefined) {
    return ""
  }

  return JSON.stringify(value, null, 2)
}

export function parseOptionalJsonField(value: string, fieldLabel: string) {
  const trimmed = value.trim()

  if (!trimmed) {
    return null
  }

  try {
    return JSON.parse(trimmed)
  } catch {
    throw new Error(`${fieldLabel} must be valid JSON`)
  }
}

export function parseTags(value: string) {
  return value
    .split(/[\n,]/)
    .map((item) => item.trim())
    .filter(Boolean)
}
