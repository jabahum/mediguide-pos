import type { ClinicalToolDefinition, ClinicalToolExpression } from "@/services/clinical-tool.service"

export type ClinicalToolPreviewResult = { values: Record<string, unknown>; interpretation?: string; recommendations: string[]; warnings: string[] }

const unitFactors: Record<string, number> = { kg: 1, g: .001, mg: .000001, mcg: .000000001, lb: .45359237, m: 1, cm: .01, mm: .001, ft: .3048, in: .0254, L: 1, mL: .001, weeks: 10080, days: 1440, hours: 60, minutes: 1 }
function convertUnit(value: number, from = "", to = ""): number {
  if (!from || !to || from === to) return value
  if (from === "celsius" && to === "fahrenheit") return value * 9 / 5 + 32
  if (from === "fahrenheit" && to === "celsius") return (value - 32) * 5 / 9
  if (!(from in unitFactors) || !(to in unitFactors)) throw new Error(`Unsupported unit conversion: ${from} to ${to}`)
  return value * unitFactors[from] / unitFactors[to]
}

function evaluate(expression: ClinicalToolExpression, values: Record<string, unknown>): unknown {
  const args = () => (expression.args ?? []).map((item) => evaluate(item, values))
  switch (expression.op) {
    case "literal": return expression.value
    case "field": return values[expression.field ?? ""]
    case "add": return args().reduce<number>((sum, value) => sum + Number(value), 0)
    case "subtract": { const [a, b] = args(); return Number(a) - Number(b) }
    case "multiply": return args().reduce<number>((total, value) => total * Number(value), 1)
    case "divide": { const [a, b] = args(); if (Number(b) === 0) throw new Error("Division by zero"); return Number(a) / Number(b) }
    case "power": { const [a, b] = args(); return Number(a) ** Number(b) }
    case "min": return Math.min(...args().map(Number))
    case "max": return Math.max(...args().map(Number))
    case "abs": return Math.abs(Number(args()[0]))
    case "greater_than": { const [a, b] = args(); return Number(a) > Number(b) }
    case "greater_than_or_equal": { const [a, b] = args(); return Number(a) >= Number(b) }
    case "less_than": { const [a, b] = args(); return Number(a) < Number(b) }
    case "less_than_or_equal": { const [a, b] = args(); return Number(a) <= Number(b) }
    case "equal": { const [a, b] = args(); return a === b }
    case "not_equal": { const [a, b] = args(); return a !== b }
    case "and": return (expression.args ?? []).every((item) => Boolean(evaluate(item, values)))
    case "or": return (expression.args ?? []).some((item) => Boolean(evaluate(item, values)))
    case "not": return !Boolean(evaluate((expression.args ?? [])[0], values))
    case "if": return Boolean(evaluate((expression.args ?? [])[0], values)) ? evaluate((expression.args ?? [])[1], values) : evaluate((expression.args ?? [])[2], values)
    case "in": { const [needle, ...haystack] = args(); return haystack.some((item) => Object.is(item, needle)) }
    case "round": { const [value] = args(); const places = expression.precision ?? 0; const scale = 10 ** places; return Math.round(Number(value) * scale) / scale }
    case "now": return new Date().toISOString()
    case "date_difference": {
      const [fromValue, toValue] = args(); const milliseconds = Date.parse(String(toValue)) - Date.parse(String(fromValue)); const days = milliseconds / 86_400_000
      if (!Number.isFinite(days)) throw new Error("Invalid date_difference operands")
      switch (expression.date_unit) { case "minutes": return days * 1440; case "hours": return days * 24; case "weeks": return days / 7; case "months": return days / 30.436875; case "years": return days / 365.2425; default: return days }
    }
    case "convert_unit": return convertUnit(Number(args()[0]), expression.from_unit, expression.to_unit)
    default: throw new Error(`Unsupported preview operation: ${expression.op}`)
  }
}

export function previewClinicalTool(definition: ClinicalToolDefinition, input: Record<string, unknown>): ClinicalToolPreviewResult {
  const values = { ...input }
  for (const field of definition.inputs) {
    const candidate = values[field.key]
    if (candidate && typeof candidate === "object" && "value" in candidate) {
      const measurement = candidate as { value: unknown; unit?: string }
      values[field.key] = convertUnit(Number(measurement.value), measurement.unit, field.default_unit)
    }
  }
  for (const calculation of definition.calculation) values[calculation.key] = evaluate(calculation.expression, values)
  const output: Record<string, unknown> = {}
  for (const item of definition.outputs) output[item.key] = evaluate(item.value, values)
  const context = { ...values, ...output }
  const interpretationByKey = new Map(definition.interpretations.map((item) => [item.key, item]))
  const warningByKey = new Map((definition.warnings ?? []).map((item) => [item.key, item]))
  let interpretation: (typeof definition.interpretations)[number] | undefined
  const recommendations: string[] = []
  const warnings = (definition.warnings ?? []).filter((item) => !item.when || Boolean(evaluate(item.when, context))).map((item) => item.text)
  const append = (items: string[]) => { for (const item of items) if (!recommendations.includes(item)) recommendations.push(item) }
  for (const rule of [...definition.rules].sort((a, b) => a.order - b.order || a.key.localeCompare(b.key))) {
    if (!Boolean(evaluate(rule.when, context))) continue
    let stop = false
    for (const action of rule.actions) {
      if (action.type === "set_output" && action.target && action.value) { output[action.target] = evaluate(action.value, context); context[action.target] = output[action.target] }
      if ((action.type === "add_interpretation" || action.type === "add_recommendation") && action.target) { const item = interpretationByKey.get(action.target); if (!item) throw new Error(`Unknown interpretation: ${action.target}`); if (action.type === "add_interpretation") interpretation ??= item; append(item.recommendations) }
      if ((action.type === "add_warning" || action.type === "escalate") && action.message_key) { const item = warningByKey.get(action.message_key); if (!item) throw new Error(`Unknown warning: ${action.message_key}`); if (!warnings.includes(item.text)) warnings.push(item.text) }
      if (action.type === "stop") stop = true
    }
    if (stop || rule.stop) break
  }
  for (const item of [...definition.interpretations].sort((a, b) => a.order - b.order || a.key.localeCompare(b.key))) {
    if (Boolean(evaluate(item.when, context))) { interpretation ??= item; append(item.recommendations) }
  }
  return { values: output, interpretation: interpretation?.label, recommendations, warnings }
}
