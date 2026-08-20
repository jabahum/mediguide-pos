"use client"

import * as React from "react"
import Link from "next/link"

import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { showToast } from "@/lib/toast"
import { GuidelineDocumentRecord, GuidelineDocumentsService } from "@/services/guideline-documents.service"

function csv(value: string) {
  return value.split(",").map((item) => item.trim()).filter(Boolean)
}

export function GuidelineNotificationDialog({ document, open, onOpenChange }: {
  document: GuidelineDocumentRecord | null
  open: boolean
  onOpenChange: (open: boolean) => void
}) {
  const [allEligible, setAllEligible] = React.useState(true)
  const [userIds, setUserIds] = React.useState("")
  const [roleIds, setRoleIds] = React.useState("")
  const [scheduledAt, setScheduledAt] = React.useState("")
  const [priority, setPriority] = React.useState<"low" | "normal" | "high" | "urgent">("normal")
  const [push, setPush] = React.useState(true)
  const [inApp, setInApp] = React.useState(true)
  const [submitting, setSubmitting] = React.useState(false)
  const [campaignId, setCampaignId] = React.useState<string | null>(null)

  React.useEffect(() => {
    if (!open) setCampaignId(null)
  }, [open])

  async function submit() {
    if (!document || (!push && !inApp)) return
    setSubmitting(true)
    try {
      const campaign = await GuidelineDocumentsService.createNotificationCampaign(document.id, {
        audience: {
          all_eligible: allEligible,
          user_ids: allEligible ? undefined : csv(userIds),
          role_ids: allEligible ? undefined : csv(roleIds),
          preference_categories: ["clinical_content_updates"],
        },
        scheduled_at: scheduledAt ? new Date(scheduledAt).toISOString() : undefined,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
        priority,
        requested_channels: [push ? "push" : null, inApp ? "in-app" : null].filter(Boolean) as Array<"push" | "in-app">,
        idempotency_key: `guideline-${document.id}-${Date.now()}`,
      })
      setCampaignId(campaign.id)
      showToast.success("Draft campaign created", "Review and approve it in Notification Operations before dispatch.")
    } catch (error) {
      showToast.error("Campaign creation failed", error instanceof Error ? error.message : "Unknown error")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Notify users about this guideline</DialogTitle>
          <DialogDescription>
            This creates a draft for review. It does not send a notification directly.
          </DialogDescription>
        </DialogHeader>
        {campaignId ? (
          <div className="space-y-4 rounded-md border p-4 text-sm">
            <p>The draft campaign is ready for the normal review and approval workflow.</p>
            <Button asChild><Link href={`/settings/notifications?campaign=${campaignId}`}>Open campaign</Link></Button>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="flex items-center gap-2"><Checkbox id="all-eligible" checked={allEligible} onCheckedChange={(value) => setAllEligible(value === true)} /><Label htmlFor="all-eligible">All eligible users</Label></div>
            {!allEligible && <><div className="space-y-2"><Label htmlFor="guideline-user-ids">User UUIDs</Label><Input id="guideline-user-ids" value={userIds} onChange={(event) => setUserIds(event.target.value)} placeholder="Comma-separated UUIDs" /></div><div className="space-y-2"><Label htmlFor="guideline-role-ids">Role UUIDs</Label><Input id="guideline-role-ids" value={roleIds} onChange={(event) => setRoleIds(event.target.value)} placeholder="Comma-separated UUIDs" /></div></>}
            <div className="space-y-2"><Label>Priority</Label><Select value={priority} onValueChange={(value) => setPriority(value as typeof priority)}><SelectTrigger className="w-full"><SelectValue /></SelectTrigger><SelectContent><SelectItem value="low">Low</SelectItem><SelectItem value="normal">Normal</SelectItem><SelectItem value="high">High</SelectItem><SelectItem value="urgent">Urgent</SelectItem></SelectContent></Select></div>
            <div className="space-y-2"><Label htmlFor="guideline-schedule">Schedule (optional)</Label><Input id="guideline-schedule" type="datetime-local" value={scheduledAt} onChange={(event) => setScheduledAt(event.target.value)} /></div>
            <div className="flex gap-5"><label className="flex items-center gap-2 text-sm"><Checkbox checked={push} onCheckedChange={(value) => setPush(value === true)} />Push</label><label className="flex items-center gap-2 text-sm"><Checkbox checked={inApp} onCheckedChange={(value) => setInApp(value === true)} />In-app</label></div>
          </div>
        )}
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Close</Button>
          {!campaignId && <Button onClick={submit} disabled={submitting || (!push && !inApp)}>{submitting ? "Creating..." : "Create draft campaign"}</Button>}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
