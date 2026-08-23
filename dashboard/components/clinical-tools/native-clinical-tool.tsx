"use client";

import * as React from "react";
import {
  previewClinicalTool,
  type ClinicalToolPreviewResult,
} from "@/lib/clinical-tool-evaluator";
import type { ClinicalToolDefinition } from "@/services/clinical-tool.service";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

function inputValue(value: unknown): unknown {
  if (typeof value === "object" && value !== null && "value" in value) {
    return (value as { value: unknown }).value;
  }
  return value;
}

export function NativeClinicalTool({
  definition,
}: {
  definition: ClinicalToolDefinition;
}) {
  const [inputs, setInputs] = React.useState<Record<string, unknown>>({});
  const [units, setUnits] = React.useState<Record<string, string>>(() =>
    Object.fromEntries(
      definition.inputs.map((field) => [
        field.key,
        field.default_unit ?? field.allowed_units?.[0] ?? "",
      ]),
    ),
  );
  const [result, setResult] = React.useState<ClinicalToolPreviewResult | null>(
    null,
  );
  const [error, setError] = React.useState<string | null>(null);
  const setValue = (key: string, value: unknown) => {
    setInputs((current) => ({ ...current, [key]: value }));
    setResult(null);
    setError(null);
  };
  const run = (event: React.FormEvent) => {
    event.preventDefault();
    try {
      setResult(previewClinicalTool(definition, inputs));
      setError(null);
    } catch (cause) {
      setResult(null);
      setError(
        cause instanceof Error
          ? cause.message
          : "The tool could not be evaluated.",
      );
    }
  };

  return (
    <div className="space-y-6" data-testid="native-clinical-tool">
      {definition.warnings
        ?.filter((warning) => !warning.when)
        .map((warning) => (
          <Alert
            key={warning.key}
            variant={
              warning.severity === "critical" ? "destructive" : "default"
            }
          >
            <AlertTitle>Clinical warning</AlertTitle>
            <AlertDescription>{warning.text}</AlertDescription>
          </Alert>
        ))}
      <form className="space-y-5" onSubmit={run}>
        {definition.inputs.map((field) => {
          const id = `clinical-tool-${field.key}`;
          if (field.type === "boolean" || field.type === "checklist_item")
            return (
              <label
                key={field.key}
                htmlFor={id}
                className="flex items-start gap-3 rounded-lg border p-4"
              >
                <input
                  id={id}
                  type="checkbox"
                  checked={inputs[field.key] === true}
                  onChange={(event) =>
                    setValue(field.key, event.target.checked)
                  }
                />
                <span>
                  <span className="font-medium">{field.label}</span>
                  {field.required ? (
                    <span aria-label="required"> *</span>
                  ) : null}
                </span>
              </label>
            );
          if (field.options?.length)
            return (
              <div key={field.key} className="space-y-2">
                <Label htmlFor={id}>
                  {field.label}
                  {field.required ? " *" : ""}
                </Label>
                <select
                  id={id}
                  required={field.required}
                  className="border-input bg-background h-9 w-full rounded-md border px-3 text-sm"
                  value={String(inputs[field.key] ?? "")}
                  onChange={(event) => {
                    const option = field.options?.find(
                      (item) => String(item.value) === event.target.value,
                    );
                    setValue(field.key, option?.value ?? event.target.value);
                  }}
                >
                  <option value="">Select an option</option>
                  {field.options.map((option) => (
                    <option
                      key={String(option.value)}
                      value={String(option.value)}
                    >
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
            );
          const numeric = ["number", "integer", "measurement"].includes(
            field.type,
          );
          return (
            <div key={field.key} className="space-y-2">
              <Label htmlFor={id}>
                {field.label}
                {field.required ? " *" : ""}
              </Label>
              <div className="flex gap-2">
                <Input
                  id={id}
                  required={field.required}
                  type={
                    field.type === "date" ? "date" : numeric ? "number" : "text"
                  }
                  min={field.minimum}
                  max={field.maximum}
                  step={field.type === "integer" ? 1 : "any"}
                  value={String(inputValue(inputs[field.key]) ?? "")}
                  onChange={(event) =>
                    setValue(
                      field.key,
                      numeric && event.target.value !== ""
                        ? field.allowed_units?.length
                          ? {
                              value: Number(event.target.value),
                              unit: units[field.key],
                            }
                          : Number(event.target.value)
                        : event.target.value,
                    )
                  }
                />
                {field.allowed_units?.length ? (
                  <select
                    aria-label={`${field.label} unit`}
                    className="border-input bg-background h-9 rounded-md border px-3 text-sm"
                    value={units[field.key]}
                    onChange={(event) => {
                      const unit = event.target.value;
                      setUnits((current) => ({
                        ...current,
                        [field.key]: unit,
                      }));
                      const value = inputValue(inputs[field.key]);
                      if (value !== undefined && value !== "") {
                        setValue(field.key, { value, unit });
                      }
                    }}
                  >
                    {field.allowed_units.map((unit) => (
                      <option key={unit} value={unit}>
                        {unit}
                      </option>
                    ))}
                  </select>
                ) : field.default_unit ? (
                  <span className="flex items-center rounded-md border px-3 text-sm text-muted-foreground">
                    {field.default_unit}
                  </span>
                ) : null}
              </div>
            </div>
          );
        })}
        {error ? (
          <Alert variant="destructive">
            <AlertTitle>Unable to calculate</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}
        <div className="flex gap-3">
          <Button type="submit">
            {definition.tool_type === "checklist"
              ? "Review checklist"
              : "Calculate"}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => {
              setInputs({});
              setUnits(
                Object.fromEntries(
                  definition.inputs.map((field) => [
                    field.key,
                    field.default_unit ?? field.allowed_units?.[0] ?? "",
                  ]),
                ),
              );
              setResult(null);
              setError(null);
            }}
          >
            Reset
          </Button>
        </div>
      </form>
      {result ? (
        <section
          className="space-y-4 rounded-lg border bg-muted/30 p-5"
          aria-live="polite"
        >
          <h3 className="text-lg font-semibold">Results</h3>
          {Object.entries(result.values).map(([key, value]) => {
            const output = definition.outputs.find((item) => item.key === key);
            return (
              <div key={key}>
                <span className="font-medium">{output?.label ?? key}: </span>
                <span>
                  {String(value)}
                  {output?.unit ? ` ${output.unit}` : ""}
                </span>
              </div>
            );
          })}
          {result.interpretation ? (
            <p>
              <span className="font-medium">Interpretation: </span>
              {result.interpretation}
            </p>
          ) : null}
          {result.recommendations.length ? (
            <div>
              <h4 className="font-medium">Recommendations</h4>
              <ul className="list-disc pl-5">
                {result.recommendations.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
          ) : null}
          {result.warnings.length ? (
            <Alert variant="destructive">
              <AlertTitle>Warnings</AlertTitle>
              <AlertDescription>
                <ul className="list-disc pl-5">
                  {result.warnings.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </AlertDescription>
            </Alert>
          ) : null}
          {result.checklist ? (
            <p>
              {result.checklist.completed_required} of{" "}
              {result.checklist.total_required} required items complete (
              {result.checklist.percentage}%).
            </p>
          ) : null}
        </section>
      ) : null}
      {definition.citations?.length ? (
        <section className="space-y-2">
          <h3 className="font-semibold">Clinical references</h3>
          <ul className="list-disc pl-5 text-sm">
            {definition.citations.map((citation) => (
              <li key={citation.key}>
                {citation.url ? (
                  <a
                    className="underline"
                    href={citation.url}
                    target="_blank"
                    rel="noreferrer"
                  >
                    {citation.title}
                  </a>
                ) : (
                  citation.title
                )}
                {citation.organization ? ` — ${citation.organization}` : ""}
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
