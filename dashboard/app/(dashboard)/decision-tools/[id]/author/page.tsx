"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { ClinicalToolWorkspace } from "@/components/clinical-tools/clinical-tool-workspace"
import { clinicalToolService, type ClinicalToolVersion } from "@/services/clinical-tool.service"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { toast } from "sonner"

type AuditItem = { id: string; action: string; created_at: string; metadata?: { comment?: string } }

export default function ClinicalToolAuthorPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = React.use(params)
  const router = useRouter()
  const [version, setVersion] = React.useState<ClinicalToolVersion>()
  const [versions, setVersions] = React.useState<ClinicalToolVersion[]>([])
  const [audit, setAudit] = React.useState<AuditItem[]>([])
  const [comment, setComment] = React.useState("")
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState("")
  React.useEffect(() => { clinicalToolService.versions(id).then((items) => { setVersions(items); setVersion(items.find((item) => item.status === "draft") ?? items[0]) }).catch((reason: unknown) => setError(reason instanceof Error ? reason.message : "Unable to load versions")).finally(() => setLoading(false)) }, [id])
  const versionId = version?.id
  const loadAudit = React.useCallback(async () => { if (versionId) setAudit(await clinicalToolService.audit(versionId)) }, [versionId])
  React.useEffect(() => { if (versionId) loadAudit().catch(() => setAudit([])) }, [versionId, loadAudit])
  const addComment = async () => {
    if (!versionId || !comment.trim()) return
    try { await clinicalToolService.reviewComment(versionId, comment.trim()); setComment(""); await loadAudit(); toast.success("Review comment added") }
    catch (reason) { toast.error(reason instanceof Error ? reason.message : "Unable to add review comment") }
  }
  const changed = (next: ClinicalToolVersion) => { setVersion(next); setVersions((items) => items.some((item) => item.id === next.id) ? items.map((item) => item.id === next.id ? next : item) : [next, ...items]) }
  const published = versions.find((item) => item.status === "published")
  return <div className="space-y-6"><PageHeader title="Clinical tool authoring" description="Build, validate, test, review and publish a native schema tool." showBackButton onBack={() => router.push(`/decision-tools/${id}`)} />{loading ? <p>Loading version history…</p> : error ? <p role="alert" className="text-destructive">{error}</p> : <><div className="grid gap-4 lg:grid-cols-2"><Card><CardHeader><CardTitle>Version history</CardTitle></CardHeader><CardContent className="flex flex-wrap gap-2">{versions.length ? versions.map((item) => <Button key={item.id} size="sm" variant={item.id === version?.id ? "default" : "outline"} onClick={() => setVersion(item)}>v{item.semantic_version} · {item.status}</Button>) : <p className="text-sm text-muted-foreground">No schema versions yet. Import or author the first draft below.</p>}</CardContent></Card><Card><CardHeader><CardTitle>Review and audit trail</CardTitle></CardHeader><CardContent className="space-y-3"><ul className="max-h-36 space-y-1 overflow-auto text-sm">{audit.map((item) => <li key={item.id}><span>{item.action} · {new Date(item.created_at).toLocaleString()}</span>{item.metadata?.comment && <blockquote className="mt-1 border-l-2 pl-2 text-muted-foreground">{item.metadata.comment}</blockquote>}</li>)}</ul>{version && version.status !== "withdrawn" && <div className="space-y-2"><Textarea aria-label="Review comment" placeholder="Add an immutable clinical review comment…" maxLength={4000} value={comment} onChange={(event) => setComment(event.target.value)} /><Button size="sm" variant="outline" disabled={!comment.trim()} onClick={addComment}>Add review comment</Button></div>}</CardContent></Card></div>{published && version && published.id !== version.id && <details className="rounded-lg border p-4"><summary className="cursor-pointer font-medium">Compare v{version.semantic_version} with published v{published.semantic_version}</summary><div className="mt-4 grid gap-4 lg:grid-cols-2"><pre className="max-h-72 overflow-auto bg-muted p-3 text-xs">{JSON.stringify(published.definition, null, 2)}</pre><pre className="max-h-72 overflow-auto bg-muted p-3 text-xs">{JSON.stringify(version.definition, null, 2)}</pre></div></details>}<ClinicalToolWorkspace key={version?.id ?? "new"} toolId={id} initialVersion={version} onChanged={changed} /></>}</div>
}
