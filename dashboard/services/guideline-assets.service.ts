"use client"

import { getBackendClient } from "@/lib/backend-client"

export type GuidelineAssetReviewStatus = "draft" | "reviewed" | "rejected"

export interface GuidelineAsset {
  id: string
  version_id: string
  type: string
  mime_type: string
  checksum: string
  size_bytes: number
  original_filename: string
  alternative_text: string
  caption: string
  source: string
  attribution: string
  license: string
  figure_number?: number | null
  clinically_sensitive: boolean
  review_status: GuidelineAssetReviewStatus
  reference: string
  referenced: boolean
  url: string
  url_expires_at: string
  created_at: string
  updated_at: string
}

export interface GuidelineAssetList {
  items: GuidelineAsset[]
  broken_references: string[]
}

export interface GuidelineAssetMetadata {
  alternative_text?: string
  caption?: string
  source?: string
  attribution?: string
  license?: string
  figure_number?: number | null
  clinically_sensitive?: boolean
}

export class GuidelineAssetsService {
  static list(versionId: string) {
    return getBackendClient().request<GuidelineAssetList>(`/api/v2/guideline-versions/${versionId}/assets`, { method: "GET" })
  }

  static upload(versionId: string, file: File, metadata: GuidelineAssetMetadata) {
    const form = new FormData()
    form.append("file", file)
    for (const [key, value] of Object.entries(metadata)) if (value !== undefined && value !== null) form.append(key, String(value))
    return getBackendClient().request<GuidelineAsset>(`/api/v2/guideline-versions/${versionId}/assets`, { method: "POST", body: form })
  }

  static update(versionId: string, assetId: string, metadata: GuidelineAssetMetadata) {
    return getBackendClient().request<GuidelineAsset>(`/api/v2/guideline-versions/${versionId}/assets/${assetId}`, { method: "PATCH", body: JSON.stringify(metadata) })
  }

  static async remove(versionId: string, assetId: string) {
    await getBackendClient().request<void>(`/api/v2/guideline-versions/${versionId}/assets/${assetId}`, { method: "DELETE" })
  }
}
