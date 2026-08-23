import type { ClinicalToolDefinition, ClinicalToolExpression } from "@/services/clinical-tool.service"

export type ClinicalToolChecklistProgress = { completed_required: number; total_required: number; percentage: number; complete: boolean; needs_review: boolean; critical_pending: string[] }
export type ClinicalToolPreviewResult = { values: Record<string, unknown>; normalizedInputs: Record<string, unknown>; interpretation?: string; recommendations: string[]; warnings: string[]; checklist?: ClinicalToolChecklistProgress }

const unitFactors: Record<string, number> = { kg: 1, g: .001, mg: .000001, mcg: .000000001, lb: .45359237, m: 1, cm: .01, mm: .001, ft: .3048, in: .0254, L: 1, mL: .001, weeks: 10080, days: 1440, hours: 60, minutes: 1 }
function convertUnit(value: number, from = "", to = ""): number {
  if (!from || !to || from === to) return value
  if (from === "celsius" && to === "fahrenheit") return value * 9 / 5 + 32
  if (from === "fahrenheit" && to === "celsius") return (value - 32) * 5 / 9
  if (!(from in unitFactors) || !(to in unitFactors)) throw new Error(`Unsupported unit conversion: ${from} to ${to}`)
  return value * unitFactors[from] / unitFactors[to]
}

function applyPrecision(value: unknown, precision?: number, mode = "half_up"): unknown {
  if (precision === undefined || typeof value !== "number" || !Number.isFinite(value)) return value
  const scale = 10 ** precision
  const scaled = value * scale
  let rounded: number
  switch (mode) {
    case "floor": rounded = Math.floor(scaled); break
    case "ceil": rounded = Math.ceil(scaled); break
    case "truncate": rounded = Math.trunc(scaled); break
    case "half_even": {
      const lower = Math.floor(scaled)
      const fraction = scaled - lower
      rounded = fraction === 0.5 ? (lower % 2 === 0 ? lower : lower + 1) : Math.round(scaled)
      break
    }
    default: rounded = Math.sign(scaled) * Math.floor(Math.abs(scaled) + 0.5)
  }
  return rounded / scale
}

function evaluate(expression: ClinicalToolExpression, values: Record<string, unknown>, now: string): unknown {
  const args = () => (expression.args ?? []).map((item) => evaluate(item, values, now))
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
    case "and": return (expression.args ?? []).every((item) => Boolean(evaluate(item, values, now)))
    case "or": return (expression.args ?? []).some((item) => Boolean(evaluate(item, values, now)))
    case "not": return !Boolean(evaluate((expression.args ?? [])[0], values, now))
    case "if": return Boolean(evaluate((expression.args ?? [])[0], values, now)) ? evaluate((expression.args ?? [])[1], values, now) : evaluate((expression.args ?? [])[2], values, now)
    case "in": { const [needle, ...haystack] = args(); return haystack.some((item) => Object.is(item, needle)) }
    case "round": { const [value] = args(); return applyPrecision(Number(value), expression.precision ?? 0, expression.rounding_mode) }
    case "now": return now
    case "date_difference": {
      const [fromValue, toValue] = args(); const milliseconds = Date.parse(String(toValue)) - Date.parse(String(fromValue)); const days = milliseconds / 86_400_000
      if (!Number.isFinite(days)) throw new Error("Invalid date_difference operands")
      if (expression.date_unit === "months" || expression.date_unit === "years") {
        const from = new Date(String(fromValue)); const to = new Date(String(toValue))
        if (expression.date_unit === "months") {
          let months = (to.getUTCFullYear() - from.getUTCFullYear()) * 12 + to.getUTCMonth() - from.getUTCMonth()
          if (to.getUTCDate() < from.getUTCDate()) months--
          return months
        }
        let years = to.getUTCFullYear() - from.getUTCFullYear()
        if (to.getUTCMonth() < from.getUTCMonth() || (to.getUTCMonth() === from.getUTCMonth() && to.getUTCDate() < from.getUTCDate())) years--
        return years
      }
      switch (expression.date_unit) { case "minutes": return days * 1440; case "hours": return days * 24; case "weeks": return days / 7; default: return days }
    }
    case "date_add": {
      const [dateValue, amountValue] = args()
      const source = String(dateValue)
      const amount = Number(amountValue)
      if (!Number.isInteger(amount)) throw new Error("date_add requires an integer amount")
      const date = new Date(source.length === 10 ? `${source}T00:00:00Z` : source)
      if (!Number.isFinite(date.getTime())) throw new Error("Invalid date_add date")
      switch (expression.date_unit) {
        case "days": date.setUTCDate(date.getUTCDate() + amount); break
        case "weeks": date.setUTCDate(date.getUTCDate() + amount * 7); break
        case "months": date.setUTCMonth(date.getUTCMonth() + amount); break
        case "years": date.setUTCFullYear(date.getUTCFullYear() + amount); break
        default: throw new Error("Unsupported date_add unit")
      }
      return date.toISOString().slice(0, 10)
    }
    case "convert_unit": return convertUnit(Number(args()[0]), expression.from_unit, expression.to_unit)
    default: throw new Error(`Unsupported preview operation: ${expression.op}`)
  }
}

