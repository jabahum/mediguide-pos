import { readFileSync, readdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
// jsdom is already a dashboard test dependency; this repository does not ship its optional type package.
// @ts-expect-error -- exercised through the deliberately small typed boundary below.
import { JSDOM, VirtualConsole } from "jsdom"
import { describe, expect, it } from "vitest"

type Scenario = {
  id: string
  tags: string[]
  fixedNow?: string
  values?: Record<string, string>
  checks?: string[]
  radios?: string[]
  invoke: string
  alert?: string
  expect?: Record<string, string>
  expectVisible?: string
  expectHidden?: string
  expectValues?: Record<string, string>
}

type ToolManifest = {
  id: string
  file: string
  type: string
  entry_point: string
  reset_entry_point?: string
  inputs: Array<Record<string, unknown>>
  logic: Record<string, unknown>
  outputs: string[]
  warnings: string[]
  sources: string[]
  ambiguities: string[]
  characterization: Scenario[]
}

const samplesDir = dirname(fileURLToPath(import.meta.url))
const catalog = JSON.parse(
  readFileSync(join(samplesDir, "manifests/legacy-tool-behaviors.json"), "utf8"),
) as { schema_version: number; tools: ToolManifest[] }

function normalize(value: string | null | undefined) {
  return (value ?? "").replace(/\s+/g, " ").trim()
}

function loadTool(tool: ToolManifest, fixedNow?: string) {
  const alerts: string[] = []
  const virtualConsole = new VirtualConsole()
  virtualConsole.on("jsdomError", (error: Error) => {
    throw error
  })

  const html = readFileSync(join(samplesDir, tool.file), "utf8")
  const dom = new JSDOM(html, {
    url: `https://legacy.invalid/${tool.file}`,
    virtualConsole,
  })

  dom.window.alert = (message?: unknown) => alerts.push(String(message ?? ""))
  for (const element of dom.window.document.querySelectorAll<HTMLElement>("[onclick]")) {
    element.onclick = new Function(element.getAttribute("onclick") ?? "") as (
      this: GlobalEventHandlers,
      event: MouseEvent,
    ) => unknown
  }
  let RuntimeDate: DateConstructor = Date
  if (fixedNow) {
    const timestamp = new Date(fixedNow).getTime()
    class FixedDate extends Date {
      constructor(value?: string | number | Date) {
        super(value === undefined ? timestamp : value instanceof Date ? value.getTime() : value)
      }

      static now() {
        return timestamp
      }
    }
    RuntimeDate = FixedDate as DateConstructor
  }

  const scripts = dom.window.document.querySelectorAll("script") as NodeListOf<HTMLScriptElement>
  const source = Array.from(scripts)
    .map((script) => script.textContent ?? "")
    .join("\n")
  const functionNames = Array.from(source.matchAll(/function\s+([A-Za-z_$][\w$]*)\s*\(/g), (match) => match[1])
  const uniqueFunctionNames = [...new Set(functionNames)]
  const runtimeFactory = new Function(
    "window",
    "document",
    "alert",
    "Date",
    `${source}\nreturn { functions: { ${uniqueFunctionNames.join(",")} }, run(expression) { return eval(expression); } };`,
  )
  const runtime = runtimeFactory(dom.window, dom.window.document, dom.window.alert, RuntimeDate) as {
    functions: Record<string, (...args: unknown[]) => unknown>
    run(expression: string): unknown
  }

  return { dom, alerts, runtime }
}

function runScenario(tool: ToolManifest, scenario: Scenario) {
  const { dom, alerts, runtime } = loadTool(tool, scenario.fixedNow)
  const { document } = dom.window

  for (const [id, value] of Object.entries(scenario.values ?? {})) {
    const element = document.getElementById(id) as HTMLInputElement | HTMLSelectElement | null
    expect(element, `${tool.id}/${scenario.id}: missing #${id}`).not.toBeNull()
    element!.value = value
  }

  for (const id of scenario.checks ?? []) {
    const element = document.getElementById(id) as HTMLInputElement | null
    expect(element, `${tool.id}/${scenario.id}: missing checkbox #${id}`).not.toBeNull()
    element!.checked = true
  }

  for (const id of scenario.radios ?? []) {
    const element = document.getElementById(id) as HTMLInputElement | null
    expect(element, `${tool.id}/${scenario.id}: missing radio #${id}`).not.toBeNull()
    element!.checked = true
  }

  runtime.run(scenario.invoke)

  if (scenario.alert) {
    expect(alerts.join("\n")).toContain(scenario.alert)
  } else {
    expect(alerts, `${tool.id}/${scenario.id}: unexpected alert`).toEqual([])
  }

  for (const [id, expected] of Object.entries(scenario.expect ?? {})) {
    const element = document.getElementById(id)
    expect(element, `${tool.id}/${scenario.id}: missing output #${id}`).not.toBeNull()
    expect(normalize(element!.textContent)).toContain(normalize(expected))
  }

  if (scenario.expectVisible) {
    const element = document.getElementById(scenario.expectVisible)
    expect(element, `${tool.id}/${scenario.id}: missing visible output`).not.toBeNull()
    expect(element!.style.display).not.toBe("none")
  }

  if (scenario.expectHidden) {
    const element = document.getElementById(scenario.expectHidden)
    expect(element, `${tool.id}/${scenario.id}: missing hidden output`).not.toBeNull()
    expect(element!.style.display).toBe("none")
  }

  for (const [id, expected] of Object.entries(scenario.expectValues ?? {})) {
    const element = document.getElementById(id) as HTMLInputElement | null
    expect(element, `${tool.id}/${scenario.id}: missing value #${id}`).not.toBeNull()
    expect(element!.value).toBe(expected)
  }

  dom.window.close()
}

describe("legacy clinical-tool inventory", () => {
  it("contains exactly one manifest for every standalone HTML tool", () => {
    const htmlFiles = readdirSync(samplesDir).filter((file) => file.endsWith(".html")).sort()
    const manifestFiles = catalog.tools.map((tool) => tool.file).sort()

    expect(catalog.schema_version).toBe(1)
    expect(catalog.tools).toHaveLength(14)
    expect(manifestFiles).toEqual(htmlFiles)
    expect(new Set(catalog.tools.map((tool) => tool.id)).size).toBe(catalog.tools.length)
  })

  it.each(catalog.tools)("$id documents the migration contract", (tool) => {
    expect(tool.type).toBeTruthy()
    expect(tool.entry_point).toBeTruthy()
    expect(tool.inputs.length).toBeGreaterThan(0)
    expect(tool.outputs.length).toBeGreaterThan(0)
    expect(tool.logic.formula).toBeTruthy()
    expect(tool.logic.precision).toBeTruthy()
    expect(tool.logic.thresholds).toBeTruthy()
    expect(tool.logic.reset).toBeTruthy()
    expect(tool.logic.time_dependency).toBeTruthy()
    expect(tool.ambiguities).toBeInstanceOf(Array)
    expect(tool.sources).toBeInstanceOf(Array)

    const { dom, runtime } = loadTool(tool)
    expect(typeof runtime.functions[tool.entry_point]).toBe("function")
    if (tool.reset_entry_point) {
      expect(typeof runtime.functions[tool.reset_entry_point]).toBe("function")
    }
    dom.window.close()
  })

  it("covers the required classes of observable legacy behavior", () => {
    const tags = new Set(catalog.tools.flatMap((tool) => tool.characterization.flatMap((test) => test.tags)))
    for (const required of [
      "normal",
      "minimum",
      "maximum",
      "boundary",
      "immediately-below",
      "immediately-above",
      "conversion",
      "missing",
      "invalid",
      "reset",
      "conditional",
      "warning",
      "critical",
      "fixed-clock",
      "checklist",
    ]) {
      expect(tags, `missing characterization tag: ${required}`).toContain(required)
    }
  })

  it("covers medication-specific compatibility cases", () => {
    const medication = catalog.tools.find((tool) => tool.id === "medication-dosage-calculator")!
    const tags = new Set(medication.characterization.flatMap((test) => test.tags))
    for (const required of [
      "pediatric",
      "adult",
      "cap",
      "daily-max",
      "frequency",
      "conversion",
      "rounding",
      "warning",
      "contraindication",
    ]) {
      expect(tags, `missing medication tag: ${required}`).toContain(required)
    }
  })
})

describe("legacy clinical-tool characterization", () => {
  for (const tool of catalog.tools) {
    describe(tool.id, () => {
      for (const scenario of tool.characterization) {
        it(scenario.id, () => runScenario(tool, scenario))
      }
    })
  }
})
