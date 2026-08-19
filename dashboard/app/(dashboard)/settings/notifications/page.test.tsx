import { cleanup, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const serviceMocks = vi.hoisted(() => ({
  listTemplates: vi.fn(),
  listCampaigns: vi.fn(),
  firebaseStatus: vi.fn(),
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
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it("states unsupported delivery behavior instead of presenting placeholder success controls", async () => {
    const user = userEvent.setup()
    render(<NotificationAdministrationPage />)

    await waitFor(() => expect(screen.getByText("Notification Administration")).toBeInTheDocument())
    expect(screen.getByText(/Scheduling, audience resolution and push dispatch will remain unavailable/)).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "New template" })).toBeDisabled()
    await user.click(screen.getByRole("tab", { name: "Campaigns" }))
    expect(screen.getByRole("button", { name: "New campaign" })).toBeDisabled()
    expect(screen.queryByText(/Test Mode/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/delivery rate/i)).not.toBeInTheDocument()
  })
})
