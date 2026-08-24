"use client"

import * as React from "react"
import Link from "next/link"
import { AlertCircle, CheckCircle2, ExternalLink, Loader2, Plus, Save, ShieldCheck } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { showToast } from "@/lib/toast"
import { healthFacilitiesService } from "@/services/health-facilities.service"
import { outbreaksService, type OutbreakAuditRecord, type OutbreakRecord, type OutbreakResourceRecord, type OutbreakUpdateRecord, type PublishedGuidelineRecord } from "@/services/outbreaks.service"
import { situationReportsService, type SituationReportRecord } from "@/services/situation-reports.service"
import type { DistrictsResponse, RegionsResponse } from "@/types/backend-types"
import { CampaignDraftBuilder } from "./campaign-draft-builder"
import { ChildContentWorkflow } from "./child-content-workflow"
import { OutbreakDocumentsWorkspace } from "./outbreak-documents-workspace"

type MetricDraft = { key: string; label: string; value: string; numeric_value?: number; unit: string; as_of: string; source_reference: string; sort_order: number }

const emptyMetric = (): MetricDraft => ({ key: "", label: "", value: "", unit: "", as_of: new Date().toISOString(), source_reference: "", sort_order: 1 })

export function OutbreakEditor({ id }: { id?: string }) {
  const [item, setItem] = React.useState<OutbreakRecord | null>(null)
  const [updates, setUpdates] = React.useState<OutbreakUpdateRecord[]>([])
  const [resources, setResources] = React.useState<OutbreakResourceRecord[]>([])
  const [audit, setAudit] = React.useState<OutbreakAuditRecord[]>([])
  const [reports, setReports] = React.useState<SituationReportRecord[]>([])
  const [guidelines, setGuidelines] = React.useState<PublishedGuidelineRecord[]>([])
  const [regions, setRegions] = React.useState<RegionsResponse[]>([])
  const [districts, setDistricts] = React.useState<DistrictsResponse[]>([])
  const [reviewComment, setReviewComment] = React.useState("")
  const [metrics, setMetrics] = React.useState<MetricDraft[]>([])
  const [updateDraft, setUpdateDraft] = React.useState({ title: "", summary: "" })
  const [resourceDraft, setResourceDraft] = React.useState({ title: "", resource_type: "guideline", url: "", asset_url: "" })
  const [form, setForm] = React.useState({ title: "", disease_type: "", geographic_area: "", region_id: "", district_id: "", summary: "", visual_tone: "warning", source_organization: "", source_url: "", source_reference: "", start_date: "", last_update: "", effective_at: "", data_as_of: "", last_verified_at: "", change_summary: "" })
  const [loading, setLoading] = React.useState(Boolean(id))
  const [saving, setSaving] = React.useState(false)
  const [error, setError] = React.useState("")

  const hydrate = React.useCallback(async () => {
    if (!id) return
    setLoading(true); setError("")
    try {
      const [record, updatePage, resourcePage, auditPage, reportPage, regionRows, guidelinePage] = await Promise.all([outbreaksService.get(id), outbreaksService.listUpdates(id), outbreaksService.listResources(id), outbreaksService.audit(id), situationReportsService.list({ outbreak_id: id, page: 1, per_page: 100 }), healthFacilitiesService.regions(), outbreaksService.listPublishedGuidelines()])
      setItem(record); setUpdates(updatePage.items || []); setResources(resourcePage.items || [])
      setAudit(auditPage.items || []); setReports(reportPage.items || []); setRegions(regionRows)
      setGuidelines(guidelinePage.items || [])
      setMetrics((record.metrics || []) as MetricDraft[])
      setForm({ title: record.title || "", disease_type: record.disease_type || "", geographic_area: record.geographic_area || "", region_id: record.region_id || "", district_id: record.district_id || "", summary: record.summary || "", visual_tone: record.visual_tone || "warning", source_organization: record.source_organization || "", source_url: record.source_url || "", source_reference: record.source_reference || "", start_date: toLocal(record.start_date), last_update: toLocal(record.last_update), effective_at: toLocal(record.effective_at), data_as_of: toLocal(record.data_as_of), last_verified_at: toLocal(record.last_verified_at), change_summary: "" })
    } catch (value) { setError(value instanceof Error ? value.message : "Unable to load outbreak workspace") }
    finally { setLoading(false) }
  }, [id])

  React.useEffect(() => { void hydrate() }, [hydrate])
  React.useEffect(() => { if (!form.region_id) { setDistricts([]); return }; void healthFacilitiesService.districts(form.region_id).then(setDistricts).catch(() => setDistricts([])) }, [form.region_id])

  function field(name: keyof typeof form, value: string) { setForm(current => ({ ...current, [name]: value })) }
  const immutable = item?.status === "published" || item?.status === "active" || item?.status === "monitoring" || item?.status === "contained" || item?.status === "closed" || item?.status === "withdrawn"

  async function save() {
    if (immutable) { showToast.error("Published content", "Create a correction instead of mutating published content."); return }
    setSaving(true)
    try {
      const payload = { ...form, region_id: form.region_id || undefined, district_id: form.district_id || undefined, change_summary: undefined, start_date: iso(form.start_date), last_update: iso(form.last_update), effective_at: iso(form.effective_at), data_as_of: iso(form.data_as_of), last_verified_at: iso(form.last_verified_at), metrics, ...(item ? { lock_version: item.lock_version } : {}) }
      const saved = item ? await outbreaksService.update(item.id!, payload) : await outbreaksService.create(payload)
      showToast.success("Outbreak saved", "The draft was saved without publishing it.")
      if (!item) { window.location.assign(`/outbreaks/${saved.id}`); return }
      setItem(saved)
    } catch (value) { showToast.error("Unable to save", conflictMessage(value)) }
    finally { setSaving(false) }
  }

  async function workflow(action: "submit" | "approve" | "publish" | "withdraw" | "correct") {
    if (!item) return
    const reason = action === "withdraw" || action === "correct" ? window.prompt(`Reason for ${action}`)?.trim() : ""
    if ((action === "withdraw" || action === "correct") && !reason) return
    if (action === "publish" && !window.confirm("Publish this verified outbreak to the public API? This cannot be edited in place.")) return
    setSaving(true)
    try {
      const next = action === "correct" ? await outbreaksService.correct(item.id!, { lock_version: item.lock_version!, reason }) : await outbreaksService.transition(item.id!, action, { lock_version: item.lock_version!, reason })
      setItem(next); showToast.success("Workflow updated", `Outbreak is now ${next.status}.`)
      if (action === "correct") window.location.assign(`/outbreaks/${next.id}`)
    } catch (value) { showToast.error("Workflow failed", conflictMessage(value)) }
    finally { setSaving(false) }
  }

  async function addUpdate() {
    if (!item || !updateDraft.title.trim()) return
    try { const created = await outbreaksService.createUpdate(item.id!, updateDraft); setUpdates(current => [...current, created]); setUpdateDraft({ title: "", summary: "" }); showToast.success("Update draft created", "Submit it independently when it is ready.") } catch (value) { showToast.error("Update not created", conflictMessage(value)) }
  }

  async function addResource() {
    if (!item || !resourceDraft.title.trim()) return
    try { const created = await outbreaksService.createResource(item.id!, { ...resourceDraft, sort_order: resources.length + 1 }); setResources(current => [...current, created]); setResourceDraft({ title: "", resource_type: "guideline", url: "", asset_url: "" }); showToast.success("Resource draft created", "The link passed the backend trust boundary.") } catch (value) { showToast.error("Resource not created", conflictMessage(value)) }
  }

  async function addReviewComment() {
    if (!item?.id || !reviewComment.trim()) return
    try { await outbreaksService.addReviewComment(item.id, reviewComment); setReviewComment(""); const history = await outbreaksService.audit(item.id); setAudit(history.items || []); showToast.success("Review comment added", "The comment is recorded in audit history.") } catch (value) { showToast.error("Comment not added", conflictMessage(value)) }
  }

  if (loading) return <div className="py-20 text-center"><Loader2 className="mr-2 inline h-5 w-5 animate-spin" />Loading workspace…</div>
  if (error) return <div className="rounded-md border border-destructive/40 p-5 text-destructive" role="alert">{error}<Button className="ml-3" variant="outline" onClick={() => void hydrate()}>Retry</Button></div>

  return <div className="space-y-6">
    <div className="flex flex-wrap items-start justify-between gap-3"><div><div className="flex items-center gap-2"><h1 className="text-2xl font-semibold">{item ? item.title || "Untitled outbreak" : "New outbreak"}</h1>{item ? <Badge variant="outline">{item.status}</Badge> : null}</div><p className="text-sm text-muted-foreground">Draft, review, publish, correct and distribute verified outbreak content.</p></div><div className="flex flex-wrap gap-2"><Button variant="outline" asChild><Link href="/outbreaks">Back to list</Link></Button><Button disabled={saving || immutable} onClick={() => void save()}><Save className="mr-2 h-4 w-4" />Save draft</Button></div></div>
    {item ? <OutbreakDocumentsWorkspace outbreakId={item.id!} /> : null}
    {immutable ? <div className="flex gap-3 rounded-md border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950"><ShieldCheck className="h-5 w-5" /><div><strong>Published content is immutable.</strong> Create a correction to make changes.</div></div> : null}
    <Card><CardHeader><CardTitle>Core metadata and source</CardTitle></CardHeader><CardContent className="grid gap-4 md:grid-cols-2"><Field label="Title" value={form.title} onChange={value => field("title", value)} /><Field label="Disease" value={form.disease_type} onChange={value => field("disease_type", value)} /><Field label="Geographic coverage" value={form.geographic_area} onChange={value => field("geographic_area", value)} /><SelectField label="Region" value={form.region_id} onChange={value => { field("region_id", value); field("district_id", "") }} options={regions.map(value => ({ id: value.id, name: value.name }))} empty="Select region" /><SelectField label="District" value={form.district_id} onChange={value => field("district_id", value)} options={districts.map(value => ({ id: value.id, name: value.name }))} empty="Select district" /><Field label="Source organization" value={form.source_organization} onChange={value => field("source_organization", value)} /><Field label="Source reference" value={form.source_reference} onChange={value => field("source_reference", value)} /><Field label="Source HTTPS URL" value={form.source_url} onChange={value => field("source_url", value)} /><Field label="Start date" type="datetime-local" value={form.start_date} onChange={value => field("start_date", value)} /><Field label="Last update" type="datetime-local" value={form.last_update} onChange={value => field("last_update", value)} /><Field label="Effective at" type="datetime-local" value={form.effective_at} onChange={value => field("effective_at", value)} /><Field label="Data as of" type="datetime-local" value={form.data_as_of} onChange={value => field("data_as_of", value)} /><Field label="Last verified" type="datetime-local" value={form.last_verified_at} onChange={value => field("last_verified_at", value)} /><div><Label>Visual tone</Label><select className="mt-2 h-10 w-full rounded-md border bg-background px-3" value={form.visual_tone} onChange={event => field("visual_tone", event.target.value)}>{["neutral","info","warning","critical","success"].map(value => <option key={value}>{value}</option>)}</select></div><div className="md:col-span-2"><Label>Summary</Label><Textarea className="mt-2" rows={5} value={form.summary} onChange={event => field("summary", event.target.value)} /></div><div className="md:col-span-2"><Label>Change summary</Label><Input className="mt-2" value={form.change_summary} onChange={event => field("change_summary", event.target.value)} placeholder="Explain the reason for this editorial change" /></div></CardContent></Card>
    <Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Metrics</CardTitle><Button variant="outline" size="sm" disabled={immutable} onClick={() => setMetrics(current => [...current, { ...emptyMetric(), sort_order: current.length + 1 }])}><Plus className="mr-2 h-4 w-4" />Metric</Button></div></CardHeader><CardContent className="space-y-3">{metrics.length === 0 ? <p className="text-sm text-muted-foreground">No metrics added.</p> : metrics.map((metric, index) => <div key={index} className="grid gap-2 rounded-md border p-3 md:grid-cols-4"><Input aria-label="Metric key" placeholder="confirmed_cases" value={metric.key} onChange={event => updateMetric(index, "key", event.target.value)} /><Input aria-label="Metric label" placeholder="Confirmed cases" value={metric.label} onChange={event => updateMetric(index, "label", event.target.value)} /><Input aria-label="Metric value" placeholder="20" value={metric.value} onChange={event => updateMetric(index, "value", event.target.value)} /><Input aria-label="Metric unit" placeholder="cases" value={metric.unit} onChange={event => updateMetric(index, "unit", event.target.value)} /><Input className="md:col-span-2" aria-label="Metric source" placeholder="WHO situation report 11" value={metric.source_reference} onChange={event => updateMetric(index, "source_reference", event.target.value)} /><Input type="datetime-local" aria-label="Metric as of" value={toLocal(metric.as_of)} onChange={event => updateMetric(index, "as_of", iso(event.target.value) || "")} /><Button variant="destructive" disabled={immutable} onClick={() => setMetrics(current => current.filter((_, position) => position !== index))}>Remove</Button></div>)}</CardContent></Card>
    {item ? <><Card><CardHeader><CardTitle>Updates</CardTitle></CardHeader><CardContent className="space-y-3"><div className="grid gap-2 md:grid-cols-[1fr_2fr_auto]"><Input placeholder="Update title" value={updateDraft.title} onChange={event => setUpdateDraft(current => ({ ...current, title: event.target.value }))} /><Input placeholder="Verified update summary" value={updateDraft.summary} onChange={event => setUpdateDraft(current => ({ ...current, summary: event.target.value }))} /><Button disabled={immutable} onClick={() => void addUpdate()}>Add draft</Button></div><ChildContentWorkflow outbreakId={item.id!} kind="update" items={updates} empty="No updates yet." onChanged={hydrate} /></CardContent></Card><Card><CardHeader><CardTitle>Typed resources</CardTitle></CardHeader><CardContent className="space-y-3"><div className="grid gap-2 md:grid-cols-2"><Input placeholder="Resource title" value={resourceDraft.title} onChange={event => setResourceDraft(current => ({ ...current, title: event.target.value }))} /><select className="rounded-md border bg-background px-3" value={resourceDraft.resource_type} onChange={event => setResourceDraft(current => ({ ...current, resource_type: event.target.value, url: "", asset_url: "" }))}>{["guideline","situation_report","internal_route","approved_external_url","managed_document","downloadable_asset"].map(value => <option key={value}>{value}</option>)}</select>{resourceDraft.resource_type === "guideline" ? <select aria-label="Published guideline" className="h-10 rounded-md border bg-background px-3" value={resourceDraft.url} onChange={event => setResourceDraft(current => ({ ...current, url: event.target.value }))}><option value="">Select a published guideline</option>{guidelines.map(value => <option key={value.id} value={`/public/guidelines/${value.id}`}>{value.title}</option>)}</select> : resourceDraft.resource_type === "situation_report" ? <select aria-label="Published situation report" className="h-10 rounded-md border bg-background px-3" value={resourceDraft.url} onChange={event => setResourceDraft(current => ({ ...current, url: event.target.value }))}><option value="">Select a published situation report</option>{reports.filter(value => value.status === "published").map(value => <option key={value.id} value={`/situation-reports/${value.id}`}>{value.title}</option>)}</select> : !["managed_document", "downloadable_asset"].includes(resourceDraft.resource_type) ? <Input placeholder="Allowlisted internal route or approved HTTPS URL" value={resourceDraft.url} onChange={event => setResourceDraft(current => ({ ...current, url: event.target.value }))} /> : <Input aria-label="Managed resource URL" disabled value="Backend-managed asset only" />}{["managed_document", "downloadable_asset"].includes(resourceDraft.resource_type) ? <Input placeholder="Backend-managed report asset path or approved HTTPS URL" value={resourceDraft.asset_url} onChange={event => setResourceDraft(current => ({ ...current, asset_url: event.target.value }))} /> : null}<Button className="md:col-span-2" disabled={immutable} onClick={() => void addResource()}>Add resource draft</Button></div><ChildContentWorkflow outbreakId={item.id!} kind="resource" items={resources} empty="No resources yet." onChanged={hydrate} /></CardContent></Card><Card><CardHeader><CardTitle>Related situation reports</CardTitle></CardHeader><CardContent><ChildRows items={reports.map(value => ({ id: value.id!, title: value.title || "Untitled report", status: value.status || "draft", detail: value.publication_date ? new Date(value.publication_date).toLocaleDateString() : "" }))} empty="No situation reports are linked." /></CardContent></Card><Card><CardHeader><CardTitle>Publication workflow</CardTitle></CardHeader><CardContent className="flex flex-wrap gap-2"><Button variant="outline" disabled={saving || item.status !== "draft"} onClick={() => void workflow("submit")}>Submit for review</Button><Button variant="outline" disabled={saving || item.status !== "pending_review"} onClick={() => void workflow("approve")}><CheckCircle2 className="mr-2 h-4 w-4" />Approve</Button><Button disabled={saving || item.status !== "pending_review" || !item.approved_at} onClick={() => void workflow("publish")}>Publish</Button><Button variant="destructive" disabled={saving || item.status === "draft" || item.status === "withdrawn"} onClick={() => void workflow("withdraw")}>Withdraw</Button><Button variant="outline" disabled={saving || !immutable || item.status === "withdrawn"} onClick={() => void workflow("correct")}>Create correction</Button><Button variant="ghost" asChild><Link href={`/api/public/outbreaks/${item.id}`} target="_blank"><ExternalLink className="mr-2 h-4 w-4" />Preview public API</Link></Button></CardContent></Card><Card><CardHeader><CardTitle>Review and audit history</CardTitle></CardHeader><CardContent className="space-y-3"><div className="flex gap-2"><Textarea maxLength={4000} value={reviewComment} onChange={event => setReviewComment(event.target.value)} placeholder="Add an auditable reviewer comment" /><Button variant="outline" disabled={!reviewComment.trim()} onClick={() => void addReviewComment()}>Add comment</Button></div><ChildRows items={audit.map(value => ({ id: value.id, title: value.action, status: new Date(value.created_at).toLocaleString(), detail: typeof value.metadata?.comment === "string" ? value.metadata.comment : `Actor ${value.actor_id}` }))} empty="No audit events recorded." /></CardContent></Card></> : null}
    {item && ["published","active","monitoring","contained","closed"].includes(item.status || "") ? <CampaignDraftBuilder contentKey={`outbreak:${item.id}:${item.lock_version}`} kinds={[{ value: "alert", label: "Outbreak alert" }, { value: "update", label: "Outbreak update" }, { value: "status_change", label: "Status change" }, { value: "closure", label: "Closure" }]} create={input => outbreaksService.createCampaign(item.id!, input)} /> : null}
  </div>

  function updateMetric(index: number, key: keyof MetricDraft, value: string) { setMetrics(current => current.map((metric, position) => position === index ? { ...metric, [key]: value } : metric)) }
}

