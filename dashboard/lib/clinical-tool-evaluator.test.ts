import { describe, expect, it } from "vitest"
import { previewClinicalTool } from "./clinical-tool-evaluator"
import type { ClinicalToolDefinition } from "@/services/clinical-tool.service"

const definition: ClinicalToolDefinition = {
  schema_version: "1.0", tool_type: "calculator", title: "BMI", version: "1.0.0", locale: "en",
  inputs: [{ key: "weight", type: "number", label: "Weight", required: true }, { key: "height", type: "number", label: "Height", required: true }], sections: [], rules: [], warnings: [], citations: [],
  calculation: [{ key: "bmi", expression: { op: "divide", args: [{ op: "field", field: "weight" }, { op: "multiply", args: [{ op: "field", field: "height" }, { op: "field", field: "height" }] }] } }],
  outputs: [{ key: "result", label: "BMI", value: { op: "round", precision: 1, args: [{ op: "field", field: "bmi" }] } }],
  interpretations: [{ key: "high", when: { op: "greater_than_or_equal", args: [{ op: "field", field: "result" }, { op: "literal", value: 25 }] }, label: "Above healthy range", severity: "warning", recommendations: ["Review clinically"], order: 1 }],
  completion: { mode: "none", reset_confirmation: true }, test_cases: [],
}

describe("clinical tool preview", () => {
  it("evaluates restricted expressions without authored code", () => {
    expect(previewClinicalTool(definition, { weight: 80, height: 1.7 })).toEqual({ values: { result: 27.7 }, normalizedInputs: { weight: 80, height: 1.7 }, interpretation: "Above healthy range", recommendations: ["Review clinically"], warnings: [] })
  })
  it("rejects operations outside the allowlist", () => {
    const unsafe = structuredClone(definition); unsafe.outputs[0].value = { op: "eval", value: "alert(1)" }
    expect(() => previewClinicalTool(unsafe, { weight: 80, height: 1.7 })).toThrow("Unsupported preview operation")
  })
})
