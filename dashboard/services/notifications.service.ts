import { getBackendClient } from "@/lib/backend-client"
import type { ModelsNotificationAction, ServicesNotificationActionTypeEnum, ServicesNotificationCampaignDTO, ServicesNotificationCampaignInput, ServicesNotificationTemplateDTO, ServicesNotificationTemplateInput } from "@/types/generated/backend-openapi"

export type NotificationType = "info" | "success" | "warning" | "error"
export type NotificationPriority = "low" | "normal" | "high" | "urgent"
export type NotificationActionType = ServicesNotificationActionTypeEnum
export type NotificationAction = Omit<ModelsNotificationAction, "type" | "parameters"> & {
  type: NotificationActionType
  parameters: Record<string, string>
}

export interface NotificationDto {
  id: string
  user_id?: string
  title: string
  message: string
  type: NotificationType
  priority: NotificationPriority
  action: NotificationAction
  /** Compatibility field for clients predating typed actions. */
  action_url?: string
  source_type?: string
  source_id?: string
  campaign_id?: string
  publish_at?: string
  expires_at?: string
  deduplication_key?: string
  created_by?: string
  published_by?: string
  is_read: boolean
  created_at: string
  updated_at: string
}

export interface NotificationListQuery {
  page?: number
  per_page?: number
  search?: string
  type?: NotificationType
  priority?: NotificationPriority
  is_read?: boolean
  from?: string
  to?: string
  sort?: "created_at" | "title" | "type" | "priority"
  order?: "asc" | "desc"
}

