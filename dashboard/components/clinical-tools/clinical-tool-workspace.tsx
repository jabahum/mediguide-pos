"use client"

import * as React from "react"
import { toast } from "sonner"
import { AlertTriangle, CheckCircle2, Download, Play, Save, Send, ShieldCheck, Upload } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"
import { clinicalToolService, type ClinicalToolDefinition, type ClinicalToolVersion, type ValidationIssue } from "@/services/clinical-tool.service"
import { previewClinicalTool, type ClinicalToolPreviewResult } from "@/lib/clinical-tool-evaluator"

const sections = ["metadata", "inputs", "calculation", "rules", "interpretations", "checklist", "warnings", "citations", "test_cases"] as const

function sectionValue(definition: ClinicalToolDefinition | undefined, section: (typeof sections)[number]): unknown {
  if (!definition) return undefined
  if (section === "metadata") return { schema_version: definition.schema_version, tool_type: definition.tool_type, title: definition.title, description: definition.description, version: definition.version, locale: definition.locale, clinical_owner: definition.clinical_owner, clinical_reviewer: definition.clinical_reviewer, minimum_app_version: definition.minimum_app_version }
  if (section === "checklist") return { sections: definition.sections, completion: definition.completion }
  return definition[section]
}

function parseDefinition(raw: string): { definition?: ClinicalToolDefinition; issues: ValidationIssue[] } {
  try {
    const value: unknown = JSON.parse(raw)
    if (!value || typeof value !== "object") return { issues: [{ path: "$", code: "type", message: "Definition must be an object" }] }
    const record = value as Record<string, unknown>
    const issues: ValidationIssue[] = []
    for (const key of ["schema_version", "tool_type", "title", "version", "locale"]) {
      if (typeof record[key] !== "string" || !String(record[key]).trim()) issues.push({ path: `$.${key}`, code: "required", message: `${key} is required` })
    }
    for (const key of ["inputs", "sections", "calculation", "rules", "outputs", "interpretations", "test_cases"]) {
      if (!Array.isArray(record[key])) issues.push({ path: `$.${key}`, code: "type", message: `${key} must be an array` })
    }
    if (issues.length) return { issues }
    return { definition: record as ClinicalToolDefinition, issues: [] }
  } catch (error) {
    return { issues: [{ path: "$", code: "json", message: error instanceof Error ? error.message : "Invalid JSON" }] }
  }
}

