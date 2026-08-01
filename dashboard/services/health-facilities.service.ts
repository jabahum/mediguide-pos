"use client"

import { getBackendClient } from "@/lib/backend-client"
import {
  AuthoritiesResponse,
  CountiesResponse,
  DistrictsResponse,
  FacilityLevelsResponse,
  HealthFacilitiesResponse,
  HealthSubDistrictsResponse,
  HealthSubRegionsResponse,
  OwnershipTypesResponse,
  ParishesResponse,
  RegionsResponse,
  SubcountiesResponse,
} from "@/types/backend-types"
import {
  AuthoritiesWithOwnershipType,
  CountiesWithDistrict,
  DistrictsWithExpanded,
  HealthSubRegionsWithRegion,
  ParishesWithSubcounty,
  SubcountiesWithExpanded,
} from "@/types/expanded"

type FacilityListParams = {
  page?: number
  perPage?: number
  search?: string
  regionId?: string
  districtId?: string
  countyId?: string
  subcountyId?: string
  parishId?: string
  facilityLevelId?: string
  ownershipTypeId?: string
  authorityId?: string
}

type ListResult<T> = {
  success: boolean
  resource: string
  page: number
  per_page: number
  total_items: number
  total_pages?: number
  items: T[]
}

type ItemResult<T> = { success: boolean; resource: string; item: T }

type TableListParams = {
  page: number
  perPage: number
  search: string
  filters?: Array<{ field: string; condition: string; value: unknown }>
}

const backend = () => getBackendClient()

function listQuery(params: FacilityListParams) {
  return {
    page: params.page ?? 1,
    per_page: params.perPage ?? 50,
    search: params.search,
    region_id: params.regionId,
    district_id: params.districtId,
    county_id: params.countyId,
    subcounty_id: params.subcountyId,
    parish_id: params.parishId,
    facility_level_id: params.facilityLevelId,
    ownership_type_id: params.ownershipTypeId,
    authority_id: params.authorityId,
  }
}

async function listResource<T>(path: string, params: Record<string, string | number | undefined> = {}) {
  const result = await backend().request<ListResult<T>>(path, { query: params })
  return result.items.map((item) => normalizeRecord<T>(item))
}

async function tableResource<T>(
  path: string,
  params: TableListParams,
  transform: (item: Record<string, unknown>) => T = normalizeRecord<T>,
  extraQuery: Record<string, string | number | undefined> = {},
) {
  const result = await backend().request<ListResult<Record<string, unknown>>>(path, {
    query: { page: params.page, per_page: params.perPage, search: params.search, ...extraQuery },
  })
  return {
    items: result.items.map(transform),
    page: result.page,
    perPage: result.per_page,
    totalItems: result.total_items,
    totalPages: result.total_pages ?? Math.ceil(result.total_items / result.per_page),
  }
}

function normalizeRecord<T>(value: unknown): T {
  const raw = value as Record<string, unknown>
  return {
    ...raw,
    created: raw.created ?? raw.created_at ?? "",
    updated: raw.updated ?? raw.updated_at ?? "",
    region: raw.region ?? raw.region_id ?? "",
    health_sub_region: raw.health_sub_region ?? raw.health_sub_region_id ?? "",
    district: raw.district ?? raw.district_id ?? "",
    county: raw.county ?? raw.county_id ?? "",
    subcounty: raw.subcounty ?? raw.subcounty_id ?? "",
    ownership_type: raw.ownership_type ?? raw.ownership_type_id ?? "",
  } as T
}

function related(id: unknown, name: unknown, code?: unknown) {
  if (!id && !name && !code) return undefined
  return {
    id: String(id ?? ""),
    name: String(name ?? ""),
    ...(code == null || code === "" ? {} : { code: String(code) }),
  }
}

function facilityFilters(filters: TableListParams["filters"]) {
  const allowed = new Set([
    "region_id", "health_sub_region_id", "district_id", "health_sub_district_id",
    "county_id", "subcounty_id", "parish_id", "facility_level_id",
    "ownership_type_id", "authority_id",
  ])
  const query: Record<string, string> = {}
  for (const filter of filters ?? []) {
    if (filter.condition === "equals" && allowed.has(filter.field) && filter.value != null) {
      query[filter.field] = String(filter.value)
    }
  }
  return query
}

