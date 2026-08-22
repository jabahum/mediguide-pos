"use client"
import * as React from "react"
import Link from "next/link"
import { Loader2 } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { PageHeader } from "@/components/ui/page-header"
import { outbreaksService, type OutbreakResourceRecord } from "@/services/outbreaks.service"

export default function OutbreakResourcesPage() {
  const [rows, setRows] = React.useState<Array<OutbreakResourceRecord & { outbreak_title: string }>>([]), [loading, setLoading] = React.useState(true), [error, setError] = React.useState("")
  React.useEffect(() => { void (async () => { try { const outbreaks = await outbreaksService.list({ per_page: 100 }); const pages = await Promise.all((outbreaks.items || []).map(async outbreak => ({ outbreak, resources: await outbreaksService.listResources(outbreak.id!) }))); setRows(pages.flatMap(({ outbreak, resources }) => (resources.items || []).map(resource => ({ ...resource, outbreak_title: outbreak.title || "Untitled" })))) } catch (value) { setError(value instanceof Error ? value.message : "Unable to load outbreak resources") } finally { setLoading(false) } })() }, [])
  return <div className="space-y-6"><PageHeader title="Outbreak resources" description="Typed navigation and managed document resources grouped by outbreak" />{error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}<div className="space-y-2 rounded-lg border p-4">{loading ? <div className="py-12 text-center"><Loader2 className="mr-2 inline h-4 w-4 animate-spin" />Loading resources…</div> : null}{!loading && !rows.length ? <div className="py-12 text-center text-muted-foreground">No outbreak resources are configured.</div> : null}{rows.map(row => <div key={row.id} className="flex items-center justify-between rounded-md border p-3"><div><div className="font-medium">{row.title}</div><div className="text-xs text-muted-foreground">{row.outbreak_title} · {row.resource_type}</div></div><div className="flex items-center gap-2"><Badge variant="outline">{row.status}</Badge><Button variant="outline" size="sm" asChild><Link href={`/outbreaks/${row.outbreak_id}`}>Manage</Link></Button></div></div>)}</div></div>
}
