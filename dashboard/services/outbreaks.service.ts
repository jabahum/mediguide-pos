"use client";

import { getBackendClient } from "@/lib/backend-client";
import type {
  ServicesChildContentInput,
  ServicesOutbreakAdminDTO,
  ServicesOutbreakInput,
  ServicesOutbreakNotificationCampaignInput,
  ServicesOutbreakMetric,
  ServicesOutbreakDocumentAdminDTO,
  ServicesOutbreakDocumentInput,
  ServicesOutbreakResourceAdminDTO,
  ServicesOutbreakUpdateAdminDTO,
  ServicesSituationReportAdminDTO,
  ServicesSituationReportAssetDTO,
  ServicesSituationReportInput,
  ServicesTransitionInput,
  ServicesNotificationCampaignDTO,
  ServicesPublicGuideline,
  ServicesPublicOutbreakDocumentContent,
} from "@/types/generated/backend-openapi";

export type OutbreakRecord = ServicesOutbreakAdminDTO;
export type OutbreakUpdateRecord = ServicesOutbreakUpdateAdminDTO;
export type OutbreakResourceRecord = ServicesOutbreakResourceAdminDTO;
export type SituationReportRecord = ServicesSituationReportAdminDTO;
export type OutbreakInput = ServicesOutbreakInput;
export type SituationReportInput = ServicesSituationReportInput;
export type ChildContentInput = ServicesChildContentInput;
export type OutbreakCampaignInput = ServicesOutbreakNotificationCampaignInput;
export type OutbreakMetric = ServicesOutbreakMetric;
export type OutbreakDocumentRecord = ServicesOutbreakDocumentAdminDTO;
export type OutbreakDocumentInput = ServicesOutbreakDocumentInput;
export type PublishedGuidelineRecord = ServicesPublicGuideline;
export type OutbreakDocumentContent = ServicesPublicOutbreakDocumentContent;

