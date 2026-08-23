import { readFileSync } from "node:fs"
import { join } from "node:path"
import { describe, expect, it } from "vitest"

import type { ClinicalToolDefinition } from "@/services/clinical-tool.service"
import { previewClinicalTool } from "./clinical-tool-evaluator"

type MigrationEnvelope = {
  definition: ClinicalToolDefinition & {
    test_cases: Array<{ key: string; inputs: Record<string, unknown>; expected: Record<string, unknown>; numeric_tolerance?: number }>
  }
}

const files = ["apgar-score-calculator", "blood-pressure-assessment", "bmi-calculator", "glasgow-coma-scale"]

describe("Wave 1 clinical-tool migration drafts", () => {
  for (const file of files) {
    const envelope = JSON.parse(readFileSync(join(process.cwd(), "..", "clinical-tools", "migrations", "v1", "definitions", `${file}.json`), "utf8")) as MigrationEnvelope
    const parity = JSON.parse(readFileSync(join(process.cwd(), "..", "clinical-tools", "migrations", "v1", "parity", `${file}.json`), "utf8")) as { status: string; reviewer_id: string | null; reviewed_at: string | null }

    it(`${file} remains explicitly unapproved`, () => {
      expect(parity.status).toBe("changes_required")
      expect(parity.reviewer_id).toBeNull()
      expect(parity.reviewed_at).toBeNull()
    })

    for (const fixture of envelope.definition.test_cases) {
      it(`${file}: ${fixture.key}`, () => {
        const result = previewClinicalTool(envelope.definition, fixture.inputs)
        const outputKeys = new Set(envelope.definition.outputs.map((output) => output.key))
        const tolerance = fixture.numeric_tolerance ?? 0
        for (const [key, expectedValue] of Object.entries(fixture.expected)) {
          if (outputKeys.has(key)) {
            if (typeof expectedValue === "number") expect(Number(result.values[key])).toBeCloseTo(expectedValue, tolerance > 0 ? 6 : 10)
            else expect(result.values[key]).toEqual(expectedValue)
          }
        }
        const expectedInterpretations = fixture.expected.interpretations as string[] | undefined
        if (expectedInterpretations) {
          const expected = envelope.definition.interpretations.find((item) => item.key === expectedInterpretations[0])
          expect(result.interpretation).toBe(expected?.label)
        }
        const expectedWarningKeys = fixture.expected.warnings as string[] | undefined
        if (expectedWarningKeys) {
          const expectedWarnings = expectedWarningKeys.map((key) => envelope.definition.warnings?.find((item) => item.key === key)?.text)
          expect(result.warnings).toEqual(expectedWarnings)
        }
      })
    }
  }
})
