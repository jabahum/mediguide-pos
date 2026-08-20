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
import { firebaseService, type FirebaseStatus } from "@/services/firebase.service"
import { notificationsService, type NotificationAction, type NotificationAudienceDefinition, type NotificationAudienceEstimate, type NotificationCampaignDto, type NotificationCampaignInput, type NotificationDeliveryAnalytics, type NotificationDeliveryDto, type NotificationOutboxJobDto, type NotificationPreferenceAggregates, type NotificationPriority, type NotificationTemplateDto, type NotificationTemplateInput, type NotificationTemplateVersionDto, type NotificationType } from "@/services/notifications.service"

type FirebaseState = "configured" | "disabled" | "unavailable"
type CampaignAudienceForm = {
  allEligible: boolean; userIds: string; roleIds: string; countries: string; regionIds: string; districtIds: string
  facilityIds: string; facilityLevelIds: string; professionalCategories: string; languages: string; platforms: string
  applicationVersions: string; preferenceCategories: string
  channels: NotificationCampaignInput["requested_channels"]
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
  const canReadAnalytics = hasBackendPermission("notification.analytics.read")
  const canAdminister = [
    canPublish,
    canReadTemplates,
    canReadCampaigns,
    canReadFirebase,
    canReadAnalytics,
  ].some(Boolean)
  const [templates, setTemplates] = React.useState<NotificationTemplateDto[]>([])
  const [campaigns, setCampaigns] = React.useState<NotificationCampaignDto[]>([])
  const [templateTotal, setTemplateTotal] = React.useState(0)
  const [campaignTotal, setCampaignTotal] = React.useState(0)
  const [firebaseState, setFirebaseState] = React.useState<FirebaseState>("unavailable")
  const [firebaseStatus, setFirebaseStatus] = React.useState<FirebaseStatus | null>(null)
  const [deliveries, setDeliveries] = React.useState<NotificationDeliveryDto[]>([])
  const [deliveryJobs, setDeliveryJobs] = React.useState<NotificationOutboxJobDto[]>([])
  const [analytics, setAnalytics] = React.useState<NotificationDeliveryAnalytics | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [loadError, setLoadError] = React.useState("")
  const [updatingId, setUpdatingId] = React.useState<string | null>(null)
  const [composerOpen, setComposerOpen] = React.useState(false)
  const [savingNotice, setSavingNotice] = React.useState(false)
  const [notice, setNotice] = React.useState({ title: "", message: "", type: "info" as NotificationType, priority: "normal" as NotificationPriority })
  const [noticeAction, setNoticeAction] = React.useState<NotificationAction>(emptyNotificationAction)
  const [templateOpen, setTemplateOpen] = React.useState(false)
  const [editingTemplateId, setEditingTemplateId] = React.useState<string | null>(null)
  const [templateHistory, setTemplateHistory] = React.useState<{ name: string; versions: NotificationTemplateVersionDto[] } | null>(null)
  const [templatePreview, setTemplatePreview] = React.useState<{ name: string; title: string; body: string; action: NotificationAction } | null>(null)
  const [campaignOpen, setCampaignOpen] = React.useState(false)
  const [editingCampaignId, setEditingCampaignId] = React.useState<string | null>(null)
  const [templateForm, setTemplateForm] = React.useState({ name: "", templateKey: "", channel: "in-app" as NotificationTemplateInput["channel"], title: "", body: "", category: "Content Updates", locale: "en", schema: "{}" })
  const [templateAction, setTemplateAction] = React.useState<NotificationAction>(emptyNotificationAction)
  const [campaignForm, setCampaignForm] = React.useState({ name: "", type: "announcement" as NotificationCampaignInput["type"], templateVersionId: "", variables: "{}", priority: "normal" as NotificationPriority, channels: ["in-app"] as NotificationCampaignInput["requested_channels"], timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", scheduledAt: "", expiresAt: "", allEligible: true, userIds: "", roleIds: "", countries: "", regionIds: "", districtIds: "", facilityIds: "", facilityLevelIds: "", professionalCategories: "", languages: "", platforms: "", applicationVersions: "", preferenceCategories: "" })
  const [audienceEstimate, setAudienceEstimate] = React.useState<NotificationAudienceEstimate | null>(null)
  const [preferenceAggregates, setPreferenceAggregates] = React.useState<NotificationPreferenceAggregates | null>(null)

  const load = React.useCallback(async () => {
    if (!canAdminister) { setLoading(false); return }
    setLoading(true)
    setLoadError("")
    const [notificationResult, firebaseResult] = await Promise.allSettled([
      Promise.all([
        canReadTemplates ? notificationsService.listTemplates({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
        canReadCampaigns ? notificationsService.listCampaigns({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
        canReadAnalytics ? notificationsService.preferenceAggregates() : Promise.resolve(null),
        canReadAnalytics ? notificationsService.listDeliveries({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
        canReadAnalytics ? notificationsService.deliveryAnalytics() : Promise.resolve(null),
        canReadAnalytics ? notificationsService.listDeliveryJobs({ page: 1, per_page: 50 }) : Promise.resolve({ items: [], page: 1, per_page: 50, total_items: 0, total_pages: 0 }),
      ]),
      canReadFirebase ? firebaseService.status() : Promise.resolve({ enabled: false }),
    ])

    if (notificationResult.status === "fulfilled") {
      const [templatePage, campaignPage, aggregates, deliveryPage, deliveryAnalytics, jobPage] = notificationResult.value
      setTemplates(templatePage.items)
      setCampaigns(campaignPage.items)
      setTemplateTotal(templatePage.total_items)
      setCampaignTotal(campaignPage.total_items)
      setPreferenceAggregates(aggregates)
      setDeliveries(deliveryPage.items)
      setAnalytics(deliveryAnalytics)
      setDeliveryJobs(jobPage.items)
    } else {
      setLoadError(notificationResult.reason instanceof Error ? notificationResult.reason.message : "Unable to load notification administration")
    }
    setFirebaseState(firebaseResult.status === "fulfilled" ? (firebaseResult.value.enabled ? "configured" : "disabled") : "unavailable")
    setFirebaseStatus(firebaseResult.status === "fulfilled" ? firebaseResult.value as FirebaseStatus : null)
    setLoading(false)
  }, [canAdminister, canReadAnalytics, canReadCampaigns, canReadFirebase, canReadTemplates])

  React.useEffect(() => {
    if (!permissionsLoading) void load()
  }, [load, permissionsLoading])

  React.useEffect(() => {
    if (!campaignOpen) {
      setEditingCampaignId(null)
      return
    }
    if (!editingCampaignId) {
      setCampaignForm({ name: "", type: "announcement", templateVersionId: "", variables: "{}", priority: "normal", channels: ["in-app"], timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", scheduledAt: "", expiresAt: "", allEligible: true, userIds: "", roleIds: "", countries: "", regionIds: "", districtIds: "", facilityIds: "", facilityLevelIds: "", professionalCategories: "", languages: "", platforms: "", applicationVersions: "", preferenceCategories: "" })
      setAudienceEstimate(null)
    }
  }, [campaignOpen, editingCampaignId])

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
      const input = { name: templateForm.name.trim(), template_key: templateForm.templateKey.trim(), channel: templateForm.channel, title_template: templateForm.title.trim() || undefined, body_template: templateForm.body, action_template: templateAction, variable_schema, category: templateForm.category, locale: templateForm.locale }
      if (editingTemplateId) await notificationsService.updateTemplate(editingTemplateId, input); else await notificationsService.createTemplate(input)
      setTemplateOpen(false); setEditingTemplateId(null); showToast.success(editingTemplateId ? "New template version created" : "Draft template created", "Review its rendered preview before publishing."); await load()
    } catch (error) { showToast.error("Template", error instanceof Error ? error.message : "Unable to create template") } finally { setUpdatingId(null) }
  }

  function editTemplate(template: NotificationTemplateDto) {
    setEditingTemplateId(template.id)
    setTemplateForm({ name: template.name, templateKey: template.template_key, channel: template.version.channel, title: template.version.title_template || "", body: template.version.body_template, category: template.version.category, locale: template.version.locale, schema: JSON.stringify(template.version.variable_schema, null, 2) })
    setTemplateAction(template.version.action_template)
    setTemplateOpen(true)
  }

  function handleTemplateOpenChange(open: boolean) {
    if (open && !editingTemplateId) {
      setTemplateForm({ name: "", templateKey: "", channel: "in-app", title: "", body: "", category: "Content Updates", locale: "en", schema: "{}" })
      setTemplateAction(emptyNotificationAction())
    }
    if (!open) setEditingTemplateId(null)
    setTemplateOpen(open)
  }

  async function cloneTemplate(template: NotificationTemplateDto) {
    const name = window.prompt("Name for the cloned draft", `${template.name} copy`)?.trim()
    if (!name) return
    const key = window.prompt("Unique stable key for the cloned draft", `${template.template_key}.copy`)?.trim()
    if (!key) return
    setUpdatingId(template.id)
    try { await notificationsService.cloneTemplate(template.id, { name, template_key: key }); showToast.success("Template cloned", "A new draft was created."); await load() }
    catch (error) { showToast.error("Template clone", error instanceof Error ? error.message : "Unable to clone template") }
    finally { setUpdatingId(null) }
  }

  async function showTemplateHistory(template: NotificationTemplateDto) {
    try { setTemplateHistory({ name: template.name, versions: await notificationsService.listTemplateVersions(template.id) }) }
    catch (error) { showToast.error("Version history", error instanceof Error ? error.message : "Unable to load history") }
  }

  async function previewTemplate(template: NotificationTemplateDto) {
    const variables = Object.fromEntries(Object.entries(template.version.variable_schema).map(([key, rule]) => [key, rule.sample_value ?? (rule.type === "number" ? 1 : rule.type === "boolean" ? true : key)]))
    try { const preview = await notificationsService.previewTemplateVersion(template.version.id, variables); setTemplatePreview({ name: template.name, ...preview }) }
    catch (error) { showToast.error("Template preview", error instanceof Error ? error.message : "Unable to render preview") }
  }

  async function testTemplate(template: NotificationTemplateDto) {
    const variables = Object.fromEntries(Object.entries(template.version.variable_schema).map(([key, rule]) => [key, rule.sample_value ?? (rule.type === "number" ? 1 : rule.type === "boolean" ? true : key)]))
    try {
      const preview = await notificationsService.previewTemplateVersion(template.version.id, variables)
      const query = new URLSearchParams({ title: preview.title, body: preview.body, action: JSON.stringify(preview.action) })
      window.location.assign(`/settings/firebase?${query}`)
    } catch (error) { showToast.error("Template test", error instanceof Error ? error.message : "Unable to validate template") }
  }

  async function saveCampaign(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    try {
      setUpdatingId("campaign-create")
      const audience = campaignAudience(campaignForm)
      const input = { name: campaignForm.name.trim(), type: campaignForm.type, template_version_id: campaignForm.templateVersionId, variables: JSON.parse(campaignForm.variables) as Record<string, unknown>, audience, timezone: campaignForm.timezone, scheduled_at: campaignForm.scheduledAt ? new Date(campaignForm.scheduledAt).toISOString() : undefined, expires_at: campaignForm.expiresAt ? new Date(campaignForm.expiresAt).toISOString() : undefined, priority: campaignForm.priority, requested_channels: campaignForm.channels, idempotency_key: editingCampaignId ? campaigns.find((item) => item.id === editingCampaignId)?.idempotency_key || crypto.randomUUID() : crypto.randomUUID(), lock_version: editingCampaignId ? campaigns.find((item) => item.id === editingCampaignId)?.lock_version : undefined }
      if (editingCampaignId) await notificationsService.updateCampaign(editingCampaignId, input); else await notificationsService.createCampaign(input)
      setCampaignOpen(false); setEditingCampaignId(null); showToast.success(editingCampaignId ? "Campaign draft updated" : "Campaign draft created", "Submit it for independent review when ready."); await load()
    } catch (error) { showToast.error("Campaign", error instanceof Error ? error.message : "Unable to create campaign") } finally { setUpdatingId(null) }
  }

  function editCampaign(campaign: NotificationCampaignDto) {
    if (campaign.status !== "draft") return
    setEditingCampaignId(campaign.id)
    setCampaignForm((value) => ({ ...value, name: campaign.name, type: campaign.type, templateVersionId: campaign.template_version_id || "", variables: "{}", priority: campaign.priority, channels: campaign.requested_channels as NotificationCampaignInput["requested_channels"], timezone: campaign.timezone, scheduledAt: campaign.scheduled_at ? campaign.scheduled_at.slice(0, 16) : "", expiresAt: campaign.expires_at ? campaign.expires_at.slice(0, 16) : "", allEligible: campaign.audience.all_eligible, userIds: campaign.audience.user_ids?.join(", ") || "", roleIds: campaign.audience.role_ids?.join(", ") || "", countries: campaign.audience.countries?.join(", ") || "", regionIds: campaign.audience.region_ids?.join(", ") || "", districtIds: campaign.audience.district_ids?.join(", ") || "", facilityIds: campaign.audience.facility_ids?.join(", ") || "", facilityLevelIds: campaign.audience.facility_level_ids?.join(", ") || "", professionalCategories: campaign.audience.professional_categories?.join(", ") || "", languages: campaign.audience.languages?.join(", ") || "", platforms: campaign.audience.platforms?.join(", ") || "", applicationVersions: campaign.audience.application_versions?.join(", ") || "", preferenceCategories: campaign.audience.preference_categories?.join(", ") || "" }))
    setCampaignForm((value) => ({ ...value, variables: JSON.stringify(campaign.variables || {}, null, 2) }))
    setCampaignOpen(true)
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

  async function transitionCampaign(campaign: NotificationCampaignDto, action: "submit" | "approve" | "reject" | "schedule" | "pause" | "resume" | "cancel") {
    const reason = action === "reject" || action === "cancel" ? window.prompt(`Reason to ${action} this campaign`) ?? "" : undefined
    if ((action === "reject" || action === "cancel") && !reason?.trim()) return
    let scheduledAt = campaign.scheduled_at
    if (action === "schedule") {
      const requested = window.prompt("Optional scheduled date/time (ISO 8601). Leave blank to send immediately.", campaign.scheduled_at || "")
      if (requested === null) return
      if (requested.trim()) {
        const parsed = new Date(requested)
        if (Number.isNaN(parsed.getTime())) { showToast.warning("Invalid schedule", "Enter an ISO 8601 date/time or leave it blank."); return }
        scheduledAt = parsed.toISOString()
      } else scheduledAt = undefined
    }
    if (!window.confirm(`${action[0].toUpperCase()}${action.slice(1)} ${campaign.name}?`)) return
    setUpdatingId(campaign.id)
    try { await notificationsService.transitionCampaign(campaign.id, action, { lock_version: campaign.lock_version, scheduled_at: action === "schedule" ? scheduledAt : undefined, timezone: action === "schedule" ? campaign.timezone : undefined, reason }); showToast.success("Campaign updated", `Campaign ${action} completed.`); await load() }
    catch (error) { showToast.error("Campaign workflow", error instanceof Error ? error.message : "Unable to update campaign") } finally { setUpdatingId(null) }
  }

  async function requeueJob(job: NotificationOutboxJobDto) {
    if (!window.confirm("Requeue this failed delivery? This may issue another provider request.")) return
    const reason = window.prompt("Operational reason for requeue")?.trim(); if (!reason) return
    setUpdatingId(job.id)
    try { await notificationsService.requeueDeliveryJob(job.id, reason); showToast.success("Delivery requeued", "The worker will retry the job."); await load() }
    catch (error) { showToast.error("Delivery requeue", error instanceof Error ? error.message : "Unable to requeue") }
    finally { setUpdatingId(null) }
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
        {preferenceAggregates ? <Summary title="Push opt-in" value={`${preferenceAggregates.push_enabled_users}/${preferenceAggregates.eligible_users}`} detail={`${preferenceAggregates.push_enabled_devices} enabled active devices`} /> : null}
        {preferenceAggregates ? <Summary title="In-app opt-in" value={`${preferenceAggregates.in_app_enabled_users}/${preferenceAggregates.eligible_users}`} detail={`${preferenceAggregates.quiet_hours_users} users use quiet hours`} /> : null}
      </div>

      <Tabs defaultValue="templates" className="space-y-4">
        <TabsList><TabsTrigger value="templates">Templates</TabsTrigger><TabsTrigger value="campaigns">Campaigns</TabsTrigger>{canReadAnalytics ? <TabsTrigger value="delivery">Delivery audit</TabsTrigger> : null}<TabsTrigger value="channels">Channels</TabsTrigger></TabsList>
        <TabsContent value="templates">
          <Card>
            <CardHeader className="flex-row items-start justify-between gap-4"><div><CardTitle>Templates</CardTitle><CardDescription>Versioned, validated content. Publishing makes the current version immutable.</CardDescription></div>{canManageTemplates ? <Dialog open={templateOpen} onOpenChange={handleTemplateOpenChange}><DialogTrigger asChild><Button><Plus className="mr-2 h-4 w-4" />New template</Button></DialogTrigger><DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-[680px]"><DialogHeader><DialogTitle>{editingTemplateId ? "Edit notification template" : "New notification template"}</DialogTitle><DialogDescription>Only declared variables using double-brace placeholders are accepted.</DialogDescription></DialogHeader><form className="space-y-4" onSubmit={saveTemplate}><div className="grid gap-4 sm:grid-cols-2"><Field label="Name"><Input required value={templateForm.name} onChange={(e) => setTemplateForm((v) => ({ ...v, name: e.target.value }))} /></Field><Field label="Stable key"><Input required pattern="[A-Za-z][A-Za-z0-9_.-]{0,63}" value={templateForm.templateKey} onChange={(e) => setTemplateForm((v) => ({ ...v, templateKey: e.target.value }))} /></Field><Field label="Channel"><Select value={templateForm.channel} onValueChange={(channel: NotificationTemplateInput["channel"]) => setTemplateForm((v) => ({ ...v, channel }))}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{["in-app", "push", "email", "sms"].map((value) => <SelectItem key={value} value={value}>{value}</SelectItem>)}</SelectContent></Select></Field><Field label="Category"><Select value={templateForm.category} onValueChange={(category) => setTemplateForm((v) => ({ ...v, category }))}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{["Content Updates", "Emergency", "Training", "System", "Marketing", "Reminder"].map((value) => <SelectItem key={value} value={value}>{value}</SelectItem>)}</SelectContent></Select></Field></div><Field label="Title template"><Input value={templateForm.title} onChange={(e) => setTemplateForm((v) => ({ ...v, title: e.target.value }))} /></Field><Field label="Body template"><Textarea required rows={5} value={templateForm.body} onChange={(e) => setTemplateForm((v) => ({ ...v, body: e.target.value }))} /></Field><Field label="Variable schema (JSON)"><Textarea className="font-mono" rows={5} value={templateForm.schema} onChange={(e) => setTemplateForm((v) => ({ ...v, schema: e.target.value }))} /><p className="text-xs text-muted-foreground">Example: {`{"name":{"type":"string","required":true,"sample_value":"Malaria"}}`}</p></Field><NotificationActionFields value={templateAction} onChange={setTemplateAction} allowSupportTicket={false} /><DialogFooter><Button type="button" variant="outline" onClick={() => handleTemplateOpenChange(false)}>Cancel</Button><Button type="submit" disabled={updatingId !== null}>{updatingId === "template-create" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}{editingTemplateId ? "Create new version" : "Create draft"}</Button></DialogFooter></form></DialogContent></Dialog> : null}</CardHeader>
            <CardContent className="space-y-3">
              {templates.length === 0 ? <Empty message="No templates found" /> : templates.map((template) => (
                <div key={template.id} className="flex flex-col gap-3 rounded-lg border p-4 sm:flex-row sm:items-center sm:justify-between">
                  <div className="space-y-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium">{template.name}</span><Badge variant="outline">{template.version.channel}</Badge><Badge variant={template.status === "published" ? "default" : "secondary"}>{template.status}</Badge><Badge variant="outline">v{template.current_version}</Badge></div><p className="text-sm text-muted-foreground">{template.version.title_template || template.version.category}</p></div>
                  <div className="flex flex-wrap gap-2"><Button variant="outline" size="sm" onClick={() => void previewTemplate(template)}>Validate & preview</Button>{template.version.channel === "push" && canReadFirebase ? <Button variant="outline" size="sm" onClick={() => void testTemplate(template)}>Send test</Button> : null}<Button variant="outline" size="sm" onClick={() => void showTemplateHistory(template)}>History</Button>{canManageTemplates ? <Button variant="outline" size="sm" onClick={() => editTemplate(template)}>Edit</Button> : null}{canManageTemplates ? <Button variant="outline" size="sm" onClick={() => void cloneTemplate(template)}>Clone</Button> : null}<Button variant="outline" size="sm" disabled={!canManageTemplates || updatingId !== null || template.status === "archived"} onClick={() => void toggleTemplate(template)}>{updatingId === template.id ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}{template.status === "published" ? "Archive" : "Publish"}</Button></div>
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
                <div key={campaign.id} className="flex flex-col gap-3 rounded-lg border p-4 lg:flex-row lg:items-center lg:justify-between"><div><p className="font-medium">{campaign.name}</p><p className="text-sm text-muted-foreground">{campaign.type} · {campaign.requested_channels.join(", ")} · {campaign.timezone} · lock {campaign.lock_version}</p><p className="mt-1 line-clamp-1 text-sm">{campaign.rendered_title}</p><div className="mt-2 grid gap-2 text-xs sm:grid-cols-2"><div className="rounded border p-2"><strong>Android preview</strong><p>{campaign.rendered_title}</p><p className="text-muted-foreground">{campaign.rendered_body}</p></div><div className="rounded border p-2"><strong>iOS preview</strong><p>{campaign.rendered_title}</p><p className="text-muted-foreground">{campaign.rendered_body}</p></div></div></div><div className="flex flex-wrap items-center gap-2"><Badge variant="outline">{campaign.status}</Badge>{campaign.status === "draft" && canManageCampaigns ? <Button size="sm" variant="outline" onClick={() => editCampaign(campaign)}>Edit</Button> : null}{campaign.status === "draft" && canManageCampaigns ? <Button size="sm" variant="outline" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "submit")}>Submit</Button> : null}{campaign.status === "pending_review" && canApproveCampaigns ? <><Button size="sm" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "approve")}>Approve</Button><Button size="sm" variant="outline" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "reject")}>Reject</Button></> : null}{campaign.status === "approved" && canManageCampaigns ? <Button size="sm" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "schedule")}>Send now</Button> : null}{["scheduled", "queued"].includes(campaign.status) && canManageCampaigns ? <Button size="sm" variant="outline" onClick={() => void transitionCampaign(campaign, "pause")}>Pause</Button> : null}{campaign.status === "paused" && canManageCampaigns ? <Button size="sm" variant="outline" onClick={() => void transitionCampaign(campaign, "resume")}>Resume</Button> : null}{["draft", "pending_review", "approved", "scheduled", "queued", "paused"].includes(campaign.status) && canManageCampaigns ? <Button size="sm" variant="destructive" disabled={updatingId !== null} onClick={() => void transitionCampaign(campaign, "cancel")}>Cancel</Button> : null}{["completed", "partially_failed", "failed", "cancelled"].includes(campaign.status) && canManageCampaigns ? <Button size="sm" variant="outline" onClick={() => { if (window.confirm("Archive this campaign?")) void notificationsService.deleteCampaign(campaign.id).then(load) }}>Archive</Button> : null}</div></div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
        {canReadAnalytics ? <TabsContent value="delivery"><Card><CardHeader><CardTitle>Delivery audit and daily metrics</CardTitle><CardDescription>Provider acceptance is distinct from device delivery. Opens and clicks are authenticated client events.</CardDescription></CardHeader><CardContent className="space-y-5">{analytics ? <><div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-6"><Summary title="Queued" value={analytics.items.reduce((sum, item) => sum + item.queued, 0)} detail="Lifecycle records" /><Summary title="Accepted" value={analytics.items.reduce((sum, item) => sum + item.accepted, 0)} detail="Provider accepted" /><Summary title="Rejected" value={analytics.items.reduce((sum, item) => sum + item.rejected, 0)} detail="Final failure" /><Summary title="Delivered" value={analytics.items.reduce((sum, item) => sum + item.delivered, 0)} detail="Reported/inferred" /><Summary title="Opened" value={analytics.items.reduce((sum, item) => sum + item.opened, 0)} detail="Client events" /><Summary title="Clicked" value={analytics.items.reduce((sum, item) => sum + item.clicked, 0)} detail="Action events" /></div><Alert><AlertTriangle className="h-4 w-4" /><AlertDescription>{analytics.big_query_export_note}</AlertDescription></Alert></> : null}<div className="overflow-x-auto rounded-md border"><table className="w-full text-sm"><thead><tr className="border-b text-left"><th className="p-2">Created</th><th className="p-2">Channel</th><th className="p-2">State</th><th className="p-2">Attempts</th><th className="p-2">Error</th></tr></thead><tbody>{deliveries.map((delivery) => <tr key={delivery.id} className="border-b last:border-0"><td className="p-2">{new Date(delivery.created_at).toLocaleString()}</td><td className="p-2">{delivery.channel}</td><td className="p-2">{delivery.state === "accepted" ? "accepted by provider" : delivery.state}</td><td className="p-2">{delivery.attempt_count}</td><td className="p-2">{delivery.error_category || "—"}</td></tr>)}</tbody></table>{deliveries.length === 0 ? <Empty message="No delivery records found" /> : null}</div><div><h3 className="mb-2 font-medium">Failed jobs</h3>{deliveryJobs.filter((job) => job.status === "failed").map((job) => <div key={job.id} className="flex items-center justify-between gap-2 border-b py-2 text-sm"><span>{job.channel} · {job.last_error_code || "failed"} · {job.attempt_count}/{job.max_attempts}</span><Button size="sm" variant="outline" disabled={!canManageCampaigns || updatingId === job.id} onClick={() => void requeueJob(job)}>Requeue</Button></div>)}{deliveryJobs.every((job) => job.status !== "failed") ? <p className="text-sm text-muted-foreground">No terminal failures.</p> : null}</div></CardContent></Card></TabsContent> : null}
        <TabsContent value="channels">
          <Card><CardHeader><CardTitle>Delivery channels</CardTitle><CardDescription>Status reflects implemented backend capabilities.</CardDescription></CardHeader><CardContent className="space-y-3">
            <Channel icon={Bell} title="Firebase push" description={`${firebaseStatus?.project_id || "No project"} · ${firebaseStatus?.active_device_count ?? 0} active · ${firebaseStatus?.stale_device_count ?? 0} stale · health ${firebaseStatus?.last_successful_health_check_at ? new Date(firebaseStatus.last_successful_health_check_at).toLocaleString() : "unavailable"}`} state={firebaseState === "configured" ? "Configured" : firebaseState === "disabled" ? "Not configured" : "Status unavailable"} configured={firebaseState === "configured"} href="/settings/firebase" />
            <Channel icon={FileText} title="In-app" description="Database-backed notices and mobile synchronization" state="Available" configured />
            <Channel icon={Send} title="Email" description="No production delivery provider is connected" state="Unsupported" />
            <Channel icon={Send} title="SMS" description="No production delivery provider is connected" state="Unsupported" />
          </CardContent></Card>
        </TabsContent>
      </Tabs>
      <Dialog open={templateHistory !== null} onOpenChange={(open) => { if (!open) setTemplateHistory(null) }}><DialogContent><DialogHeader><DialogTitle>{templateHistory?.name} version history</DialogTitle><DialogDescription>Published versions are immutable and campaigns retain their selected version.</DialogDescription></DialogHeader><div className="space-y-2">{templateHistory?.versions.map((version) => <div key={version.id} className="flex items-center justify-between rounded border p-3"><span>Version {version.version} · {version.channel}</span><Badge variant="outline">{version.status}</Badge></div>)}</div></DialogContent></Dialog>
      <Dialog open={templatePreview !== null} onOpenChange={(open) => { if (!open) setTemplatePreview(null) }}><DialogContent><DialogHeader><DialogTitle>{templatePreview?.name} preview</DialogTitle><DialogDescription>Rendered with the declared sample variables.</DialogDescription></DialogHeader><div className="space-y-3 rounded border p-4"><h3 className="font-semibold">{templatePreview?.title || "(no channel title)"}</h3><p className="whitespace-pre-wrap text-sm">{templatePreview?.body}</p><Badge variant="outline">Action: {templatePreview?.action.type}</Badge></div></DialogContent></Dialog>
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
    <div><p className="mb-2 text-sm font-medium">Delivery channels</p><div className="flex flex-wrap gap-3">{(["in-app", "push"] as const).map((channel) => <label key={channel} className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.channels.includes(channel)} onChange={(event) => { const next = event.target.checked ? [...form.channels, channel] : form.channels.filter((item) => item !== channel); if (next.length) onChange({ channels: next }) }} />{channel}</label>)}<span className="text-xs text-muted-foreground">Email and SMS are unsupported.</span></div></div>
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
