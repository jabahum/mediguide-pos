import { backendClient } from "@/lib/backend-client";
import type {
  AbbreviationsResponse,
  GuidelineCategoriesResponse,
  GuidelineIndexResponse,
  GuidelineTagsResponse,
  MedicalGuidelinesResponse,
} from "@/types/backend-types";
import type { DomainPageQuery, DomainPageResult } from "@/types/data-table";
import type {
  AbbreviationsWithExpanded,
  GuidelineCategoriesWithParent,
  GuidelineIndexWithExpanded,
  MedicalGuidelinesWithExpanded,
} from "@/types/expanded";
import type {
  ModelsAbbreviation,
  ModelsGuidelineCategory,
  ModelsGuidelineIndexEntry,
  ModelsGuidelineTag,
  ModelsMedicalGuideline,
  ServicesAbbreviationInput,
  ServicesGuidelineCategoryInput,
  ServicesGuidelineIndexInput,
  ServicesGuidelineTagInput,
  ServicesMedicalGuidelineInput,
} from "@/types/generated/backend-openapi";

type JsonInput = Record<string, unknown>;
interface Page<T> {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}
interface WireBase {
  id?: string;
  created_at?: string;
  updated_at?: string;
}
type WireCategory = ModelsGuidelineCategory;
type WireTag = ModelsGuidelineTag;
type WireAbbreviation = ModelsAbbreviation;
type WireIndex = ModelsGuidelineIndexEntry;
type WireGuideline = ModelsMedicalGuideline;

export type GuidelineCategoryRecord = GuidelineCategoriesWithParent;
export type GuidelineIndexRecord = GuidelineIndexWithExpanded;
export type GuidelineRecord = MedicalGuidelinesWithExpanded;

const base = (value: WireBase, collection: string) => ({
  id: value.id || "",
  created: value.created_at || "",
  updated: value.updated_at || "",
  collectionId: collection,
  collectionName: collection,
});
const normalizeCategory = (v: WireCategory): GuidelineCategoryRecord =>
  ({
    ...v,
    name: v.name || "",
    status: v.status || "inactive",
    ...base(v, "guideline_categories"),
    parent_category: v.parent_category_id || "",
    expand: {
      parent_category: {
        id: v.parent_category_id || "",
        name: v.parent_name || "",
      },
    },
  }) as unknown as GuidelineCategoryRecord;
const normalizeTag = (v: WireTag): GuidelineTagsResponse =>
  ({
    ...v,
    name: v.name || "",
    ...base(v, "guideline_tags"),
  }) as GuidelineTagsResponse;
const normalizeAbbreviation = (
  v: WireAbbreviation,
): AbbreviationsWithExpanded =>
  ({
    ...v,
    abbreviation: v.abbreviation || "",
    meaning: v.meaning || "",
    ...base(v, "abbreviations"),
    category: v.categories?.[0] || "",
    tags: v.tags || [],
    usageCount: v.usage_count || 0,
    expand: {},
  }) as unknown as AbbreviationsWithExpanded;
const normalizeIndex = (v: WireIndex): GuidelineIndexRecord =>
  ({
    ...v,
    title: v.title || "",
    ...base(v, "guideline_index"),
    parent: v.parent_id || "",
    order: v.sort_order || 0,
    hasChildren: v.has_children || false,
    expand: v.parent_id
      ? { parent: [{ id: v.parent_id, title: v.parent_title || "" }] }
      : {},
  }) as unknown as GuidelineIndexRecord;
const normalizeGuideline = (v: WireGuideline): GuidelineRecord =>
  ({
    ...v,
    condition_name: v.condition_name || "",
    ...base(v, "medical_guidelines"),
    index_item: v.index_item_id || "",
    usageCount: v.usage_count || 0,
    expand: {
      index_item: v.index_item_id
        ? { id: v.index_item_id, title: v.index_item_title || "" }
        : undefined,
      categories: [],
      tags: [],
    },
  }) as unknown as GuidelineRecord;

