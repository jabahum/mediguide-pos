"use client";

import { getBackendClient } from "@/lib/backend-client";

export interface Page<T> {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}
export interface DiseaseAlias {
  id?: string;
  alias: string;
}
export interface DiseaseCode {
  id?: string;
  code_system: string;
  code: string;
  display_name?: string;
}
export interface Disease {
  id: string;
  parent_id?: string;
  parent_name?: string;
  name: string;
  slug: string;
  short_name?: string;
  description?: string;
  icon?: string;
  color?: string;
  status: string;
  sort_order: number;
  aliases: DiseaseAlias[];
  codes: DiseaseCode[];
}
export type DiseaseInput = Omit<Disease, "id" | "parent_name"> & {
  id?: string;
};
export interface OutbreakSummary {
  id: string;
  title: string;
  disease_type?: string;
  status?: string;
}
export interface ContentHub {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  color?: string;
  audience?: string;
  status: string;
  sort_order: number;
  lock_version: number;
  published_at?: string;
  diseases: Disease[];
  outbreaks: OutbreakSummary[];
}
export interface ContentPillarItem {
  id: string;
  pillar_id: string;
  content_type: string;
  content_id?: string;
  target?: string;
  label_override?: string;
  description_override?: string;
  icon_override?: string;
  sort_order: number;
  featured: boolean;
  starts_at?: string;
  ends_at?: string;
  status: string;
  lock_version: number;
}
export interface ContentPillar {
  id: string;
  hub_id: string;
  parent_id?: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  color?: string;
  sort_order: number;
  status: string;
  lock_version: number;
  items: ContentPillarItem[];
}
export interface ContentHubWorkspace {
  hub: ContentHub;
  pillars: ContentPillar[];
}
export interface HubTemplate {
  id: string;
  name: string;
  slug: string;
  description?: string;
  pillars: Array<{
    id: string;
    parent_id?: string;
    name: string;
    slug: string;
    sort_order: number;
  }>;
}
export interface AssignableResource {
  id: string;
  content_type: string;
  title: string;
  description?: string;
  status: string;
  context?: string;
}
export interface HubAudit {
  id: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  metadata: Record<string, unknown>;
  created_at: string;
}
export interface DiseaseAssignment {
  id: string;
  disease_id: string;
  content_type: string;
  content_id: string;
  is_primary: boolean;
  disease?: Disease;
}

const client = () => getBackendClient();
const json = (value: unknown) => JSON.stringify(value);

export const diseaseService = {
  list(search = "", status = "") {
    return client().send<Page<Disease>>("/api/v2/diseases", {
      query: { page: 1, per_page: 100, search, status },
    });
  },
  get(id: string) {
    return client().send<Disease>(`/api/v2/diseases/${id}`);
  },
  create(input: Partial<DiseaseInput>) {
    return client().send<Disease>("/api/v2/diseases", {
      method: "POST",
      body: json(input),
    });
  },
  update(id: string, input: Partial<DiseaseInput>) {
    return client().send<Disease>(`/api/v2/diseases/${id}`, {
      method: "PATCH",
      body: json(input),
    });
  },
  archive(id: string) {
    return client().send<void>(`/api/v2/diseases/${id}`, { method: "DELETE" });
  },
};

export const contentDiseaseService = {
  list(contentType: string, contentId: string) {
    return client().send<Page<DiseaseAssignment>>(
      "/api/v2/content-disease-assignments",
      {
        query: {
          page: 1,
          per_page: 100,
          content_type: contentType,
          content_id: contentId,
        },
      },
    );
  },
  replace(
    contentType: string,
    contentId: string,
    diseaseIds: string[],
    primaryDiseaseId?: string,
  ) {
    return client().send<DiseaseAssignment[]>(
      "/api/v2/content-disease-assignments/replace",
      {
        method: "PUT",
        body: json({
          content_type: contentType,
          content_id: contentId,
          disease_ids: diseaseIds,
          primary_disease_id: primaryDiseaseId || null,
        }),
      },
    );
  },
};

