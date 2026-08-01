import { afterEach, describe, expect, it, vi } from "vitest"

import { DocumentationService } from "./documentation.service"
import { FaqService } from "./faq.service"

const pageResponse = (items: unknown[] = []) =>
  new Response(JSON.stringify({
    success: true,
    data: {
      items,
      page: 1,
      per_page: 20,
      total_items: items.length,
      total_pages: items.length ? 1 : 0,
    },
  }), { status: 200, headers: { "Content-Type": "application/json" } })

describe("typed help-content services", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("uses typed FAQ query parameters instead of resource filters", async () => {
    const fetchMock = vi.fn().mockResolvedValue(pageResponse())
    vi.stubGlobal("fetch", fetchMock)

    await FaqService.loadPage({ page: 1, perPage: 20, search: "password reset" })

    const url = String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/faqs")
    expect(url).toContain("search=password+reset")
    expect(url).not.toContain("filter=")
    expect(url).not.toContain("expand=")
  })

  it("creates documentation through its dedicated endpoint", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: {
          id: "doc-1",
          title: "Account help",
          content: "Help content",
          status: "draft",
        },
      }), { status: 201, headers: { "Content-Type": "application/json" } }),
    )
    vi.stubGlobal("fetch", fetchMock)

    await DocumentationService.create({ title: "Account help", content: "Help content" })

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit]
    expect(String(url)).toContain("/api/v2/documentation")
    expect(init.method).toBe("POST")
    expect(JSON.parse(String(init.body))).toMatchObject({
      title: "Account help",
      content: "Help content",
      status: "draft",
    })
  })
})
