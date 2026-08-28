"use client";

import { BackendRequestError, getBackendClient } from "@/lib/backend-client";
import type {
  HandlersPaginatedMarkdownRevisions,
  ServicesDuplicatedMarkdownVersion,
  ServicesDuplicateMarkdownVersionInput,
  ServicesMarkdownDraftInput,
} from "@/types/generated/backend-openapi";
import type { GuidelineVersionRecord } from "@/services/guideline-documents.service";
import type { MarkdownAnchorMetadata } from "@/components/guidelines/markdown-authoring";

export type MarkdownRevisionSource =
  | "blank"
  | "template"
  | "uploaded_markdown"
  | "pdf_generated"
  | "manual_edit"
  | "restored"
  | "duplicated";

export type StructuredContentStatus =
  | "not_generated"
  | "outdated"
  | "queued"
  | "processing"
  | "review_required"
  | "approved"
  | "failed"
  | "canceled";

export interface MarkdownValidationIssue {
  severity: "error" | "warning" | "info";
  code: string;
  message: string;
  line: number;
  column: number;
  end_line: number;
  end_column: number;
}

export interface MarkdownValidationResult {
  revision_id: string;
  valid: boolean;
  issues: MarkdownValidationIssue[];
  errors: number;
  warnings: number;
  info: number;
}

export interface RegenerationJob {
  id: string;
  status: string;
  progress_stage: string;
  progress_percent: number;
  error?: string;
  attempt_count: number;
  created_at: string;
  started_at?: string;
  completed_at?: string;
}
export interface RegenerationJobView {
  job: RegenerationJob;
  revision_id: string;
  operations: string[];
}
export interface RegenerationReview {
  id: string;
  version_id: string;
  revision_id: string;
  job_id: string;
  status: "pending" | "accepted" | "rejected";
  before_snapshot: Record<string, unknown>;
  after_snapshot: Record<string, unknown>;
  comparison: Record<string, unknown>;
  decision_comment?: string;
  reviewed_by?: string;
  reviewed_at?: string;
}
export interface RegenerationReviewComment {
  id: string;
  job_id: string;
  block_id?: string;
  author_id: string;
  body: string;
  created_at: string;
}
export interface GuidelineReviewAssignment {
  id: string;
  version_id: string;
  reviewer_id: string;
  reviewer_name: string;
  reviewer_email: string;
  assigned_by?: string;
  status: "assigned" | "completed" | "dismissed";
  due_at?: string;
  completed_at?: string;
  created_at: string;
}
export interface GuidelineReviewerCandidate {
  id: string;
  name: string;
  email: string;
}
export interface GuidelineEditorComment {
  id: string;
  version_id: string;
  revision_id?: string;
  section_id?: string;
  block_id?: string;
  author_id: string;
  body: string;
  resolved: boolean;
  resolved_by?: string;
  resolved_at?: string;
  created_at: string;
}
export interface GuidelineActivityItem {
  id: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  metadata_json: string;
  created_at: string;
}

export interface MarkdownRevision {
  id: string;
  document_id: string;
  version_id: string;
  revision_number: number;
  checksum: string;
  size_bytes: number;
  source_type: MarkdownRevisionSource;
  parent_revision_id?: string | null;
  source_ingestion_job_id?: string | null;
  regeneration_job_id?: string | null;
  checkpoint_name: string;
  change_summary: string;
  created_by?: string | null;
  is_current: boolean;
  structured_content_status: StructuredContentStatus;
  review_state: "draft" | "review_required" | "approved" | "rejected";
  publication_state: "draft" | "published" | "superseded";
  created_at: string;
  updated_at: string;
  anchor_metadata?: MarkdownAnchorMetadata;
}

export interface MarkdownDraft {
  revision: MarkdownRevision;
  content: string;
  etag: string;
  saved: boolean;
}

export interface MarkdownDraftInput extends Omit<
  ServicesMarkdownDraftInput,
  "source_type"
> {
  content: string;
  source_type?: MarkdownRevisionSource;
  anchor_metadata?: MarkdownAnchorMetadata;
}

export interface MarkdownRevisionPage extends Omit<
  HandlersPaginatedMarkdownRevisions,
  "items"
