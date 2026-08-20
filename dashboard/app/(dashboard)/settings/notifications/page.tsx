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
import { notificationsService, type NotificationAction, type NotificationAudienceDefinition, type NotificationAudienceEstimate, type NotificationCampaignDto, type NotificationCampaignInput, type NotificationPriority, type NotificationTemplateDto, type NotificationTemplateInput, type NotificationType } from "@/services/notifications.service"

type FirebaseState = "configured" | "disabled" | "unavailable"
type CampaignAudienceForm = {
  allEligible: boolean; userIds: string; roleIds: string; countries: string; regionIds: string; districtIds: string
  facilityIds: string; facilityLevelIds: string; professionalCategories: string; languages: string; platforms: string
  applicationVersions: string; preferenceCategories: string
}

export default function NotificationAdministrationPage() {
  const { loading: permissionsLoading } = usePermissionContext()
  const canPublish = hasBackendPermission("notification.publish")
  const canReadTemplates = hasBackendPermission("notification.template.read")
  const canManageTemplates = hasBackendPermission("notification.template.manage")
  const canReadCampaigns = hasBackendPermission("notification.campaign.read")
  const canManageCampaigns = hasBackendPermission("notification.campaign.manage")
  const canApproveCampaigns = hasBackendPermission("notification.campaign.approve")
  const canReadFirebase = hasBackendPermission("firebase.status.read")
  const canAdminister = [
    canPublish,
    canReadTemplates,
    canReadCampaigns,
    canReadFirebase,
  ].some(Boolean)
  const [templates, setTemplates] = React.useState<NotificationTemplateDto[]>([])
  const [campaigns, setCampaigns] = React.useState<NotificationCampaignDto[]>([])
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
  const [templateOpen, setTemplateOpen] = React.useState(false)
  const [campaignOpen, setCampaignOpen] = React.useState(false)
  const [templateForm, setTemplateForm] = React.useState({ name: "", templateKey: "", channel: "in-app" as NotificationTemplateInput["channel"], title: "", body: "", category: "Content Updates", locale: "en", schema: "{}" })
  const [templateAction, setTemplateAction] = React.useState<NotificationAction>(emptyNotificationAction)
  const [campaignForm, setCampaignForm] = React.useState({ name: "", type: "announcement" as NotificationCampaignInput["type"], templateVersionId: "", variables: "{}", priority: "normal" as NotificationPriority, channels: ["in-app"] as NotificationCampaignInput["requested_channels"], timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", scheduledAt: "", expiresAt: "", allEligible: true, userIds: "", roleIds: "", countries: "", regionIds: "", districtIds: "", facilityIds: "", facilityLevelIds: "", professionalCategories: "", languages: "", platforms: "", applicationVersions: "", preferenceCategories: "" })
  const [audienceEstimate, setAudienceEstimate] = React.useState<NotificationAudienceEstimate | null>(null)

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

  async function toggleTemplate(template: NotificationTemplateDto) {
    const nextStatus = template.status === "published" ? "archived" : "published"
    if (!window.confirm(`${nextStatus === "published" ? "Publish" : "Archive"} ${template.name}? Published versions cannot be edited.`)) return
    setUpdatingId(template.id)
    try {
      await notificationsService.updateTemplateStatus(template.id, nextStatus)
      showToast.success("Template updated", `Template is now ${nextStatus}. No notification was sent.`)
      await load()
    } catch (error) {
      showToast.error("Template", error instanceof Error ? error.message : "Unable to update template")
    } finally { setUpdatingId(null) }
  }

  async function saveTemplate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    try {
      const variable_schema = JSON.parse(templateForm.schema) as NotificationTemplateInput["variable_schema"]
      setUpdatingId("template-create")
      await notificationsService.createTemplate({ name: templateForm.name.trim(), template_key: templateForm.templateKey.trim(), channel: templateForm.channel, title_template: templateForm.title.trim() || undefined, body_template: templateForm.body, action_template: templateAction, variable_schema, category: templateForm.category, locale: templateForm.locale })
      setTemplateOpen(false); showToast.success("Draft template created", "Review its rendered preview before publishing."); await load()
    } catch (error) { showToast.error("Template", error instanceof Error ? error.message : "Unable to create template") } finally { setUpdatingId(null) }
  }

  async function previewTemplate(template: NotificationTemplateDto) {
    const variables = Object.fromEntries(Object.entries(template.version.variable_schema).map(([key, rule]) => [key, rule.sample_value ?? (rule.type === "number" ? 1 : rule.type === "boolean" ? true : key)]))
    try { const preview = await notificationsService.previewTemplateVersion(template.version.id, variables); window.alert(`${preview.title}\n\n${preview.body}\n\nAction: ${preview.action.type}`) }
    catch (error) { showToast.error("Template preview", error instanceof Error ? error.message : "Unable to render preview") }
  }

  async function saveCampaign(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    try {
      setUpdatingId("campaign-create")
      const audience = campaignAudience(campaignForm)
      await notificationsService.createCampaign({ name: campaignForm.name.trim(), type: campaignForm.type, template_version_id: campaignForm.templateVersionId, variables: JSON.parse(campaignForm.variables) as Record<string, unknown>, audience, timezone: campaignForm.timezone, scheduled_at: campaignForm.scheduledAt ? new Date(campaignForm.scheduledAt).toISOString() : undefined, expires_at: campaignForm.expiresAt ? new Date(campaignForm.expiresAt).toISOString() : undefined, priority: campaignForm.priority, requested_channels: campaignForm.channels, idempotency_key: crypto.randomUUID() })
      setCampaignOpen(false); showToast.success("Campaign draft created", "Submit it for independent review when ready."); await load()
    } catch (error) { showToast.error("Campaign", error instanceof Error ? error.message : "Unable to create campaign") } finally { setUpdatingId(null) }
  }

  async function estimateCampaignAudience() {
    setUpdatingId("audience-estimate")
    try {
      const estimate = await notificationsService.estimateAudience(campaignAudience(campaignForm))
      setAudienceEstimate(estimate)
      showToast.success("Audience estimated", `${estimate.eligible_users} eligible users and ${estimate.active_devices} active devices.`)
    } catch (error) {
      setAudienceEstimate(null)
      showToast.error("Audience estimate", error instanceof Error ? error.message : "Unable to estimate the audience")
    } finally { setUpdatingId(null) }
  }

  async function transitionCampaign(campaign: NotificationCampaignDto, action: "submit" | "approve" | "reject" | "schedule" | "cancel") {
    const reason = action === "reject" || action === "cancel" ? window.prompt(`Reason to ${action} this campaign`) ?? "" : undefined
    if ((action === "reject" || action === "cancel") && !reason?.trim()) return
    if (!window.confirm(`${action[0].toUpperCase()}${action.slice(1)} ${campaign.name}?`)) return
    setUpdatingId(campaign.id)
    try { await notificationsService.transitionCampaign(campaign.id, action, { lock_version: campaign.lock_version, scheduled_at: action === "schedule" ? campaign.scheduled_at : undefined, timezone: action === "schedule" ? campaign.timezone : undefined, reason }); showToast.success("Campaign updated", `Campaign ${action} completed.`); await load() }
    catch (error) { showToast.error("Campaign workflow", error instanceof Error ? error.message : "Unable to update campaign") } finally { setUpdatingId(null) }
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
        <PageHeader title="Notification Administration" description="Build, approve, schedule, and monitor typed in-app and Firebase campaigns." />
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

      <Alert><AlertTriangle className="h-4 w-4" /><AlertDescription>Approval resolves and freezes the audience in one transaction. Scheduling releases deterministic outbox jobs; provider acceptance is reported separately from delivery.</AlertDescription></Alert>
      {loadError ? <Alert variant="destructive"><AlertTriangle className="h-4 w-4" /><AlertDescription className="flex flex-wrap items-center justify-between gap-3"><span>{loadError}</span><Button variant="outline" size="sm" onClick={() => void load()}>Try again</Button></AlertDescription></Alert> : null}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Summary title="Templates" value={templateTotal} detail="Stored template records" />
        <Summary title="Published templates" value={templates.filter((item) => item.status === "published").length} detail="Immutable approved versions" />
        <Summary title="Campaigns" value={campaignTotal} detail="Stored campaign records" />
        <Summary title="Firebase" value={firebaseState === "configured" ? "Configured" : firebaseState === "disabled" ? "Disabled" : "Unavailable"} detail="Live backend status" />
      </div>

      <Tabs defaultValue="templates" className="space-y-4">
        <TabsList><TabsTrigger value="templates">Templates</TabsTrigger><TabsTrigger value="campaigns">Campaigns</TabsTrigger><TabsTrigger value="channels">Channels</TabsTrigger></TabsList>
        <TabsContent value="templates">
          <Card>
            <CardHeader className="flex-row items-start justify-between gap-4"><div><CardTitle>Templates</CardTitle><CardDescription>Versioned, validated content. Publishing makes the current version immutable.</CardDescription></div>{canManageTemplates ? <Dialog open={templateOpen} onOpenChange={setTemplateOpen}><DialogTrigger asChild><Button><Plus className="mr-2 h-4 w-4" />New template</Button></DialogTrigger><DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-[680px]"><DialogHeader><DialogTitle>New notification template</DialogTitle><DialogDescription>Only declared variables using double-brace placeholders are accepted.</DialogDescription></DialogHeader><form className="space-y-4" onSubmit={saveTemplate}><div className="grid gap-4 sm:grid-cols-2"><Field label="Name"><Input required value={templateForm.name} onChange={(e) => setTemplateForm((v) => ({ ...v, name: e.target.value }))} /></Field><Field label="Stable key"><Input required pattern="[A-Za-z][A-Za-z0-9_.-]{0,63}" value={templateForm.templateKey} onChange={(e) => setTemplateForm((v) => ({ ...v, templateKey: e.target.value }))} /></Field><Field label="Channel"><Select value={templateForm.channel} onValueChange={(channel: NotificationTemplateInput["channel"]) => setTemplateForm((v) => ({ ...v, channel }))}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{["in-app", "push", "email", "sms"].map((value) => <SelectItem key={value} value={value}>{value}</SelectItem>)}</SelectContent></Select></Field><Field label="Category"><Select value={templateForm.category} onValueChange={(category) => setTemplateForm((v) => ({ ...v, category }))}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{["Content Updates", "Emergency", "Training", "System", "Marketing", "Reminder"].map((value) => <SelectItem key={value} value={value}>{value}</SelectItem>)}</SelectContent></Select></Field></div><Field label="Title template"><Input value={templateForm.title} onChange={(e) => setTemplateForm((v) => ({ ...v, title: e.target.value }))} /></Field><Field label="Body template"><Textarea required rows={5} value={templateForm.body} onChange={(e) => setTemplateForm((v) => ({ ...v, body: e.target.value }))} /></Field><Field label="Variable schema (JSON)"><Textarea className="font-mono" rows={5} value={templateForm.schema} onChange={(e) => setTemplateForm((v) => ({ ...v, schema: e.target.value }))} /><p className="text-xs text-muted-foreground">Example: {`{"name":{"type":"string","required":true,"sample_value":"Malaria"}}`}</p></Field><NotificationActionFields value={templateAction} onChange={setTemplateAction} allowSupportTicket={false} /><DialogFooter><Button type="button" variant="outline" onClick={() => setTemplateOpen(false)}>Cancel</Button><Button type="submit" disabled={updatingId !== null}>{updatingId === "template-create" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Create draft</Button></DialogFooter></form></DialogContent></Dialog> : null}</CardHeader>
            <CardContent className="space-y-3">
              {templates.length === 0 ? <Empty message="No templates found" /> : templates.map((template) => (
                <div key={template.id} className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between">
                  <div className="space-y-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium">{template.name}</span><Badge variant="outline">{template.version.channel}</Badge><Badge variant={template.status === "published" ? "default" : "secondary"}>{template.status}</Badge><Badge variant="outline">v{template.current_version}</Badge></div><p className="text-sm text-muted-foreground">{template.version.title_template || template.version.category}</p></div>
                  <div className="flex flex-wrap gap-2"><Button variant="outline" size="sm" onClick={() => void previewTemplate(template)}>Preview sample</Button><Button variant="outline" size="sm" disabled={!canManageTemplates || updatingId !== null || template.status === "archived"} onClick={() => void toggleTemplate(template)}>{updatingId === template.id ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}{template.status === "published" ? "Archive" : "Publish"}</Button></div>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="campaigns">
          <Card>
            <CardHeader className="flex-row items-start justify-between gap-4"><div><CardTitle>Campaign workflow</CardTitle><CardDescription>Draft, review, approve and schedule against an immutable dispatch snapshot.</CardDescription></div>{canManageCampaigns ? <Dialog open={campaignOpen} onOpenChange={setCampaignOpen}><DialogTrigger asChild><Button disabled={templates.every((item) => item.status !== "published")}><Plus className="mr-2 h-4 w-4" />New campaign</Button></DialogTrigger><DialogContent className="sm:max-w-[620px]"><DialogHeader><DialogTitle>New campaign draft</DialogTitle><DialogDescription>Recipients are resolved in the delivery phase. This step freezes rendered content and audience intent.</DialogDescription></DialogHeader><form className="space-y-4" onSubmit={saveCampaign}><Field label="Name"><Input required value={campaignForm.name} onChange={(e) => setCampaignForm((v) => ({ ...v, name: e.target.value }))} /></Field><div className="grid gap-4 sm:grid-cols-2"><Field label="Published template"><Select required value={campaignForm.templateVersionId} onValueChange={(templateVersionId) => setCampaignForm((v) => ({ ...v, templateVersionId }))}><SelectTrigger><SelectValue placeholder="Choose template" /></SelectTrigger><SelectContent>{templates.filter((item) => item.status === "published").map((item) => <SelectItem key={item.version.id} value={item.version.id}>{item.name} · v{item.current_version}</SelectItem>)}</SelectContent></Select></Field><Field label="Priority"><Select value={campaignForm.priority} onValueChange={(priority: NotificationPriority) => setCampaignForm((v) => ({ ...v, priority }))}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{["low", "normal", "high", "urgent"].map((value) => <SelectItem key={value} value={value}>{value}</SelectItem>)}</SelectContent></Select></Field></div><Field label="Template variables (JSON)"><Textarea className="font-mono" rows={5} value={campaignForm.variables} onChange={(e) => setCampaignForm((v) => ({ ...v, variables: e.target.value }))} /></Field><Field label="Expiry (optional)"><Input type="datetime-local" value={campaignForm.expiresAt} onChange={(e) => setCampaignForm((v) => ({ ...v, expiresAt: e.target.value }))} /></Field><AudienceFields form={campaignForm} estimate={audienceEstimate} estimating={updatingId === "audience-estimate"} onEstimate={() => void estimateCampaignAudience()} onChange={(patch) => { setCampaignForm((value) => ({ ...value, ...patch })); setAudienceEstimate(null) }} /><Alert><AlertTriangle className="h-4 w-4" /><AlertDescription>Urgent, emergency, and broad campaigns require independent approval. Audience estimates return counts only; recipient identities are never exposed here.</AlertDescription></Alert><DialogFooter><Button type="button" variant="outline" onClick={() => setCampaignOpen(false)}>Cancel</Button><Button type="submit" disabled={updatingId !== null || !campaignForm.templateVersionId}>{updatingId === "campaign-create" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Create draft</Button></DialogFooter></form></DialogContent></Dialog> : null}</CardHeader>
            <CardContent className="space-y-3">
              {campaigns.length === 0 ? <Empty message="No campaigns found" /> : campaigns.map((campaign) => (
                <div key={campaign.id} className="flex flex-col gap-3 rounded-lg border p-4 lg:flex-row lg:items-center lg:justify-between"><div><p className="font-medium">{campaign.name}</p><p className="text-sm text-muted-foreground">{campaign.type} · {campaign.requested_channels.join(", ")} · {campaign.timezone} · lock {campaign.lock_version}</p><p className="mt-1 line-clamp-1 text-sm">{campaign.rendered_title}</p></div><div className="flex flex-wrap items-center gap-2"><Badge variant="outline">{campaign.status}</Badge>{campaign.status === "draft" && canManageCampaigns ? <Button size="sm" variant="outline" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "submit")}>Submit</Button> : null}{campaign.status === "pending_review" && canApproveCampaigns ? <><Button size="sm" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "approve")}>Approve</Button><Button size="sm" variant="outline" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "reject")}>Reject</Button></> : null}{campaign.status === "approved" && canManageCampaigns ? <Button size="sm" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "schedule")}>Queue now</Button> : null}{["draft", "pending_review", "approved", "scheduled", "queued"].includes(campaign.status) && canManageCampaigns ? <Button size="sm" variant="destructive" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "cancel")}>Cancel</Button> : null}</div></div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="channels">
          <Card><CardHeader><CardTitle>Delivery channels</CardTitle><CardDescription>Status reflects implemented backend capabilities.</CardDescription></CardHeader><CardContent className="space-y-3">
            <Channel icon={Bell} title="Firebase push" description="Worker-backed targeted delivery with retries and invalid-token cleanup" state={firebaseState === "configured" ? "Configured" : firebaseState === "disabled" ? "Not configured" : "Status unavailable"} configured={firebaseState === "configured"} href="/settings/firebase" />
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

function Field({ label, children }: { label: string; children: React.ReactNode }) { return <div className="space-y-2"><Label>{label}</Label>{children}</div> }

function AudienceFields({ form, estimate, estimating, onChange, onEstimate }: {
  form: CampaignAudienceForm
  estimate: NotificationAudienceEstimate | null
  estimating: boolean
  onChange: (value: Partial<CampaignAudienceForm>) => void
  onEstimate: () => void
}) {
  const fields: Array<[keyof CampaignAudienceForm, string, string]> = [
    ["userIds", "User IDs", "UUIDs"], ["roleIds", "Role IDs", "UUIDs"], ["countries", "Countries", "Uganda"],
    ["regionIds", "Region IDs", "UUIDs"], ["districtIds", "District IDs", "UUIDs"], ["facilityIds", "Facility IDs", "UUIDs"],
    ["facilityLevelIds", "Facility level IDs", "UUIDs"], ["professionalCategories", "Professional categories", "Nurse, Doctor"],
    ["languages", "Languages", "en, sw"], ["platforms", "Platforms", "android, ios"],
    ["applicationVersions", "App versions", "2.0.24"], ["preferenceCategories", "Preference categories", "clinical_content_updates"],
  ]
  return <div className="space-y-3 rounded-lg border p-4">
    <div className="flex items-center justify-between gap-4">
      <div><p className="text-sm font-medium">Audience</p><p className="text-xs text-muted-foreground">Filters are combined with AND and resolved on the server.</p></div>
      <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.allEligible} onChange={(event) => onChange({ allEligible: event.target.checked })} />All eligible</label>
    </div>
    {!form.allEligible ? <div className="grid gap-3 sm:grid-cols-2">{fields.map(([key, label, placeholder]) => <Field key={key} label={label}><Input value={String(form[key])} placeholder={placeholder} onChange={(event) => onChange({ [key]: event.target.value })} /></Field>)}</div> : null}
    <div className="flex flex-wrap items-center gap-3"><Button type="button" variant="outline" disabled={estimating} onClick={onEstimate}>{estimating ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Estimate audience</Button>{estimate ? <p className="text-sm"><strong>{estimate.eligible_users}</strong> eligible users · <strong>{estimate.active_devices}</strong> active devices</p> : null}</div>
  </div>
}

function csvValues(value: string): string[] | undefined {
  const values = [...new Set(value.split(/[\n,]/).map((item) => item.trim()).filter(Boolean))]
  return values.length > 0 ? values : undefined
}

function campaignAudience(form: CampaignAudienceForm): NotificationAudienceDefinition {
  if (form.allEligible) return { all_eligible: true }
  return {
    all_eligible: false,
    user_ids: csvValues(form.userIds), role_ids: csvValues(form.roleIds), countries: csvValues(form.countries),
    region_ids: csvValues(form.regionIds), district_ids: csvValues(form.districtIds), facility_ids: csvValues(form.facilityIds),
    facility_level_ids: csvValues(form.facilityLevelIds), professional_categories: csvValues(form.professionalCategories),
    languages: csvValues(form.languages), platforms: csvValues(form.platforms) as NotificationAudienceDefinition["platforms"],
    application_versions: csvValues(form.applicationVersions), preference_categories: csvValues(form.preferenceCategories) as NotificationAudienceDefinition["preference_categories"],
  }
}

function Channel({ icon: Icon, title, description, state, configured = false, href }: { icon: LucideIcon; title: string; description: string; state: string; configured?: boolean; href?: string }) {
  return <div className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-3"><Icon className="h-6 w-6 text-muted-foreground" /><div><p className="font-medium">{title}</p><p className="text-sm text-muted-foreground">{description}</p></div></div><div className="flex items-center gap-2"><Badge variant={configured ? "default" : "secondary"}>{configured ? <CheckCircle className="mr-1 h-3 w-3" /> : <CloudCog className="mr-1 h-3 w-3" />}{state}</Badge>{href ? <Button asChild size="sm" variant="outline"><Link href={href}>Configure</Link></Button> : null}</div></div>
}
