import { beforeEach, describe, expect, it, vi } from "vitest"

const { send } = vi.hoisted(() => ({ send: vi.fn() }))
vi.mock("@/lib/backend-client", () => ({ backendClient: { send } }))

import { clinicalToolService } from "./clinical-tool.service"

describe("clinical tool reviewer service", () => {
  beforeEach(() => send.mockReset())

  it("uses a dedicated typed review queue with explicit query parameters", async () => {
    send.mockResolvedValue({ items: [], page: 1, per_page: 20, total_items: 0, total_pages: 0 })
    await clinicalToolService.reviewQueue({
      page: 2,
      status: "pending_review",
      type: "calculator",
      program_area: "Emergency care",
      sort: "created_at",
      order: "desc",
    })
    expect(send).toHaveBeenCalledOnce()
    const path = String(send.mock.calls[0][0])
    expect(path).toContain("/api/v2/calculator-versions/review-queue?")
    expect(path).toContain("status=pending_review")
    expect(path).toContain("program_area=Emergency+care")
    expect(path).not.toContain("filter=")
  })

  it("loads unpublished definitions only through reviewer preview", async () => {
    send.mockResolvedValue({ version: { id: "version-1" } })
    await clinicalToolService.reviewPreview("version-1")
    expect(send).toHaveBeenCalledWith(
      "/api/v2/calculator-versions/version-1/preview",
    )
  })

  it("submits immutable review comments through the review endpoint", async () => {
    send.mockResolvedValue(undefined)
    await clinicalToolService.reviewComment("version-1", "Check threshold wording")
    expect(send).toHaveBeenCalledWith(
      "/api/v2/calculator-versions/version-1/review-comments",
      { method: "POST", body: JSON.stringify({ comment: "Check threshold wording" }) },
    )
  })
})