> {
  items: MarkdownRevision[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}

export interface MarkdownRevisionQuery {
  page?: number;
  per_page?: number;
  source_type?: MarkdownRevisionSource | "";
  created_by?: string;
  from?: string;
  to?: string;
}

export interface MarkdownRegenerationResult {
  job: {
    id: string;
    status: string;
    job_type: string;
    created_at: string;
  };
  revision_id: string;
  operations: string[];
  queued_at: string;
}

export interface DuplicateMarkdownVersionInput extends ServicesDuplicateMarkdownVersionInput {
  version: string;
}

export interface DuplicatedMarkdownVersion extends Omit<
  ServicesDuplicatedMarkdownVersion,
  "version" | "draft"
> {
  version: GuidelineVersionRecord;
  draft: MarkdownDraft;
}

export interface MarkdownUpdateResult {
  updated: boolean;
  queued: boolean;
  size: number;
  job_id: string;
}

export class GuidelineMarkdownError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
  ) {
    super(message);
    this.name = "GuidelineMarkdownError";
  }

  get conflict() {
    return this.status === 409 || this.status === 412;
  }
}

function toGuidelineMarkdownError(error: unknown, fallback: string) {
  if (error instanceof BackendRequestError) {
    return new GuidelineMarkdownError(error.message || fallback, error.status);
  }
  if (error instanceof Error) {
    return new GuidelineMarkdownError(error.message || fallback);
  }
  return new GuidelineMarkdownError(fallback);
}

export class GuidelineMarkdownService {
  static async duplicateVersion(
    sourceVersionId: string,
    input: DuplicateMarkdownVersionInput,
  ): Promise<DuplicatedMarkdownVersion> {
    try {
      return await getBackendClient().send<DuplicatedMarkdownVersion>(
        `/api/v2/guideline-versions/${sourceVersionId}/duplicate`,
        { method: "POST", body: JSON.stringify(input) },
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to create the new Markdown draft version",
      );
    }
  }

