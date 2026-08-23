import { backendClient } from "@/lib/backend-client";
import type {
  DrugCategoriesResponse,
  DrugClassesResponse,
  DrugsResponse,
  DrugTagsResponse,
  TherapeuticCategoriesResponse,
} from "@/types/backend-types";
import type {
  ModelsDrug,
  ModelsDrugCategory,
  ModelsDrugClass,
  ModelsDrugTag,
  ModelsTherapeuticCategory,
  ServicesDrugCategoryInput,
  ServicesDrugInput,
  ServicesDrugNamedReferenceInput,
  ServicesDrugTagInput,
} from "@/types/generated/backend-openapi";
import type { DomainPageQuery, DomainPageResult } from "@/types/data-table";

interface Page<T> {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}
type JsonInput = Record<string, unknown>;
export type DrugRecord = DrugsResponse<{
  categories: DrugCategoriesResponse[];
  tags: DrugTagsResponse[];
  drug_class: DrugClassesResponse;
  therapeutic_category: TherapeuticCategoriesResponse;
}>;
export type DrugCategoryRecord = DrugCategoriesResponse<{
  parent_category: DrugCategoriesResponse;
}>;

const base = (
  value: { id?: string; created_at?: string; updated_at?: string },
  collection: string,
) => ({
  id: value.id || "",
  created: value.created_at || "",
  updated: value.updated_at || "",
  collectionId: collection,
  collectionName: collection,
});
const normalizeCategory = (v: ModelsDrugCategory) =>
  ({
    ...v,
    ...base(v, "drug_categories"),
    parent_category: v.parent_category_id || "",
    expand: {},
  }) as unknown as DrugCategoryRecord;
const normalizeTag = (v: ModelsDrugTag) =>
  ({ ...v, ...base(v, "drug_tags") }) as DrugTagsResponse;
const normalizeClass = (v: ModelsDrugClass) =>
  ({ ...v, ...base(v, "drug_classes") }) as DrugClassesResponse;
const normalizeTherapeutic = (v: ModelsTherapeuticCategory) =>
  ({
    ...v,
    ...base(v, "therapeutic_categories"),
  }) as TherapeuticCategoriesResponse;
const normalizeDrug = (v: ModelsDrug): DrugRecord =>
  ({
    ...v,
    ...base(v, "drugs"),
    categories: v.categories_json || [],
    tags: v.tags_json || [],
    drug_class: v.drug_class_id || "",
    therapeutic_category: v.therapeutic_category_id || "",
    references: v.reference_text || "",
    usageCount: v.usage_count || 0,
    expand: {
      categories: [],
      tags: [],
      drug_class: { id: v.drug_class_id || "", name: v.drug_class_name || "" },
      therapeutic_category: {
        id: v.therapeutic_category_id || "",
        name: v.therapeutic_category_name || "",
      },
    },
  }) as unknown as DrugRecord;

const drugPayload = (v: JsonInput): ServicesDrugInput => {
  const allowed = [
    "name",
    "description",
    "brand_names",
    "adult_dose",
    "pediatric_dose",
    "elderly_dose",
    "frequency",
    "duration",
    "max_daily_dose",
    "route_of_administration",
    "pregnancy_category",
    "controlled_substance",
    "who_eml_status",
    "antimicrobial_status",
    "mechanism_of_action",
    "indications",
    "contraindications",
    "side_effects",
    "warnings",
    "monitoring_parameters",
    "clinical_notes",
    "search_keywords",
    "status",
    "review_status",
  ] as const;
  const payload: Record<string, unknown> = {};
  for (const key of allowed) if (v[key] !== undefined) payload[key] = v[key];
  payload.categories =
    (v.categories as string[] | undefined) ||
    (v.categories_json as string[] | undefined);
  payload.tags =
    (v.tags as string[] | undefined) || (v.tags_json as string[] | undefined);
  payload.drug_class_id =
    (v.drug_class_id as string | undefined) ||
    (v.drug_class as string | undefined);
  payload.therapeutic_category_id =
    (v.therapeutic_category_id as string | undefined) ||
    (v.therapeutic_category as string | undefined);
  payload.reference_text =
    (v.reference_text as string | undefined) ||
    (v.references as string | undefined);
  return payload as ServicesDrugInput;
};