export interface PagedNotifications {
  items: NotificationDto[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

interface PagedResult<T> {
  items: T[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

export interface CreateNotificationInput {
  user_id?: string
  title: string
  message: string
  type: NotificationType
  priority: NotificationPriority
  action: NotificationAction
  /** Compatibility field for clients predating typed actions. */
  action_url?: string
  source_type?: string
  source_id?: string
  publish_at?: string
  expires_at?: string
  deduplication_key?: string
}

export interface NotificationTemplateInput extends Omit<ServicesNotificationTemplateInput, "action_template" | "channel" | "variable_schema"> {
  name: string
  template_key: string
  channel: "push" | "email" | "sms" | "in-app"
  title_template?: string
  body_template: string
  action_template: NotificationAction
  variable_schema: Record<string, { type: "string" | "number" | "boolean" | "date"; required: boolean; sample_value?: unknown }>
  category: string
  locale: string
}

export interface NotificationTemplateVersionDto extends Omit<NotificationTemplateInput, "name" | "template_key"> {
  id: string; template_id: string; version: number; status: "draft" | "published" | "archived"; created_at: string
}
export interface NotificationTemplateDto extends Omit<ServicesNotificationTemplateDTO, "id" | "name" | "template_key" | "status" | "current_version" | "locale" | "version" | "created_at" | "updated_at"> {
  id: string; name: string; template_key: string; status: "draft" | "published" | "archived"
  current_version: number; locale: string; version: NotificationTemplateVersionDto; created_at: string; updated_at: string
}
export type NotificationCampaignStatus = "draft" | "pending_review" | "approved" | "scheduled" | "queued" | "sending" | "completed" | "partially_failed" | "failed" | "cancelled"
export interface NotificationCampaignInput extends Omit<ServicesNotificationCampaignInput, "audience" | "priority" | "requested_channels" | "type" | "variables"> {
  name: string
  type: "emergency" | "update" | "reminder" | "marketing" | "announcement"
  template_version_id: string
  variables: Record<string, unknown>
  audience: { all_eligible: boolean; user_ids?: string[]; role_ids?: string[]; countries?: string[]; regions?: string[] }
  scheduled_at?: string; timezone: string; expires_at?: string; ttl_seconds?: number
  priority: NotificationPriority; collapse_key?: string; requested_channels: Array<"push" | "email" | "sms" | "in-app">
  idempotency_key: string; lock_version?: number
}
export interface NotificationCampaignDto extends Omit<ServicesNotificationCampaignDTO, "action_snapshot" | "audience" | "id" | "name" | "priority" | "requested_channels" | "status" | "type"> {
  id: string; name: string; type: NotificationCampaignInput["type"]; status: NotificationCampaignStatus
  template_version_id?: string; rendered_title: string; rendered_body: string; action_snapshot: NotificationAction
  audience: NotificationCampaignInput["audience"]; resolved_recipient_count: number; scheduled_at?: string; timezone: string
  expires_at?: string; ttl_seconds?: number; priority: NotificationPriority; collapse_key?: string
  requested_channels: string[]; created_by?: string; reviewed_by?: string; approved_by?: string; approved_at?: string
  reviewed_at?: string; started_at?: string; completed_at?: string; cancelled_at?: string; failure_reason?: string
  idempotency_key: string; lock_version: number; created_at: string; updated_at: string
}

const client = () => getBackendClient()

export const notificationsService = {
  list(query: NotificationListQuery = {}) {
    return client().send<PagedNotifications>("/api/v2/notifications", { query: { ...query } })
  },
  get(id: string) {
    return client().send<NotificationDto>(`/api/v2/notifications/${id}`)
  },
  create(input: CreateNotificationInput) {
    return client().send<NotificationDto>("/api/v2/notifications", {
      method: "POST",
      body: JSON.stringify(input),
    })
  },
  markRead(id: string) {
    return client().send<NotificationDto>(`/api/v2/notifications/${id}/read`, { method: "POST" })
  },
  markUnread(id: string) {
    return client().send<NotificationDto>(`/api/v2/notifications/${id}/unread`, { method: "POST" })
  },
  markAllRead() {
    return client().send<void>("/api/v2/notifications/read-all", { method: "POST" })
  },
  listTemplates(query: Record<string, string | number | undefined> = {}) {
    return client().send<PagedResult<NotificationTemplateDto>>("/api/v2/notification-templates", { query })
  },
  createTemplate(input: NotificationTemplateInput) {
    return client().send("/api/v2/notification-templates", { method: "POST", body: JSON.stringify(input) })
  },
  updateTemplate(id: string, input: NotificationTemplateInput) {
    return client().send(`/api/v2/notification-templates/${id}`, { method: "PATCH", body: JSON.stringify(input) })
  },
  updateTemplateStatus(id: string, status: "published" | "archived") {
    return client().send(`/api/v2/notification-templates/${id}/status`, { method: "PATCH", body: JSON.stringify({ status }) })
  },
  listTemplateVersions(id: string) {
    return client().send<NotificationTemplateVersionDto[]>(`/api/v2/notification-templates/${id}/versions`)
  },
  previewTemplateVersion(id: string, variables: Record<string, unknown>) {
    return client().send<{ title: string; body: string; action: NotificationAction }>(`/api/v2/notification-template-versions/${id}/preview`, { method: "POST", body: JSON.stringify({ variables }) })
  },
  deleteTemplate(id: string) {
    return client().send<void>(`/api/v2/notification-templates/${id}`, { method: "DELETE" })
  },
  listCampaigns(query: Record<string, string | number | undefined> = {}) {
    return client().send<PagedResult<NotificationCampaignDto>>("/api/v2/notification-campaigns", { query })
  },
  createCampaign(input: NotificationCampaignInput) {
    return client().send("/api/v2/notification-campaigns", { method: "POST", body: JSON.stringify(input) })
  },
  updateCampaign(id: string, input: NotificationCampaignInput) {
    return client().send(`/api/v2/notification-campaigns/${id}`, { method: "PATCH", body: JSON.stringify(input) })
  },
  transitionCampaign(id: string, action: "submit" | "approve" | "reject" | "schedule" | "cancel", input: { lock_version: number; scheduled_at?: string; timezone?: string; reason?: string }) {
    return client().send<NotificationCampaignDto>(`/api/v2/notification-campaigns/${id}/${action}`, { method: "POST", body: JSON.stringify(input) })
  },
  deleteCampaign(id: string) {
    return client().send<void>(`/api/v2/notification-campaigns/${id}`, { method: "DELETE" })
  },
}