  static async loadDraft(versionId: string): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-draft`,
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to load the Markdown draft",
      );
    }
  }

  static async saveDraft(
    versionId: string,
    input: MarkdownDraftInput,
  ): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-draft`,
        { method: "PUT", body: JSON.stringify(input) },
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to save the Markdown draft",
      );
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
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to save the Markdown checkpoint",
      );
    }
  }

  static async revisions(
    versionId: string,
    query: MarkdownRevisionQuery | number = {},
  ): Promise<MarkdownRevisionPage> {
    try {
      const normalized = typeof query === "number" ? { page: query } : query;
      return await getBackendClient().send<MarkdownRevisionPage>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions`,
        {
          query: {
            page: normalized.page ?? 1,
            per_page: normalized.per_page ?? 20,
            ...normalized,
          },
        },
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to load Markdown revision history",
      );
    }
  }

  static async revision(
    versionId: string,
    revisionId: string,
  ): Promise<MarkdownDraft> {
    try {
      return await getBackendClient().send<MarkdownDraft>(
        `/api/v2/guideline-versions/${versionId}/markdown-revisions/${revisionId}`,
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to load the Markdown revision",
      );
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
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to restore the Markdown revision",
      );
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
      );
    } catch (error) {
      throw toGuidelineMarkdownError(
        error,
        "Failed to queue Markdown regeneration",
      );
    }
  }

  static async validate(
    versionId: string,
    revisionId: string,
  ): Promise<MarkdownValidationResult> {
    return getBackendClient().request<MarkdownValidationResult>(
      `/api/v2/guideline-versions/${versionId}/markdown-revisions/${revisionId}/validation`,
    );
  }

  static async regenerationJob(
    versionId: string,
    jobId: string,
  ): Promise<RegenerationJobView> {
    return getBackendClient().request<RegenerationJobView>(
      `/api/v2/guideline-versions/${versionId}/regeneration-jobs/${jobId}`,
    );
  }
  static async cancelRegeneration(
    versionId: string,
    jobId: string,
  ): Promise<RegenerationJob> {
    return getBackendClient().request<RegenerationJob>(
      `/api/v2/guideline-versions/${versionId}/regeneration-jobs/${jobId}/cancel`,
      { method: "POST" },
    );
  }
  static async retryRegeneration(
    versionId: string,
    jobId: string,
  ): Promise<RegenerationJob> {
    return getBackendClient().request<RegenerationJob>(
      `/api/v2/guideline-versions/${versionId}/regeneration-jobs/${jobId}/retry`,
      { method: "POST" },
    );
  }
  static async regenerationReview(
    versionId: string,
    jobId: string,
  ): Promise<RegenerationReview> {
    return getBackendClient().request<RegenerationReview>(
      `/api/v2/guideline-versions/${versionId}/regeneration-reviews/${jobId}`,
    );
  }
  static async decideRegeneration(
    versionId: string,
    jobId: string,
    decision: "accept" | "reject",
    comment = "",
  ): Promise<RegenerationReview> {
    return getBackendClient().request<RegenerationReview>(
      `/api/v2/guideline-versions/${versionId}/regeneration-reviews/${jobId}/${decision}`,
      { method: "POST", body: JSON.stringify({ comment }) },
    );
  }
  static async reviewComments(
    versionId: string,
    jobId: string,
  ): Promise<RegenerationReviewComment[]> {
    return getBackendClient().request<RegenerationReviewComment[]>(
      `/api/v2/guideline-versions/${versionId}/regeneration-reviews/${jobId}/comments`,
    );
  }
  static async addReviewComment(
    versionId: string,
    jobId: string,
    body: string,
    blockId?: string,
  ): Promise<RegenerationReviewComment> {
    return getBackendClient().request<RegenerationReviewComment>(
      `/api/v2/guideline-versions/${versionId}/regeneration-reviews/${jobId}/comments`,
      { method: "POST", body: JSON.stringify({ body, block_id: blockId }) },
    );
  }
  static async reviewAssignments(
    versionId: string,
  ): Promise<GuidelineReviewAssignment[]> {
    return getBackendClient().request<GuidelineReviewAssignment[]>(
      `/api/v2/guideline-versions/${versionId}/reviewers`,
    );
  }
  static async reviewerCandidates(
    search = "",
  ): Promise<GuidelineReviewerCandidate[]> {
    return getBackendClient().request<GuidelineReviewerCandidate[]>(
      "/api/v2/guideline-reviewers",
      { query: { search: search || undefined } },
    );
  }
  static async assignReviewer(
    versionId: string,
    reviewerId: string,
    dueAt?: string,
  ): Promise<GuidelineReviewAssignment> {
    return getBackendClient().request<GuidelineReviewAssignment>(
      `/api/v2/guideline-versions/${versionId}/reviewers`,
      {
        method: "POST",
        body: JSON.stringify({
          reviewer_id: reviewerId,
          due_at: dueAt || undefined,
        }),
      },
    );
  }
  static async updateReviewAssignment(
    versionId: string,
    assignmentId: string,
    status: "completed" | "dismissed",
  ): Promise<GuidelineReviewAssignment> {
    return getBackendClient().request<GuidelineReviewAssignment>(
      `/api/v2/guideline-versions/${versionId}/reviewers/${assignmentId}`,
      { method: "PATCH", body: JSON.stringify({ status }) },
    );
  }
  static async editorComments(
    versionId: string,
    resolved?: boolean,
  ): Promise<GuidelineEditorComment[]> {
    return getBackendClient().request<GuidelineEditorComment[]>(
      `/api/v2/guideline-versions/${versionId}/review-comments`,
      { query: { resolved } },
    );
  }
  static async addEditorComment(
    versionId: string,
    body: string,
    revisionId?: string,
    sectionId?: string,
    blockId?: string,
  ): Promise<GuidelineEditorComment> {
    return getBackendClient().request<GuidelineEditorComment>(
      `/api/v2/guideline-versions/${versionId}/review-comments`,
      {
        method: "POST",
        body: JSON.stringify({
          body,
          revision_id: revisionId,
          section_id: sectionId,
          block_id: blockId,
        }),
      },
    );
  }
  static async resolveEditorComment(
    versionId: string,
    commentId: string,
    resolved: boolean,
  ): Promise<GuidelineEditorComment> {
    return getBackendClient().request<GuidelineEditorComment>(
      `/api/v2/guideline-versions/${versionId}/review-comments/${commentId}`,
      { method: "PATCH", body: JSON.stringify({ resolved }) },
    );
  }
  static async activity(versionId: string): Promise<GuidelineActivityItem[]> {
    return getBackendClient().request<GuidelineActivityItem[]>(
      `/api/v2/guideline-versions/${versionId}/activity`,
      { query: { limit: 100 } },
    );
  }

  static async load(versionId: string): Promise<string> {
    try {
      return (await this.loadDraft(versionId)).content;
    } catch (error) {
      if (error instanceof GuidelineMarkdownError && error.status !== 404)
        throw error;
      try {
        return await getBackendClient().send<string>(
          `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
          { method: "GET", responseType: "text" },
        );
      } catch (legacyError) {
        throw toGuidelineMarkdownError(
          legacyError,
          "Failed to load extracted Markdown",
        );
      }
    }
  }

  /** @deprecated Use saveDraft; this compatibility method never regenerates content. */
  static async update(
    versionId: string,
    content: string,
  ): Promise<MarkdownUpdateResult> {
    const draft = await this.saveDraft(versionId, {
      content,
      source_type: "manual_edit",
    });
    return {
      updated: true,
      queued: false,
      size: content.length,
      job_id: draft.revision.regeneration_job_id || "",
    };
  }
}
