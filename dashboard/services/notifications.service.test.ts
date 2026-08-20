import { beforeEach, describe, expect, it, vi } from "vitest"

const send = vi.fn()

vi.mock("@/lib/backend-client", () => ({
  getBackendClient: () => ({ send }),
}))

import { notificationsService } from "./notifications.service"

describe("notificationsService", () => {
  beforeEach(() => send.mockReset())

  it("uses explicit list query parameters", async () => {
    send.mockResolvedValue({ items: [], page: 2, per_page: 10, total_items: 0, total_pages: 0 })

    await notificationsService.list({ page: 2, per_page: 10, type: "warning", is_read: false })

    expect(send).toHaveBeenCalledWith("/api/v2/notifications", {
      query: { page: 2, per_page: 10, type: "warning", is_read: false },
    })
  })

  it("uses owner-scoped read operations instead of generic resources", async () => {
    send.mockResolvedValue({ id: "notice-1", is_read: true })

    await notificationsService.markRead("notice-1")
    await notificationsService.markAllRead()

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/notifications/notice-1/read", { method: "POST" })
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/notifications/read-all", { method: "POST" })
  })

  it("creates an in-app notification explicitly", async () => {
    send.mockResolvedValue({ id: "notice-1" })
    const input = {
      title: "Guideline updated",
      message: "A new guideline version is available.",
      type: "info" as const,
      priority: "normal" as const,
      action: { type: "none" as const, parameters: {} },
    }

    await notificationsService.create(input)

    expect(send).toHaveBeenCalledWith("/api/v2/notifications", {
      method: "POST",
      body: JSON.stringify(input),
    })
  })

  it("routes version publishing and guarded campaign transitions through admin endpoints", async () => {
    send.mockResolvedValue({})

    await notificationsService.updateTemplateStatus("template-1", "published")
    await notificationsService.transitionCampaign("campaign-1", "approve", { lock_version: 3 })

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/notification-templates/template-1/status", {
      method: "PATCH",
      body: JSON.stringify({ status: "published" }),
    })
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/notification-campaigns/campaign-1/approve", {
      method: "POST",
      body: JSON.stringify({ lock_version: 3 }),
    })
  })

  it("estimates a typed audience without requesting recipient records", async () => {
    send.mockResolvedValue({ eligible_users: 14, active_devices: 9 })
    const audience = { all_eligible: false, countries: ["Uganda"], platforms: ["android" as const] }

    await notificationsService.estimateAudience(audience)

    expect(send).toHaveBeenCalledWith("/api/v2/notification-campaigns/audience-estimate", {
      method: "POST",
      body: JSON.stringify({ audience }),
    })
  })

  it("loads aggregate preference counts without raw devices or tokens", async () => {
    send.mockResolvedValue({ eligible_users: 20, push_enabled_users: 15 })

    await notificationsService.preferenceAggregates()

    expect(send).toHaveBeenCalledWith("/api/v2/notification-preferences/aggregates")
  })

  it("uses typed delivery audit, analytics, clone, pause and requeue endpoints", async () => {
    await notificationsService.cloneTemplate("template-1", { name: "Copy", template_key: "copy" })
    await notificationsService.transitionCampaign("campaign-1", "pause", { lock_version: 4 })
    await notificationsService.listDeliveries({ campaign_id: "campaign-1", state: "accepted" })
    await notificationsService.deliveryAnalytics("2026-08-01", "2026-08-20")
    await notificationsService.requeueDeliveryJob("job-1", "operator retry")
    expect(send).toHaveBeenCalledWith("/api/v2/notification-templates/template-1/clone", expect.anything())
    expect(send).toHaveBeenCalledWith("/api/v2/notification-campaigns/campaign-1/pause", expect.anything())
    expect(send).toHaveBeenCalledWith("/api/v2/notification-deliveries", expect.anything())
    expect(send).toHaveBeenCalledWith("/api/v2/notification-delivery-analytics/daily", expect.anything())
    expect(send).toHaveBeenCalledWith("/api/v2/notification-delivery-jobs/job-1/requeue", expect.anything())
  })
})
