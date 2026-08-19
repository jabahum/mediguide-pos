import { getBackendClient } from "@/lib/backend-client"
import type { NotificationCampaignsResponse, NotificationTemplatesResponse } from "@/types/backend-types"
import type { ModelsNotificationAction, ServicesNotificationActionTypeEnum } from "@/types/generated/backend-openapi"

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
}

export interface NotificationTemplateInput {
  name: string
  type: "push" | "email" | "sms" | "in-app"
  category: string
  status: "active" | "draft" | "inactive"
  subject?: string
  content: string
  audience?: string
  variables?: Record<string, unknown>
}

export interface NotificationCampaignInput {
  name: string
  type: string
  channels: string[]
  status: "draft" | "scheduled" | "active" | "paused" | "completed" | "cancelled"
  audience_countries?: string[]
  audience_roles?: string[]
  schedule_start?: string
  schedule_end?: string
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
    return client().send<PagedResult<NotificationTemplatesResponse>>("/api/v2/notification-templates", { query })
  },
  createTemplate(input: NotificationTemplateInput) {
    return client().send("/api/v2/notification-templates", { method: "POST", body: JSON.stringify(input) })
  },
  updateTemplate(id: string, input: NotificationTemplateInput) {
    return client().send(`/api/v2/notification-templates/${id}`, { method: "PATCH", body: JSON.stringify(input) })
  },
  updateTemplateStatus(id: string, status: "active" | "draft" | "inactive") {
    return client().send(`/api/v2/notification-templates/${id}/status`, { method: "PATCH", body: JSON.stringify({ status }) })
  },
  deleteTemplate(id: string) {
    return client().send<void>(`/api/v2/notification-templates/${id}`, { method: "DELETE" })
  },
  listCampaigns(query: Record<string, string | number | undefined> = {}) {
    return client().send<PagedResult<NotificationCampaignsResponse>>("/api/v2/notification-campaigns", { query })
  },
  createCampaign(input: NotificationCampaignInput) {
    return client().send("/api/v2/notification-campaigns", { method: "POST", body: JSON.stringify(input) })
  },
  updateCampaign(id: string, input: NotificationCampaignInput) {
    return client().send(`/api/v2/notification-campaigns/${id}`, { method: "PATCH", body: JSON.stringify(input) })
  },
  updateCampaignStatus(id: string, status: "draft" | "scheduled" | "running" | "paused" | "completed") {
    return client().send(`/api/v2/notification-campaigns/${id}/status`, { method: "PATCH", body: JSON.stringify({ status }) })
  },
  deleteCampaign(id: string) {
    return client().send<void>(`/api/v2/notification-campaigns/${id}`, { method: "DELETE" })
  },
}
