import { beforeEach, describe, expect, it, vi } from "vitest"

const request = vi.fn()

vi.mock("@/lib/backend-client", () => ({
  getBackendClient: () => ({ request }),
}))

import { GuidelineDocumentsService } from "./guideline-documents.service"

describe("GuidelineDocumentsService", () => {
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

  it("normalizes nullable review workspace collections from historical rows", async () => {
    request.mockResolvedValue({
      version: { id: "version-1", version: "1" },
      sections: null,
      blocks: null,
      assets: null,
      extraction_warnings: null,
      validation: { valid: true, errors: null, warnings: null },
      block_review_policy: {
        high_risk_types: null,
        bulk_review_eligible_types: null,
        conditional_risk_types: null,
        ineligible_bulk_types: null,
      },
    })

    const workspace =
      await GuidelineDocumentsService.getReviewWorkspace("version-1")

    expect(workspace.sections).toEqual([])
    expect(workspace.blocks).toEqual([])
    expect(workspace.assets).toEqual([])
    expect(workspace.extraction_warnings).toEqual([])
    expect(workspace.validation).toEqual({
      valid: true,
      errors: [],
      warnings: [],
    })
    expect(workspace.block_review_policy).toEqual({
      high_risk_types: [],
      bulk_review_eligible_types: [],
      conditional_risk_types: [],
      ineligible_bulk_types: [],
    })
  })
})
