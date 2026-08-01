"use client"

import { getBackendClient } from "@/lib/backend-client"
import type { DomainPageQuery, DomainPageResult } from "@/types/data-table"
import type { Consultant } from "@/app/(dashboard)/consultants/columns"

type ConsultantEnvelope = { item: Record<string, unknown> }
type ConsultantPageEnvelope = {
  items: Record<string, unknown>[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export type ConsultantWrite = Partial<Consultant> & Record<string, unknown>

const backend = () => getBackendClient()

function assetPath(value: unknown): string | undefined {
  if (typeof value === "string") return value || undefined
  if (!value || typeof value !== "object") return undefined
  const asset = value as Record<string, unknown>
  const path = asset.path ?? asset.url ?? asset.name
  return typeof path === "string" && path ? path : undefined
}

function normalized(raw: Record<string, unknown>): Consultant {
  const user = raw.user as Record<string, unknown> | undefined
  return {
    ...raw,
    id: String(raw.id),
    name: String(raw.name ?? ""),
    email: String(raw.email ?? ""),
    phone: String(raw.phone ?? ""),
    alternativePhone: raw.alternative_phone as string | undefined,
    profilePicture: assetPath(raw.profile_picture),
    avatar: assetPath(raw.avatar),
    specialty: String(raw.specialty ?? ""),
    licenseNumber: raw.license_number as string | undefined,
    yearsOfExperience: raw.years_of_experience as number | undefined,
    qualifications: (raw.qualifications as string[] | undefined) ?? [],
    certifications: raw.certifications as string | undefined,
    address: raw.address as string | undefined,
    city: raw.city as string | undefined,
    region: raw.region as string | undefined,
    country: String(raw.country ?? ""),
    postalCode: raw.postal_code as string | undefined,
    organization: raw.organization as string | undefined,
    department: raw.department as string | undefined,
    preferredLanguage: raw.preferred_language as string | undefined,
    timezone: raw.timezone as string | undefined,
    availability: raw.availability as Record<string, unknown> | undefined,
    consultationTypes: (raw.consultation_types as string[] | undefined) ?? [],
    status: raw.status as Consultant["status"],
    isVerified: Boolean(raw.is_verified),
    rating: raw.rating as number | undefined,
    totalConsultations: raw.total_consultations as number | undefined,
    notes: raw.notes as string | undefined,
    created: String(raw.created_at ?? ""),
    updated: String(raw.updated_at ?? ""),
    user: user?.id ? String(user.id) : undefined,
  } as Consultant
}

function payload(data: ConsultantWrite) {
  const aliases: Record<string, string> = {
    alternativePhone: "alternative_phone", profilePicture: "profile_picture",
    licenseNumber: "license_number", yearsOfExperience: "years_of_experience",
    postalCode: "postal_code", preferredLanguage: "preferred_language",
    consultationTypes: "consultation_types", isVerified: "is_verified",
    totalConsultations: "total_consultations", user: "user_id",
  }
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [aliases[key] ?? key, value]))
}

function tableFilters(filters: DomainPageQuery["filters"]) {
  const allowed = new Set(["status", "specialty", "qualification", "language", "region", "city", "consultation_type", "verified"])
  const aliases: Record<string, string> = { isVerified: "verified", preferredLanguage: "language", consultationTypes: "consultation_type" }
  const query: Record<string, string | boolean> = {}
  for (const filter of filters ?? []) {
    const field = aliases[filter.field] ?? filter.field
    if (filter.condition === "equals" && allowed.has(field) && filter.value !== undefined) query[field] = String(filter.value)
  }
  return query
}

export const consultantService = {
  async list(params: Record<string, string | number | boolean | undefined> = {}) {
    const result = await backend().request<ConsultantPageEnvelope>("/api/v2/consultants", { query: params })
    return { ...result, items: result.items.map(normalized) }
  },

  async loadPage(query: DomainPageQuery): Promise<DomainPageResult<Consultant>> {
    const result = await consultantService.list({
      page: query.page, per_page: query.perPage, search: query.search,
      sort: "created_at", order: "desc", ...tableFilters(query.filters),
    })
    return { items: result.items, page: result.page, perPage: result.per_page, totalItems: result.total_items, totalPages: result.total_pages }
  },

  async get(id: string) {
    const result = await backend().request<ConsultantEnvelope>(`/api/v2/consultants/${id}`)
    return normalized(result.item)
  },

  async create(data: ConsultantWrite) {
    const result = await backend().request<ConsultantEnvelope>("/api/v2/consultants", { method: "POST", body: JSON.stringify(payload(data)) })
    return normalized(result.item)
  },

  async update(id: string, data: ConsultantWrite) {
    const result = await backend().request<ConsultantEnvelope>(`/api/v2/consultants/${id}`, { method: "PATCH", body: JSON.stringify(payload(data)) })
    return normalized(result.item)
  },

  delete(id: string) {
    return backend().request<void>(`/api/v2/consultants/${id}`, { method: "DELETE" })
  },
}
