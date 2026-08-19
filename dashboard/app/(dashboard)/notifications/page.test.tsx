import { cleanup, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const serviceMocks = vi.hoisted(() => ({
  list: vi.fn(),
  markRead: vi.fn(),
  markAllRead: vi.fn(),
}))

vi.mock("@/lib/backend-client", () => ({
  hasBackendPermission: () => false,
}))

vi.mock("@/services/notifications.service", () => ({
  notificationsService: serviceMocks,
}))

import NotificationsInboxPage from "./page"

describe("NotificationsInboxPage", () => {
  beforeEach(() => {
    serviceMocks.list.mockResolvedValue({
      items: [{
        id: "notice-1",
        title: "Guideline updated",
        message: "A published guideline has changed.",
        type: "info",
        priority: "normal",
        is_read: false,
        created_at: "2026-08-19T10:00:00Z",
        updated_at: "2026-08-19T10:00:00Z",
      }],
      page: 1,
      per_page: 20,
      total_items: 1,
      total_pages: 1,
    })
    serviceMocks.markRead.mockResolvedValue({
      id: "notice-1",
      title: "Guideline updated",
      message: "A published guideline has changed.",
      type: "info",
      priority: "normal",
      is_read: true,
      created_at: "2026-08-19T10:00:00Z",
      updated_at: "2026-08-19T10:01:00Z",
    })
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it("presents user-scoped inbox data and marks an item read", async () => {
    const user = userEvent.setup()
    render(<NotificationsInboxPage />)

    expect(await screen.findByText("Guideline updated")).toBeInTheDocument()
    expect(screen.getByText("Notices visible to your signed-in account")).toBeInTheDocument()
    expect(screen.queryByRole("link", { name: /Administration/ })).not.toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Mark Guideline updated as read" }))

    await waitFor(() => expect(serviceMocks.markRead).toHaveBeenCalledWith("notice-1"))
    expect(screen.getByText("Read")).toBeInTheDocument()
  })
})
