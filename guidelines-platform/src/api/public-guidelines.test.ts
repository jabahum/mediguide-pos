import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  askPublicGuideline,
  clearPublicMarkdownCache,
  getPublicGuidelineManifest,
  getPublicGuidelineContent,
  getPublicGuidelineMarkdown,
  listPublicGuidelines,
  searchPublicContent,
} from "./public-guidelines";

describe("public guideline API client", () => {
  beforeEach(() => clearPublicMarkdownCache());

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("loads metadata with encoded filters and does not request Markdown", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: { items: [], page: 1, per_page: 20, total_items: 0, total_pages: 0 },
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await listPublicGuidelines({ search: "maternal & child", programArea: "Care" });

    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain("search=maternal+%26+child");
    expect(url).toContain("program_area=Care");
    expect(url).not.toContain("/markdown");
  });

  it("sends every disease and hub discovery filter to unified public search", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, data: [] }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await searchPublicContent("EVD care", {
      categoryId: "category-id",
      diseaseSlug: "evd",
      hubSlug: "ebola-response",
      pillarSlug: "clinical-care",
      contentType: "guideline",
      limit: 17,
    });

    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain("q=EVD+care");
    expect(url).toContain("category_id=category-id");
    expect(url).toContain("disease_slug=evd");
    expect(url).toContain("hub_slug=ebola-response");
    expect(url).toContain("pillar_slug=clinical-care");
    expect(url).toContain("content_type=guideline");
    expect(url).toContain("limit=17");
  });

  it("revalidates cached Markdown with an ETag and reuses it on 304", async () => {
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(new Response("# Published", {
        status: 200,
        headers: { ETag: '"sha256-one"', "Content-Type": "text/markdown" },
      }))
      .mockResolvedValueOnce(new Response(null, { status: 304 }));
    vi.stubGlobal("fetch", fetchMock);

    const first = await getPublicGuidelineMarkdown("guideline-id");
    const second = await getPublicGuidelineMarkdown("guideline-id");

    expect(first).toMatchObject({ content: "# Published", fromCache: false });
    expect(second).toMatchObject({ content: "# Published", fromCache: true });
    const secondOptions = fetchMock.mock.calls[1][1] as RequestInit;
    expect((secondOptions.headers as Record<string, string>)["If-None-Match"])
      .toBe('"sha256-one"');
  });

  it("validates and conditionally revalidates each document manifest", async () => {
    const manifest = {
      guideline_id: "guideline-id",
      version_id: "version-id",
      version: "2.1",
      schema_version: 1,
      package_version: 3,
      extraction_quality: "reviewed",
      has_chapters: true,
      has_key_points: true,
      has_tables: false,
      has_figures: false,
      has_algorithms: false,
      has_original_pdf: true,
      has_offline_package: true,
      section_count: 7,
      reviewed_section_count: 5,
      leaf_section_count: 4,
      reviewed_leaf_section_count: 3,
      empty_leaf_section_count: 1,
      block_count: 42,
      reviewed_paragraph_count: 31,
      table_count: 0,
      figure_count: 0,
      algorithm_count: 0,
      checksum: "sha256-document",
      etag: '"manifest-v3"',
      generated_at: "2026-08-10T10:00:00Z",
    };
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ success: true, data: manifest }), {
        status: 200,
        headers: { ETag: '"manifest-v3"', "Content-Type": "application/json" },
      }))
      .mockResolvedValueOnce(new Response(null, { status: 304 }));
    vi.stubGlobal("fetch", fetchMock);

    const first = await getPublicGuidelineManifest("guideline/id");
    expect(first).toEqual(manifest);
    expect(first.section_count).toBe(7);
    expect(first.reviewed_section_count).toBe(5);
    expect(first.reviewed_leaf_section_count).toBe(3);
    expect(first.empty_leaf_section_count).toBe(1);
    expect(await getPublicGuidelineManifest("guideline/id")).toEqual(manifest);
    expect(String(fetchMock.mock.calls[0][0])).toContain("guideline%2Fid/manifest");
    const secondOptions = fetchMock.mock.calls[1][1] as RequestInit;
    expect((secondOptions.headers as Record<string, string>)["If-None-Match"])
      .toBe('"manifest-v3"');
  });

  it("rejects malformed structured manifests instead of rendering dynamic data", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, data: { guideline_id: "guideline-id" } }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    ));

    await expect(getPublicGuidelineManifest("guideline-id")).rejects.toMatchObject({
      kind: "invalid-response",
    });
  });

  it("rejects structured content from a different publication identity", async () => {
    const manifest = {
      guideline_id: "guideline-id", version_id: "version-2", version: "2",
      schema_version: 2, package_version: 2, extraction_quality: "reviewed" as const,
      has_chapters: true, has_key_points: false, has_tables: false,
      has_figures: false, has_algorithms: false, has_original_pdf: false,
      has_offline_package: false, section_count: 1, block_count: 1,
      table_count: 0, figure_count: 0, algorithm_count: 0,
      checksum: "new-checksum", etag: "new-etag", generated_at: "2026-09-09T00:00:00Z",
    };
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({
      success: true,
      data: {
        guideline_id: "guideline-id", version_id: "version-1",
        package_version: 1, checksum: "old-checksum", sections: [], blocks: [],
      },
    }), { status: 200, headers: { "Content-Type": "application/json" } })));

    await expect(getPublicGuidelineContent("guideline-id", manifest)).rejects.toMatchObject({
      kind: "invalid-response",
    });
  });

  it("invalidates structured content when the publication manifest changes", async () => {
    const manifest = (version: string, packageVersion: number, checksum: string) => ({
      guideline_id: "guideline-id", version_id: version, version,
      schema_version: 2, package_version: packageVersion, extraction_quality: "reviewed" as const,
      has_chapters: true, has_key_points: false, has_tables: false,
      has_figures: false, has_algorithms: false, has_original_pdf: false,
      has_offline_package: false, section_count: 1, block_count: 1,
      table_count: 0, figure_count: 0, algorithm_count: 0,
      checksum, etag: `etag-${version}`, generated_at: "2026-09-09T00:00:00Z",
    });
    const firstManifest = manifest("version-1", 1, "checksum-1");
    const secondManifest = manifest("version-2", 2, "checksum-2");
    const content = (value: typeof firstManifest) => ({
      guideline_id: value.guideline_id, version_id: value.version_id,
      package_version: value.package_version, checksum: value.checksum,
      sections: [], blocks: [],
    });
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ success: true, data: firstManifest }), { status: 200, headers: { "Content-Type": "application/json" } }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ success: true, data: content(firstManifest) }), { status: 200, headers: { "Content-Type": "application/json", ETag: '"content-1"' } }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ success: true, data: secondManifest }), { status: 200, headers: { "Content-Type": "application/json" } }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ success: true, data: content(secondManifest) }), { status: 200, headers: { "Content-Type": "application/json", ETag: '"content-2"' } }));
    vi.stubGlobal("fetch", fetchMock);

    const first = await getPublicGuidelineManifest("guideline-id");
    await getPublicGuidelineContent("guideline-id", first);
    const second = await getPublicGuidelineManifest("guideline-id");
    const current = await getPublicGuidelineContent("guideline-id", second);

    expect(current.version_id).toBe("version-2");
    expect(fetchMock).toHaveBeenCalledTimes(4);
    const finalHeaders = fetchMock.mock.calls[3][1]?.headers as Record<string, string>;
    expect(finalHeaders["If-None-Match"]).toBeUndefined();
  });

  it("aborts an in-flight request when navigation is cancelled", async () => {
    vi.stubGlobal("fetch", vi.fn((_url: string, options: RequestInit) =>
      new Promise((_resolve, reject) => {
        options.signal?.addEventListener("abort", () => {
          reject(new DOMException("Aborted", "AbortError"));
        });
      }),
    ));
    const controller = new AbortController();
    const request = listPublicGuidelines({}, controller.signal);
    controller.abort();
    await expect(request).rejects.toMatchObject({ name: "AbortError" });
  });

  it("deduplicates concurrent list requests and keeps the result briefly", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: { items: [], page: 1, per_page: 20, total_items: 0, total_pages: 0 },
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await Promise.all([listPublicGuidelines(), listPublicGuidelines()]);
    await listPublicGuidelines();

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("exposes Retry-After on rate-limit responses", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: false, error: "rate limit exceeded" }), {
        status: 429,
        headers: { "Retry-After": "17", "Content-Type": "application/json" },
      }),
    ));

    await expect(listPublicGuidelines()).rejects.toMatchObject({
      kind: "rate-limited",
      status: 429,
      retryAfterSeconds: 17,
    });
  });

  it("asks the exact encoded published guideline and validates citations", async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({
      success: true,
      data: { answer: "Use the cited recommendation.", citations: [{ chunk_id: "chunk-1", guideline_id: "guide/id", title: "Treatment", source_name: "MoH", source_version: "2" }] },
    }), { status: 200, headers: { "Content-Type": "application/json" } }));
    vi.stubGlobal("fetch", fetchMock);

    const answer = await askPublicGuideline("guide/id", "  What is the treatment?  ");

    expect(answer.citations[0].title).toBe("Treatment");
    expect(String(fetchMock.mock.calls[0][0])).toContain("guidelines/guide%2Fid/ask");
    const options = fetchMock.mock.calls[0][1] as RequestInit;
    expect(options.method).toBe("POST");
    expect(JSON.parse(String(options.body))).toEqual({ question: "What is the treatment?" });
  });
});