async function list<T>(path: string, query: Record<string, unknown> = {}) {
  return backendClient.send<Page<T>>(path, {
    query: { page: 1, per_page: 100, ...query },
  });
}
const table =
  <TWire, TRecord>(
    fetcher: (query: Record<string, unknown>) => Promise<Page<TWire>>,
    normalize: (item: TWire) => TRecord,
  ) =>
  async (query: DomainPageQuery): Promise<DomainPageResult<TRecord>> => {
    const result = await fetcher({
      page: query.page,
      per_page: query.perPage,
      search: query.search || undefined,
    });
    return {
      items: result.items.map(normalize),
      page: result.page,
      perPage: result.per_page,
      totalItems: result.total_items,
      totalPages: result.total_pages,
    };
  };
const body = (value: unknown) => JSON.stringify(value);

const categoryPayload = (data: JsonInput): ServicesGuidelineCategoryInput =>
  ({
    ...data,
    parent_category_id: data.parent_category_id ?? data.parent_category,
  }) as ServicesGuidelineCategoryInput;
const abbreviationPayload = (data: JsonInput): ServicesAbbreviationInput =>
  ({
    ...data,
    categories: data.categories ?? (data.category ? [data.category] : []),
  }) as ServicesAbbreviationInput;
const indexPayload = (data: JsonInput): ServicesGuidelineIndexInput => ({
  title: data.title as string | undefined,
  description: data.description as string | undefined,
  parent_id: (data.parent_id ?? data.parent) as string | undefined,
  sort_order: (data.sort_order ?? data.order) as number | undefined,
});
const guidelinePayload = (data: JsonInput): ServicesMedicalGuidelineInput =>
  ({
    ...data,
    index_item_id: data.index_item_id ?? data.index_item,
  }) as ServicesMedicalGuidelineInput;

