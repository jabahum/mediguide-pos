/**
 * Expanded types for legacy collection API responses with relationship data
 */

import {
  HealthFacilitiesResponse,
  HealthSubRegionsResponse,
  HealthSubDistrictsResponse,
  CountiesResponse,
  DistrictsResponse,
  ParishesResponse,
  SubcountiesResponse,
  AuthoritiesResponse,
  RegionsResponse,
  FacilityLevelsResponse,
  OwnershipTypesResponse,
  GuidelineCategoriesResponse,
  AbbreviationsResponse,
  GuidelineTagsResponse,
  MedicalGuidelinesResponse,
  GuidelineIndexResponse,
  FaqsResponse,
  FaqTagsResponse,
  UsersResponse,
  SupportTicketsResponse,
  SupportTicketRepliesResponse,
} from "./backend-types"

/**
 * Health Sub-Region with expanded region relationship
 */
export type HealthSubRegionsWithRegion = HealthSubRegionsResponse<{
  region: RegionsResponse
}>

/**
 * Health Facilities with all expanded relationships
 */
export type HealthFacilitiesWithExpanded = HealthFacilitiesResponse<{
  authority: AuthoritiesResponse[]
  county: CountiesResponse[]
  district: DistrictsResponse[]
  facility_level: FacilityLevelsResponse[]
  health_sub_district: HealthSubDistrictsResponse[]
  health_sub_region: HealthSubRegionsResponse[]
  ownership_type: OwnershipTypesResponse[]
  parish: ParishesResponse[]
  region: RegionsResponse[]
}>

/**
 * Counties with expanded district relationship
 */
export type CountiesWithDistrict = CountiesResponse<{
  district: DistrictsResponse
}>

/**
 * Districts with expanded relationships
 */
export type DistrictsWithExpanded = DistrictsResponse<{
  health_sub_region: HealthSubRegionsResponse
  region: RegionsResponse
}>

/**
 * Health Sub-Districts with expanded district relationship
 */
export type HealthSubDistrictsWithDistrict = HealthSubDistrictsResponse<{
  district: DistrictsResponse
}>

/**
 * Parishes with expanded subcounty relationship
 */
export type ParishesWithSubcounty = ParishesResponse<{
  subcounty: SubcountiesResponse
}>

/**
 * Subcounties with expanded relationships
 */
export type SubcountiesWithExpanded = SubcountiesResponse<{
  county: CountiesResponse
  district: DistrictsResponse
}>

/**
 * Authorities with expanded ownership type relationship
 */
export type AuthoritiesWithOwnershipType = AuthoritiesResponse<{
  ownership_type: OwnershipTypesResponse
}>

/**
 * Guideline Categories with expanded parent category relationship
 */
export type GuidelineCategoriesWithParent = GuidelineCategoriesResponse<{
  parent_category: GuidelineCategoriesResponse
}>

/**
 * Abbreviations with expanded category and tags relationships
 */
export type AbbreviationsWithExpanded = AbbreviationsResponse<{
  category?: GuidelineCategoriesResponse
  tags?: GuidelineTagsResponse[]
}>

/**
 * Medical Guidelines with expanded categories, tags, and index_item relationships
 */
export type MedicalGuidelinesWithExpanded = MedicalGuidelinesResponse<{
  categories?: GuidelineCategoriesResponse[]
  tags?: GuidelineTagsResponse[]
  index_item?: GuidelineIndexResponse
}>

/**
 * Guideline Index with expanded parent relationship and children
 */
export type GuidelineIndexWithExpanded = GuidelineIndexResponse<{
  parent?: GuidelineIndexResponse[]
}>

/**
 * Type guards for checking expanded data
 */
export function hasExpandedRegion(
  record: HealthSubRegionsResponse
): record is HealthSubRegionsWithRegion {
  return !!(record.expand as any)?.region
}

export function hasExpandedDistricts(
  record: CountiesResponse
): record is CountiesWithDistrict {
  return !!(record.expand as any)?.district
}

export function hasExpandedParentCategory(
  record: GuidelineCategoriesResponse
): record is GuidelineCategoriesWithParent {
  return !!(record.expand as any)?.parent_category
}

export function hasExpandedCategoryAndTags(
  record: AbbreviationsResponse
): record is AbbreviationsWithExpanded {
  return !!(record.expand as any)?.category || !!(record.expand as any)?.tags
}

export function hasExpandedMedicalGuidelineRelations(
  record: MedicalGuidelinesResponse
): record is MedicalGuidelinesWithExpanded {
  return !!(record.expand as any)?.categories || !!(record.expand as any)?.tags || !!(record.expand as any)?.index_item
}

export function hasExpandedGuidelineIndex(
  record: GuidelineIndexResponse
): record is GuidelineIndexWithExpanded {
  return !!(record.expand as any)?.parent
}

/**
 * FAQs with expanded relationships
 */
export type FaqsWithExpanded = FaqsResponse<{
  tags?: FaqTagsResponse[]
  author?: UsersResponse
  reviewer?: UsersResponse
  related_faqs?: FaqsResponse[]
}>

/**
 * FAQ Tags with expanded relationships (if any)
 */
export type FaqTagsWithExpanded = FaqTagsResponse<{}>

/**
 * Type guards for FAQ expanded data
 */
export function hasExpandedFaqRelations(
  record: FaqsResponse
): record is FaqsWithExpanded {
  return !!(record.expand as any)?.tags || 
         !!(record.expand as any)?.author || 
         !!(record.expand as any)?.reviewer || 
         !!(record.expand as any)?.related_faqs
}

export function hasExpandedTags(
  record: FaqsResponse
): record is FaqsWithExpanded {
  return !!(record.expand as any)?.tags
}

export function hasExpandedAuthor(
  record: FaqsResponse
): record is FaqsWithExpanded {
  return !!(record.expand as any)?.author
}

export function hasExpandedReviewer(
  record: FaqsResponse
): record is FaqsWithExpanded {
  return !!(record.expand as any)?.reviewer
}

/**
 * Support Tickets with expanded relationships
 */
export type SupportTicketsWithExpanded = SupportTicketsResponse<{
  user_id?: UsersResponse
  assigned_to?: UsersResponse
}>

/**
 * Support Ticket Replies with expanded relationships
 */
export type SupportTicketRepliesWithExpanded = SupportTicketRepliesResponse<{
  user_id?: UsersResponse
  ticket_id?: SupportTicketsResponse
}>

/**
 * Type guards for support ticket expanded data
 */
export function hasExpandedTicketUser(
  record: SupportTicketsResponse
): record is SupportTicketsWithExpanded {
  return !!(record.expand as any)?.user_id
}

export function hasExpandedAssignedTo(
  record: SupportTicketsResponse
): record is SupportTicketsWithExpanded {
  return !!(record.expand as any)?.assigned_to
}

export function hasExpandedTicketUserAndAssigned(
  record: SupportTicketsResponse
): record is SupportTicketsWithExpanded {
  return !!(record.expand as any)?.user_id || !!(record.expand as any)?.assigned_to
}

export function hasExpandedReplyUser(
  record: SupportTicketRepliesResponse
): record is SupportTicketRepliesWithExpanded {
  return !!(record.expand as any)?.user_id
}

export function hasExpandedReplyTicket(
  record: SupportTicketRepliesResponse
): record is SupportTicketRepliesWithExpanded {
  return !!(record.expand as any)?.ticket_id
}