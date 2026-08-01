import { afterEach, describe, expect, it, vi } from "vitest"

import { SupportTicketsService } from "./support-tickets.service"

describe("SupportTicketsService", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("uses typed ticket filters instead of resource expressions", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: { items: [], page: 1, per_page: 20, total_items: 0, total_pages: 0 },
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    )
    vi.stubGlobal("fetch", fetchMock)

    await SupportTicketsService.getTickets({ status: "open", search: "login" })

    const url = String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/support/tickets")
    expect(url).toContain("status=open")
    expect(url).toContain("search=login")
    expect(url).not.toContain("filter=")
  })

  it("does not send a client-provided owner when creating a ticket", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: {
          id: "ticket-1",
          user_id: "server-owner",
          subject: "Login",
          description: "Cannot sign in",
          status: "open",
          priority: "normal",
        },
      }), { status: 201, headers: { "Content-Type": "application/json" } }),
    )
    vi.stubGlobal("fetch", fetchMock)

    await SupportTicketsService.createTicket({
      user_id: "untrusted-owner",
      subject: "Login",
      description: "Cannot sign in",
      priority: "normal",
      category: "Account Problem",
    })

    const init = fetchMock.mock.calls[0][1] as RequestInit
    expect(JSON.parse(String(init.body))).not.toHaveProperty("user_id")
  })
})
