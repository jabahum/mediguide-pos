import { afterEach, describe, expect, it, vi } from "vitest"

import { healthFacilitiesService } from "./health-facilities.service"

describe("healthFacilitiesService", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("loads a facility table page with explicit query parameters", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        resource: "health_facilities",
        page: 2,
        per_page: 20,
        total_items: 21,
        items: [{
          id: "facility-id",
          name: "Clinic",
          created_at: "2026-01-01T00:00:00Z",
          updated_at: "2026-01-02T00:00:00Z",
          region_id: "region-id",
          region_name: "Central",
        }],
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    )
    vi.stubGlobal("fetch", fetchMock)

    const result = await healthFacilitiesService.listFacilityTable({
      page: 2,
      perPage: 20,
      search: "clinic",
    })

    expect(fetchMock.mock.calls[0][0]).toBe(
      "http://127.0.0.1:8080/api/v2/facilities?page=2&per_page=20&search=clinic",
    )
    expect(result.totalPages).toBe(2)
    expect(result.items[0].created).toBe("2026-01-01T00:00:00Z")
    expect((result.items[0].expand as Record<string, unknown>).region).toEqual({
      id: "region-id",
      name: "Central",
    })
  })

  it("unwraps and normalizes a typed facility detail response", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        resource: "health_facilities",
        item: {
          id: "facility-id",
          name: "Clinic",
          region_id: "region-id",
          created_at: "2026-01-01T00:00:00Z",
          updated_at: "2026-01-02T00:00:00Z",
        },
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    ))

    const facility = await healthFacilitiesService.getFacility("facility-id")

    expect(facility.region).toBe("region-id")
    expect(facility.updated).toBe("2026-01-02T00:00:00Z")
  })
})
