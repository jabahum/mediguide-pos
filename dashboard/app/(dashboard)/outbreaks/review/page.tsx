"use client"
import * as React from "react"
import Link from "next/link"
import { Loader2, ShieldCheck } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { PageHeader } from "@/components/ui/page-header"
import { outbreaksService, situationReportsService } from "@/services/outbreaks.service"

export default function OutbreakReviewPage() {
  const [rows, setRows] = React.useState<Array<{ id?: string; title?: string; kind: string; status?: string; updated_at?: string }>>([]), [loading, setLoading] = React.useState(true), [error, setError] = React.useState("")
  const load = React.useCallback(async () => { setLoading(true); setError(""); try { const [outbreaks, reports] = await Promise.all([outbreaksService.list({ status: "pending_review", per_page: 100, sort: "updated_at", order: "asc" }), situationReportsService.list({ status: "pending_review", per_page: 100, sort: "updated_at", order: "asc" })]); setRows([...(outbreaks.items || []).map(value => ({ ...value, kind: "Outbreak" })), ...(reports.items || []).map(value => ({ ...value, kind: "Situation report" }))]) } catch (value) { setError(value instanceof Error ? value.message : "Unable to load review queue") } finally { setLoading(false) } }, [])
  React.useEffect(() => { void load() }, [load])
  return <div className="space-y-6"><PageHeader title="Publication review" description="Independent review queue for safety-critical outbreak content" />{error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}<div className="space-y-3 rounded-lg border p-4">{loading ? <div className="py-12 text-center"><Loader2 className="mr-2 inline h-4 w-4 animate-spin" />Loading review queue…</div> : null}{!loading && !rows.length ? <div className="py-12 text-center text-muted-foreground"><ShieldCheck className="mx-auto mb-3 h-8 w-8" />Nothing is waiting for review.</div> : null}{rows.map(row => <div key={`${row.kind}-${row.id}`} className="flex items-center justify-between rounded-md border p-4"><div><div className="font-medium">{row.title}</div><div className="text-sm text-muted-foreground">{row.kind} · updated {row.updated_at ? new Date(row.updated_at).toLocaleString() : "—"}</div></div><div className="flex items-center gap-2"><Badge variant="outline">{row.status}</Badge><Button asChild size="sm"><Link href={row.kind === "Outbreak" ? `/outbreaks/${row.id}` : `/situation-reports/${row.id}`}>Review</Link></Button></div></div>)}</div></div>
}
