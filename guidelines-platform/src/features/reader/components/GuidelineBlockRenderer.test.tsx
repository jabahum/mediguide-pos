import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import type { PublicGuidelineBlock } from "../../../api/public-guidelines";
import { GuidelineBlockRenderer } from "./GuidelineBlockRenderer";

function block(overrides: Partial<PublicGuidelineBlock>): PublicGuidelineBlock {
  return {
    id: "block-id",
    type: "paragraph",
    sort_order: 1,
    content: { text: "Published guidance" },
    ...overrides,
  };
}

describe("GuidelineBlockRenderer", () => {
  it("renders typed tables without interpreting cell content as HTML", () => {
    const html = renderToStaticMarkup(<GuidelineBlockRenderer block={block({
      type: "table",
      content: {
        title: "Dose table",
        columns: ["Medicine", "Dose"],
        rows: [["Example", "<script>alert(1)</script>"]],
      },
    })} />);

    expect(html).toContain("Dose table");
    expect(html).toContain("&lt;script&gt;alert(1)&lt;/script&gt;");
    expect(html).not.toContain("<script>");
  });

  it("uses a safe fallback for unknown block types", () => {
    const html = renderToStaticMarkup(<GuidelineBlockRenderer block={block({
      type: "future_interactive_widget",
      content: { html: "<iframe src='https://example.org'></iframe>" },
    })} />);

    expect(html).toContain("content type is not available");
    expect(html).not.toContain("iframe");
  });

  it("does not render non-http figure asset URLs", () => {
    const html = renderToStaticMarkup(<GuidelineBlockRenderer
      block={block({ type: "figure", content: { alternative_text: "Clinical flow" } })}
      figure={{
        id: "block-id",
        sort_order: 1,
        content: { type: "figure", asset_id: "asset-id", alternative_text: "Clinical flow" },
        asset: { type: "figure", mime_type: "image/svg+xml", url: "javascript:alert(1)", expires_at: "2026-08-10T10:00:00Z" },
      }}
    />);

    expect(html).toContain("Reviewed figure unavailable");
    expect(html).not.toContain("javascript:");
  });
});
