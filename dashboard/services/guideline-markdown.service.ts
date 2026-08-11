"use client"

import { BackendRequestError, getBackendClient } from "@/lib/backend-client"
import type {
  HandlersPaginatedMarkdownRevisions,
  ServicesMarkdownDraftInput,
} from "@/types/generated/backend-openapi"

export type MarkdownRevisionSource =
  | "blank"
  | "template"
  | "uploaded_markdown"
  | "pdf_generated"
  | "manual_edit"
  | "restored"
  | "duplicated"

export type StructuredContentStatus =
  | "not_generated"
  | "outdated"
  | "queued"
  | "processing"
  | "review_required"
  | "approved"
  | "failed"

export interface MarkdownRevision {
  id: string
  document_id: string
  version_id: string
  revision_number: number
  checksum: string
  size_bytes: number
  source_type: MarkdownRevisionSource
  parent_revision_id?: string | null
  source_ingestion_job_id?: string | null
  regeneration_job_id?: string | null
  checkpoint_name: string
  change_summary: string
  created_by?: string | null
  is_current: boolean
  structured_content_status: StructuredContentStatus
  review_state: "draft" | "review_required" | "approved" | "rejected"
  publication_state: "draft" | "published" | "superseded"
  created_at: string
  updated_at: string
}

export interface MarkdownDraft {
  revision: MarkdownRevision
  content: string
  etag: string
  saved: boolean
}

export interface MarkdownDraftInput extends Omit<ServicesMarkdownDraftInput, "source_type"> {
  content: string
  source_type?: MarkdownRevisionSource
}

export interface MarkdownRevisionPage
  extends Omit<HandlersPaginatedMarkdownRevisions, "items"> {
  items: MarkdownRevision[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export interface MarkdownRegenerationResult {
  job: {
    id: string
    status: string
    job_type: string
    created_at: string
  }
  revision_id: string
  operations: string[]
  queued_at: string
}

export interface MarkdownUpdateResult {
  updated: boolean
  queued: boolean
  size: number
  job_id: string
}

export class GuidelineMarkdownError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
  ) {
    super(message)
    this.name = "GuidelineMarkdownError"
  }

  get conflict() {
    return this.status === 409 || this.status === 412
  }
}

function toGuidelineMarkdownError(error: unknown, fallback: string) {
  if (error instanceof BackendRequestError) {
    return new GuidelineMarkdownError(error.message || fallback, error.status)
  }
  if (error instanceof Error) {
    return new GuidelineMarkdownError(error.message || fallback)
  }
  return new GuidelineMarkdownError(fallback)
}

export class GuidelineMarkdownService {
  static async loadDraft(versionId: string): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-draft`,
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to load the Markdown draft")
    }
  }

  static async saveDraft(versionId: string, input: MarkdownDraftInput): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-draft`,
        { method: "PUT", body: JSON.stringify(input) },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to save the Markdown draft")
    }
  }

  static async createCheckpoint(
    versionId: string,
    input: MarkdownDraftInput,
  ): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions`,
        { method: "POST", body: JSON.stringify(input) },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to save the Markdown checkpoint")
    }
  }

  static async revisions(versionId: string, page = 1): Promise<MarkdownRevisionPage> {
    try {
      return await getBackendClient().send<MarkdownRevisionPage>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions`,
        { query: { page, per_page: 50 } },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to load Markdown revision history")
    }
  }

  static async revision(versionId: string, revisionId: string): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions/${revisionId}`,
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to load the Markdown revision")
    }
  }

  static async restore(
    versionId: string,
    revisionId: string,
    expectedRevision: string,
  ): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions/${revisionId}/restore`,
        {
          method: "POST",
          body: JSON.stringify({ expected_revision: expectedRevision }),
        },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to restore the Markdown revision")
    }
  }

  static async regenerate(
    versionId: string,
    revisionId: string,
  ): Promise<MarkdownRegenerationResult> {
    try {
      return await getBackendClient().send<MarkdownRegenerationResult>(
        `/api/v2/guideline-versions/${versionId}/regenerate`,
        {
          method: "POST",
          body: JSON.stringify({
            revision_id: revisionId,
            idempotency_key: `markdown-${revisionId}`,
          }),
        },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to queue Markdown regeneration")
    }
  }

  static async load(versionId: string): Promise<string> {
    try {
      return (await this.loadDraft(versionId)).content
    } catch (error) {
      if (error instanceof GuidelineMarkdownError && error.status !== 404) throw error
      try {
        return await getBackendClient().send<string>(
          `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
          { method: "GET", responseType: "text" },
        )
      } catch (legacyError) {
        throw toGuidelineMarkdownError(legacyError, "Failed to load extracted Markdown")
      }
    }
  }

  /** @deprecated Use saveDraft; this compatibility method never regenerates content. */
  static async update(versionId: string, content: string): Promise<MarkdownUpdateResult> {
    const draft = await this.saveDraft(versionId, { content, source_type: "manual_edit" })
    return { updated: true, queued: false, size: content.length, job_id: draft.revision.regeneration_job_id || "" }
  }
}
