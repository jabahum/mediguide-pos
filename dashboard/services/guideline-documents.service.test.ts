import { beforeEach, describe, expect, it, vi } from "vitest"

const request = vi.fn()

vi.mock("@/lib/backend-client", () => ({
  getBackendClient: () => ({ request }),
}))

import { GuidelineDocumentsService } from "./guideline-documents.service"

describe("GuidelineDocumentsService notification campaigns", () => {
  beforeEach(() => request.mockReset())

  it("creates a draft through the published-guideline endpoint", async () => {
    request.mockResolvedValue({ id: "campaign-1", status: "draft" })
    const payload = {
      audience: {
        all_eligible: true,
        preference_categories: ["clinical_content_updates"],
      },
      timezone: "Africa/Kampala",
      priority: "high" as const,
      requested_channels: ["push" as const, "in-app" as const],
      idempotency_key: "guideline-document-1-123",
    }

    await GuidelineDocumentsService.createNotificationCampaign(
      "document-1",
      payload,
    )

    expect(request).toHaveBeenCalledWith(
      "/api/v2/guidelines/document-1/notification-campaign",
      { method: "POST", body: JSON.stringify(payload) },
    )
  })
})
