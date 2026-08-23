"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { RefreshCw, Search } from "lucide-react"
import { PageHeader } from "@/components/ui/page-header"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { clinicalToolService, type ClinicalToolReviewQueue } from "@/services/clinical-tool.service"

export default function ClinicalToolReviewQueuePage() {
  const router = useRouter()
  const [query, setQuery] = React.useState("")
  const [status, setStatus] = React.useState("pending_review")
  const [type, setType] = React.useState("")
  const [page, setPage] = React.useState(1)
  const [data, setData] = React.useState<ClinicalToolReviewQueue>()
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState("")

  const load = React.useCallback(async () => {
    setLoading(true); setError("")
    try { setData(await clinicalToolService.reviewQueue({ page, per_page: 20, search: query, status, type, sort: "created_at", order: "desc" })) }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Unable to load the clinical review queue") }
    finally { setLoading(false) }
  }, [page, query, status, type])
  React.useEffect(() => { void load() }, [load])

  return <div className="space-y-6">
    <PageHeader title="Clinical tool review" description="Review validated schema definitions without exposing drafts through the public calculator catalog." />
    <Card><CardContent className="grid gap-3 pt-6 md:grid-cols-[1fr_220px_220px_auto]">
      <label className="relative"><span className="sr-only">Search review queue</span><Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" /><Input className="pl-9" value={query} onChange={(event) => { setQuery(event.target.value); setPage(1) }} placeholder="Search tool or version" /></label>
      <select aria-label="Version status" className="rounded-md border bg-background px-3" value={status} onChange={(event) => { setStatus(event.target.value); setPage(1) }}><option value="pending_review">Pending review</option><option value="draft,pending_review,approved,published">All review states</option><option value="draft">Draft</option><option value="approved">Approved</option><option value="published">Published</option></select>
      <select aria-label="Tool type" className="rounded-md border bg-background px-3" value={type} onChange={(event) => { setType(event.target.value); setPage(1) }}><option value="">All tool types</option><option value="calculator">Calculator</option><option value="decision_tool">Decision tool</option><option value="checklist">Checklist</option></select>
      <Button variant="outline" onClick={() => void load()}><RefreshCw className="mr-2 h-4 w-4" />Refresh</Button>
    </CardContent></Card>
    {loading ? <p aria-live="polite">Loading review queue…</p> : error ? <Card className="border-destructive"><CardContent className="space-y-3 pt-6"><p role="alert">{error}</p><Button onClick={() => void load()}>Try again</Button></CardContent></Card> : !data?.items.length ? <Card><CardContent className="pt-6 text-muted-foreground">No versions match the selected review filters.</CardContent></Card> : <div className="space-y-3">{data.items.map((item) => <button key={item.version_id} className="w-full rounded-lg border bg-card p-4 text-left transition-colors hover:bg-muted/50" onClick={() => router.push(`/decision-tools/${item.calculator_id}/review/${item.version_id}`)}><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-semibold">{item.tool_name} <span className="font-normal text-muted-foreground">v{item.semantic_version}</span></h2><p className="text-sm text-muted-foreground">{item.tool_type.replaceAll("_", " ")} · {item.clinical_owner || "No program area recorded"}</p></div><div className="flex flex-wrap gap-2"><Badge variant="outline">{item.version_status.replaceAll("_", " ")}</Badge><Badge variant={item.validation_passed ? "default" : "destructive"}>validation {item.validation_passed ? "passed" : "required"}</Badge><Badge variant={item.tests_passed ? "default" : "destructive"}>{item.fixture_passed_count}/{item.fixture_count} fixtures</Badge></div></div><div className="mt-3 grid gap-1 text-xs text-muted-foreground md:grid-cols-3"><span>Author: {item.author_id || "not recorded"}</span><span>Reviewer: {item.reviewer_id || "unassigned"}</span><span>Parity evidence: {item.review_evidence_status.replaceAll("_", " ")}</span></div></button>)}</div>}
    {data && data.total_pages > 1 && <div className="flex items-center justify-between"><p className="text-sm text-muted-foreground">Page {data.page} of {data.total_pages} · {data.total_items} versions</p><div className="flex gap-2"><Button variant="outline" disabled={page <= 1} onClick={() => setPage((value) => value - 1)}>Previous</Button><Button variant="outline" disabled={page >= data.total_pages} onClick={() => setPage((value) => value + 1)}>Next</Button></div></div>}
  </div>
}
