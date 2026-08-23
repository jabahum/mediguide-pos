import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { renderPreview } from "./page";
import type { ClinicalToolDefinition } from "@/services/clinical-tool.service";

const definition: ClinicalToolDefinition = {
  schema_version: "1.0",
  tool_type: "calculator",
  title: "BMI",
  version: "1.0.0",
  locale: "en",
  inputs: [{ key: "weight", type: "number", label: "Weight", required: true }],
  sections: [],
  calculation: [],
  rules: [],
  outputs: [
    { key: "result", label: "Result", value: { op: "field", field: "weight" } },
  ],
  interpretations: [],
  completion: { mode: "none", reset_confirmation: true },
  test_cases: [],
};

describe("native clinical-tool preview", () => {
  it("renders and evaluates schema controls without an iframe", () => {
    const { container } = render(
      renderPreview({ definition, previewError: null }),
    );
    fireEvent.change(screen.getByLabelText("Weight *"), {
      target: { value: "72" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Calculate" }));
    expect(screen.getByText("Result:")).toBeInTheDocument();
    expect(screen.getByText("72")).toBeInTheDocument();
    expect(container.querySelector("iframe")).toBeNull();
  });
  it("fails closed without a reviewed schema", () => {
    render(
      renderPreview({
        definition: null,
        previewError: "A reviewed schema is required.",
      }),
    );
    expect(
      screen.getByText("Native clinical tool unavailable"),
    ).toBeInTheDocument();
  });
});
