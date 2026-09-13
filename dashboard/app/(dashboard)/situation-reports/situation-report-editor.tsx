"use client"

import * as React from "react"
import Link from "next/link"
import { ExternalLink, FileUp, Loader2, Plus, Save } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { showToast } from "@/lib/toast"
import { withDashboardBasePath } from "@/lib/dashboard-path"
import { healthFacilitiesService } from "@/services/health-facilities.service"
import { outbreaksService, type OutbreakMetric, type OutbreakRecord } from "@/services/outbreaks.service"
import { situationReportsService, type OutbreakAuditRecord, type SituationReportRecord } from "@/services/situation-reports.service"
import type { DistrictsResponse, RegionsResponse } from "@/types/backend-types"
import { CampaignDraftBuilder } from "../outbreaks/campaign-draft-builder"

const emptyMetric = (position: number): OutbreakMetric => ({ key: "", label: "", value: "", unit: "", source_reference: "", as_of: new Date().toISOString(), sort_order: position })

export function SituationReportEditor({ id }: { id?: string }) {
  const [item, setItem] = React.useState<SituationReportRecord | null>(null)
  const [outbreaks, setOutbreaks] = React.useState<OutbreakRecord[]>([])
  const [regions, setRegions] = React.useState<RegionsResponse[]>([])
  const [districts, setDistricts] = React.useState<DistrictsResponse[]>([])
  const [audit, setAudit] = React.useState<OutbreakAuditRecord[]>([])
  const [metrics, setMetrics] = React.useState<OutbreakMetric[]>([])
  const [reviewComment, setReviewComment] = React.useState("")
  const [loading, setLoading] = React.useState(Boolean(id))
  const [saving, setSaving] = React.useState(false)
  const [error, setError] = React.useState("")
  const [form, setForm] = React.useState({ outbreak_id: "", region_id: "", district_id: "", title: "", geographic_area: "", summary: "", source_organization: "", source_url: "", source_reference: "", publication_date: "", effective_at: "", data_as_of: "", last_verified_at: "", standalone_allowed: false, highlights: "" })

  const loadReferences = React.useCallback(async () => {
    const [outbreakPage, regionRows] = await Promise.all([outbreaksService.list({ page: 1, per_page: 100, sort: "updated_at", order: "desc" }), healthFacilitiesService.regions()])
    setOutbreaks(outbreakPage.items || []); setRegions(regionRows)
  }, [])
  const hydrate = React.useCallback(async () => {
    setLoading(true); setError("")
    try {
      await loadReferences()
      if (!id) return
      const [value, history] = await Promise.all([situationReportsService.get(id), situationReportsService.audit(id)])
      setItem(value); setAudit(history.items || []); setMetrics(value.metrics || [])
      setForm({ outbreak_id: value.outbreak_id || "", region_id: value.region_id || "", district_id: value.district_id || "", title: value.title || "", geographic_area: value.geographic_area || "", summary: value.summary || "", source_organization: value.source_organization || "", source_url: value.source_url || "", source_reference: value.source_reference || "", publication_date: local(value.publication_date), effective_at: local(value.effective_at), data_as_of: local(value.data_as_of), last_verified_at: local(value.last_verified_at), standalone_allowed: Boolean(value.standalone_allowed), highlights: (value.key_highlights || []).join("\n") })
    } catch (value) { setError(value instanceof Error ? value.message : "Unable to load report") }
    finally { setLoading(false) }
  }, [id, loadReferences])

  React.useEffect(() => { void hydrate() }, [hydrate])
  React.useEffect(() => {
    if (!form.region_id) { setDistricts([]); return }
    void healthFacilitiesService.districts(form.region_id).then(setDistricts).catch(() => setDistricts([]))
  }, [form.region_id])

  const immutable = item?.status === "published" || item?.status === "withdrawn"
  const field = (name: keyof typeof form, value: string | boolean) => setForm(current => ({ ...current, [name]: value }))
  async function save() {
    setSaving(true)
    try {
      const input = { outbreak_id: form.outbreak_id || undefined, region_id: form.region_id || undefined, district_id: form.district_id || undefined, title: form.title, geographic_area: form.geographic_area, summary: form.summary, source_organization: form.source_organization, source_url: form.source_url, source_reference: form.source_reference, publication_date: iso(form.publication_date), effective_at: iso(form.effective_at), data_as_of: iso(form.data_as_of), last_verified_at: iso(form.last_verified_at), standalone_allowed: form.standalone_allowed, key_highlights: form.highlights.split("\n").map(value => value.trim()).filter(Boolean), metrics, ...(item ? { lock_version: item.lock_version } : {}) }
      const saved = item ? await situationReportsService.update(item.id!, input) : await situationReportsService.create(input)
      showToast.success("Report saved", "The report remains unpublished.")
      if (!item) window.location.assign(withDashboardBasePath(`/situation-reports/${saved.id}`)); else setItem(saved)
    } catch (value) { showToast.error("Unable to save", message(value)) }
    finally { setSaving(false) }
  }
  async function transition(action: "submit" | "approve" | "publish" | "withdraw" | "correct") {
    if (!item) return
    const reason = ["withdraw", "correct"].includes(action) ? window.prompt(`Reason for ${action}`)?.trim() : ""
    if (["withdraw", "correct"].includes(action) && !reason) return
    if (action === "publish" && !window.confirm("Publish this verified situation report? Published content is immutable.")) return
    if (action === "withdraw" && !window.confirm("Withdraw this published report? Existing links will stop resolving.")) return
    setSaving(true)
    try {
      const next = action === "correct" ? await situationReportsService.correct(item.id!, { lock_version: item.lock_version!, reason }) : await situationReportsService.transition(item.id!, action, { lock_version: item.lock_version!, reason })
      setItem(next); await refreshAudit()
      if (action === "correct") window.location.assign(withDashboardBasePath(`/situation-reports/${next.id}`))
    } catch (value) { showToast.error("Workflow failed", message(value)) }
    finally { setSaving(false) }
  }
  async function upload(file?: File) { if (!item || !file) return; try { await situationReportsService.uploadAsset(item.id!, file); showToast.success("PDF uploaded", "The managed asset is attached to this draft."); await hydrate() } catch (value) { showToast.error("Upload failed", message(value)) } }
  async function refreshAudit() { if (!item?.id) return; const history = await situationReportsService.audit(item.id); setAudit(history.items || []) }
  async function comment() { if (!item?.id || !reviewComment.trim()) return; try { await situationReportsService.addReviewComment(item.id, reviewComment); setReviewComment(""); await refreshAudit(); showToast.success("Review comment added", "The comment is part of the immutable audit history.") } catch (value) { showToast.error("Comment not added", message(value)) } }
  function updateMetric(index: number, key: keyof OutbreakMetric, value: string) { setMetrics(current => current.map((metric, position) => position === index ? { ...metric, [key]: value } : metric)) }

  if (loading) return <div className="py-20 text-center"><Loader2 className="mr-2 inline h-5 w-5 animate-spin" />Loading…</div>
  if (error) return <div role="alert" className="rounded-md border border-destructive/40 p-5 text-destructive">{error}<Button className="ml-3" variant="outline" onClick={() => void hydrate()}>Retry</Button></div>
  return <div className="space-y-6">
    <div className="flex flex-wrap justify-between gap-3"><div className="flex items-center gap-2"><h1 className="text-2xl font-semibold">{item?.title || "New situation report"}</h1>{item ? <Badge variant="outline">{item.status}</Badge> : null}</div><div className="flex flex-wrap gap-2"><Button variant="outline" asChild><Link href="/situation-reports">Back</Link></Button>{item ? <Button variant="outline" asChild><Link href={`/api/public/situation-reports/${item.id}`} target="_blank"><ExternalLink className="mr-2 h-4 w-4" />Preview</Link></Button> : null}<Button disabled={saving || immutable} onClick={() => void save()}><Save className="mr-2 h-4 w-4" />Save draft</Button></div></div>
    <Card><CardHeader><CardTitle>Report metadata</CardTitle></CardHeader><CardContent className="grid gap-4 md:grid-cols-2">
      <SelectField label="Related outbreak" value={form.outbreak_id} onChange={value => field("outbreak_id", value)} options={outbreaks.map(value => ({ id: value.id!, name: value.title || value.id! }))} empty="Standalone report" />
      <label className="flex items-center gap-2 pt-8 text-sm"><input type="checkbox" checked={form.standalone_allowed} onChange={event => field("standalone_allowed", event.target.checked)} />Explicitly allow standalone report</label>
      <Field label="Title" value={form.title} onChange={value => field("title", value)} /><Field label="Geographic area" value={form.geographic_area} onChange={value => field("geographic_area", value)} />
      <SelectField label="Region" value={form.region_id} onChange={value => { field("region_id", value); field("district_id", "") }} options={regions.map(value => ({ id: value.id, name: value.name }))} empty="Select region" />
      <SelectField label="District" value={form.district_id} onChange={value => field("district_id", value)} options={districts.map(value => ({ id: value.id, name: value.name }))} empty="Select district" />
      <Field label="Source organization" value={form.source_organization} onChange={value => field("source_organization", value)} /><Field label="Source reference" value={form.source_reference} onChange={value => field("source_reference", value)} /><Field label="Source HTTPS URL" value={form.source_url} onChange={value => field("source_url", value)} /><Field label="Publication date" type="datetime-local" value={form.publication_date} onChange={value => field("publication_date", value)} /><Field label="Effective at" type="datetime-local" value={form.effective_at} onChange={value => field("effective_at", value)} /><Field label="Data as of" type="datetime-local" value={form.data_as_of} onChange={value => field("data_as_of", value)} /><Field label="Last verified" type="datetime-local" value={form.last_verified_at} onChange={value => field("last_verified_at", value)} />
      <div className="md:col-span-2"><Label>Summary</Label><Textarea className="mt-2" rows={4} value={form.summary} onChange={event => field("summary", event.target.value)} /></div><div className="md:col-span-2"><Label>Highlights (one bounded statement per line)</Label><Textarea className="mt-2" rows={6} value={form.highlights} onChange={event => field("highlights", event.target.value)} /></div>
    </CardContent></Card>
    <Card><CardHeader><div className="flex items-center justify-between"><CardTitle>Typed metrics</CardTitle><Button variant="outline" size="sm" disabled={immutable} onClick={() => setMetrics(current => [...current, emptyMetric(current.length + 1)])}><Plus className="mr-2 h-4 w-4" />Metric</Button></div></CardHeader><CardContent className="space-y-3">{metrics.length ? metrics.map((metric, index) => <div key={index} className="grid gap-2 rounded-md border p-3 md:grid-cols-4"><Input placeholder="confirmed_cases" value={metric.key || ""} onChange={event => updateMetric(index, "key", event.target.value)} /><Input placeholder="Confirmed cases" value={metric.label || ""} onChange={event => updateMetric(index, "label", event.target.value)} /><Input placeholder="20" value={metric.value || ""} onChange={event => updateMetric(index, "value", event.target.value)} /><Input placeholder="cases" value={metric.unit || ""} onChange={event => updateMetric(index, "unit", event.target.value)} /><Input className="md:col-span-2" placeholder="Source reference" value={metric.source_reference || ""} onChange={event => updateMetric(index, "source_reference", event.target.value)} /><Input type="datetime-local" value={local(metric.as_of)} onChange={event => updateMetric(index, "as_of", iso(event.target.value) || "")} /><Button variant="destructive" disabled={immutable} onClick={() => setMetrics(current => current.filter((_, position) => position !== index))}>Remove</Button></div>) : <p className="text-sm text-muted-foreground">No metrics added.</p>}</CardContent></Card>
    {item ? <><Card><CardHeader><CardTitle>Managed PDF and publication workflow</CardTitle></CardHeader><CardContent className="space-y-4"><label className="flex cursor-pointer items-center gap-2 rounded-md border border-dashed p-4"><FileUp className="h-5 w-5" /><span>{item.report_asset_id ? "Replace managed PDF" : "Upload managed PDF"}</span><input className="sr-only" type="file" accept="application/pdf" disabled={immutable} onChange={event => void upload(event.target.files?.[0])} /></label><div className="flex flex-wrap gap-2"><Button variant="outline" disabled={item.status !== "draft"} onClick={() => void transition("submit")}>Submit</Button><Button variant="outline" disabled={item.status !== "pending_review"} onClick={() => void transition("approve")}>Approve</Button><Button disabled={item.status !== "pending_review" || !item.approved_at || !item.report_asset_id} onClick={() => void transition("publish")}>Publish</Button><Button variant="destructive" disabled={item.status === "draft" || item.status === "withdrawn"} onClick={() => void transition("withdraw")}>Withdraw</Button><Button variant="outline" disabled={!immutable || item.status === "withdrawn"} onClick={() => void transition("correct")}>Create correction</Button></div></CardContent></Card>
    <Card><CardHeader><CardTitle>Review and audit history</CardTitle></CardHeader><CardContent className="space-y-3"><div className="flex gap-2"><Textarea value={reviewComment} onChange={event => setReviewComment(event.target.value)} placeholder="Add an auditable reviewer comment" maxLength={4000} /><Button variant="outline" disabled={!reviewComment.trim()} onClick={() => void comment()}>Add comment</Button></div>{audit.length ? audit.map(event => <div key={event.id} className="rounded-md border p-3"><div className="font-medium">{event.action}</div>{typeof event.metadata?.comment === "string" ? <div className="mt-1 text-sm">{event.metadata.comment}</div> : null}<div className="text-xs text-muted-foreground">{new Date(event.created_at).toLocaleString()} · actor {event.actor_id}</div></div>) : <p className="text-sm text-muted-foreground">No audit events recorded.</p>}</CardContent></Card></> : null}
    {item?.status === "published" ? <CampaignDraftBuilder contentKey={`situation-report:${item.id}:${item.lock_version}`} kinds={[{ value: "publication", label: "Situation-report publication" }]} create={input => situationReportsService.createCampaign(item.id!, input)} /> : null}
  </div>
}

function Field({ label, value, onChange, type = "text" }: { label: string; value: string; onChange: (value: string) => void; type?: string }) { return <div><Label>{label}</Label><Input className="mt-2" value={value} type={type} onChange={event => onChange(event.target.value)} /></div> }
function SelectField({ label, value, onChange, options, empty }: { label: string; value: string; onChange: (value: string) => void; options: Array<{ id: string; name: string }>; empty: string }) { return <div><Label>{label}</Label><select className="mt-2 h-10 w-full rounded-md border bg-background px-3" value={value} onChange={event => onChange(event.target.value)}><option value="">{empty}</option>{options.map(option => <option key={option.id} value={option.id}>{option.name}</option>)}</select></div> }
function iso(value: string) { return value ? new Date(value).toISOString() : undefined }
function local(value?: string) { if (!value) return ""; const date = new Date(value); return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16) }
function message(value: unknown) { const text = value instanceof Error ? value.message : "Operation failed"; return /conflict|modified|lock/i.test(text) ? "Another editor changed this report. Reload and review their changes." : text }
