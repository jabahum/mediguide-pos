"use client";

import { getBackendClient } from "@/lib/backend-client";
import type { ServicesGuidelineNotificationCampaignInput } from "@/types/generated/backend-openapi";

export const guidelineDocumentsQueryKey = ["v2-guideline-documents"] as const;

export interface GuidelineNotificationCampaignInput extends Omit<
  ServicesGuidelineNotificationCampaignInput,
  "audience" | "priority" | "requested_channels"
> {
  audience: {
    all_eligible: boolean;
    user_ids?: string[];
    role_ids?: string[];
    countries?: string[];
    languages?: string[];
    platforms?: Array<"android" | "ios">;
    preference_categories?: string[];
  };
  timezone: string;
  priority: "low" | "normal" | "high" | "urgent";
  requested_channels: Array<"push" | "in-app">;
  idempotency_key: string;
}

export interface GuidelineVersionRecord {
  id: string;
  document_id: string;
  version: string;
  publication_date?: string;
  review_date?: string;
  status: string;
  original_file_key?: string;
  html_file_key?: string;
  markdown_file_key?: string;
  checksum?: string;
  approved_by?: string | null;
  approved_at?: string | null;
  extraction_schema_version?: number;
  extraction_metadata?: Record<string, unknown>;
  extraction_warnings?: string[];
  current_markdown_revision_id?: string | null;
  structured_markdown_revision_id?: string | null;
  published_markdown_revision_id?: string | null;
  structured_content_status?: string;
  created_at: string;
  updated_at: string;
}

export interface GuidelineDocumentRecord {
  id: string;
  title: string;
  country?: string;
  source_org?: string;
  program_area?: string;
  language?: string;
  description?: string;
  current_version_id?: string | null;
  versions: GuidelineVersionRecord[];
  created_at: string;
  updated_at: string;
}

