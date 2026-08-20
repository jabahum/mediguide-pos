import { cleanup, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const serviceMocks = vi.hoisted(() => ({
  listTemplates: vi.fn(),
  listCampaigns: vi.fn(),
  firebaseStatus: vi.fn(),
  estimateAudience: vi.fn(),
  preferenceAggregates: vi.fn(),
}))

vi.mock("@/lib/backend-client", () => ({
  hasBackendPermission: () => true,
}))

vi.mock("@/lib/permission-context", () => ({
  usePermissionContext: () => ({ loading: false }),
}))

vi.mock("@/services/notifications.service", () => ({
  notificationsService: {
    listTemplates: serviceMocks.listTemplates,
    listCampaigns: serviceMocks.listCampaigns,
    estimateAudience: serviceMocks.estimateAudience,
    preferenceAggregates: serviceMocks.preferenceAggregates,
  },
}))

vi.mock("@/services/firebase.service", () => ({
  firebaseService: { status: serviceMocks.firebaseStatus },
}))

import NotificationAdministrationPage from "./page"

describe("NotificationAdministrationPage", () => {
  beforeEach(() => {
    serviceMocks.listTemplates.mockResolvedValue({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 })
    serviceMocks.listCampaigns.mockResolvedValue({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 })
    serviceMocks.firebaseStatus.mockResolvedValue({ enabled: false })
    serviceMocks.estimateAudience.mockResolvedValue({ eligible_users: 12, active_devices: 8 })
    serviceMocks.preferenceAggregates.mockResolvedValue({ eligible_users: 20, push_enabled_users: 15, in_app_enabled_users: 18, quiet_hours_users: 5, active_devices: 16, push_enabled_devices: 12, devices_by_platform: { android: 10, ios: 6 }, category_opt_in_counts: {} })
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it("enables authoring while honestly separating workflow from delivery fan-out", async () => {
    const user = userEvent.setup()
    render(<NotificationAdministrationPage />)

    await waitFor(() => expect(screen.getByText("Notification Administration")).toBeInTheDocument())
    expect(screen.getByText(/approval resolves and freezes the audience/i)).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "New template" })).toBeEnabled()
    await user.click(screen.getByRole("tab", { name: "Campaigns" }))
    expect(screen.getByRole("button", { name: "New campaign" })).toBeDisabled()
    expect(screen.queryByText(/Test Mode/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/delivery rate/i)).not.toBeInTheDocument()
    expect(screen.getByText("15/20")).toBeInTheDocument()
  })

  it("shows server-estimated user and device counts before campaign approval", async () => {
    serviceMocks.listTemplates.mockResolvedValue({
      items: [{ id: "template-1", name: "Clinical update", status: "published", current_version: 1, locale: "en", version: { id: "version-1", template_id: "template-1", version: 1, channel: "push", status: "published", variable_schema: {}, category: "Clinical", locale: "en", body_template: "Update", action_template: { type: "none", parameters: {} }, created_at: "2026-08-20T00:00:00Z" }, created_at: "2026-08-20T00:00:00Z", updated_at: "2026-08-20T00:00:00Z" }],
      page: 1, per_page: 50, total_items: 1, total_pages: 1,
    })
    const user = userEvent.setup()
    render(<NotificationAdministrationPage />)
    await screen.findByText("Notification Administration")
    await user.click(screen.getByRole("tab", { name: "Campaigns" }))
    await user.click(screen.getByRole("button", { name: "New campaign" }))
    await user.click(screen.getByRole("button", { name: "Estimate audience" }))
    await waitFor(() => expect(serviceMocks.estimateAudience).toHaveBeenCalledWith({ all_eligible: true }))
    expect(screen.getByText((_, element) => element?.tagName === "P" && element.textContent === "12 eligible users · 8 active devices")).toBeInTheDocument()
  })
})
