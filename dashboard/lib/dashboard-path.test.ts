import { describe, expect, test } from "vitest"

import { withDashboardBasePath } from "./dashboard-path"

describe("withDashboardBasePath", () => {
  test("prefixes dashboard paths with the configured base path", () => {
    expect(withDashboardBasePath("/users/123")).toBe("/admin/users/123")
  })

  test("does not prefix an already-prefixed dashboard path", () => {
    expect(withDashboardBasePath("/admin/users/123")).toBe("/admin/users/123")
  })

  test("leaves external protocols untouched", () => {
    expect(withDashboardBasePath("https://example.org/help")).toBe(
      "https://example.org/help",
    )
    expect(withDashboardBasePath("tel:+256700000000")).toBe("tel:+256700000000")
  })
})