export const contentHubService = {
  list(
    query: {
      search?: string;
      status?: string;
      disease_id?: string;
      outbreak_id?: string;
    } = {},
  ) {
    return client().send<Page<ContentHub>>("/api/v2/content-hubs", {
      query: { page: 1, per_page: 100, ...query },
    });
  },
  workspace(id: string) {
    return client().send<ContentHubWorkspace>(
      `/api/v2/content-hubs/${id}/workspace`,
    );
  },
  create(
    input: Partial<ContentHub> & {
      disease_ids?: string[];
      outbreak_ids?: string[];
    },
  ) {
    return client().send<ContentHub>("/api/v2/content-hubs", {
      method: "POST",
      body: json(input),
    });
  },
  update(
    id: string,
    input: Partial<ContentHub> & {
      disease_ids?: string[];
      outbreak_ids?: string[];
      lock_version: number;
    },
  ) {
    return client().send<ContentHub>(`/api/v2/content-hubs/${id}`, {
      method: "PATCH",
      body: json(input),
    });
  },
  transition(id: string, action: "publish" | "archive", lockVersion: number) {
    return client().send<ContentHub>(`/api/v2/content-hubs/${id}/${action}`, {
      method: "POST",
      body: json({ lock_version: lockVersion }),
    });
  },
  templates() {
    return client().send<HubTemplate[]>("/api/v2/content-hub-templates");
  },
  applyTemplate(id: string, templateId: string, lockVersion: number) {
    return client().send<ContentPillar[]>(
      `/api/v2/content-hubs/${id}/apply-template`,
      {
        method: "POST",
        body: json({ template_id: templateId, lock_version: lockVersion }),
      },
    );
  },
  createPillar(id: string, input: Partial<ContentPillar>) {
    return client().send<ContentPillar>(`/api/v2/content-hubs/${id}/pillars`, {
      method: "POST",
      body: json(input),
    });
  },
  updatePillar(
    id: string,
    pillarId: string,
    input: Partial<ContentPillar> & {
      lock_version: number;
      clear_parent?: boolean;
    },
  ) {
    return client().send<ContentPillar>(
      `/api/v2/content-hubs/${id}/pillars/${pillarId}`,
      { method: "PATCH", body: json(input) },
    );
  },
  removePillar(id: string, pillar: ContentPillar) {
    return client().send<void>(
      `/api/v2/content-hubs/${id}/pillars/${pillar.id}`,
      { method: "DELETE", query: { lock_version: pillar.lock_version } },
    );
  },
  reorderPillars(id: string, pillars: ContentPillar[]) {
    return client().send(`/api/v2/content-hubs/${id}/pillars/reorder`, {
      method: "PUT",
      body: json(
        pillars.map((value, index) => ({
          id: value.id,
          sort_order: (index + 1) * 10,
          lock_version: value.lock_version,
        })),
      ),
    });
  },
  searchResources(contentType: string, search: string, outbreakId = "") {
    return client().send<Page<AssignableResource>>(
      "/api/v2/content-hub-resources",
      {
        query: {
          page: 1,
          per_page: 50,
          content_type: contentType,
          search,
          outbreak_id: outbreakId,
        },
      },
    );
  },
  createItem(id: string, pillarId: string, input: Partial<ContentPillarItem>) {
    return client().send<ContentPillarItem>(
      `/api/v2/content-hubs/${id}/pillars/${pillarId}/items`,
      { method: "POST", body: json(input) },
    );
  },
  updateItem(
    id: string,
    pillarId: string,
    itemId: string,
    input: Partial<ContentPillarItem> & { lock_version: number },
  ) {
    return client().send<ContentPillarItem>(
      `/api/v2/content-hubs/${id}/pillars/${pillarId}/items/${itemId}`,
      { method: "PATCH", body: json(input) },
    );
  },
  removeItem(id: string, pillarId: string, item: ContentPillarItem) {
    return client().send<void>(
      `/api/v2/content-hubs/${id}/pillars/${pillarId}/items/${item.id}`,
      { method: "DELETE", query: { lock_version: item.lock_version } },
    );
  },
  reorderItems(id: string, pillarId: string, items: ContentPillarItem[]) {
    return client().send(
      `/api/v2/content-hubs/${id}/pillars/${pillarId}/items/reorder`,
      {
        method: "PUT",
        body: json(
          items.map((value, index) => ({
            id: value.id,
            sort_order: (index + 1) * 10,
            lock_version: value.lock_version,
          })),
        ),
      },
    );
  },
  audit(id: string) {
    return client().send<Page<HubAudit>>(`/api/v2/content-hubs/${id}/audit`, {
      query: { page: 1, per_page: 100 },
    });
  },
  configureOutbreak(outbreakId: string, publish = false) {
    return client().send<ContentHubWorkspace>(
      `/api/v2/outbreaks/${outbreakId}/content-hub`,
      { method: "POST", body: json({ publish }) },
    );
  },
};
