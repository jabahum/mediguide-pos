"use client"

import { getBackendClient } from "@/lib/backend-client"

export const guidelineDocumentsQueryKey = ["v2-guideline-documents"] as const

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

export interface GuidelineDocumentInput {
  title: string
  country?: string
  source_org?: string
  program_area?: string
  language?: string
  description?: string
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

export interface GuidelineSectionRecord {
  id: string
  version_id: string
  parent_id?: string | null
  title: string
  slug: string
  level: number
  html: string
  text: string
  page_start?: number | null
  page_end?: number | null
  sort_order: number
}

interface GuidelineSectionsPage {
  items: GuidelineSectionRecord[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export function getDocumentCurrentVersion(document?: GuidelineDocumentRecord | null) {
  if (!document) return null
  if (document.current_version_id) {
    const current = document.versions.find((version) => version.id === document.current_version_id)
    if (current) return current
  }
  return document.versions[0] || null
}

export function getDocumentLatestVersion(document?: GuidelineDocumentRecord | null) {
  return document?.versions[0] || null
}

function sortVersions(versions: GuidelineVersionRecord[]) {
  return [...versions].sort((left, right) => {
    const leftDate = new Date(left.publication_date || left.created_at).getTime()
    const rightDate = new Date(right.publication_date || right.created_at).getTime()
    return rightDate - leftDate
  })
}

function normalizeDocument(document: GuidelineDocumentRecord): GuidelineDocumentRecord {
  return { ...document, versions: sortVersions(document.versions || []) }
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement("a")
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

export class GuidelineDocumentsService {
  static async listDocuments(programArea?: string): Promise<GuidelineDocumentsPage> {
    const backend = getBackendClient()
    const first = await backend.request<GuidelineDocumentsPage>("/api/v2/guidelines", {
      method: "GET",
      query: { page: 1, per_page: 100, program_area: programArea },
    })
    const items = [...(first.items || [])]
    for (let page = 2; page <= first.total_pages; page += 1) {
      const next = await backend.request<GuidelineDocumentsPage>("/api/v2/guidelines", {
        method: "GET",
        query: { page, per_page: 100, program_area: programArea },
      })
      items.push(...(next.items || []))
    }
    return { ...first, items: items.map(normalizeDocument), total_items: items.length }
  }

  static async getDocument(documentId: string): Promise<GuidelineDocumentRecord> {
    const document = await getBackendClient().request<GuidelineDocumentRecord>(
      `/api/v2/guidelines/${documentId}`,
      { method: "GET" }
    )
    return normalizeDocument(document)
  }

  static async createDocument(payload: GuidelineDocumentInput): Promise<GuidelineDocumentRecord> {
    return getBackendClient().request<GuidelineDocumentRecord>("/api/v2/guidelines", {
      method: "POST",
      body: JSON.stringify(payload),
    })
  }

  static async updateDocument(
    documentId: string,
    payload: GuidelineDocumentInput
  ): Promise<GuidelineDocumentRecord> {
    return getBackendClient().request<GuidelineDocumentRecord>(`/api/v2/guidelines/${documentId}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    })
  }

  static async createVersion(
    documentId: string,
    payload: CreateGuidelineVersionInput
  ): Promise<GuidelineVersionRecord> {
    return getBackendClient().request<GuidelineVersionRecord>(`/api/v2/guidelines/${documentId}/versions`, {
      method: "POST",
      body: JSON.stringify(payload),
    })
  }

  static async uploadVersionPdf(versionId: string, file: File): Promise<IngestionJobRecord> {
    const formData = new FormData()
    formData.append("file", file)
    return getBackendClient().request<IngestionJobRecord>(`/api/v2/guideline-versions/${versionId}/upload`, {
      method: "POST",
      body: formData,
    })
  }

  static async publishVersion(versionId: string): Promise<{ published: boolean }> {
    return getBackendClient().request<{ published: boolean }>(
      `/api/v2/guideline-versions/${versionId}/publish`,
      { method: "POST" }
    )
  }

  static async listSections(versionId: string): Promise<GuidelineSectionRecord[]> {
    const first = await getBackendClient().request<GuidelineSectionsPage>(
      `/api/v2/guideline-versions/${versionId}/sections`,
      { method: "GET", query: { page: 1, per_page: 500 } }
    )
    const sections = [...(first.items || [])]
    for (let page = 2; page <= first.total_pages; page += 1) {
      const next = await getBackendClient().request<GuidelineSectionsPage>(
        `/api/v2/guideline-versions/${versionId}/sections`,
        { method: "GET", query: { page, per_page: 500 } }
      )
      sections.push(...(next.items || []))
    }
    return sections.sort((left, right) => left.sort_order - right.sort_order)
  }

  static async getExtractedMarkdown(versionId: string): Promise<string> {
    return getBackendClient().request<string>(`/api/v2/guideline-versions/${versionId}/extracted/markdown`, {
      method: "GET",
      responseType: "text",
    })
  }

  static async updateExtractedMarkdown(
    versionId: string,
    content: string
  ): Promise<{ updated: boolean; size: number }> {
    return getBackendClient().request<{ updated: boolean; size: number }>(
      `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
      {
        method: "PUT",
        headers: { "Content-Type": "text/markdown; charset=utf-8" },
        body: content,
      }
    )
  }

  static async downloadExtractedAsset(
    versionId: string,
    format: "md" | "html",
    filename: string
  ): Promise<void> {
    const blob = await getBackendClient().request<Blob>(
      `/api/v2/guideline-versions/${versionId}/extracted/${format}`,
      { method: "GET", responseType: "blob" }
    )
    downloadBlob(blob, filename)
  }
}