export interface PagedResult<T> {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}
export interface OutbreakAuditRecord {
  id: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface OutbreakListQuery {
  page?: number;
  per_page?: number;
  search?: string;
  status?: string;
  disease?: string;
  area?: string;
  region_id?: string;
  visual_tone?: string;
  outbreak_id?: string;
  effective_from?: string;
  effective_to?: string;
  updated_from?: string;
  updated_to?: string;
  sort?: string;
  order?: "asc" | "desc";
}

export interface OutbreakDocumentQuery {
  page?: number;
  per_page?: number;
  search?: string;
  document_kind?: string;
  issuing_authority?: string;
  language?: string;
  audience?: string;
  status?: string;
  effective_from?: string;
  effective_to?: string;
  sort?: string;
  order?: "asc" | "desc";
}

const client = () => getBackendClient();

function transition(path: string, input: ServicesTransitionInput) {
  return client().send(path, { method: "POST", body: JSON.stringify(input) });
}

export const outbreaksService = {
  list(query: OutbreakListQuery = {}) {
    return client().send<PagedResult<OutbreakRecord>>("/api/v2/outbreaks", {
      query: { ...query },
    });
  },
  listPublishedGuidelines(search = "") {
    return client().send<PagedResult<PublishedGuidelineRecord>>(
      "/api/public/guidelines",
      { query: { search, page: 1, per_page: 100 } },
    );
  },
  get(id: string) {
    return client().send<OutbreakRecord>(`/api/v2/outbreaks/${id}`);
  },
  create(input: OutbreakInput) {
    return client().send<OutbreakRecord>("/api/v2/outbreaks", {
      method: "POST",
      body: JSON.stringify(input),
    });
  },
  update(id: string, input: OutbreakInput) {
    return client().send<OutbreakRecord>(`/api/v2/outbreaks/${id}`, {
      method: "PATCH",
      body: JSON.stringify(input),
    });
  },
  remove(id: string, lockVersion: number) {
    return client().send<void>(`/api/v2/outbreaks/${id}`, {
      method: "DELETE",
      query: { lock_version: lockVersion },
    });
  },
  transition(
    id: string,
    action: "submit" | "approve" | "publish" | "withdraw",
    input: ServicesTransitionInput,
  ) {
    return transition(
      `/api/v2/outbreaks/${id}/${action}`,
      input,
    ) as Promise<OutbreakRecord>;
  },
  correct(id: string, input: ServicesTransitionInput) {
    return transition(
      `/api/v2/outbreaks/${id}/correct`,
      input,
    ) as Promise<OutbreakRecord>;
  },
  listUpdates(id: string, page = 1) {
    return client().send<PagedResult<OutbreakUpdateRecord>>(
      `/api/v2/outbreaks/${id}/updates`,
      { query: { page, per_page: 100 } },
    );
  },
  createUpdate(id: string, input: ChildContentInput) {
    return client().send<OutbreakUpdateRecord>(
      `/api/v2/outbreaks/${id}/updates`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  updateUpdate(id: string, childId: string, input: ChildContentInput) {
    return client().send<OutbreakUpdateRecord>(
      `/api/v2/outbreaks/${id}/updates/${childId}`,
      { method: "PATCH", body: JSON.stringify(input) },
    );
  },
  transitionUpdate(
    id: string,
    childId: string,
    action: "submit" | "approve" | "publish" | "withdraw",
    input: ServicesTransitionInput,
  ) {
    return transition(
      `/api/v2/outbreaks/${id}/updates/${childId}/${action}`,
      input,
    ) as Promise<OutbreakUpdateRecord>;
  },
  correctUpdate(id: string, childId: string, input: ServicesTransitionInput) {
    return transition(
      `/api/v2/outbreaks/${id}/updates/${childId}/correct`,
      input,
    ) as Promise<OutbreakUpdateRecord>;
  },
  listResources(id: string, page = 1) {
    return client().send<PagedResult<OutbreakResourceRecord>>(
      `/api/v2/outbreaks/${id}/resources`,
      { query: { page, per_page: 100 } },
    );
  },
  createResource(id: string, input: ChildContentInput) {
    return client().send<OutbreakResourceRecord>(
      `/api/v2/outbreaks/${id}/resources`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  updateResource(id: string, childId: string, input: ChildContentInput) {
    return client().send<OutbreakResourceRecord>(
      `/api/v2/outbreaks/${id}/resources/${childId}`,
      { method: "PATCH", body: JSON.stringify(input) },
    );
  },
  transitionResource(
    id: string,
    childId: string,
    action: "submit" | "approve" | "publish" | "withdraw",
    input: ServicesTransitionInput,
  ) {
    return transition(
      `/api/v2/outbreaks/${id}/resources/${childId}/${action}`,
      input,
    ) as Promise<OutbreakResourceRecord>;
  },
  correctResource(id: string, childId: string, input: ServicesTransitionInput) {
    return transition(
      `/api/v2/outbreaks/${id}/resources/${childId}/correct`,
      input,
    ) as Promise<OutbreakResourceRecord>;
  },
  listDocuments(id: string, query: OutbreakDocumentQuery = {}) {
    return client().send<PagedResult<OutbreakDocumentRecord>>(
      `/api/v2/outbreaks/${id}/documents`,
      { query: { page: 1, per_page: 100, ...query } },
    );
  },
  createDocument(id: string, input: OutbreakDocumentInput) {
    return client().send<OutbreakDocumentRecord>(
      `/api/v2/outbreaks/${id}/documents`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  updateDocument(id: string, documentId: string, input: OutbreakDocumentInput) {
    return client().send<OutbreakDocumentRecord>(
      `/api/v2/outbreaks/${id}/documents/${documentId}`,
      { method: "PATCH", body: JSON.stringify(input) },
    );
  },
  removeDocument(id: string, documentId: string, lockVersion: number) {
    return client().send<void>(
      `/api/v2/outbreaks/${id}/documents/${documentId}`,
      { method: "DELETE", query: { lock_version: lockVersion } },
    );
  },
  uploadDocument(id: string, documentId: string, lockVersion: number, file: File) {
    const body = new FormData();
    body.append("file", file);
    return client().send<OutbreakDocumentRecord>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/file`,
      { method: "PUT", query: { lock_version: lockVersion }, body },
    );
  },
  documentContent(id: string, documentId: string) {
    return client().send<OutbreakDocumentContent>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/content`,
    );
  },
  reprocessDocument(id: string, documentId: string, lockVersion: number) {
    return client().send<OutbreakDocumentRecord>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/reprocess`,
      { method: "POST", body: JSON.stringify({ lock_version: lockVersion }) },
    );
  },
  transitionDocument(
    id: string,
    documentId: string,
    action: "submit" | "approve" | "publish" | "withdraw",
    input: ServicesTransitionInput,
  ) {
    return transition(
      `/api/v2/outbreaks/${id}/documents/${documentId}/${action}`,
      input,
    ) as Promise<OutbreakDocumentRecord>;
  },
  correctDocument(id: string, documentId: string, input: ServicesTransitionInput) {
    return client().send<OutbreakDocumentRecord>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/corrections`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  documentVersions(id: string, documentId: string) {
    return client().send<OutbreakDocumentRecord[]>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/versions`,
    );
  },
  documentAudit(id: string, documentId: string) {
    return client().send<PagedResult<OutbreakAuditRecord>>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/audit`,
      { query: { page: 1, per_page: 100 } },
    );
  },
  addDocumentReviewComment(id: string, documentId: string, comment: string) {
    return client().send<void>(
      `/api/v2/outbreaks/${id}/documents/${documentId}/review-comments`,
      { method: "POST", body: JSON.stringify({ comment }) },
    );
  },
  createCampaign(id: string, input: OutbreakCampaignInput) {
    return client().send<ServicesNotificationCampaignDTO>(
      `/api/v2/outbreaks/${id}/notification-campaign`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  audit(id: string) {
    return client().send<PagedResult<OutbreakAuditRecord>>(
      `/api/v2/outbreaks/${id}/audit`,
      { query: { page: 1, per_page: 50 } },
    );
  },
  addReviewComment(id: string, comment: string) {
    return client().send<void>(`/api/v2/outbreaks/${id}/review-comments`, {
      method: "POST",
      body: JSON.stringify({ comment }),
    });
  },
};

export const situationReportsService = {
  list(query: OutbreakListQuery = {}) {
    return client().send<PagedResult<SituationReportRecord>>(
      "/api/v2/situation-reports",
      { query: { ...query } },
    );
  },
  get(id: string) {
    return client().send<SituationReportRecord>(
      `/api/v2/situation-reports/${id}`,
    );
  },
  create(input: SituationReportInput) {
    return client().send<SituationReportRecord>("/api/v2/situation-reports", {
      method: "POST",
      body: JSON.stringify(input),
    });
  },
  update(id: string, input: SituationReportInput) {
    return client().send<SituationReportRecord>(
      `/api/v2/situation-reports/${id}`,
      { method: "PATCH", body: JSON.stringify(input) },
    );
  },
  remove(id: string, lockVersion: number) {
    return client().send<void>(`/api/v2/situation-reports/${id}`, {
      method: "DELETE",
      query: { lock_version: lockVersion },
    });
  },
  transition(
    id: string,
    action: "submit" | "approve" | "publish" | "withdraw",
    input: ServicesTransitionInput,
  ) {
    return transition(
      `/api/v2/situation-reports/${id}/${action}`,
      input,
    ) as Promise<SituationReportRecord>;
  },
  correct(id: string, input: ServicesTransitionInput) {
    return transition(
      `/api/v2/situation-reports/${id}/correct`,
      input,
    ) as Promise<SituationReportRecord>;
  },
  uploadAsset(id: string, file: File) {
    const body = new FormData();
    body.append("file", file);
    return client().send<ServicesSituationReportAssetDTO>(
      `/api/v2/situation-reports/${id}/asset`,
      { method: "POST", body },
    );
  },
  createCampaign(id: string, input: OutbreakCampaignInput) {
    return client().send<ServicesNotificationCampaignDTO>(
      `/api/v2/situation-reports/${id}/notification-campaign`,
      { method: "POST", body: JSON.stringify(input) },
    );
  },
  audit(id: string) {
    return client().send<PagedResult<OutbreakAuditRecord>>(
      `/api/v2/situation-reports/${id}/audit`,
      { query: { page: 1, per_page: 50 } },
    );
  },
  addReviewComment(id: string, comment: string) {
    return client().send<void>(
      `/api/v2/situation-reports/${id}/review-comments`,
      { method: "POST", body: JSON.stringify({ comment }) },
    );
  },
};
