import { afterEach, describe, expect, it, vi } from "vitest";
import { emergencyProtocolService } from "./emergency-protocol.service";
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify({ success: true, data }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
describe("emergencyProtocolService", () => {
  afterEach(() => vi.unstubAllGlobals());
  it("uses typed list filters", async () => {
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
    await emergencyProtocolService.list({
      status: "active",
      category: "Trauma",
      priority: "critical",
    });
    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain("/api/v2/emergency-protocols");
    expect(url).toContain("category=Trauma");
    expect(url).not.toContain("filter=");
  });
  it("writes structured payloads to the typed endpoint", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      json(
        {
          id: "p-1",
          title: "Triage",
          category: "Trauma",
          priority: "high",
          status: "draft",
        },
        201,
      ),
    );
    vi.stubGlobal("fetch", fetchMock);
    await emergencyProtocolService.create({
      title: "Triage",
      category: "Trauma",
      priority: "high",
      status: "draft",
      steps: [{ action: "Assess" }],
    });
    expect((fetchMock.mock.calls[0][1] as RequestInit).method).toBe("POST");
    expect(
      JSON.parse(String((fetchMock.mock.calls[0][1] as RequestInit).body)),
    ).toMatchObject({ steps: [{ action: "Assess" }] });
  });
});
