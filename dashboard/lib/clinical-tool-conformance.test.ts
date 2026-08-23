import { readFileSync } from "node:fs"
import { join } from "node:path"
import { describe, expect, it } from "vitest"

import type { ClinicalToolDefinition } from "@/services/clinical-tool.service"
import { previewClinicalTool } from "./clinical-tool-evaluator"

type FixtureCase = { key: string; input: Record<string, unknown>; fixed_now?: string; expected_normalized_input?: Record<string, unknown>; expected_outputs?: Record<string, unknown>; expected_interpretation?: string; expected_recommendations?: string[]; expected_warnings?: string[]; expected_checklist?: Record<string, unknown>; expected_error?: string; numeric_tolerance?: number }
type FixtureSuite = { tools: Array<{ definition: ClinicalToolDefinition; cases: FixtureCase[] }> }

const suite = JSON.parse(readFileSync(join(process.cwd(), "..", "clinical-tools", "conformance", "v1", "runtime-fixtures.json"), "utf8")) as FixtureSuite

function expectRecord(actual: Record<string, unknown>, expected: Record<string, unknown>, tolerance = 0) {
  expect(Object.keys(actual).sort()).toEqual(Object.keys(expected).sort())
  for (const [key, value] of Object.entries(expected)) {
    if (typeof value === "number") expect(Number(actual[key])).toBeCloseTo(value, tolerance > 0 ? 6 : 10)
    else expect(actual[key]).toEqual(value)
  }
}

describe("shared clinical-tool runtime conformance", () => {
  for (const tool of suite.tools) for (const fixture of tool.cases) {
    it(fixture.key, () => {
      if (fixture.expected_error) {
        expect(() => previewClinicalTool(tool.definition, fixture.input, { fixedNow: fixture.fixed_now })).toThrow()
        return
      }
      const result = previewClinicalTool(tool.definition, fixture.input, { fixedNow: fixture.fixed_now })
      expectRecord(result.normalizedInputs, fixture.expected_normalized_input!, fixture.numeric_tolerance)
      expectRecord(result.values, fixture.expected_outputs!, fixture.numeric_tolerance)
      expect(result.interpretation).toBe(fixture.expected_interpretation)
      expect(result.recommendations).toEqual(fixture.expected_recommendations!)
      expect(result.warnings).toEqual(fixture.expected_warnings!)
      if (fixture.expected_checklist) expect(result.checklist).toEqual(fixture.expected_checklist)
    })
  }
})