export interface GuidelineDocumentsPage {
  items: GuidelineDocumentRecord[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}

export interface GuidelineDocumentInput {
  title: string;
  country?: string;
  source_org?: string;
  program_area?: string;
  language?: string;
  description?: string;
}

export interface CreateGuidelineVersionInput {
  version: string;
  publication_date?: string;
  review_date?: string;
}

export interface IngestionJobRecord {
  id: string;
  version_id: string;
  job_type: string;
  status: string;
  payload_json?: string;
  error?: string;
  created_at: string;
  updated_at: string;
}

export interface GuidelineSectionRecord {
  id: string;
  version_id: string;
  parent_id?: string | null;
  title: string;
  slug: string;
  level: number;
  html: string;
  text: string;
  page_start?: number | null;
  page_end?: number | null;
  sort_order: number;
}

export type GuidelineBlockType =
  | "heading"
  | "paragraph"
  | "ordered_list"
  | "unordered_list"
  | "table"
  | "figure"
  | "recommendation"
  | "warning"
  | "caution"
  | "key_point"
  | "contraindication"
  | "dosage"
  | "evidence"
  | "definition"
  | "procedure"
  | "clinical_note"
  | "referral_criteria"
  | "algorithm_reference"
  | "algorithm"
  | "reference"
  | "page_break"
  | "unknown";

export type GuidelineBlockReviewStatus = "draft" | "reviewed" | "rejected";

export interface GuidelineContentBlockRecord {
  id: string;
  version_id: string;
  section_id?: string | null;
  type: GuidelineBlockType;
  sort_order: number;
  content: Record<string, unknown>;
  provenance?: Record<string, unknown>;
  page_start?: number | null;
  page_end?: number | null;
  extraction_confidence?: number | null;
  review_status: GuidelineBlockReviewStatus;
  reviewed_by?: string | null;
  reviewed_at?: string | null;
}

export interface GuidelineAssetRecord {
  id: string;
  version_id: string;
  section_id?: string | null;
  type: string;
  mime_type: string;
  checksum: string;
  size_bytes: number;
  original_filename?: string | null;
  page_start?: number | null;
  page_end?: number | null;
}

export interface GuidelineReviewIssue {
  code: string;
  message: string;
  remediation?: string;
  section_id?: string;
  block_id?: string;
  asset_id?: string;
}

export interface GuidelinePublicationValidation {
  valid: boolean;
  errors: GuidelineReviewIssue[];
  warnings: GuidelineReviewIssue[];
}

export interface GuidelineReviewWorkspace {
  version: GuidelineVersionRecord;
  sections: GuidelineSectionRecord[];
  blocks: GuidelineContentBlockRecord[];
  assets: GuidelineAssetRecord[];
  block_review_policy?: {
    high_risk_types: GuidelineBlockType[];
    bulk_review_eligible_types: GuidelineBlockType[];
    conditional_risk_types: GuidelineBlockType[];
    ineligible_bulk_types: GuidelineBlockType[];
  };
  extraction_warnings: string[];
  validation: GuidelinePublicationValidation;
}

export interface GuidelineReviewProgress {
  total_blocks: number;
  reviewed_blocks: number;
  pending_low_risk_blocks: number;
  pending_high_risk_blocks: number;
  rejected_blocks: number;
  sections_with_reviewed_content: number;
  empty_clinical_leaf_sections: number;
}

export interface GuidelineReviewBlocksPage {
  items: GuidelineContentBlockRecord[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
  progress: GuidelineReviewProgress;
  markdown_revision_id?: string;
  regeneration_job_id?: string;
}

export interface GuidelineReviewBlocksFilter {
  page?: number;
  per_page?: number;
  status?: "all" | "pending" | "reviewed" | "rejected";
  risk?: "all" | "low-risk-pending" | "high-risk" | "pending-high-risk";
  block_type?: GuidelineBlockType | "all";
  section_id?: string;
}

export interface GuidelineBulkReviewResult {
  reviewed_count: number;
  skipped_count: number;
  rejected_count: number;
  reviewed_ids: string[];
  skipped_ids: string[];
  reasons: Array<{
    code: string;
    message: string;
    block_id?: string;
    type?: GuidelineBlockType;
  }>;
}

export interface GuidelineCompletenessReport {
  generated_at: string;
  read_only: boolean;
  guideline_id: string;
  guideline_title: string;
  version_id: string;
  version: string;
  version_status: string;
  total_blocks: number;
  active_blocks: number;
  reviewed_blocks: number;
  reviewed_percentage: number;
  block_counts: Array<{
    block_type: string;
    total: number;
    draft: number;
    reviewed: number;
    rejected: number;
  }>;
  sections: {
    total_sections: number;
    reviewed_sections: number;
    leaf_sections: number;
    reviewed_leaf_sections: number;
    empty_leaf_sections: number;
  };
  empty_leaf_sections: Array<{
    id: string;
    title: string;
    level: number;
    active_block_count: number;
    review_exempt: boolean;
  }>;
  sources: {
    original_pdf_available: boolean;
    original_pdf_reviewed: boolean;
    offline_package_available: boolean;
    offline_package_reviewed: boolean;
    reviewed_fallback_available: boolean;
  };
  regeneration: {
    current_markdown_revision_id?: string;
    structured_markdown_revision_id?: string;
    published_markdown_revision_id?: string;
    latest_job_id?: string;
    latest_job_status?: string;
    latest_job_stage?: string;
    review_id?: string;
    review_status?: string;
    review_revision_id?: string;
    review_job_id?: string;
    accepted_by?: string;
    accepted_at?: string;
    identities_match: boolean;
  };
  rag: {
    total_chunks: number;
    approved_chunks: number;
    draft_chunks: number;
    rejected_chunks: number;
    reviewed_blocks_with_chunks: number;
    reviewed_blocks_without_chunks: number;
    embedding_column_available: boolean;
    embedded_approved_chunks: number;
    missing_approved_embeddings: number;
    reviewed_block_chunks: number;
    embedded_reviewed_block_chunks: number;
    missing_reviewed_embeddings: number;
    ready: boolean;
  };
  current_comparison?: {
    current_version_id: string;
    current_version: string;
    same_version: boolean;
    metrics: Array<{ name: string; current: number; candidate: number; delta: number }>;
  };
  validation: GuidelinePublicationValidation;
}

export interface UpdateGuidelineSectionInput {
  title?: string;
  slug?: string;
  parent_id?: string;
  level?: number;
  sort_order?: number;
}

export interface UpdateGuidelineBlockInput {
  section_id?: string;
  type?: GuidelineBlockType;
  sort_order?: number;
  content?: Record<string, unknown>;
}

interface GuidelineSectionsPage {
  items: GuidelineSectionRecord[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}

export function getDocumentCurrentVersion(
  document?: GuidelineDocumentRecord | null,
) {
  if (!document) return null;
  if (document.current_version_id) {
    const current = document.versions.find(
      (version) => version.id === document.current_version_id,
    );
    if (current) return current;
  }
  return document.versions[0] || null;
}

export function getDocumentLatestVersion(
  document?: GuidelineDocumentRecord | null,
) {
  return document?.versions[0] || null;
}

function sortVersions(versions: GuidelineVersionRecord[]) {
  return [...versions].sort((left, right) => {
    const leftDate = new Date(
      left.publication_date || left.created_at,
    ).getTime();
    const rightDate = new Date(
      right.publication_date || right.created_at,
    ).getTime();
    return rightDate - leftDate;
  });
}

function normalizeDocument(
  document: GuidelineDocumentRecord,
): GuidelineDocumentRecord {
  return { ...document, versions: sortVersions(document.versions || []) };
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

export class GuidelineDocumentsService {
  static async listDocuments(
    programArea?: string,
  ): Promise<GuidelineDocumentsPage> {
    const backend = getBackendClient();
    const first = await backend.request<GuidelineDocumentsPage>(
      "/api/v2/guidelines",
      {
        method: "GET",
        query: { page: 1, per_page: 100, program_area: programArea },
      },
    );
    const items = [...(first.items || [])];
    for (let page = 2; page <= first.total_pages; page += 1) {
      const next = await backend.request<GuidelineDocumentsPage>(
        "/api/v2/guidelines",
        {
          method: "GET",
          query: { page, per_page: 100, program_area: programArea },
        },
      );
      items.push(...(next.items || []));
    }
    return {
      ...first,
      items: items.map(normalizeDocument),
      total_items: items.length,
    };
  }

  static async getDocument(
    documentId: string,
  ): Promise<GuidelineDocumentRecord> {
    const document = await getBackendClient().request<GuidelineDocumentRecord>(
      `/api/v2/guidelines/${documentId}`,
      { method: "GET" },
    );
    return normalizeDocument(document);
  }

  static async createDocument(
    payload: GuidelineDocumentInput,
  ): Promise<GuidelineDocumentRecord> {
    return getBackendClient().request<GuidelineDocumentRecord>(
      "/api/v2/guidelines",
      {
        method: "POST",
        body: JSON.stringify(payload),
      },
    );
  }

  static async updateDocument(
    documentId: string,
    payload: GuidelineDocumentInput,
  ): Promise<GuidelineDocumentRecord> {
    return getBackendClient().request<GuidelineDocumentRecord>(
      `/api/v2/guidelines/${documentId}`,
      {
        method: "PATCH",
        body: JSON.stringify(payload),
      },
    );
  }

  static async createVersion(
    documentId: string,
    payload: CreateGuidelineVersionInput,
  ): Promise<GuidelineVersionRecord> {
    return getBackendClient().request<GuidelineVersionRecord>(
      `/api/v2/guidelines/${documentId}/versions`,
      {
        method: "POST",
        body: JSON.stringify(payload),
      },
    );
  }

  static async uploadVersionSource(
    versionId: string,
    file: File,
  ): Promise<IngestionJobRecord> {
    const formData = new FormData();
    formData.append("file", file);
    return getBackendClient().request<IngestionJobRecord>(
      `/api/v2/guideline-versions/${versionId}/upload`,
      {
        method: "POST",
        body: formData,
      },
    );
  }

  static async uploadVersionPdf(
    versionId: string,
    file: File,
  ): Promise<IngestionJobRecord> {
    return this.uploadVersionSource(versionId, file);
  }

  static async publishVersion(
    versionId: string,
  ): Promise<{ published: boolean }> {
    return getBackendClient().request<{ published: boolean }>(
      `/api/v2/guideline-versions/${versionId}/publish`,
      { method: "POST" },
    );
  }

  static async createNotificationCampaign(
    documentId: string,
    payload: GuidelineNotificationCampaignInput,
  ): Promise<{ id: string; status: "draft"; name: string }> {
    return getBackendClient().request<{
      id: string;
      status: "draft";
      name: string;
    }>(`/api/v2/guidelines/${documentId}/notification-campaign`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async getReviewWorkspace(
    versionId: string,
  ): Promise<GuidelineReviewWorkspace> {
    const workspace = await getBackendClient().request<GuidelineReviewWorkspace>(
      `/api/v2/guideline-versions/${versionId}/review`,
      { method: "GET" },
    );
    // Be defensive around historical API rows whose JSON arrays may have been
    // persisted as null. One nullable advisory field must not take down the
    // complete editorial workspace.
    return {
      ...workspace,
      sections: Array.isArray(workspace.sections) ? workspace.sections : [],
      blocks: Array.isArray(workspace.blocks) ? workspace.blocks : [],
      assets: Array.isArray(workspace.assets) ? workspace.assets : [],
      extraction_warnings: Array.isArray(workspace.extraction_warnings)
        ? workspace.extraction_warnings
        : [],
      validation: {
        valid: Boolean(workspace.validation?.valid),
        errors: Array.isArray(workspace.validation?.errors)
          ? workspace.validation.errors
          : [],
        warnings: Array.isArray(workspace.validation?.warnings)
          ? workspace.validation.warnings
          : [],
      },
      block_review_policy: workspace.block_review_policy
        ? {
            high_risk_types: Array.isArray(
              workspace.block_review_policy.high_risk_types,
            )
              ? workspace.block_review_policy.high_risk_types
              : [],
            bulk_review_eligible_types: Array.isArray(
              workspace.block_review_policy.bulk_review_eligible_types,
            )
              ? workspace.block_review_policy.bulk_review_eligible_types
              : [],
            conditional_risk_types: Array.isArray(
              workspace.block_review_policy.conditional_risk_types,
            )
              ? workspace.block_review_policy.conditional_risk_types
              : [],
            ineligible_bulk_types: Array.isArray(
              workspace.block_review_policy.ineligible_bulk_types,
            )
              ? workspace.block_review_policy.ineligible_bulk_types
              : [],
          }
        : undefined,
    };
  }

  static async getReviewBlocks(
    versionId: string,
    filters: GuidelineReviewBlocksFilter,
  ): Promise<GuidelineReviewBlocksPage> {
    return getBackendClient().request<GuidelineReviewBlocksPage>(
      `/api/v2/guideline-versions/${versionId}/review-blocks`,
      {
        method: "GET",
        query: {
          page: filters.page,
          per_page: filters.per_page,
          status: filters.status,
          risk: filters.risk,
          block_type: filters.block_type,
          section_id: filters.section_id,
        },
      },
    );
  }

  static async bulkReviewBlocks(
    versionId: string,
    payload: {
      block_ids: string[];
      status: "reviewed";
      confirmation: string;
      expected_markdown_revision_id: string;
      expected_regeneration_job_id: string;
    },
  ): Promise<GuidelineBulkReviewResult> {
    return getBackendClient().request<GuidelineBulkReviewResult>(
      `/api/v2/guideline-versions/${versionId}/blocks/bulk-review`,
      { method: "POST", body: JSON.stringify(payload) },
    );
  }

  static async validatePublication(
    versionId: string,
  ): Promise<GuidelinePublicationValidation> {
    return getBackendClient().request<GuidelinePublicationValidation>(
      `/api/v2/guideline-versions/${versionId}/validate-publication`,
      { method: "POST" },
    );
  }

  static async getCompletenessReport(
    versionId: string,
  ): Promise<GuidelineCompletenessReport> {
    return getBackendClient().request<GuidelineCompletenessReport>(
      `/api/v2/guideline-versions/${versionId}/completeness-report`,
      { method: "GET" },
    );
  }

  static async downloadCompletenessReport(
    versionId: string,
    format: "json" | "csv",
  ): Promise<void> {
    const blob = await getBackendClient().request<Blob>(
      `/api/v2/guideline-versions/${versionId}/completeness-report/export`,
      { method: "GET", query: { format }, responseType: "blob" },
    );
    downloadBlob(blob, `guideline-completeness-${versionId}.${format}`);
  }

  static async updateReviewSection(
    versionId: string,
    sectionId: string,
    payload: UpdateGuidelineSectionInput,
  ): Promise<GuidelineSectionRecord> {
    return getBackendClient().request<GuidelineSectionRecord>(
      `/api/v2/guideline-versions/${versionId}/sections/${sectionId}`,
      { method: "PATCH", body: JSON.stringify(payload) },
    );
  }

  static async reorderReviewSections(
    versionId: string,
    sections: Array<{
      id: string;
      parent_id?: string | null;
      level: number;
      sort_order: number;
    }>,
  ): Promise<{ updated: boolean }> {
    return getBackendClient().request<{ updated: boolean }>(
      `/api/v2/guideline-versions/${versionId}/sections/reorder`,
      { method: "PUT", body: JSON.stringify({ sections }) },
    );
  }

  static async splitReviewSection(
    versionId: string,
    sectionId: string,
    payload: { block_id: string; title: string; slug?: string; level?: number },
  ): Promise<GuidelineSectionRecord> {
    return getBackendClient().request<GuidelineSectionRecord>(
      `/api/v2/guideline-versions/${versionId}/sections/${sectionId}/split`,
      { method: "POST", body: JSON.stringify(payload) },
    );
  }

  static async mergeReviewSection(
    versionId: string,
    sectionId: string,
    targetSectionId: string,
  ): Promise<{ updated: boolean }> {
    return getBackendClient().request<{ updated: boolean }>(
      `/api/v2/guideline-versions/${versionId}/sections/${sectionId}/merge`,
      {
        method: "POST",
        body: JSON.stringify({ target_section_id: targetSectionId }),
      },
    );
  }

  static async updateReviewBlock(
    versionId: string,
    blockId: string,
    payload: UpdateGuidelineBlockInput,
  ): Promise<GuidelineContentBlockRecord> {
    return getBackendClient().request<GuidelineContentBlockRecord>(
      `/api/v2/guideline-versions/${versionId}/blocks/${blockId}`,
      { method: "PATCH", body: JSON.stringify(payload) },
    );
  }

  static async reviewBlock(
    versionId: string,
    blockId: string,
    status: "reviewed" | "rejected",
  ): Promise<GuidelineContentBlockRecord> {
    return getBackendClient().request<GuidelineContentBlockRecord>(
      `/api/v2/guideline-versions/${versionId}/blocks/${blockId}/review`,
      { method: "POST", body: JSON.stringify({ status }) },
    );
  }

  static async deleteReviewBlock(
    versionId: string,
    blockId: string,
  ): Promise<void> {
    await getBackendClient().request<void>(
      `/api/v2/guideline-versions/${versionId}/blocks/${blockId}`,
      { method: "DELETE" },
    );
  }

  static async getOriginalPdf(versionId: string): Promise<Blob> {
    return getBackendClient().request<Blob>(
      `/api/v2/guideline-versions/${versionId}/extracted/original`,
      { method: "GET", responseType: "blob" },
    );
  }

  static async getReviewAsset(
    versionId: string,
    assetId: string,
  ): Promise<Blob> {
    return getBackendClient().request<Blob>(
      `/api/v2/guideline-versions/${versionId}/assets/${assetId}/content`,
      { method: "GET", responseType: "blob" },
    );
  }

  static async listSections(
    versionId: string,
  ): Promise<GuidelineSectionRecord[]> {
    const first = await getBackendClient().request<GuidelineSectionsPage>(
      `/api/v2/guideline-versions/${versionId}/sections`,
      { method: "GET", query: { page: 1, per_page: 500 } },
    );
    const sections = [...(first.items || [])];
    for (let page = 2; page <= first.total_pages; page += 1) {
      const next = await getBackendClient().request<GuidelineSectionsPage>(
        `/api/v2/guideline-versions/${versionId}/sections`,
        { method: "GET", query: { page, per_page: 500 } },
      );
      sections.push(...(next.items || []));
    }
    return sections.sort((left, right) => left.sort_order - right.sort_order);
  }

  static async getExtractedMarkdown(versionId: string): Promise<string> {
    return getBackendClient().request<string>(
      `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
      {
        method: "GET",
        responseType: "text",
      },
    );
  }

  static async updateExtractedMarkdown(
    versionId: string,
    content: string,
  ): Promise<{ updated: boolean; size: number }> {
    return getBackendClient().request<{ updated: boolean; size: number }>(
      `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
      {
        method: "PUT",
        headers: { "Content-Type": "text/markdown; charset=utf-8" },
        body: content,
      },
    );
  }

  static async downloadExtractedAsset(
    versionId: string,
    format: "md" | "html",
    filename: string,
  ): Promise<void> {
    const blob = await getBackendClient().request<Blob>(
      `/api/v2/guideline-versions/${versionId}/extracted/${format}`,
      { method: "GET", responseType: "blob" },
    );
    downloadBlob(blob, filename);
  }
}
