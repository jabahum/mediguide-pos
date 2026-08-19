"use client"

import * as React from "react"
import Link from "next/link"
import { AlertTriangle, Bell, CheckCircle, CloudCog, FileText, Loader2, LockKeyhole, Plus, RefreshCw, Send, Settings, type LucideIcon } from "lucide-react"

import { Alert, AlertDescription } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { PageHeader } from "@/components/ui/page-header"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"
import { emptyNotificationAction, NotificationActionFields } from "@/components/notifications/notification-action-fields"
import { hasBackendPermission } from "@/lib/backend-client"
import { usePermissionContext } from "@/lib/permission-context"
import { showToast } from "@/lib/toast"
import { firebaseService } from "@/services/firebase.service"
import { notificationsService, type NotificationAction, type NotificationPriority, type NotificationType } from "@/services/notifications.service"
import type { NotificationCampaignsResponse, NotificationTemplatesResponse } from "@/types/backend-types"

type FirebaseState = "configured" | "disabled" | "unavailable"

export default function NotificationAdministrationPage() {
  const { loading: permissionsLoading } = usePermissionContext()
  const canPublish = hasBackendPermission("notification.publish")
  const canReadTemplates = hasBackendPermission("notification.template.read")
  const canManageTemplates = hasBackendPermission("notification.template.manage")
  const canReadCampaigns = hasBackendPermission("notification.campaign.read")
  const canReadFirebase = hasBackendPermission("firebase.status.read")
  const canAdminister = [
    canPublish,
    canReadTemplates,
    canReadCampaigns,
    canReadFirebase,
  ].some(Boolean)
  const [templates, setTemplates] = React.useState<NotificationTemplatesResponse[]>([])
  const [campaigns, setCampaigns] = React.useState<NotificationCampaignsResponse[]>([])
  const [templateTotal, setTemplateTotal] = React.useState(0)
  const [campaignTotal, setCampaignTotal] = React.useState(0)
  const [firebaseState, setFirebaseState] = React.useState<FirebaseState>("unavailable")
  const [loading, setLoading] = React.useState(true)
  const [loadError, setLoadError] = React.useState("")
  const [updatingId, setUpdatingId] = React.useState<string | null>(null)
  const [composerOpen, setComposerOpen] = React.useState(false)
  const [savingNotice, setSavingNotice] = React.useState(false)
  const [notice, setNotice] = React.useState({ title: "", message: "", type: "info" as NotificationType, priority: "normal" as NotificationPriority })
  const [noticeAction, setNoticeAction] = React.useState<NotificationAction>(emptyNotificationAction)

  const load = React.useCallback(async () => {
    if (!canAdminister) { setLoading(false); return }
    setLoading(true)
    setLoadError("")
    const [notificationResult, firebaseResult] = await Promise.allSettled([
      Promise.all([
        canReadTemplates ? notificationsService.listTemplates({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
        canReadCampaigns ? notificationsService.listCampaigns({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
      ]),
      canReadFirebase ? firebaseService.status() : Promise.resolve({ enabled: false }),
    ])

    if (notificationResult.status === "fulfilled") {
      const [templatePage, campaignPage] = notificationResult.value
      setTemplates(templatePage.items)
      setCampaigns(campaignPage.items)
      setTemplateTotal(templatePage.total_items)
      setCampaignTotal(campaignPage.total_items)
    } else {
      setLoadError(notificationResult.reason instanceof Error ? notificationResult.reason.message : "Unable to load notification administration")
    }
    setFirebaseState(firebaseResult.status === "fulfilled" ? (firebaseResult.value.enabled ? "configured" : "disabled") : "unavailable")
    setLoading(false)
  }, [canAdminister, canReadCampaigns, canReadFirebase, canReadTemplates])

  React.useEffect(() => {
    if (!permissionsLoading) void load()
  }, [load, permissionsLoading])

  async function saveInAppNotice(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const title = notice.title.trim()
    const message = notice.message.trim()
    if (!title || !message) { showToast.warning("Missing details", "Enter a title and message"); return }
    if (!window.confirm("Save this in-app notice for all users? This does not send a device push.")) return
    setSavingNotice(true)
    try {
      await notificationsService.create({
        ...notice,
        title,
        message,
        action: noticeAction,
      })
      setNotice({ title: "", message: "", type: "info", priority: "normal" })
      setNoticeAction(emptyNotificationAction())
      setComposerOpen(false)
      showToast.success("In-app notice saved", "The notice will appear when mobile clients synchronize. No device push was sent.")
    } catch (error) {
      showToast.error("In-app notice", error instanceof Error ? error.message : "Unable to save the notice")
    } finally { setSavingNotice(false) }
  }

  async function toggleTemplate(template: NotificationTemplatesResponse) {
    const nextStatus = template.status === "active" ? "inactive" : "active"
    if (!window.confirm(`${nextStatus === "active" ? "Activate" : "Deactivate"} ${template.name}? This changes template availability but does not send a notification.`)) return
    setUpdatingId(template.id)
    try {
      await notificationsService.updateTemplateStatus(template.id, nextStatus)
      showToast.success("Template updated", `Template is now ${nextStatus}. No notification was sent.`)
      await load()
    } catch (error) {
      showToast.error("Template", error instanceof Error ? error.message : "Unable to update template")
    } finally { setUpdatingId(null) }
  }

  if (permissionsLoading || loading) {
    return <div className="space-y-6"><PageHeader title="Notification Administration" description="Loading notification configuration…" /><div className="flex h-64 items-center justify-center text-muted-foreground"><Loader2 className="mr-2 h-6 w-6 animate-spin" />Loading…</div></div>
  }
  if (!canAdminister) {
    return (
      <div className="space-y-6">
        <PageHeader title="Notification Administration" description="Manage notification operations" />
        <Alert variant="destructive">
          <LockKeyhole className="h-4 w-4" />
          <AlertDescription>You do not have permission to administer notifications.</AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader title="Notification Administration" description="Manage in-app notices and notification metadata. Campaign push delivery is not enabled yet." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => void load()}><RefreshCw className="mr-2 h-4 w-4" />Refresh</Button>
          {canReadFirebase ? <Button variant="outline" asChild><Link href="/settings/firebase"><Settings className="mr-2 h-4 w-4" />Firebase settings</Link></Button> : null}
          {canPublish ? <Dialog open={composerOpen} onOpenChange={setComposerOpen}>
            <DialogTrigger asChild><Button><Plus className="mr-2 h-4 w-4" />New in-app notice</Button></DialogTrigger>
            <DialogContent className="sm:max-w-[560px]">
              <DialogHeader><DialogTitle>Create an in-app notice</DialogTitle><DialogDescription>This saves a global notice in MediGuide. It does not send an FCM push notification.</DialogDescription></DialogHeader>
              <form className="space-y-4" onSubmit={saveInAppNotice}>
                <Alert><Bell className="h-4 w-4" /><AlertDescription>Audience: all authenticated app users. Delivery occurs when the app synchronizes.</AlertDescription></Alert>
                <div className="space-y-2"><Label htmlFor="notice-title">Title</Label><Input id="notice-title" required maxLength={200} value={notice.title} onChange={(event) => setNotice((value) => ({ ...value, title: event.target.value }))} /></div>
                <div className="space-y-2"><Label htmlFor="notice-message">Message</Label><Textarea id="notice-message" required rows={5} value={notice.message} onChange={(event) => setNotice((value) => ({ ...value, message: event.target.value }))} /></div>
                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2"><Label htmlFor="notice-type">Type</Label><Select value={notice.type} onValueChange={(type: NotificationType) => setNotice((value) => ({ ...value, type }))}><SelectTrigger id="notice-type"><SelectValue /></SelectTrigger><SelectContent><SelectItem value="info">Info</SelectItem><SelectItem value="success">Success</SelectItem><SelectItem value="warning">Warning</SelectItem><SelectItem value="error">Error</SelectItem></SelectContent></Select></div>
                  <div className="space-y-2"><Label htmlFor="notice-priority">Priority</Label><Select value={notice.priority} onValueChange={(priority: NotificationPriority) => setNotice((value) => ({ ...value, priority }))}><SelectTrigger id="notice-priority"><SelectValue /></SelectTrigger><SelectContent><SelectItem value="low">Low</SelectItem><SelectItem value="normal">Normal</SelectItem><SelectItem value="high">High</SelectItem><SelectItem value="urgent">Urgent</SelectItem></SelectContent></Select></div>
                </div>
                <NotificationActionFields value={noticeAction} onChange={setNoticeAction} allowSupportTicket={false} />
                <DialogFooter><Button type="button" variant="outline" disabled={savingNotice} onClick={() => setComposerOpen(false)}>Cancel</Button><Button type="submit" disabled={savingNotice}>{savingNotice ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <FileText className="mr-2 h-4 w-4" />}Save in-app notice</Button></DialogFooter>
              </form>
            </DialogContent>
          </Dialog> : null}
        </div>
      </div>

      <Alert><AlertTriangle className="h-4 w-4" /><AlertDescription>Templates and campaigns are currently metadata only. Scheduling, audience resolution and push dispatch will remain unavailable until the durable delivery worker is implemented.</AlertDescription></Alert>
      {loadError ? <Alert variant="destructive"><AlertTriangle className="h-4 w-4" /><AlertDescription className="flex flex-wrap items-center justify-between gap-3"><span>{loadError}</span><Button variant="outline" size="sm" onClick={() => void load()}>Try again</Button></AlertDescription></Alert> : null}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Summary title="Templates" value={templateTotal} detail="Stored template records" />
        <Summary title="Active templates" value={templates.filter((item) => item.status === "active").length} detail="Available metadata; not delivery" />
        <Summary title="Campaigns" value={campaignTotal} detail="Stored campaign records" />
        <Summary title="Firebase" value={firebaseState === "configured" ? "Configured" : firebaseState === "disabled" ? "Disabled" : "Unavailable"} detail="Live backend status" />
      </div>

      <Tabs defaultValue="templates" className="space-y-4">
        <TabsList><TabsTrigger value="templates">Templates</TabsTrigger><TabsTrigger value="campaigns">Campaigns</TabsTrigger><TabsTrigger value="channels">Channels</TabsTrigger></TabsList>
        <TabsContent value="templates">
          <Card>
            <CardHeader className="flex-row items-start justify-between gap-4"><div><CardTitle>Templates</CardTitle><CardDescription>Reusable metadata records. Rendering and campaign test delivery are not connected yet.</CardDescription></div><Button disabled title="Template authoring will be enabled with versioned template APIs"><Plus className="mr-2 h-4 w-4" />New template</Button></CardHeader>
            <CardContent className="space-y-3">
              {templates.length === 0 ? <Empty message="No templates found" /> : templates.map((template) => (
                <div key={template.id} className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between">
                  <div className="space-y-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium">{template.name}</span><Badge variant="outline">{template.type}</Badge><Badge variant={template.status === "active" ? "default" : "secondary"}>{template.status}</Badge></div><p className="text-sm text-muted-foreground">{template.subject || template.category}</p></div>
                  <div className="flex flex-wrap gap-2"><Button variant="outline" size="sm" disabled title="Template test rendering is not implemented">Test unavailable</Button><Button variant="outline" size="sm" disabled={!canManageTemplates || updatingId !== null} onClick={() => void toggleTemplate(template)}>{updatingId === template.id ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}{template.status === "active" ? "Deactivate" : "Activate"}</Button></div>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="campaigns">
          <Card>
            <CardHeader className="flex-row items-start justify-between gap-4"><div><CardTitle>Campaign records</CardTitle><CardDescription>These records do not currently schedule or send notifications.</CardDescription></div><Button disabled title="Campaign delivery requires the notification outbox worker"><Plus className="mr-2 h-4 w-4" />New campaign</Button></CardHeader>
            <CardContent className="space-y-3">
              {campaigns.length === 0 ? <Empty message="No campaigns found" /> : campaigns.map((campaign) => (
                <div key={campaign.id} className="flex flex-col gap-2 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between"><div><p className="font-medium">{campaign.name}</p><p className="text-sm text-muted-foreground">{campaign.type} · {(campaign.channels as string[])?.join(", ") || "No channels"}</p></div><div className="flex items-center gap-2"><Badge variant="outline">{campaign.status}</Badge><Button size="sm" variant="outline" disabled>Delivery unavailable</Button></div></div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="channels">
          <Card><CardHeader><CardTitle>Delivery channels</CardTitle><CardDescription>Status reflects implemented backend capabilities.</CardDescription></CardHeader><CardContent className="space-y-3">
            <Channel icon={Bell} title="Firebase push" description="Targeted test delivery only" state={firebaseState === "configured" ? "Configured" : firebaseState === "disabled" ? "Not configured" : "Status unavailable"} configured={firebaseState === "configured"} href="/settings/firebase" />
            <Channel icon={FileText} title="In-app" description="Database-backed notices and mobile synchronization" state="Available" configured />
            <Channel icon={Send} title="Email" description="No production delivery provider is connected" state="Unsupported" />
            <Channel icon={Send} title="SMS" description="No production delivery provider is connected" state="Unsupported" />
          </CardContent></Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

function Summary({ title, value, detail }: { title: string; value: string | number; detail: string }) {
  return <Card><CardHeader className="pb-2"><CardTitle className="text-sm">{title}</CardTitle></CardHeader><CardContent><p className="text-2xl font-bold">{value}</p><p className="text-xs text-muted-foreground">{detail}</p></CardContent></Card>
}

function Empty({ message }: { message: string }) { return <div className="py-10 text-center text-sm text-muted-foreground">{message}</div> }

function Channel({ icon: Icon, title, description, state, configured = false, href }: { icon: LucideIcon; title: string; description: string; state: string; configured?: boolean; href?: string }) {
  return <div className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-3"><Icon className="h-6 w-6 text-muted-foreground" /><div><p className="font-medium">{title}</p><p className="text-sm text-muted-foreground">{description}</p></div></div><div className="flex items-center gap-2"><Badge variant={configured ? "default" : "secondary"}>{configured ? <CheckCircle className="mr-1 h-3 w-3" /> : <CloudCog className="mr-1 h-3 w-3" />}{state}</Badge>{href ? <Button asChild size="sm" variant="outline"><Link href={href}>Configure</Link></Button> : null}</div></div>
}
