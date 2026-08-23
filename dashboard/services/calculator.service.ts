import { backendClient } from "@/lib/backend-client"
import type { CalculatorsResponse, UsersResponse } from "@/types/backend-types"
import type {
  ModelsCalculator,
  ServicesCreateCalculatorInput,
  ServicesUpdateCalculatorInput,
} from "@/types/generated/backend-openapi"
import type { DomainPageQuery, DomainPageResult } from "@/types/data-table"

interface Page<T> {
  items: T[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export type CalculatorRecord = CalculatorsResponse<{addedBy:UsersResponse[]}>
export type CalculatorInput = Record<string, unknown> | FormData

function artifactPath(value: unknown): string {
  if (typeof value === "string") return value
  if (!value || typeof value !== "object") return ""
  const record = value as Record<string, unknown>
  return typeof record.path === "string"
    ? record.path
    : typeof record.name === "string"
      ? record.name
      : ""
}

function normalizeCalculator(value: ModelsCalculator): CalculatorRecord {
  return {
    ...value,
    id: value.id || "",
    name: value.name || "",
    description: value.description || "",
    version: value.version || "",
    type: value.type || "calculator",
    status: value.status || "draft",
    appFile: artifactPath(value.app_file_json),
    appFileJson: value.app_file_json,
    addedBy: value.added_by_user_id || "",
    backgroundColor: value.background_color || "",
    usageCount: value.usage_count || 0,
    created: value.created_at || "",
    updated: value.updated_at || "",
    collectionId: "calculators",
    collectionName: "calculators",
    expand: { addedBy: [] },
  } as unknown as CalculatorRecord
}

async function calculatorPayload(
  input: CalculatorInput,
  requireArtifact: boolean,
): Promise<ServicesCreateCalculatorInput | ServicesUpdateCalculatorInput> {
  const values: Record<string, unknown> = {}
  if (input instanceof FormData) {
    for (const [key, value] of input.entries()) values[key] = value
  } else {
    Object.assign(values, input)
  }

  const payload: Record<string, unknown> = {}
  const stringFields: Record<string, string> = {
    name: "name",
    description: "description",
    icon: "icon",
    color: "color",
    backgroundColor: "background_color",
    background_color: "background_color",
    version: "version",
    type: "type",
    status: "status",
  }
  for (const [source, target] of Object.entries(stringFields)) {
    if (values[source] !== undefined && values[source] !== null) {
      payload[target] = String(values[source])
    }
  }
  if (values.featured !== undefined) {
    payload.featured = values.featured === true || String(values.featured) === "true"
  }

  const artifact = values.app_file_json ?? values.appFile ?? values.app_file
  if (typeof File !== "undefined" && artifact instanceof File) {
    throw new Error("Executable clinical-tool uploads are disabled; use the schema authoring workspace")
  } else if (typeof artifact === "string" && artifact.trim()) {
    payload.app_file_json = { path: artifact.trim(), name: artifact.trim() }
  } else if (artifact && typeof artifact === "object") {
    payload.app_file_json = artifact
  } else if (requireArtifact) {
    payload.app_file_json = {}
  }
  return payload
}

export const calculatorService = {
  async list(query: {
    page?: number
    perPage?: number
    search?: string
    type?: string
    status?: string
    featured?: boolean
    sort?: string
    order?: "asc" | "desc"
  } = {}): Promise<Page<ModelsCalculator>> {
    return backendClient.send("/api/v2/calculators", {
      query: {
        page: query.page || 1,
        per_page: query.perPage || 20,
        search: query.search,
        type: query.type,
        status: query.status,
        featured: query.featured,
        sort: query.sort,
        order: query.order,
      },
    })
  },

  async listTable(query: DomainPageQuery, type?: string): Promise<DomainPageResult<CalculatorRecord>> {
    const result = await this.list({
      page: query.page,
      perPage: query.perPage,
      search: query.search,
      type,
      sort: "name",
    })
    return {
      items: result.items.map(normalizeCalculator),
      page: result.page,
      perPage: result.per_page,
      totalItems: result.total_items,
      totalPages: result.total_pages,
    }
  },

  async get(id: string): Promise<CalculatorRecord> {
    return normalizeCalculator(await backendClient.send<ModelsCalculator>(`/api/v2/calculators/${id}`))
  },

  async create(input: CalculatorInput): Promise<CalculatorRecord> {
    return normalizeCalculator(await backendClient.send<ModelsCalculator>("/api/v2/calculators", {
      method: "POST",
      body: JSON.stringify(await calculatorPayload(input, false)),
    }))
  },

  async update(id: string, input: CalculatorInput): Promise<CalculatorRecord> {
    return normalizeCalculator(await backendClient.send<ModelsCalculator>(`/api/v2/calculators/${id}`, {
      method: "PATCH",
      body: JSON.stringify(await calculatorPayload(input, false)),
    }))
  },

  async delete(id: string): Promise<void> {
    await backendClient.send<void>(`/api/v2/calculators/${id}`, { method: "DELETE" })
  },
}

export async function getCalculatorContent(id: string): Promise<string> {
  return backendClient.send<string>(`/api/v2/calculators/${id}/content`, {
    responseType: "text",
  })
}
