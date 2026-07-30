import { describe, expect, it } from "vitest"

import {
  getAppFileLabel,
  getBundledAppFileName,
  getBundledAppFileUrl,
} from "./app-file"

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

  it("maps stored PocketBase filenames to bundled sample routes", () => {
    const value = {
      name: "emergency_triage_assessment_7gp8xwwbiv.html",
      path: "emergency_triage_assessment_7gp8xwwbiv.html",
    }

    expect(getBundledAppFileName(value))
      .toBe("emergency-triage-assessment.html")
    expect(getBundledAppFileUrl(value))
      .toBe("/decision-tools/samples/emergency-triage-assessment.html")
    expect(getBundledAppFileUrl("calculator.pdf")).toBe("")
  })
})