const categoryPayload = (data: JsonInput): ServicesDrugCategoryInput => ({
  name: data.name as string | undefined,
  description: data.description as string | undefined,
  color: data.color as string | undefined,
  icon: data.icon as string | undefined,
  sort_order: data.sort_order as number | undefined,
  status: data.status as string | undefined,
  parent_category_id:
    (data.parent_category_id as string | undefined) ||
    (Array.isArray(data.parent_category)
      ? (data.parent_category[0] as string | undefined)
      : (data.parent_category as string | undefined)),
});

async function list<T>(path: string, query: Record<string, unknown> = {}) {
  return backendClient.send<Page<T>>(path, {
    query: { page: 1, per_page: 100, ...query },
  });
}
const table =
  <TWire, TRecord>(
    fetcher: (q: Record<string, unknown>) => Promise<Page<TWire>>,
    normalize: (v: TWire) => TRecord,
  ) =>
  async (q: DomainPageQuery): Promise<DomainPageResult<TRecord>> => {
    const r = await fetcher({
      page: q.page,
      per_page: q.perPage,
      search: q.search || undefined,
    });
    return {
      items: r.items.map(normalize),
      page: r.page,
      perPage: r.per_page,
      totalItems: r.total_items,
      totalPages: r.total_pages,
    };
  };

async function hydrateDrugRelations(
  records: DrugRecord[],
): Promise<DrugRecord[]> {
  const [categories, tags] = await Promise.all([
    list<ModelsDrugCategory>("/api/v2/drug-categories", { per_page: 100 }),
    list<ModelsDrugTag>("/api/v2/drug-tags", { per_page: 100 }),
  ]);
  const categoryIndex = new Map(
    categories.items.map((v) => [v.id, normalizeCategory(v)]),
  );
  const tagIndex = new Map(tags.items.map((v) => [v.id, normalizeTag(v)]));
  return records.map(
    (record) =>
      ({
        ...record,
        expand: {
          ...record.expand,
          categories: (record.categories || [])
            .map((id) => categoryIndex.get(id))
            .filter(Boolean),
          tags: (record.tags || [])
            .map((id) => tagIndex.get(id))
            .filter(Boolean),
        },
      }) as DrugRecord,
  );
}

export const drugService = {
  async list(query: Record<string, unknown> = {}) {
    return list<ModelsDrug>("/api/v2/drugs", query);
  },
  async listTable(query: DomainPageQuery) {
    const r = await this.list({
      page: query.page,
      per_page: query.perPage,
      search: query.search || undefined,
      sort: "name",
      order: "asc",
    });
    return {
      items: await hydrateDrugRelations(r.items.map(normalizeDrug)),
      page: r.page,
      perPage: r.per_page,
      totalItems: r.total_items,
      totalPages: r.total_pages,
    };
  },
  async get(id: string) {
    return (
      await hydrateDrugRelations([
        normalizeDrug(
          await backendClient.send<ModelsDrug>(`/api/v2/drugs/${id}`),
        ),
      ])
    )[0];
  },
  async create(data: JsonInput) {
    return normalizeDrug(
      await backendClient.send<ModelsDrug>("/api/v2/drugs", {
        method: "POST",
        body: JSON.stringify(drugPayload(data)),
      }),
    );
  },
  async update(id: string, data: JsonInput) {
    return normalizeDrug(
      await backendClient.send<ModelsDrug>(`/api/v2/drugs/${id}`, {
        method: "PATCH",
        body: JSON.stringify(drugPayload(data)),
      }),
    );
  },
  async delete(id: string) {
    await backendClient.send<void>(`/api/v2/drugs/${id}`, { method: "DELETE" });
  },
};