export const guidelineCategoryService = {
  async list(query: Record<string, unknown> = {}) {
    return list<WireCategory>("/api/v2/guideline-categories", query);
  },
  listTable: table(
    (q) => list<WireCategory>("/api/v2/guideline-categories", q),
    normalizeCategory,
  ),
  async all(query: Record<string, unknown> = {}) {
    return (
      await this.list({
        per_page: 100,
        sort: "sort_order",
        order: "asc",
        ...query,
      })
    ).items.map(normalizeCategory);
  },
  async get(id: string) {
    return normalizeCategory(
      await backendClient.send<WireCategory>(
        `/api/v2/guideline-categories/${id}`,
      ),
    );
  },
  async create(data: JsonInput) {
    return normalizeCategory(
      await backendClient.send<WireCategory>("/api/v2/guideline-categories", {
        method: "POST",
        body: body(categoryPayload(data)),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeCategory(
      await backendClient.send<WireCategory>(
        `/api/v2/guideline-categories/${id}`,
        { method: "PATCH", body: body(categoryPayload(data)) },
      ),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/guideline-categories/${id}`, {
      method: "DELETE",
    });
  },
};
export const guidelineTagService = {
  async list(query: Record<string, unknown> = {}) {
    return list<WireTag>("/api/v2/guideline-tags", query);
  },
  listTable: table(
    (q) => list<WireTag>("/api/v2/guideline-tags", q),
    normalizeTag,
  ),
  async all(query: Record<string, unknown> = {}) {
    return (
      await this.list({ per_page: 100, sort: "name", order: "asc", ...query })
    ).items.map(normalizeTag);
  },
  async get(id: string) {
    return normalizeTag(
      await backendClient.send<WireTag>(`/api/v2/guideline-tags/${id}`),
    );
  },
  async create(data: JsonInput) {
    return normalizeTag(
      await backendClient.send<WireTag>("/api/v2/guideline-tags", {
        method: "POST",
        body: body(data),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeTag(
      await backendClient.send<WireTag>(`/api/v2/guideline-tags/${id}`, {
        method: "PATCH",
        body: body(data),
      }),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/guideline-tags/${id}`, {
      method: "DELETE",
    });
  },
};
export const abbreviationService = {
  async list(query: Record<string, unknown> = {}) {
    return list<WireAbbreviation>("/api/v2/abbreviations", query);
  },
  listTable: table(
    (q) => list<WireAbbreviation>("/api/v2/abbreviations", q),
    normalizeAbbreviation,
  ),
  async get(id: string) {
    return normalizeAbbreviation(
      await backendClient.send<WireAbbreviation>(`/api/v2/abbreviations/${id}`),
    );
  },
  async create(data: JsonInput) {
    return normalizeAbbreviation(
      await backendClient.send<WireAbbreviation>("/api/v2/abbreviations", {
        method: "POST",
        body: body(abbreviationPayload(data)),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeAbbreviation(
      await backendClient.send<WireAbbreviation>(
        `/api/v2/abbreviations/${id}`,
        { method: "PATCH", body: body(abbreviationPayload(data)) },
      ),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/abbreviations/${id}`, {
      method: "DELETE",
    });
  },
};
export const guidelineIndexService = {
  async list(query: Record<string, unknown> = {}) {
    return list<WireIndex>("/api/v2/guideline-index", query);
  },
  listTable: table(
    (q) => list<WireIndex>("/api/v2/guideline-index", q),
    normalizeIndex,
  ),
  async all(query: Record<string, unknown> = {}) {
    return (
      await this.list({
        per_page: 100,
        sort: "sort_order",
        order: "asc",
        ...query,
      })
    ).items.map(normalizeIndex);
  },
  async children(id: string, query: Record<string, unknown> = {}) {
    return (
      await list<WireIndex>(`/api/v2/guideline-index/${id}/children`, query)
    ).items.map(normalizeIndex);
  },
  async get(id: string) {
    return normalizeIndex(
      await backendClient.send<WireIndex>(`/api/v2/guideline-index/${id}`),
    );
  },
  async create(data: JsonInput) {
    return normalizeIndex(
      await backendClient.send<WireIndex>("/api/v2/guideline-index", {
        method: "POST",
        body: body(indexPayload(data)),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeIndex(
      await backendClient.send<WireIndex>(`/api/v2/guideline-index/${id}`, {
        method: "PATCH",
        body: body(indexPayload(data)),
      }),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/guideline-index/${id}`, {
      method: "DELETE",
    });
  },
};
export const medicalGuidelineService = {
  async list(query: Record<string, unknown> = {}) {
    return list<WireGuideline>("/api/v2/medical-guidelines", query);
  },
  listTable: table(
    (q) => list<WireGuideline>("/api/v2/medical-guidelines", q),
    normalizeGuideline,
  ),
  async get(id: string) {
    return normalizeGuideline(
      await backendClient.send<WireGuideline>(
        `/api/v2/medical-guidelines/${id}`,
      ),
    );
  },
  async create(data: JsonInput) {
    return normalizeGuideline(
      await backendClient.send<WireGuideline>("/api/v2/medical-guidelines", {
        method: "POST",
        body: body(guidelinePayload(data)),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeGuideline(
      await backendClient.send<WireGuideline>(
        `/api/v2/medical-guidelines/${id}`,
        { method: "PATCH", body: body(guidelinePayload(data)) },
      ),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/medical-guidelines/${id}`, {
      method: "DELETE",
    });
  },
};

export const guidelineCategoryCrud = {
  create: guidelineCategoryService.create.bind(guidelineCategoryService),
  update: guidelineCategoryService.update.bind(guidelineCategoryService),
  delete: guidelineCategoryService.delete.bind(guidelineCategoryService),
};
export const guidelineTagCrud = {
  create: guidelineTagService.create.bind(guidelineTagService),
  update: guidelineTagService.update.bind(guidelineTagService),
  delete: guidelineTagService.delete.bind(guidelineTagService),
};
export const abbreviationCrud = {
  create: abbreviationService.create.bind(abbreviationService),
  update: abbreviationService.update.bind(abbreviationService),
  delete: abbreviationService.delete.bind(abbreviationService),
};
