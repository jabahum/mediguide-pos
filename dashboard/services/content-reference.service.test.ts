import { afterEach, describe, expect, it, vi } from "vitest"

import { GenericPagesService } from "./generic-pages.service"
import { LocalizationService } from "./localization.service"

vi.mock("@/lib/toast", () => ({
  showToast: { success: vi.fn(), error: vi.fn() },
}))

const json = (data: unknown, status = 200) => new Response(
  JSON.stringify({ success: true, data }),
  { status, headers: { "Content-Type": "application/json" } },
)

describe("typed content reference services", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("lists generic pages with explicit query parameters", async () => {
    const fetchMock = vi.fn().mockResolvedValue(json({
      items: [{ id: "p-1", key: "about", title: "About", content: {} }],
      page: 2,
      per_page: 10,
      total_items: 11,
      total_pages: 2,
    }))
    vi.stubGlobal("fetch", fetchMock)
    const result = await GenericPagesService.list({ page: 2, perPage: 10, search: "about" })
    const url = String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/pages")
    expect(url).toContain("search=about")
    expect(url).not.toContain("filter=")
    expect(result.items[0].created).toBe("")
  })

  it("uses typed language filters without compatibility expressions", async () => {
    const fetchMock = vi.fn().mockResolvedValue(json({
      items: [], page: 1, per_page: 100, total_items: 0, total_pages: 0,
    }))
    vi.stubGlobal("fetch", fetchMock)
    await LocalizationService.getAllLanguages({
      status: ["draft", "review"],
      is_active: true,
      enabled_for_users: true,
      search: "luganda",
    }, "-progress")
    const url = String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/languages")
    expect(url).toContain("status=draft%2Creview")
    expect(url).toContain("order=desc")
    expect(url).not.toContain("filter=")
  })
})
