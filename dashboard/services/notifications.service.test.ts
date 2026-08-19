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
    }

    await notificationsService.create(input)

    expect(send).toHaveBeenCalledWith("/api/v2/notifications", {
      method: "POST",
      body: JSON.stringify(input),
    })
  })

  it("routes template and campaign status changes through admin endpoints", async () => {
    send.mockResolvedValue({})

    await notificationsService.updateTemplateStatus("template-1", "inactive")
    await notificationsService.updateCampaignStatus("campaign-1", "paused")

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/notification-templates/template-1/status", {
      method: "PATCH",
      body: JSON.stringify({ status: "inactive" }),
    })
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/notification-campaigns/campaign-1/status", {
      method: "PATCH",
      body: JSON.stringify({ status: "paused" }),
    })
  })
})