export function previewClinicalTool(definition: ClinicalToolDefinition, input: Record<string, unknown>, options: { fixedNow?: string } = {}): ClinicalToolPreviewResult {
  const now = options.fixedNow ?? new Date().toISOString()
  const values = { ...input }
  const normalizedInputs: Record<string, unknown> = {}
  const knownInputs = new Set(definition.inputs.map((field) => field.key))
  for (const key of Object.keys(input)) if (!knownInputs.has(key)) throw new Error(`Unknown input: ${key}`)
  for (const field of definition.inputs) {
    if ((values[field.key] === undefined || values[field.key] === null) && field.default !== undefined && field.default !== null) values[field.key] = field.default
  }
  for (const field of definition.inputs) {
    const candidate = values[field.key]
    const visible = !field.visible_when || Boolean(evaluate(field.visible_when, values, now))
    if (visible && field.required && (candidate === undefined || candidate === null || candidate === "")) throw new Error(`Required input: ${field.key}`)
    if (candidate === undefined || candidate === null) continue
    if (candidate && typeof candidate === "object" && "value" in candidate) {
      const measurement = candidate as { value: unknown; unit?: string }
      values[field.key] = convertUnit(Number(measurement.value), measurement.unit, field.default_unit)
      normalizedInputs[field.key] = { value: values[field.key], unit: field.default_unit }
    } else {
      normalizedInputs[field.key] = candidate
    }
  }
  for (const calculation of definition.calculation) values[calculation.key] = applyPrecision(evaluate(calculation.expression, values, now), calculation.precision, calculation.rounding_mode)
  const output: Record<string, unknown> = {}
  for (const item of definition.outputs) output[item.key] = applyPrecision(evaluate(item.value, values, now), item.precision, item.rounding_mode)
  const context = { ...values, ...output }
  const interpretationByKey = new Map(definition.interpretations.map((item) => [item.key, item]))
  const warningByKey = new Map((definition.warnings ?? []).map((item) => [item.key, item]))
  let interpretation: (typeof definition.interpretations)[number] | undefined
  const recommendations: string[] = []
  const warnings = (definition.warnings ?? []).filter((item) => !item.when || Boolean(evaluate(item.when, context, now))).map((item) => item.text)
  const append = (items: string[]) => { for (const item of items) if (!recommendations.includes(item)) recommendations.push(item) }
  for (const rule of [...definition.rules].sort((a, b) => a.order - b.order || a.key.localeCompare(b.key))) {
    if (!Boolean(evaluate(rule.when, context, now))) continue
    let stop = false
    for (const action of rule.actions) {
      if (action.type === "set_output" && action.target && action.value) { output[action.target] = evaluate(action.value, context, now); context[action.target] = output[action.target] }
      if ((action.type === "add_interpretation" || action.type === "add_recommendation") && action.target) { const item = interpretationByKey.get(action.target); if (!item) throw new Error(`Unknown interpretation: ${action.target}`); if (action.type === "add_interpretation") interpretation ??= item; append(item.recommendations) }
      if ((action.type === "add_warning" || action.type === "escalate") && action.message_key) { const item = warningByKey.get(action.message_key); if (!item) throw new Error(`Unknown warning: ${action.message_key}`); if (!warnings.includes(item.text)) warnings.push(item.text) }
      if (action.type === "stop") stop = true
    }
    if (stop || rule.stop) break
  }
  for (const item of [...definition.interpretations].sort((a, b) => a.order - b.order || a.key.localeCompare(b.key))) {
    if (Boolean(evaluate(item.when, context, now))) { interpretation ??= item; append(item.recommendations) }
  }
  let checklist: ClinicalToolChecklistProgress | undefined
  if (definition.tool_type === "checklist") {
    const required = definition.inputs.filter((field) => field.type === "checklist_item" && field.required)
    const completeResponse = (value: unknown) => value === true || typeof value === "number" || (typeof value === "string" && value.length > 0) || (Array.isArray(value) && value.length > 0)
    const completed = required.filter((field) => completeResponse(input[field.key])).length
    const criticalPending = required.filter((field) => field.critical && !completeResponse(input[field.key])).map((field) => field.key)
    const needsReview = Boolean(definition.completion.require_review)
    checklist = {
      completed_required: completed,
      total_required: required.length,
      percentage: required.length === 0 ? 100 : Math.round(completed / required.length * 10_000) / 100,
      complete: definition.completion.mode === "all_required" && completed === required.length && !needsReview && criticalPending.length === 0,
      needs_review: needsReview,
      critical_pending: criticalPending,
    }
  }
  return { values: output, normalizedInputs, interpretation: interpretation?.label, recommendations, warnings, checklist }
}