function Field({ label, value, onChange, type = "text" }: { label: string; value: string; onChange: (value: string) => void; type?: string }) { return <div><Label>{label}</Label><Input className="mt-2" type={type} value={value} onChange={event => onChange(event.target.value)} /></div> }
function SelectField({ label, value, onChange, options, empty }: { label: string; value: string; onChange: (value: string) => void; options: Array<{ id: string; name: string }>; empty: string }) { return <div><Label>{label}</Label><select className="mt-2 h-10 w-full rounded-md border bg-background px-3" value={value} onChange={event => onChange(event.target.value)}><option value="">{empty}</option>{options.map(option => <option key={option.id} value={option.id}>{option.name}</option>)}</select></div> }
function ChildRows({ items, empty }: { items: Array<{ id: string; title: string; status: string; detail?: string }>; empty: string }) { return items.length ? <div className="space-y-2">{items.map(item => <div key={item.id} className="flex items-center justify-between rounded-md border p-3"><div><div className="font-medium">{item.title}</div><div className="text-xs text-muted-foreground">{item.detail}</div></div><Badge variant="outline">{item.status}</Badge></div>)}</div> : <div className="flex items-center gap-2 text-sm text-muted-foreground"><AlertCircle className="h-4 w-4" />{empty}</div> }
function iso(value: string) { return value ? new Date(value).toISOString() : undefined }
function toLocal(value?: string) { if (!value) return ""; const date = new Date(value); return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16) }
function conflictMessage(value: unknown) { const message = value instanceof Error ? value.message : "Operation failed"; return /conflict|modified|lock/i.test(message) ? "Another editor changed this record. Reload before retrying." : message }