export const drugReferenceService = {
  async listCategories(query: Record<string, unknown> = {}) {
    return list<ModelsDrugCategory>("/api/v2/drug-categories", query);
  },
  listCategoriesTable: table(
    (q) => list<ModelsDrugCategory>("/api/v2/drug-categories", q),
    normalizeCategory,
  ),
  async allCategories() {
    return (
      await list<ModelsDrugCategory>("/api/v2/drug-categories", {
        per_page: 100,
        status: "active",
      })
    ).items.map(normalizeCategory);
  },
  async createCategory(data: JsonInput) {
    return normalizeCategory(
      await backendClient.send<ModelsDrugCategory>("/api/v2/drug-categories", {
        method: "POST",
        body: JSON.stringify(categoryPayload(data)),
      }),
    );
  },
  async updateCategory(id: string, data: JsonInput) {
    return normalizeCategory(
      await backendClient.send<ModelsDrugCategory>(
        `/api/v2/drug-categories/${id}`,
        { method: "PATCH", body: JSON.stringify(categoryPayload(data)) },
      ),
    );
  },
  async deleteCategory(id: string) {
    await backendClient.send<void>(`/api/v2/drug-categories/${id}`, {
      method: "DELETE",
    });
  },
  async listTags(query: Record<string, unknown> = {}) {
    return list<ModelsDrugTag>("/api/v2/drug-tags", query);
  },
  listTagsTable: table(
    (q) => list<ModelsDrugTag>("/api/v2/drug-tags", q),
    normalizeTag,
  ),
  async allTags() {
    return (
      await list<ModelsDrugTag>("/api/v2/drug-tags", {
        per_page: 100,
        status: "active",
      })
    ).items.map(normalizeTag);
  },
  async createTag(data: ServicesDrugTagInput) {
    return normalizeTag(
      await backendClient.send<ModelsDrugTag>("/api/v2/drug-tags", {
        method: "POST",
        body: JSON.stringify(data),
      }),
    );
  },
  async updateTag(id: string, data: ServicesDrugTagInput) {
    return normalizeTag(
      await backendClient.send<ModelsDrugTag>(`/api/v2/drug-tags/${id}`, {
        method: "PATCH",
        body: JSON.stringify(data),
      }),
    );
  },
  async deleteTag(id: string) {
    await backendClient.send<void>(`/api/v2/drug-tags/${id}`, {
      method: "DELETE",
    });
  },
  async allClasses() {
    return (
      await list<ModelsDrugClass>("/api/v2/drug-classes", {
        per_page: 100,
        status: "active",
      })
    ).items.map(normalizeClass);
  },
  async createClass(data: ServicesDrugNamedReferenceInput) {
    return normalizeClass(
      await backendClient.send<ModelsDrugClass>("/api/v2/drug-classes", {
        method: "POST",
        body: JSON.stringify(data),
      }),
    );
  },
  async allTherapeuticCategories() {
    return (
      await list<ModelsTherapeuticCategory>("/api/v2/therapeutic-categories", {
        per_page: 100,
        status: "active",
      })
    ).items.map(normalizeTherapeutic);
  },
  async createTherapeuticCategory(data: ServicesDrugNamedReferenceInput) {
    return normalizeTherapeutic(
      await backendClient.send<ModelsTherapeuticCategory>(
        "/api/v2/therapeutic-categories",
        { method: "POST", body: JSON.stringify(data) },
      ),
    );
  },
};

export const drugCategoryCrud = {
  create: drugReferenceService.createCategory.bind(drugReferenceService),
  update: drugReferenceService.updateCategory.bind(drugReferenceService),
  delete: drugReferenceService.deleteCategory.bind(drugReferenceService),
};
export const drugTagCrud = {
  create: drugReferenceService.createTag.bind(drugReferenceService),
  update: drugReferenceService.updateTag.bind(drugReferenceService),
  delete: drugReferenceService.deleteTag.bind(drugReferenceService),
};
