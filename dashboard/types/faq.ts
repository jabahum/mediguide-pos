import type { 
  FaqTagsRecord, 
  FaqTagsResponse, 
  FaqsRecord, 
  FaqsResponse, 
  UsersRecord, 
  UsersResponse,
  FaqsStatusOptions,
  FaqsPriorityOptions,
  FaqsTargetAudienceOptions
} from "./backend-types"
import type { FaqsWithExpanded } from "./expanded"

// FAQ Tag with usage statistics
export type FaqTagWithStats = FaqTagsResponse & {
  faq_count?: number
}

// Form data types for creation and updates
export type FaqCreateData = Omit<FaqsRecord, 'id' | 'created' | 'updated'>
export type FaqUpdateData = Partial<FaqCreateData>

export type FaqTagCreateData = Omit<FaqTagsRecord, 'id' | 'created' | 'updated' | 'usage_count'>
export type FaqTagUpdateData = Partial<FaqTagCreateData>

// Enum re-exports for convenient usage
export type FaqStatus = FaqsStatusOptions
export type FaqPriority = FaqsPriorityOptions  
export type TargetAudience = FaqsTargetAudienceOptions

// Constants for select options
export const FAQ_STATUS_OPTIONS = [
  { value: 'draft', label: 'Draft' },
  { value: 'review', label: 'Under Review' },
  { value: 'published', label: 'Published' },
  { value: 'archived', label: 'Archived' },
] as const

export const FAQ_PRIORITY_OPTIONS = [
  { value: 'low', label: 'Low' },
  { value: 'normal', label: 'Normal' },
  { value: 'high', label: 'High' },
  { value: 'critical', label: 'Critical' },
] as const

export const TARGET_AUDIENCE_OPTIONS = [
  { value: 'all', label: 'All Users' },
  { value: 'admin', label: 'Administrators' },
  { value: 'health_worker', label: 'Health Workers' },
  { value: 'patient', label: 'Patients' },
] as const

// Color options for tags (semantic colors only)
export const TAG_COLOR_OPTIONS = [
  { value: 'primary', label: 'Primary', color: 'hsl(var(--primary))' },
  { value: 'secondary', label: 'Secondary', color: 'hsl(var(--secondary))' },
  { value: 'destructive', label: 'Destructive', color: 'hsl(var(--destructive))' },
  { value: 'muted', label: 'Muted', color: 'hsl(var(--muted))' },
  { value: 'accent', label: 'Accent', color: 'hsl(var(--accent))' },
  { value: 'popover', label: 'Popover', color: 'hsl(var(--popover))' },
  { value: 'card', label: 'Card', color: 'hsl(var(--card))' },
] as const

// Search and filtering types
export type FaqSearchFilters = {
  search?: string
  tags?: string[]
  status?: FaqStatus[]
  priority?: FaqPriority[]
  target_audience?: TargetAudience[]
  author?: string
  is_featured?: boolean
  created_after?: string
  created_before?: string
  updated_after?: string
  updated_before?: string
}

export type FaqTagSearchFilters = {
  search?: string
  is_active?: boolean
  color?: string
  min_usage_count?: number
  max_usage_count?: number
}

// Analytics and statistics types
export type FaqStats = {
  total_faqs: number
  published_faqs: number
  draft_faqs: number
  review_faqs: number
  archived_faqs: number
  featured_faqs: number
  total_tags: number
  active_tags: number
  avg_tags_per_faq: number
}

export type FaqTagStats = {
  total_tags: number
  active_tags: number  
  inactive_tags: number
  most_used_tags: Array<{
    tag: FaqTagsResponse
    usage_count: number
  }>
  least_used_tags: Array<{
    tag: FaqTagsResponse
    usage_count: number
  }>
}

// Service response types
export type FaqServiceResponse<T = any> = {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export type BulkOperationResult = {
  success_count: number
  error_count: number
  errors?: Array<{
    id: string
    error: string
  }>
}