export const healthFacilitiesService = {
  listFacilityTable<T extends HealthFacilitiesResponse>(params: TableListParams) {
    return tableResource<T>("/api/v2/facilities", params, (raw) => ({
      ...normalizeRecord<HealthFacilitiesResponse>(raw),
      expand: {
        facility_level: related(raw.facility_level_id, raw.facility_level_name, raw.facility_level_code),
        authority: related(raw.authority_id, raw.authority_name, raw.authority_code),
        ownership_type: related(raw.ownership_type_id, raw.ownership_type_name, raw.ownership_type_code),
        region: related(raw.region_id, raw.region_name),
        district: related(raw.district_id, raw.district_name),
        county: related(raw.county_id, raw.county_name),
        subcounty: related(raw.subcounty_id, raw.subcounty_name),
        parish: related(raw.parish_id, raw.parish_name),
        health_sub_region: related(raw.health_sub_region_id, raw.health_sub_region_name),
        health_sub_district: related(raw.health_sub_district_id, raw.health_sub_district_name),
      },
    }) as T, facilityFilters(params.filters))
  },
  listRegions(params: TableListParams) {
    return tableResource<RegionsResponse>("/api/v2/regions", params)
  },
  listHealthSubRegions(params: TableListParams) {
    return tableResource<HealthSubRegionsWithRegion>("/api/v2/health-sub-regions", params, (raw) => ({
      ...normalizeRecord<HealthSubRegionsResponse>(raw),
      expand: { region: related(raw.region_id, raw.region_name)! as RegionsResponse },
    }))
  },
  listDistricts(params: TableListParams) {
    return tableResource<DistrictsWithExpanded>("/api/v2/districts", params, (raw) => ({
      ...normalizeRecord<DistrictsResponse>(raw),
      expand: {
        region: related(raw.region_id, raw.region_name)! as RegionsResponse,
        health_sub_region: related(raw.health_sub_region_id, raw.health_sub_region_name)! as HealthSubRegionsResponse,
      },
    }))
  },
  listHealthSubDistricts(params: TableListParams) {
    return tableResource<HealthSubDistrictsResponse>("/api/v2/health-sub-districts", params)
  },
  listCounties(params: TableListParams) {
    return tableResource<CountiesWithDistrict>("/api/v2/counties", params, (raw) => ({
      ...normalizeRecord<CountiesResponse>(raw),
      expand: { district: related(raw.district_id, raw.district_name)! as DistrictsResponse },
    }))
  },
  listSubcounties(params: TableListParams) {
    return tableResource<SubcountiesWithExpanded>("/api/v2/subcounties", params, (raw) => ({
      ...normalizeRecord<SubcountiesResponse>(raw),
      expand: {
        district: related(raw.district_id, raw.district_name)! as DistrictsResponse,
        county: related(raw.county_id, raw.county_name)! as CountiesResponse,
      },
    }))
  },
  listParishes(params: TableListParams) {
    return tableResource<ParishesWithSubcounty>("/api/v2/parishes", params, (raw) => ({
      ...normalizeRecord<ParishesResponse>(raw),
      expand: { subcounty: related(raw.subcounty_id, raw.subcounty_name)! as SubcountiesResponse },
    }))
  },
  listFacilityLevels(params: TableListParams) {
    return tableResource<FacilityLevelsResponse>("/api/v2/facility-levels", params)
  },
  listOwnershipTypes(params: TableListParams) {
    return tableResource<OwnershipTypesResponse>("/api/v2/ownership-types", params)
  },
  listAuthorities(params: TableListParams) {
    return tableResource<AuthoritiesWithOwnershipType>("/api/v2/authorities", params, (raw) => ({
      ...normalizeRecord<AuthoritiesResponse>(raw),
      expand: { ownership_type: related(raw.ownership_type_id, raw.ownership_type_name)! as OwnershipTypesResponse },
    }))
  },
  listFacilities(params: FacilityListParams = {}) {
    return backend().request<ListResult<HealthFacilitiesResponse>>("/api/v2/facilities", {
      query: listQuery(params),
    })
  },
  async getFacility(id: string) {
    const result = await backend().request<ItemResult<Record<string, unknown>>>(`/api/v2/facilities/${id}`)
    return normalizeRecord<HealthFacilitiesResponse>(result.item)
  },
  createFacility(data: Record<string, unknown>) {
    return backend().request<HealthFacilitiesResponse>("/api/v2/facilities", {
      method: "POST",
      body: JSON.stringify(data),
    })
  },
  updateFacility(id: string, data: Record<string, unknown>) {
    return backend().request<HealthFacilitiesResponse>(`/api/v2/facilities/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    })
  },
  deleteFacility(id: string) {
    return backend().request<void>(`/api/v2/facilities/${id}`, { method: "DELETE" })
  },
  createRegion(data: Record<string, unknown>) {
    return backend().request<RegionsResponse>("/api/v2/regions", { method: "POST", body: JSON.stringify(data) })
  },
  updateRegion(id: string, data: Record<string, unknown>) {
    return backend().request<RegionsResponse>(`/api/v2/regions/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteRegion(id: string) {
    return backend().request<void>(`/api/v2/regions/${id}`, { method: "DELETE" })
  },
  createHealthSubRegion(data: Record<string, unknown>) {
    return backend().request<HealthSubRegionsResponse>("/api/v2/health-sub-regions", { method: "POST", body: JSON.stringify(data) })
  },
  updateHealthSubRegion(id: string, data: Record<string, unknown>) {
    return backend().request<HealthSubRegionsResponse>(`/api/v2/health-sub-regions/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteHealthSubRegion(id: string) {
    return backend().request<void>(`/api/v2/health-sub-regions/${id}`, { method: "DELETE" })
  },
  createDistrict(data: Record<string, unknown>) {
    return backend().request<DistrictsResponse>("/api/v2/districts", { method: "POST", body: JSON.stringify(data) })
  },
  updateDistrict(id: string, data: Record<string, unknown>) {
    return backend().request<DistrictsResponse>(`/api/v2/districts/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteDistrict(id: string) {
    return backend().request<void>(`/api/v2/districts/${id}`, { method: "DELETE" })
  },
  createHealthSubDistrict(data: Record<string, unknown>) {
    return backend().request<HealthSubDistrictsResponse>("/api/v2/health-sub-districts", { method: "POST", body: JSON.stringify(data) })
  },
  updateHealthSubDistrict(id: string, data: Record<string, unknown>) {
    return backend().request<HealthSubDistrictsResponse>(`/api/v2/health-sub-districts/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteHealthSubDistrict(id: string) {
    return backend().request<void>(`/api/v2/health-sub-districts/${id}`, { method: "DELETE" })
  },
  createCounty(data: Record<string, unknown>) {
    return backend().request<CountiesResponse>("/api/v2/counties", { method: "POST", body: JSON.stringify(data) })
  },
  updateCounty(id: string, data: Record<string, unknown>) {
    return backend().request<CountiesResponse>(`/api/v2/counties/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteCounty(id: string) {
    return backend().request<void>(`/api/v2/counties/${id}`, { method: "DELETE" })
  },
  createSubcounty(data: Record<string, unknown>) {
    return backend().request<SubcountiesResponse>("/api/v2/subcounties", { method: "POST", body: JSON.stringify(data) })
  },
  updateSubcounty(id: string, data: Record<string, unknown>) {
    return backend().request<SubcountiesResponse>(`/api/v2/subcounties/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteSubcounty(id: string) {
    return backend().request<void>(`/api/v2/subcounties/${id}`, { method: "DELETE" })
  },
  createParish(data: Record<string, unknown>) {
    return backend().request<ParishesResponse>("/api/v2/parishes", { method: "POST", body: JSON.stringify(data) })
  },
  updateParish(id: string, data: Record<string, unknown>) {
    return backend().request<ParishesResponse>(`/api/v2/parishes/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteParish(id: string) {
    return backend().request<void>(`/api/v2/parishes/${id}`, { method: "DELETE" })
  },
  createFacilityLevel(data: Record<string, unknown>) {
    return backend().request<FacilityLevelsResponse>("/api/v2/facility-levels", { method: "POST", body: JSON.stringify(data) })
  },
  updateFacilityLevel(id: string, data: Record<string, unknown>) {
    return backend().request<FacilityLevelsResponse>(`/api/v2/facility-levels/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteFacilityLevel(id: string) {
    return backend().request<void>(`/api/v2/facility-levels/${id}`, { method: "DELETE" })
  },
  createOwnershipType(data: Record<string, unknown>) {
    return backend().request<OwnershipTypesResponse>("/api/v2/ownership-types", { method: "POST", body: JSON.stringify(data) })
  },
  updateOwnershipType(id: string, data: Record<string, unknown>) {
    return backend().request<OwnershipTypesResponse>(`/api/v2/ownership-types/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteOwnershipType(id: string) {
    return backend().request<void>(`/api/v2/ownership-types/${id}`, { method: "DELETE" })
  },
  createAuthority(data: Record<string, unknown>) {
    return backend().request<AuthoritiesResponse>("/api/v2/authorities", { method: "POST", body: JSON.stringify(data) })
  },
  updateAuthority(id: string, data: Record<string, unknown>) {
    return backend().request<AuthoritiesResponse>(`/api/v2/authorities/${id}`, { method: "PATCH", body: JSON.stringify(data) })
  },
  deleteAuthority(id: string) {
    return backend().request<void>(`/api/v2/authorities/${id}`, { method: "DELETE" })
  },
  regions() {
    return listResource<RegionsResponse>("/api/v2/regions", { per_page: 200 })
  },
  districts(regionId?: string) {
    return listResource<DistrictsResponse>("/api/v2/districts", { per_page: 200, region_id: regionId })
  },
  counties(districtId?: string) {
    return listResource<CountiesResponse>("/api/v2/counties", { per_page: 200, district_id: districtId })
  },
  subcounties(districtId?: string, countyId?: string) {
    return listResource<SubcountiesResponse>("/api/v2/subcounties", { per_page: 200, district_id: districtId, county_id: countyId })
  },
  parishes(subcountyId?: string) {
    return listResource<ParishesResponse>("/api/v2/parishes", { per_page: 200, subcounty_id: subcountyId })
  },
  healthSubRegions(regionId?: string) {
    return listResource<HealthSubRegionsResponse>("/api/v2/health-sub-regions", { per_page: 200, region_id: regionId })
  },
  healthSubDistricts(districtId?: string) {
    return listResource<HealthSubDistrictsResponse>("/api/v2/health-sub-districts", { per_page: 200, district_id: districtId })
  },
  facilityLevels() {
    return listResource<FacilityLevelsResponse>("/api/v2/facility-levels", { per_page: 200 })
  },
  ownershipTypes() {
    return listResource<OwnershipTypesResponse>("/api/v2/ownership-types", { per_page: 200 })
  },
  authorities(ownershipTypeId?: string) {
    return listResource<AuthoritiesResponse>("/api/v2/authorities", { per_page: 200, ownership_type_id: ownershipTypeId })
  },
}

const relationOptions = <T>(path: string) => (search: string, pageSize: number) =>
  listResource<T>(path, { search, per_page: pageSize }) as Promise<Array<Record<string, unknown>>>

export const facilityRelationOptions = {
  regions: { key: "regions", loadOptions: relationOptions<RegionsResponse>("/api/v2/regions") },
  healthSubRegions: { key: "health-sub-regions", loadOptions: relationOptions<HealthSubRegionsResponse>("/api/v2/health-sub-regions") },
  districts: { key: "districts", loadOptions: relationOptions<DistrictsResponse>("/api/v2/districts") },
  healthSubDistricts: { key: "health-sub-districts", loadOptions: relationOptions<HealthSubDistrictsResponse>("/api/v2/health-sub-districts") },
  counties: { key: "counties", loadOptions: relationOptions<CountiesResponse>("/api/v2/counties") },
  subcounties: { key: "subcounties", loadOptions: relationOptions<SubcountiesResponse>("/api/v2/subcounties") },
  parishes: { key: "parishes", loadOptions: relationOptions<ParishesResponse>("/api/v2/parishes") },
  facilityLevels: { key: "facility-levels", loadOptions: relationOptions<FacilityLevelsResponse>("/api/v2/facility-levels") },
  authorities: { key: "authorities", loadOptions: relationOptions<AuthoritiesResponse>("/api/v2/authorities") },
  ownershipTypes: { key: "ownership-types", loadOptions: relationOptions<OwnershipTypesResponse>("/api/v2/ownership-types") },
}
