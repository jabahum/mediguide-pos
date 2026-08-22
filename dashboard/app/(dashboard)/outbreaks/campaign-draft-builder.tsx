"use client"

import * as React from "react"
import Link from "next/link"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { showToast } from "@/lib/toast"
import type { OutbreakCampaignInput } from "@/services/outbreaks.service"

export function CampaignDraftBuilder({ contentKey, kinds, create }: { contentKey: string; kinds: Array<{ value: "alert" | "update" | "status_change" | "closure" | "publication"; label: string }>; create: (input: OutbreakCampaignInput) => Promise<{ id?: string }> }) {
  const [kind, setKind] = React.useState(kinds[0]?.value || "alert")
  const [priority, setPriority] = React.useState<"low" | "normal" | "high" | "urgent">("high")
  const [scheduledAt, setScheduledAt] = React.useState("")
  const [audienceMode, setAudienceMode] = React.useState<"all" | "regions" | "districts" | "users">("all")
  const [audienceIDs, setAudienceIDs] = React.useState("")
  const [preference, setPreference] = React.useState<"outbreak_alerts" | "emergency_alerts">("outbreak_alerts")
  const [channels, setChannels] = React.useState(["push", "in-app"])
  const [urgentConfirmation, setUrgentConfirmation] = React.useState("")
  const [creating, setCreating] = React.useState(false)
  const [campaignID, setCampaignID] = React.useState("")

  function toggleChannel(channel: string) { setChannels(current => current.includes(channel) ? current.filter(value => value !== channel) : [...current, channel]) }
  async function submit() {
    if (!channels.length) { showToast.error("Channel required", "Choose at least one delivery channel."); return }
    if (audienceMode !== "all" && !audienceIDs.split(",").some(value => value.trim())) { showToast.error("Audience required", "Enter at least one typed audience identifier."); return }
    if (priority === "urgent" && urgentConfirmation !== "URGENT") { showToast.error("Confirmation required", "Type URGENT to create this high-risk draft."); return }
    const ids = audienceIDs.split(",").map(value => value.trim()).filter(Boolean)
    const audience: NonNullable<OutbreakCampaignInput["audience"]> = { all_eligible: audienceMode === "all", preference_categories: [preference] }
    if (audienceMode === "regions") audience.region_ids = ids
    if (audienceMode === "districts") audience.district_ids = ids
    if (audienceMode === "users") audience.user_ids = ids
    setCreating(true)
    try {
      const result = await create({ kind, audience, scheduled_at: scheduledAt ? new Date(scheduledAt).toISOString() : undefined, timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", priority, requested_channels: channels, idempotency_key: `${contentKey}:${kind}:${scheduledAt || "unscheduled"}:${priority}`, confirmed_urgent: priority === "urgent" })
      setCampaignID(result.id || "")
      showToast.success("Campaign draft created", "It still requires normal review, approval, and scheduling.")
    } catch (value) { showToast.error("Campaign not created", value instanceof Error ? value.message : "Campaign creation failed") }
    finally { setCreating(false) }
  }

  return <Card><CardHeader><CardTitle className="flex items-center gap-2"><Bell className="h-5 w-5" />Notification campaign draft</CardTitle></CardHeader><CardContent className="space-y-4"><p className="text-sm text-muted-foreground">This creates a draft only. It never sends directly.</p><div className="grid gap-4 md:grid-cols-2"><Select label="Template purpose" value={kind} onChange={value => setKind(value as typeof kind)} options={kinds} /><Select label="Priority" value={priority} onChange={value => setPriority(value as typeof priority)} options={["low","normal","high","urgent"].map(value => ({ value, label: value }))} /><Select label="Audience" value={audienceMode} onChange={value => setAudienceMode(value as typeof audienceMode)} options={[{value:"all",label:"All eligible users"},{value:"regions",label:"Region IDs"},{value:"districts",label:"District IDs"},{value:"users",label:"Specific user IDs"}]} /><Select label="Preference category" value={preference} onChange={value => setPreference(value as typeof preference)} options={[{value:"outbreak_alerts",label:"Outbreak alerts"},{value:"emergency_alerts",label:"Emergency alerts"}]} />{audienceMode !== "all" ? <div className="md:col-span-2"><Label>Audience UUIDs (comma separated)</Label><Input className="mt-2" value={audienceIDs} onChange={event => setAudienceIDs(event.target.value)} /></div> : null}<div><Label>Schedule (optional)</Label><Input className="mt-2" type="datetime-local" value={scheduledAt} onChange={event => setScheduledAt(event.target.value)} /></div><div><Label>Channels</Label><div className="mt-3 flex gap-4">{["push","in-app"].map(channel => <label key={channel} className="flex items-center gap-2 text-sm"><input type="checkbox" checked={channels.includes(channel)} onChange={() => toggleChannel(channel)} />{channel}</label>)}</div></div>{priority === "urgent" ? <div className="md:col-span-2"><Label>Type URGENT to confirm the stronger permission-controlled path</Label><Input className="mt-2" value={urgentConfirmation} onChange={event => setUrgentConfirmation(event.target.value)} /></div> : null}</div><div className="flex items-center gap-3"><Button disabled={creating} onClick={() => void submit()}>Create campaign draft</Button>{campaignID ? <Button variant="outline" asChild><Link href={`/settings/notifications?campaign=${campaignID}`}>Open campaign {campaignID.slice(0, 8)}</Link></Button> : null}</div></CardContent></Card>
}

function Select({ label, value, onChange, options }: { label: string; value: string; onChange: (value: string) => void; options: Array<{ value: string; label: string }> }) { return <div><Label>{label}</Label><select className="mt-2 h-10 w-full rounded-md border bg-background px-3 capitalize" value={value} onChange={event => onChange(event.target.value)}>{options.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select></div> }
