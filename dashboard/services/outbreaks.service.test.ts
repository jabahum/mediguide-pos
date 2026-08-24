import { beforeEach, describe, expect, it, vi } from "vitest"

const send = vi.fn()
vi.mock("@/lib/backend-client", () => ({ getBackendClient: () => ({ send }) }))

import { outbreaksService, situationReportsService } from "./outbreaks.service"
import type { OutbreakCampaignInput } from "./outbreaks.service"

describe("typed outbreak administration services", () => {
  beforeEach(() => send.mockReset())

  it("uses optimistic locking for workflow transitions", async () => {
    send.mockResolvedValue({ id: "outbreak-1", status: "pending_review" })
    await outbreaksService.transition("outbreak-1", "submit", { lock_version: 4 })
    expect(send).toHaveBeenCalledWith("/api/v2/outbreaks/outbreak-1/submit", {
      method: "POST",
      body: JSON.stringify({ lock_version: 4 }),
    })
  })

  it("creates campaign drafts only through content-specific endpoints", async () => {
    const input: OutbreakCampaignInput = {
      kind: "publication",
      audience: { all_eligible: true, preference_categories: ["outbreak_alerts"] },
      timezone: "Africa/Kampala",
      priority: "high",
      requested_channels: ["push", "in-app"],
      idempotency_key: "report-1-v1",
      confirmed_urgent: false,
    }
    send.mockResolvedValue({ id: "campaign-1", status: "draft" })
    await situationReportsService.createCampaign("report-1", input)
    expect(send).toHaveBeenCalledWith("/api/v2/situation-reports/report-1/notification-campaign", {
      method: "POST",
      body: JSON.stringify(input),
    })
  })

  it("uses dedicated correction endpoints for published child content", async () => {
    send.mockResolvedValue({ id: "correction-1", status: "draft" })

    await outbreaksService.correctUpdate("outbreak-1", "update-1", {
      lock_version: 7,
      reason: "Correct the verified case total",
    })
    await outbreaksService.correctResource("outbreak-1", "resource-1", {
      lock_version: 3,
      reason: "Replace the superseded clinical link",
    })

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/outbreaks/outbreak-1/updates/update-1/correct", {
      method: "POST",
      body: JSON.stringify({ lock_version: 7, reason: "Correct the verified case total" }),
    })
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/outbreaks/outbreak-1/resources/resource-1/correct", {
      method: "POST",
      body: JSON.stringify({ lock_version: 3, reason: "Replace the superseded clinical link" }),
    })
  })

  it("uses typed managed-document upload and clinical workflow endpoints", async () => {
    send
      .mockResolvedValueOnce({ id: "document-1", status: "draft", lock_version: 2 })
      .mockResolvedValueOnce({ id: "document-1", status: "pending_review", lock_version: 3 })
      .mockResolvedValueOnce({ items: [], page: 1, per_page: 100, total_items: 0, total_pages: 0 })

    const file = new File(["%PDF-1.7\n%%EOF"], "protocol.pdf", { type: "application/pdf" })
    await outbreaksService.uploadDocument("outbreak-1", "document-1", 1, file)
    await outbreaksService.transitionDocument("outbreak-1", "document-1", "approve", { lock_version: 2, reason: "Clinically reviewed" })
    await outbreaksService.documentAudit("outbreak-1", "document-1")

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/outbreaks/outbreak-1/documents/document-1/file", expect.objectContaining({ method: "PUT", query: { lock_version: 1 }, body: expect.any(FormData) }))
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/outbreaks/outbreak-1/documents/document-1/approve", { method: "POST", body: JSON.stringify({ lock_version: 2, reason: "Clinically reviewed" }) })
    expect(send).toHaveBeenNthCalledWith(3, "/api/v2/outbreaks/outbreak-1/documents/document-1/audit", { query: { page: 1, per_page: 100 } })
  })
})