export function ClinicalToolWorkspace({ toolId, initialVersion, onChanged }: { toolId: string; initialVersion?: ClinicalToolVersion; onChanged?: (version: ClinicalToolVersion) => void }) {
  const [version, setVersion] = React.useState(initialVersion)
  const [raw, setRaw] = React.useState(() => JSON.stringify(initialVersion?.definition ?? {}, null, 2))
  const [summary, setSummary] = React.useState(initialVersion?.change_summary ?? "")
  const [issues, setIssues] = React.useState<ValidationIssue[]>([])
  const [busy, setBusy] = React.useState("")
  const [previewInput, setPreviewInput] = React.useState<Record<string, unknown>>({})
  const [preview, setPreview] = React.useState<ClinicalToolPreviewResult>()
  const [previewWidth, setPreviewWidth] = React.useState<"mobile" | "tablet" | "desktop">("mobile")
  const [previewDark, setPreviewDark] = React.useState(false)
  const [previewScale, setPreviewScale] = React.useState(1)
  const importRef = React.useRef<HTMLInputElement>(null)
  const parsed = React.useMemo(() => parseDefinition(raw), [raw])

  const updateVersion = (next: ClinicalToolVersion) => { setVersion(next); setRaw(JSON.stringify(next.definition, null, 2)); onChanged?.(next) }
  const action = async (name: string, work: () => Promise<void>) => {
    setBusy(name)
    try { await work() } catch (error) { toast.error(error instanceof Error ? error.message : `${name} failed`) } finally { setBusy("") }
  }
  const save = () => action("save", async () => {
    if (!parsed.definition) { setIssues(parsed.issues); throw new Error("Fix the highlighted definition errors") }
    const next = version
      ? await clinicalToolService.update(version.id, parsed.definition, summary, version.lock_version)
      : await clinicalToolService.create(toolId, parsed.definition, summary)
    updateVersion(next); setIssues([]); toast.success("Draft saved")
  })
  const validate = () => action("validate", async () => {
    if (!version) throw new Error("Save the draft first")
    const result = await clinicalToolService.validate(version.id, version.lock_version)
    setIssues(result.errors ?? []); setVersion({ ...version, validation_passed: result.valid, tests_passed: false, lock_version: result.lock_version })
    if (result.valid) toast.success("Definition is valid"); else toast.error("Definition has validation errors")
  })
  const test = () => action("test", async () => {
    if (!version) throw new Error("Save the draft first")
    const result = await clinicalToolService.test(version.id, version.lock_version)
    setVersion({ ...version, validation_passed: true, tests_passed: result.report.passed, lock_version: result.lock_version })
    if (result.report.passed) toast.success("All saved fixtures passed"); else toast.error("One or more fixtures failed")
  })
  const transition = (name: "submit" | "approve" | "publish" | "withdraw") => action(name, async () => {
    if (!version) throw new Error("Save the draft first")
    if (!window.confirm(`Confirm ${name} for version ${version.semantic_version}?`)) return
    updateVersion(await clinicalToolService.transition(version.id, name, version.lock_version)); toast.success(`Version ${name} complete`)
  })

  const runPreview = () => {
    if (!parsed.definition) { setIssues(parsed.issues); return }
    try { setPreview(previewClinicalTool(parsed.definition, previewInput)) } catch (error) { toast.error(error instanceof Error ? error.message : "Preview failed") }
  }
  const exportDefinition = () => {
    const blob = new Blob([raw], { type: "application/json" }); const url = URL.createObjectURL(blob)
    const link = document.createElement("a"); link.href = url; link.download = `${parsed.definition?.title ?? "clinical-tool"}-${parsed.definition?.version ?? "draft"}.json`; link.click(); URL.revokeObjectURL(url)
  }
  const importDefinition = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]; if (!file) return
    const content = await file.text(); const candidate = parseDefinition(content)
    if (!candidate.definition) { setIssues(candidate.issues); toast.error("Imported definition is invalid"); return }
    setRaw(JSON.stringify(candidate.definition, null, 2)); setIssues([]); toast.success("Definition imported; save to persist it")
  }

  return <div className="grid gap-6 xl:grid-cols-[minmax(0,1.3fr)_minmax(340px,.7fr)]">
    <div className="space-y-4">
      <Card><CardContent className="flex flex-wrap items-end gap-3 pt-6">
        <div className="min-w-64 flex-1 space-y-2"><Label htmlFor="change-summary">Change summary</Label><Input id="change-summary" value={summary} onChange={(event) => setSummary(event.target.value)} /></div>
        <Button onClick={save} disabled={Boolean(busy)}><Save className="mr-2 h-4 w-4" />Save draft</Button>
        <Button variant="outline" onClick={validate} disabled={!version || Boolean(busy)}><ShieldCheck className="mr-2 h-4 w-4" />Validate</Button>
        <Button variant="outline" onClick={test} disabled={!version || Boolean(busy)}><Play className="mr-2 h-4 w-4" />Run tests</Button>
        <input ref={importRef} className="hidden" type="file" accept="application/json,.json" onChange={importDefinition} />
        <Button variant="outline" onClick={() => importRef.current?.click()} disabled={Boolean(busy)}><Upload className="mr-2 h-4 w-4" />Import</Button>
        <Button variant="outline" onClick={exportDefinition}><Download className="mr-2 h-4 w-4" />Export</Button>
      </CardContent></Card>
      <Tabs defaultValue="metadata">
        <TabsList className="h-auto flex-wrap justify-start">{sections.map((section) => <TabsTrigger key={section} value={section}>{section.replaceAll("_", " ")}</TabsTrigger>)}<TabsTrigger value="json">Advanced JSON</TabsTrigger></TabsList>
        {sections.map((section) => <TabsContent key={section} value={section}><Card><CardHeader><CardTitle className="capitalize">{section.replaceAll("_", " ")}</CardTitle></CardHeader><CardContent><p className="mb-3 text-sm text-muted-foreground">Edit this typed section in Advanced JSON. Validation reports exact JSON paths here.</p><pre className="max-h-96 overflow-auto rounded-md bg-muted p-4 text-xs">{JSON.stringify(sectionValue(parsed.definition, section), null, 2)}</pre></CardContent></Card></TabsContent>)}
        <TabsContent value="json"><Card><CardHeader><CardTitle>Schema v1 definition</CardTitle></CardHeader><CardContent><Textarea aria-label="Clinical tool JSON definition" spellCheck={false} className="min-h-[620px] font-mono text-xs" value={raw} onChange={(event) => setRaw(event.target.value)} /></CardContent></Card></TabsContent>
      </Tabs>
      {(parsed.issues.length > 0 || issues.length > 0) && <Card className="border-destructive"><CardHeader><CardTitle className="flex items-center gap-2"><AlertTriangle className="h-5 w-5" />Validation issues</CardTitle></CardHeader><CardContent><ul className="space-y-2">{[...parsed.issues, ...issues].map((item, index) => <li key={`${item.path}-${index}`} className="text-sm"><code>{item.path}</code>: {item.message}</li>)}</ul></CardContent></Card>}
      <Card><CardHeader><CardTitle>Clinical workflow</CardTitle></CardHeader><CardContent className="flex flex-wrap gap-2"><Button onClick={() => transition("submit")} disabled={!version || version.status !== "draft"}><Send className="mr-2 h-4 w-4" />Submit</Button><Button variant="outline" onClick={() => transition("approve")} disabled={!version || version.status !== "pending_review"}>Approve</Button><Button variant="outline" onClick={() => transition("publish")} disabled={!version || version.status !== "approved"}><Upload className="mr-2 h-4 w-4" />Publish</Button><Button variant="destructive" onClick={() => transition("withdraw")} disabled={!version || version.status !== "superseded"}>Withdraw</Button></CardContent></Card>
    </div>
    <Card className="h-fit xl:sticky xl:top-6"><CardHeader><CardTitle>Safe native preview</CardTitle></CardHeader><CardContent className="space-y-5">
      <div className="flex flex-wrap items-center gap-2" aria-label="Preview settings"><select aria-label="Preview width" className="rounded-md border bg-background px-2 py-2 text-sm" value={previewWidth} onChange={(event) => setPreviewWidth(event.target.value as typeof previewWidth)}><option value="mobile">Mobile</option><option value="tablet">Tablet</option><option value="desktop">Desktop</option></select><Button size="sm" variant="outline" onClick={() => setPreviewDark((value) => !value)}>{previewDark ? "Light theme" : "Dark theme"}</Button><Label className="flex items-center gap-2 text-xs">Text scale<input aria-label="Preview text scale" type="range" min="1" max="2" step="0.25" value={previewScale} onChange={(event) => setPreviewScale(Number(event.target.value))} /></Label></div>
      <div className={`mx-auto space-y-5 rounded-lg border p-4 transition-all ${previewDark ? "dark bg-slate-950 text-slate-50" : "bg-background"} ${previewWidth === "mobile" ? "max-w-sm" : previewWidth === "tablet" ? "max-w-2xl" : "max-w-none"}`} style={{ fontSize: `${previewScale}rem` }}>
      <div className="flex items-center gap-2 text-sm">{version?.validation_passed ? <CheckCircle2 className="h-4 w-4 text-emerald-600" /> : <AlertTriangle className="h-4 w-4 text-amber-600" />}<span>{version?.status ?? "unsaved"} · {version?.semantic_version ?? parsed.definition?.version ?? "no version"}</span></div>
      {parsed.definition?.inputs.map((input) => <div key={input.key} className="space-y-2"><Label htmlFor={`preview-${input.key}`}>{input.label}{input.required ? " *" : ""}</Label>{input.type === "boolean" || input.type === "checklist_item" ? <input id={`preview-${input.key}`} type="checkbox" checked={Boolean(previewInput[input.key])} onChange={(event) => setPreviewInput((current) => ({ ...current, [input.key]: event.target.checked }))} /> : input.options?.length ? <select id={`preview-${input.key}`} className="w-full rounded-md border bg-background px-3 py-2" value={String(previewInput[input.key] ?? "")} onChange={(event) => { const selected = input.options?.find((item) => String(item.value) === event.target.value); setPreviewInput((current) => ({ ...current, [input.key]: selected?.value ?? event.target.value })) }}><option value="">Select…</option>{input.options.map((item) => <option key={String(item.value)} value={String(item.value)}>{item.label}</option>)}</select> : <Input id={`preview-${input.key}`} type={input.type === "number" || input.type === "measurement" ? "number" : input.type === "date" ? "date" : "text"} min={input.minimum} max={input.maximum} onChange={(event) => setPreviewInput((current) => ({ ...current, [input.key]: input.type === "number" || input.type === "measurement" ? Number(event.target.value) : event.target.value }))} />}{input.default_unit && <p className="text-xs text-muted-foreground">{input.default_unit}</p>}</div>)}
      <div className="flex gap-2"><Button onClick={runPreview}><Play className="mr-2 h-4 w-4" />Calculate</Button><Button variant="outline" onClick={() => { setPreviewInput({}); setPreview(undefined) }}>Reset</Button></div>
      {preview && <div aria-live="polite" className="space-y-3 rounded-lg border bg-muted/40 p-4"><h3 className="font-semibold">Result</h3>{Object.entries(preview.values).map(([key, value]) => <p key={key}><span className="text-muted-foreground">{key}: </span><strong>{String(value)}</strong></p>)}{preview.interpretation && <p className="font-medium">{preview.interpretation}</p>}<ul className="list-disc pl-5 text-sm">{preview.recommendations.map((item) => <li key={item}>{item}</li>)}</ul>{preview.warnings.map((item) => <div key={item} role="alert" className="rounded border border-amber-300 bg-amber-50 p-2 text-sm text-amber-950">{item}</div>)}</div>}
      <p className="text-xs text-muted-foreground">Preview uses the restricted schema evaluator. The backend remains the authority for validation, fixtures and publication.</p>
      </div>
    </CardContent></Card>
  </div>
}
