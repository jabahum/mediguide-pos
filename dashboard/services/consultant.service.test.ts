import { afterEach, describe, expect, it, vi } from "vitest"

import { consultantService } from "./consultant.service"

const json = (data: unknown) => new Response(JSON.stringify(data), {
  status: 200,
  headers: { "Content-Type": "application/json" },
})

describe("consultantService", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("uses explicit query parameters and normalizes wire fields", async () => {
    const fetchMock = vi.fn().mockResolvedValue(json({
      items: [{ id: "consultant-1", name: "Dr Amina", email: "a@example.com", phone: "+256", specialty: "Cardiology", country: "Uganda", status: "active", is_verified: true }],
      page: 1,
      per_page: 20,
      total_items: 1,
      total_pages: 1,
    }))
    vi.stubGlobal("fetch", fetchMock)

    const result = await consultantService.loadPage({
      page: 1,
      perPage: 20,
      search: "amina",
      filters: [{ id: "verified", field: "verified", condition: "equals", value: true }],
    })
    const url = String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/consultants")
    expect(url).toContain("search=amina")
    expect(url).toContain("verified=true")
    expect(url).not.toContain("filter=")
    expect(result.items[0].isVerified).toBe(true)
  })
})
