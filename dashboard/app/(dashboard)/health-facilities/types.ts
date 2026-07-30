import { 
  HealthFacilitiesResponse, 
  FacilityLevelsResponse, 
  AuthoritiesResponse, 
  OwnershipTypesResponse,
  RegionsResponse,
  HealthSubRegionsResponse,
  DistrictsResponse,
  CountiesResponse,
  HealthSubDistrictsResponse,
  SubcountiesResponse,
  ParishesResponse
} from "@/types/backend-types"

// Extended Health Facility type with all possible expanded relations
export interface HealthFacilityWithExpand extends HealthFacilitiesResponse {
  expand?: {
    // Classification
    facility_level?: FacilityLevelsResponse
    authority?: AuthoritiesResponse
    ownership_type?: OwnershipTypesResponse
    
    // Geographic hierarchy (complete chain)
    region?: RegionsResponse
    health_sub_region?: HealthSubRegionsResponse
    district?: DistrictsResponse
    county?: CountiesResponse
    health_sub_district?: HealthSubDistrictsResponse
    subcounty?: SubcountiesResponse
    parish?: ParishesResponse
  }
}

// Facility location hierarchy interface
export interface FacilityLocationHierarchy {
  region?: string
  healthSubRegion?: string
  district?: string
  county?: string
  healthSubDistrict?: string
  subcounty?: string
  parish?: string
}

// Facility classification interface
export interface FacilityClassification {
  level?: {
    id: string
    code: string
    name: string
  }
  authority?: {
    id: string
    name: string
    code?: string
  }
  ownership?: {
    id: string
    code: string
    name: string
  }
}

// Facility search/filter interfaces
export interface FacilitySearchParams {
  name?: string
  nhpiCode?: string
  hsdtCode?: string
  facilityLevel?: string
  authority?: string
  ownershipType?: string
  region?: string
  district?: string
  county?: string
  subcounty?: string
  parish?: string
}

// Facility statistics interface
export interface FacilityStatistics {
  total: number
  byLevel: Record<string, number>
  byAuthority: Record<string, number>
  byOwnership: Record<string, number>
  byRegion: Record<string, number>
  byDistrict: Record<string, number>
}

// Facility report data interface
export interface FacilityReportData {
  facility: HealthFacilityWithExpand
  classification: FacilityClassification
  location: FacilityLocationHierarchy
  metadata: {
    generated: string
    generatedBy: string
  }
}

// Bulk operations result interface
export interface BulkOperationResult {
  success: number
  failed: number
  errors: string[]
}