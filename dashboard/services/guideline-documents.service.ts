"use client"

import { getBackendClient } from "@/lib/backend-client"

export interface GuidelineVersionRecord {
  id: string
  document_id: string
  version: string
  publication_date?: string
  review_date?: string
  status: string
  original_file_key?: string
  html_file_key?: string
  markdown_file_key?: string
  checksum?: string
  approved_by?: string | null
  approved_at?: string | null
  created_at: string
  updated_at: string
}

export interface GuidelineDocumentRecord {
  id: string
  title: string
  country?: string
  source_org?: string
  program_area?: string
  language?: string
  description?: string
  current_version_id?: string | null
  versions: GuidelineVersionRecord[]
  created_at: string
  updated_at: string
}

export interface GuidelineDocumentsPage {
  items: GuidelineDocumentRecord[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export interface CreateGuidelineVersionInput {
  version: string
  publication_date?: string
  review_date?: string
}

export interface IngestionJobRecord {
  id: string
  version_id: string
  job_type: string
  status: string
  payload_json?: string
  error?: string
  created_at: string
  updated_at: string
}

export function normalizeGuidelineDocumentKey(value?: string | null) {
  return (value || "")
    .toLowerCase()
    .replace(/&amp;/g, "&")
    .replace(/<[^>]+>/g, " ")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
}

export function buildGuidelineDocumentLookup(documents: GuidelineDocumentRecord[]) {
  const lookup = new Map<string, GuidelineDocumentRecord>()
  for (const document of documents) {
    const key = normalizeGuidelineDocumentKey(document.title)
    if (key && !lookup.has(key)) {
      lookup.set(key, document)
    }
  }
  return lookup
}

export function getDocumentCurrentVersion(document?: GuidelineDocumentRecord | null) {
  if (!document) return null

  if (document.current_version_id) {
    const current = document.versions.find((version) => version.id === document.current_version_id)
    if (current) return current
  }

  return document.versions[0] || null
}

function sortVersions(versions: GuidelineVersionRecord[]) {
  return [...versions].sort((left, right) => {
    const leftDate = new Date(left.publication_date || left.created_at).getTime()
    const rightDate = new Date(right.publication_date || right.created_at).getTime()
    return rightDate - leftDate
  })
}

function normalizeDocument(document: GuidelineDocumentRecord): GuidelineDocumentRecord {
  return {
    ...document,
    versions: sortVersions(document.versions || []),
  }
}

export class GuidelineDocumentsService {
  static async listDocuments(programArea?: string): Promise<GuidelineDocumentsPage> {
    const backend = getBackendClient()
    const data = await backend.send<GuidelineDocumentsPage>("/api/v2/guidelines", {
      method: "GET",
      query: {
        page: 1,
        per_page: 100,
        program_area: programArea,
      },
    })

    return {
      ...data,
      items: (data.items || []).map(normalizeDocument),
    }
  }

  static async createVersion(
    documentId: string,
    payload: CreateGuidelineVersionInput
  ): Promise<GuidelineVersionRecord> {
    const backend = getBackendClient()
    return backend.send<GuidelineVersionRecord>(`/api/v2/guidelines/${documentId}/versions`, {
      method: "POST",
      body: JSON.stringify(payload),
    })
  }

  static async getDocument(documentId: string): Promise<GuidelineDocumentRecord> {
    const backend = getBackendClient()
    const document = await backend.send<GuidelineDocumentRecord>(`/api/v2/guidelines/${documentId}`, {
      method: "GET",
    })
    return normalizeDocument(document)
  }

  static async uploadVersionPdf(
    versionId: string,
    file: File
  ): Promise<IngestionJobRecord> {
    const backend = getBackendClient()
    const formData = new FormData()
    formData.append("file", file)

    return backend.send<IngestionJobRecord>(`/api/v2/guideline-versions/${versionId}/upload`, {
      method: "POST",
      body: formData,
    })
  }

  static async publishVersion(versionId: string): Promise<{ published: boolean }> {
    const backend = getBackendClient()
    return backend.send<{ published: boolean }>(`/api/v2/guideline-versions/${versionId}/publish`, {
      method: "POST",
    })
  }
}
