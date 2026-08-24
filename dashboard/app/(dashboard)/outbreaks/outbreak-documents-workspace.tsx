"use client"

import * as React from "react"
import { CheckCircle2, Download, FileText, FileUp, History, Pencil, Plus, Trash2 } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { showToast } from "@/lib/toast"
import { outbreaksService, type OutbreakAuditRecord, type OutbreakDocumentInput, type OutbreakDocumentRecord } from "@/services/outbreaks.service"

const documentKinds = ["sop", "case_definition", "ipc_protocol", "laboratory_protocol", "surveillance_protocol", "contact_tracing_guide", "treatment_protocol", "referral_protocol", "training_material", "checklist", "communication_material", "form", "policy", "situation_report_attachment", "other"]

type Draft = { title: string; description: string; document_kind: string; issuing_authority: string; document_number: string; version: string; language: string; audience: string; effective_date: string; review_date: string; expires_at: string }
const emptyDraft = (): Draft => ({ title: "", description: "", document_kind: "sop", issuing_authority: "Ministry of Health Uganda", document_number: "", version: "1.0", language: "en", audience: "Healthcare workers", effective_date: "", review_date: "", expires_at: "" })

export function OutbreakDocumentsWorkspace({ outbreakId, initialDocumentId }: { outbreakId: string; initialDocumentId?: string }) {
  const [documents, setDocuments] = React.useState<OutbreakDocumentRecord[]>([])
  const [draft, setDraft] = React.useState<Draft>(emptyDraft)
  const [editingId, setEditingId] = React.useState<string | null>(null)
  const [workingId, setWorkingId] = React.useState<string | null>(null)
  const [showForm, setShowForm] = React.useState(false)
  const [auditId, setAuditId] = React.useState<string | null>(null)
  const [audit, setAudit] = React.useState<OutbreakAuditRecord[]>([])
  const [comment, setComment] = React.useState("")
  const [error, setError] = React.useState("")

  const refresh = React.useCallback(async () => {
    try { const page = await outbreaksService.listDocuments(outbreakId, { sort: "created_at", order: "desc" }); setDocuments(page.items || []); setError("") }
    catch (value) { setError(message(value)) }
  }, [outbreakId])
  React.useEffect(() => { void refresh() }, [refresh])
  React.useEffect(() => {
    if (!initialDocumentId || !documents.some(value => value.id === initialDocumentId)) return
    setAuditId(initialDocumentId)
    void outbreaksService.documentAudit(outbreakId, initialDocumentId).then(page => setAudit(page.items || [])).catch(value => setError(message(value)))
  }, [documents, initialDocumentId, outbreakId])

  function field(key: keyof Draft, value: string) { setDraft(current => ({ ...current, [key]: value })) }
  function resetForm() { setDraft(emptyDraft()); setEditingId(null); setShowForm(false) }

  async function saveDraft() {
    if (!draft.title.trim()) return
    setWorkingId(editingId || "new")
    try {
      const input: OutbreakDocumentInput = { title: draft.title.trim(), description: draft.description.trim(), document_kind: draft.document_kind, issuing_authority: draft.issuing_authority.trim(), document_number: draft.document_number.trim(), version: draft.version.trim(), language: draft.language.trim(), audience: draft.audience.trim(), effective_date: iso(draft.effective_date), review_date: iso(draft.review_date), expires_at: iso(draft.expires_at), ...(editingId ? { lock_version: documents.find(value => value.id === editingId)?.lock_version } : {}) }
      if (editingId) await outbreaksService.updateDocument(outbreakId, editingId, input)
      else await outbreaksService.createDocument(outbreakId, input)
      resetForm(); await refresh(); showToast.success("Document draft saved", "Upload the managed file before submitting it for clinical review.")
    } catch (value) { showToast.error("Document not saved", message(value)) }
    finally { setWorkingId(null) }
  }

  function edit(item: OutbreakDocumentRecord) {
    if (item.status !== "draft") return
    setEditingId(item.id || null); setShowForm(true)
    setDraft({ title: item.title || "", description: item.description || "", document_kind: item.document_kind || "other", issuing_authority: item.issuing_authority || "", document_number: item.document_number || "", version: item.version || "", language: item.language || "en", audience: item.audience || "", effective_date: local(item.effective_date), review_date: local(item.review_date), expires_at: local(item.expires_at) })
  }

  async function upload(item: OutbreakDocumentRecord, file?: File) {
    if (!file || !item.id || item.lock_version === undefined) return
    setWorkingId(item.id)
    try { await outbreaksService.uploadDocument(outbreakId, item.id, item.lock_version, file); await refresh(); showToast.success("Managed file uploaded", "The checksum and immutable storage metadata were recorded.") }
    catch (value) { showToast.error("Upload failed", message(value)) }
    finally { setWorkingId(null) }
  }

  async function transition(item: OutbreakDocumentRecord, action: "submit" | "approve" | "publish" | "withdraw" | "correct") {
    if (!item.id || item.lock_version === undefined) return
    let reason = ""
    if (action === "approve") reason = window.prompt("Record the clinical basis for approval")?.trim() || ""
    if (action === "withdraw" || action === "correct") reason = window.prompt(`Enter the reason for ${action}`)?.trim() || ""
    if (["approve", "withdraw", "correct"].includes(action) && !reason) return
    if (action === "publish" && !window.confirm("Publish this clinically approved document? Published files and metadata are immutable.")) return
    setWorkingId(item.id)
    try {
      if (action === "correct") await outbreaksService.correctDocument(outbreakId, item.id, { lock_version: item.lock_version, reason })
      else await outbreaksService.transitionDocument(outbreakId, item.id, action, { lock_version: item.lock_version, reason })
      await refresh(); showToast.success("Document workflow updated", `The ${action} action completed.`)
    } catch (value) { showToast.error("Workflow failed", message(value)) }
    finally { setWorkingId(null) }
  }

  async function remove(item: OutbreakDocumentRecord) {
    if (!item.id || item.lock_version === undefined || !window.confirm("Delete this document draft and its unreferenced managed file?")) return
    setWorkingId(item.id)
    try { await outbreaksService.removeDocument(outbreakId, item.id, item.lock_version); await refresh(); showToast.success("Draft deleted", "Unreferenced managed storage was cleaned up.") }
    catch (value) { showToast.error("Delete failed", message(value)) }
    finally { setWorkingId(null) }
  }

  async function showAudit(item: OutbreakDocumentRecord) {
    if (!item.id) return
    setAuditId(item.id); setComment("")
    try { const page = await outbreaksService.documentAudit(outbreakId, item.id); setAudit(page.items || []) }
    catch (value) { showToast.error("Audit unavailable", message(value)) }
  }

  async function addComment() {
    if (!auditId || !comment.trim()) return
    try { await outbreaksService.addDocumentReviewComment(outbreakId, auditId, comment.trim()); const page = await outbreaksService.documentAudit(outbreakId, auditId); setAudit(page.items || []); setComment(""); showToast.success("Review comment added", "The comment is now part of the immutable audit history.") }
    catch (value) { showToast.error("Comment not added", message(value)) }
  }

  return <Card>
    <CardHeader><div className="flex flex-wrap items-center justify-between gap-3"><div><CardTitle>Outbreak documents and SOPs</CardTitle><p className="mt-1 text-sm text-muted-foreground">Managed, versioned documents require independent clinical approval before publication.</p></div><Button variant="outline" onClick={() => { resetForm(); setShowForm(true) }}><Plus className="mr-2 h-4 w-4" />Document draft</Button></div></CardHeader>
    <CardContent className="space-y-4">
      {error ? <div className="rounded-md border border-destructive/40 p-3 text-sm text-destructive" role="alert">{error} <Button size="sm" variant="outline" onClick={() => void refresh()}>Retry</Button></div> : null}
      {showForm ? <div className="space-y-3 rounded-md border bg-muted/20 p-4"><div className="grid gap-3 md:grid-cols-2"><TextField label="Title" value={draft.title} onChange={value => field("title", value)} /><SelectField label="Document kind" value={draft.document_kind} onChange={value => field("document_kind", value)} /><TextField label="Issuing authority" value={draft.issuing_authority} onChange={value => field("issuing_authority", value)} /><TextField label="Document number" value={draft.document_number} onChange={value => field("document_number", value)} /><TextField label="Version" value={draft.version} onChange={value => field("version", value)} /><TextField label="Language (BCP-47)" value={draft.language} onChange={value => field("language", value)} /><TextField label="Audience" value={draft.audience} onChange={value => field("audience", value)} /><TextField label="Effective date" type="datetime-local" value={draft.effective_date} onChange={value => field("effective_date", value)} /><TextField label="Review date" type="datetime-local" value={draft.review_date} onChange={value => field("review_date", value)} /><TextField label="Expiry date" type="datetime-local" value={draft.expires_at} onChange={value => field("expires_at", value)} /><div className="md:col-span-2"><Label>Description</Label><Textarea className="mt-2" maxLength={10000} value={draft.description} onChange={event => field("description", event.target.value)} /></div></div><div className="flex gap-2"><Button disabled={!draft.title.trim() || workingId !== null} onClick={() => void saveDraft()}>{editingId ? "Save metadata" : "Create draft"}</Button><Button variant="ghost" onClick={resetForm}>Cancel</Button></div></div> : null}
      {!documents.length ? <p className="text-sm text-muted-foreground">No outbreak documents have been created.</p> : <div className="space-y-3">{documents.map(item => <DocumentRow key={item.id} item={item} busy={workingId === item.id} onEdit={() => edit(item)} onUpload={file => void upload(item, file)} onTransition={action => void transition(item, action)} onDelete={() => void remove(item)} onAudit={() => void showAudit(item)} />)}</div>}
      {auditId ? <div className="space-y-3 rounded-md border p-4"><div className="flex items-center justify-between"><h3 className="font-semibold">Clinical review and audit history</h3><Button size="sm" variant="ghost" onClick={() => setAuditId(null)}>Close</Button></div><div className="flex gap-2"><Textarea maxLength={4000} value={comment} onChange={event => setComment(event.target.value)} placeholder="Add an auditable clinical review comment" /><Button variant="outline" disabled={!comment.trim()} onClick={() => void addComment()}>Add comment</Button></div>{audit.length ? audit.map(event => <div key={event.id} className="rounded-md border p-3 text-sm"><div className="font-medium">{event.action}</div>{typeof event.metadata?.comment === "string" ? <p>{event.metadata.comment}</p> : null}{typeof event.metadata?.reason === "string" && event.metadata.reason ? <p>{event.metadata.reason}</p> : null}<div className="text-xs text-muted-foreground">{new Date(event.created_at).toLocaleString()} · actor {event.actor_id}</div></div>) : <p className="text-sm text-muted-foreground">No audit events recorded.</p>}</div> : null}
    </CardContent>
  </Card>
}

