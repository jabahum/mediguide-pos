import { afterEach, describe, expect, it, vi } from "vitest";

import { calculatorService } from "./calculator.service";
import { drugReferenceService, drugService } from "./drug.service";

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify({ success: true, data }), {
    status,
    headers: { "Content-Type": "application/json" },
  });

describe("typed calculator and drug services", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("serializes calculator list filters as typed query parameters", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      json({
        items: [],
        page: 1,
        per_page: 20,
        total_items: 0,
        total_pages: 0,
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await calculatorService.listTable(
      { page: 1, perPage: 20, search: "triage", filters: [] },
      "decision_tool",
    );

    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain("/api/v2/calculators");
    expect(url).toContain("search=triage");
    expect(url).toContain("type=decision_tool");
    expect(url).not.toContain("filter=");
    expect(url).not.toContain("expand=");
  });

  it("maps legacy drug form fields to the typed drug DTO", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      json(
        {
          id: "drug-1",
          name: "Example",
          status: "active",
          review_status: "approved",
        },
        201,
      ),
    );
    vi.stubGlobal("fetch", fetchMock);

    await drugService.create({
      name: "Example",
      categories: ["category-1"],
      tags: ["tag-1"],
      drug_class: "class-1",
      therapeutic_category: "therapy-1",
      references: "Clinical reference",
    });

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect(JSON.parse(String(init.body))).toMatchObject({
      categories: ["category-1"],
      tags: ["tag-1"],
      drug_class_id: "class-1",
      therapeutic_category_id: "therapy-1",
      reference_text: "Clinical reference",
    });
  });

  it("loads active drug references without PocketBase filter expressions", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      json({
        items: [],
        page: 1,
        per_page: 100,
        total_items: 0,
        total_pages: 0,
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await drugReferenceService.allCategories();

    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain("/api/v2/drug-categories");
    expect(url).toContain("status=active");
    expect(url).not.toContain("filter=");
  });
});
