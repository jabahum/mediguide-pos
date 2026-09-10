import { describe, expect, it } from "vitest"

import { guidelineAssetMarkdown, insertMarkdownBlock } from "./guideline-asset-markdown"
import type { GuidelineAsset } from "@/services/guideline-assets.service"

const asset: GuidelineAsset = {
  id: "asset-id",
  version_id: "version-id",
  type: "figure",
  mime_type: "image/png",
  checksum: "checksum",
  size_bytes: 12,
  original_filename: "flow.png",
  alternative_text: "Treatment [flow]",
  caption: 'Confirm the "yes" branch',
  source: "UCG 2023",
  attribution: "Ministry of Health Uganda",
  license: "",
  clinically_sensitive: true,
  review_status: "draft",
  reference: "guideline-asset://3b9dfdf2-6ffc-42f4-bbd3-0bab9a6305fe",
  referenced: false,
  url: "https://example.test/asset",
  url_expires_at: "2026-09-10T12:00:00Z",
  created_at: "2026-09-10T10:00:00Z",
  updated_at: "2026-09-10T10:00:00Z",
}

describe("guideline asset Markdown", () => {
  it("creates a governed image with a caption and source attribution", () => {
    expect(guidelineAssetMarkdown(asset)).toBe(
      '![Treatment flow](guideline-asset://3b9dfdf2-6ffc-42f4-bbd3-0bab9a6305fe "Confirm the \\"yes\\" branch")\n\n' +
      "*Source: UCG 2023 · Ministry of Health Uganda*",
    )
  })

  it("separates an inserted figure from adjacent Markdown blocks", () => {
    const content = "Before paragraph.\n\nAfter paragraph."
    const from = content.indexOf("After")
    expect(insertMarkdownBlock(content, from, from, "![Flow](guideline-asset://id)")).toBe(
      "![Flow](guideline-asset://id)\n\n",
    )
  })
})