function DocumentRow({ item, busy, onEdit, onUpload, onTransition, onDelete, onAudit }: { item: OutbreakDocumentRecord; busy: boolean; onEdit: () => void; onUpload: (file?: File) => void; onTransition: (action: "submit" | "approve" | "publish" | "withdraw" | "correct") => void; onDelete: () => void; onAudit: () => void }) {
  const status = item.status || "draft"
  return <div className="space-y-3 rounded-md border p-4"><div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between"><div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><FileText className="h-4 w-4" /><span className="font-medium">{item.title || "Untitled document"}</span><Badge variant="outline">{status}</Badge><Badge variant="secondary">{label(item.document_kind)}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{[item.issuing_authority, item.document_number, item.version ? `v${item.version}` : "", item.language].filter(Boolean).join(" · ")}</p>{item.original_filename ? <p className="mt-1 text-xs text-muted-foreground">{item.original_filename} · {formatBytes(item.file_size || 0)} · SHA-256 {item.checksum_sha256?.slice(0, 12)}…</p> : <p className="mt-1 text-xs text-amber-700">A managed file is required before review.</p>}</div><div className="flex flex-wrap gap-2"><Button size="sm" variant="ghost" disabled={busy} onClick={onAudit}><History className="mr-1 h-4 w-4" />Audit</Button>{status === "draft" ? <><Button size="sm" variant="outline" disabled={busy} onClick={onEdit}><Pencil className="mr-1 h-4 w-4" />Edit</Button><label className="inline-flex h-9 cursor-pointer items-center rounded-md border px-3 text-sm"><FileUp className="mr-1 h-4 w-4" />{item.original_filename ? "Replace file" : "Upload file"}<input className="sr-only" type="file" accept=".pdf,.docx,.xlsx,.md,.txt" disabled={busy} onChange={event => { onUpload(event.target.files?.[0]); event.currentTarget.value = "" }} /></label><Button size="sm" variant="destructive" disabled={busy} onClick={onDelete}><Trash2 className="h-4 w-4" /><span className="sr-only">Delete</span></Button></> : null}{status === "published" && item.id ? <Button size="sm" variant="outline" asChild><a href={`/api/public/outbreaks/${item.outbreak_id}/documents/${item.id}/download`} target="_blank" rel="noreferrer"><Download className="mr-1 h-4 w-4" />Open</a></Button> : null}</div></div><div className="flex flex-wrap gap-2">{status === "draft" ? <Button size="sm" variant="outline" disabled={busy || !item.original_filename} onClick={() => onTransition("submit")}>Submit for clinical review</Button> : null}{status === "pending_review" && !item.approved_at ? <Button size="sm" variant="outline" disabled={busy} onClick={() => onTransition("approve")}><CheckCircle2 className="mr-1 h-4 w-4" />Clinician approve</Button> : null}{status === "pending_review" && item.approved_at ? <Button size="sm" disabled={busy} onClick={() => onTransition("publish")}>Publish</Button> : null}{status === "published" ? <Button size="sm" variant="outline" disabled={busy} onClick={() => onTransition("correct")}>Create correction</Button> : null}{status !== "draft" && status !== "withdrawn" ? <Button size="sm" variant="destructive" disabled={busy} onClick={() => onTransition("withdraw")}>Withdraw</Button> : null}</div></div>
}

function TextField({ label: text, value, onChange, type = "text" }: { label: string; value: string; onChange: (value: string) => void; type?: string }) { return <div><Label>{text}</Label><Input className="mt-2" type={type} value={value} onChange={event => onChange(event.target.value)} /></div> }
function SelectField({ label: text, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) { return <div><Label>{text}</Label><select className="mt-2 h-10 w-full rounded-md border bg-background px-3" value={value} onChange={event => onChange(event.target.value)}>{documentKinds.map(kind => <option key={kind} value={kind}>{label(kind)}</option>)}</select></div> }
function label(value?: string) { return (value || "other").split("_").map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ") }
function iso(value: string) { return value ? new Date(value).toISOString() : undefined }
function local(value?: string) { if (!value) return ""; const date = new Date(value); return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16) }
function formatBytes(value: number) { if (value < 1024) return `${value} B`; if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`; return `${(value / 1024 / 1024).toFixed(1)} MB` }
function message(value: unknown) { const text = value instanceof Error ? value.message : "Operation failed"; return /conflict|modified|lock/i.test(text) ? "Another editor changed this document. Reload before retrying." : text }
