import { describe, expect, it } from "vitest"

import { getAppFileLabel } from "./app-file"

describe("getAppFileLabel", () => {
  it("extracts names from normalized and serialized file values", () => {
    expect(getAppFileLabel({ name: "triage.html", path: "uploads/triage.html" }))
      .toBe("triage.html")
    expect(getAppFileLabel('{"name":"dosage.html","path":"uploads/dosage.html"}'))
      .toBe("dosage.html")
  })

  it("falls back safely without rendering objects as React children", () => {
    expect(getAppFileLabel({ path: "uploads/checklist.html" }))
      .toBe("uploads/checklist.html")
    expect(getAppFileLabel("legacy-calculator.html")).toBe("legacy-calculator.html")
    expect(getAppFileLabel({ unexpected: true })).toBe("")
    expect(getAppFileLabel(null)).toBe("")
  })
})
