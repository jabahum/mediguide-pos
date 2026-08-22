"use client"

import * as React from "react"
import Link from "next/link"
import { AlertTriangle, Loader2, Plus, RefreshCw, Search } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PageHeader } from "@/components/ui/page-header"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { outbreaksService, type OutbreakRecord } from "@/services/outbreaks.service"

export default function OutbreaksPage() {
  const [items, setItems] = React.useState<OutbreakRecord[]>([])
  const [search, setSearch] = React.useState("")
  const [status, setStatus] = React.useState("")
  const [disease, setDisease] = React.useState("")
  const [area, setArea] = React.useState("")
  const [tone, setTone] = React.useState("")
  const [effectiveFrom, setEffectiveFrom] = React.useState("")
  const [updatedFrom, setUpdatedFrom] = React.useState("")
  const [sort, setSort] = React.useState("updated_at")
  const [page, setPage] = React.useState(1)
  const [totalPages, setTotalPages] = React.useState(0)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState("")

  const load = React.useCallback(async () => {
    setLoading(true); setError("")
    try {
      const result = await outbreaksService.list({ page, per_page: 20, search: search || undefined, status: status || undefined, disease: disease || undefined, area: area || undefined, visual_tone: tone || undefined, effective_from: effectiveFrom ? new Date(`${effectiveFrom}T00:00:00`).toISOString() : undefined, updated_from: updatedFrom ? new Date(`${updatedFrom}T00:00:00`).toISOString() : undefined, sort, order: "desc" })
      setItems(result.items || []); setTotalPages(result.total_pages || 0)
    } catch (value) { setError(value instanceof Error ? value.message : "Unable to load outbreaks") }
    finally { setLoading(false) }
  }, [area, disease, effectiveFrom, page, search, sort, status, tone, updatedFrom])

  React.useEffect(() => { void load() }, [load])

  return <div className="space-y-6">
    <div className="flex flex-wrap items-start justify-between gap-3">
      <PageHeader title="Outbreaks" description="Author, review and publish verified public-health outbreak content" />
      <Button asChild><Link href="/outbreaks/new"><Plus className="mr-2 h-4 w-4" />New outbreak</Link></Button>
    </div>
    <div className="grid gap-3 rounded-lg border p-4 md:grid-cols-5">
      <div className="relative md:col-span-2"><Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" /><Input className="pl-9" value={search} onChange={event => { setSearch(event.target.value); setPage(1) }} placeholder="Search title or summary" /></div>
      <Input value={disease} onChange={event => { setDisease(event.target.value); setPage(1) }} placeholder="Disease" />
      <Input value={area} onChange={event => { setArea(event.target.value); setPage(1) }} placeholder="Geographic area" />
      <select className="rounded-md border bg-background px-3 text-sm" value={status} onChange={event => { setStatus(event.target.value); setPage(1) }} aria-label="Lifecycle status"><option value="">All states</option>{["draft","pending_review","published","active","monitoring","contained","closed","withdrawn"].map(value => <option key={value}>{value}</option>)}</select>
      <select className="rounded-md border bg-background px-3 text-sm" value={tone} onChange={event => { setTone(event.target.value); setPage(1) }} aria-label="Visual tone"><option value="">All tones</option>{["neutral","info","warning","critical","success"].map(value => <option key={value}>{value}</option>)}</select>
      <label className="text-xs text-muted-foreground">Effective from<Input className="mt-1" type="date" value={effectiveFrom} onChange={event => { setEffectiveFrom(event.target.value); setPage(1) }} /></label>
      <label className="text-xs text-muted-foreground">Updated from<Input className="mt-1" type="date" value={updatedFrom} onChange={event => { setUpdatedFrom(event.target.value); setPage(1) }} /></label>
      <select className="rounded-md border bg-background px-3 text-sm" value={sort} onChange={event => { setSort(event.target.value); setPage(1) }} aria-label="Sort outbreaks"><option value="updated_at">Recently updated</option><option value="effective_at">Effective date</option><option value="data_as_of">Data freshness</option><option value="last_verified_at">Last verified</option><option value="title">Title</option></select>
    </div>
    {error ? <div className="rounded-md border border-destructive/40 p-4 text-sm text-destructive" role="alert">{error}<Button variant="outline" size="sm" className="ml-3" onClick={() => void load()}>Retry</Button></div> : null}
    <div className="rounded-lg border">
      <Table><TableHeader><TableRow><TableHead>Outbreak</TableHead><TableHead>Status</TableHead><TableHead>Area</TableHead><TableHead>Tone</TableHead><TableHead>Data as of</TableHead><TableHead>Last verified</TableHead><TableHead>Updated</TableHead></TableRow></TableHeader>
      <TableBody>
        {loading ? <TableRow><TableCell colSpan={7} className="py-12 text-center"><Loader2 className="mr-2 inline h-4 w-4 animate-spin" />Loading outbreaks…</TableCell></TableRow> : null}
        {!loading && items.length === 0 ? <TableRow><TableCell colSpan={7} className="py-12 text-center text-muted-foreground"><AlertTriangle className="mx-auto mb-2 h-8 w-8" />No outbreaks match these filters.</TableCell></TableRow> : null}
        {items.map(item => <TableRow key={item.id}><TableCell><Link className="font-medium hover:underline" href={`/outbreaks/${item.id}`}>{item.title || "Untitled"}</Link><div className="text-xs text-muted-foreground">{item.disease_type}</div></TableCell><TableCell><Badge variant={item.status === "withdrawn" ? "destructive" : "outline"}>{item.status}</Badge></TableCell><TableCell>{item.geographic_area}</TableCell><TableCell>{item.visual_tone}</TableCell><TableCell>{formatDate(item.data_as_of)}</TableCell><TableCell>{formatDate(item.last_verified_at)}</TableCell><TableCell>{formatDate(item.updated_at)}</TableCell></TableRow>)}
      </TableBody></Table>
    </div>
    <div className="flex items-center justify-between text-sm"><span>Page {page}{totalPages ? ` of ${totalPages}` : ""}</span><div className="flex gap-2"><Button variant="outline" size="sm" onClick={() => void load()} disabled={loading}><RefreshCw className="h-4 w-4" /></Button><Button variant="outline" size="sm" disabled={page <= 1 || loading} onClick={() => setPage(value => value - 1)}>Previous</Button><Button variant="outline" size="sm" disabled={page >= totalPages || loading} onClick={() => setPage(value => value + 1)}>Next</Button></div></div>
  </div>
}

function formatDate(value?: string) { return value ? new Date(value).toLocaleString() : "—" }
