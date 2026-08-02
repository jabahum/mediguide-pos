import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  clearPublicMarkdownCache,
  getPublicGuidelineMarkdown,
  listPublicGuidelines,
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
});
