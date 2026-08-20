"use client"

import { useCallback, useEffect, useState } from "react"
import { CloudCog, Loader2, LockKeyhole, Save, Send } from "lucide-react"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { PageHeader } from "@/components/ui/page-header"
import { Textarea } from "@/components/ui/textarea"
import { emptyNotificationAction, NotificationActionFields } from "@/components/notifications/notification-action-fields"
import { showToast } from "@/lib/toast"
import { hasBackendPermission } from "@/lib/backend-client"
import { firebaseService, type FirebaseStatus, type FirebaseTestRecipient, type TestPushResult } from "@/services/firebase.service"
import type { NotificationAction } from "@/services/notifications.service"

export default function FirebaseSettingsPage() {
  const canReadStatus = hasBackendPermission("firebase.status.read")
  const canManageConfig = hasBackendPermission("firebase.config.manage")
  const canTestPush = hasBackendPermission("firebase.push.test")
  const canAdminister = canReadStatus || canManageConfig || canTestPush
  const [enabled, setEnabled] = useState<boolean | null>(null)
  const [status, setStatus] = useState<FirebaseStatus | null>(null)
  const [template, setTemplate] = useState("")
  const [etag, setEtag] = useState("")
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [sending, setSending] = useState(false)
  const [userId, setUserId] = useState("")
  const [recipientSearch, setRecipientSearch] = useState("")
  const [recipients, setRecipients] = useState<FirebaseTestRecipient[]>([])
  const [searching, setSearching] = useState(false)
  const [currentUser, setCurrentUser] = useState(true)
  const [pushResult, setPushResult] = useState<TestPushResult | null>(null)
  const [title, setTitle] = useState("MediGuide test notification")
  const [body, setBody] = useState("Firebase Cloud Messaging is configured correctly.")
  const [action, setAction] = useState<NotificationAction>(emptyNotificationAction)

  const load = useCallback(async () => {
    if (!canAdminister) {
      setLoading(false)
      return
    }
    setLoading(true)
    try {
      const status = canReadStatus ? await firebaseService.status() : { enabled: true }
      setEnabled(status.enabled)
      setStatus(status as FirebaseStatus)
      if (status.enabled && canManageConfig) {
        const config = await firebaseService.remoteConfig()
        setTemplate(JSON.stringify(config.template, null, 2))
        setEtag(config.etag)
      }
    } catch (error) {
      showToast.error("Firebase", error instanceof Error ? error.message : "Unable to load Firebase settings")
    } finally {
      setLoading(false)
    }
  }, [canAdminister, canManageConfig, canReadStatus])

  useEffect(() => void load(), [load])

  useEffect(() => {
    const query = new URLSearchParams(window.location.search)
    const initialTitle = query.get("title")
    const initialBody = query.get("body")
    const initialAction = query.get("action")
    if (initialTitle) setTitle(initialTitle)
    if (initialBody) setBody(initialBody)
    if (initialAction) {
      try { setAction(JSON.parse(initialAction) as NotificationAction) } catch { /* malformed query input is ignored */ }
    }
  }, [])

  async function save(validateOnly: boolean) {
    setSaving(true)
    try {
      const parsed = JSON.parse(template) as Record<string, unknown>
      const result = await firebaseService.updateRemoteConfig(parsed, etag, validateOnly)
      setTemplate(JSON.stringify(result.template, null, 2))
      setEtag(result.etag)
      showToast.success("Remote Config", validateOnly ? "Template is valid" : "Template published")
    } catch (error) {
      showToast.error("Remote Config", error instanceof Error ? error.message : "Remote Config update failed")
    } finally {
      setSaving(false)
    }
  }

  async function sendPush(dryRun: boolean) {
    setSending(true)
    try {
      const result = await firebaseService.sendTestPush({
        user_id: currentUser ? undefined : userId,
        current_user: currentUser,
        title,
        body,
        action,
        dry_run: dryRun,
      })
      setPushResult(result)
      showToast.success(
        dryRun ? "Push validation completed" : "Push request completed",
        dryRun
          ? `${result.validated} accepted by validation and ${result.failed} rejected across ${result.attempted} attempts. No push was sent.`
          : `${result.accepted} accepted by FCM and ${result.failed} rejected across ${result.attempted} attempts. Device delivery is not confirmed.`,
      )
    } catch (error) {
      showToast.error("Push test", error instanceof Error ? error.message : "Push test failed")
    } finally {
      setSending(false)
    }
  }

  async function searchRecipients() {
    if (recipientSearch.trim().length < 2) return
    setSearching(true)
    try { setRecipients(await firebaseService.searchTestRecipients(recipientSearch.trim())) }
    catch (error) { showToast.error("Recipients", error instanceof Error ? error.message : "Unable to search users") }
    finally { setSearching(false) }
  }

  if (!canAdminister) {
    return (
      <div className="space-y-6">
        <PageHeader title="Firebase" description="Manage mobile notification configuration" />
        <Alert variant="destructive">
          <LockKeyhole className="h-4 w-4" />
          <AlertDescription>You do not have permission to manage Firebase configuration.</AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Firebase" description="Manage mobile Remote Config and test push delivery" />
      {loading ? <div className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" />Loading Firebase status…</div> : null}
      {enabled === false ? (
        <Alert><CloudCog className="h-4 w-4" /><AlertDescription>Firebase is disabled. Configure FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT_BASE64 on the backend.</AlertDescription></Alert>
      ) : null}
      {enabled ? (
        <>
          {status ? <Card><CardHeader><CardTitle>Live channel health</CardTitle><CardDescription>Non-secret status reported by the backend.</CardDescription></CardHeader><CardContent className="grid gap-3 text-sm sm:grid-cols-2 lg:grid-cols-4"><div><span className="text-muted-foreground">Project</span><p className="font-medium">{status.project_id || "Not configured"}</p></div><div><span className="text-muted-foreground">Last initialized</span><p className="font-medium">{status.last_successful_health_check_at ? new Date(status.last_successful_health_check_at).toLocaleString() : "Unavailable"}</p></div><div><span className="text-muted-foreground">Active devices</span><p className="font-medium">{status.active_device_count ?? 0}</p></div><div><span className="text-muted-foreground">Stale devices</span><p className="font-medium">{status.stale_device_count ?? 0}</p></div><div className="sm:col-span-2 lg:col-span-4 text-muted-foreground">{status.delivery_reporting}</div></CardContent></Card> : null}
          {canManageConfig ? <Card>
            <CardHeader><CardTitle>Remote Config template</CardTitle><CardDescription>Edit the Firebase template with optimistic concurrency protection. Validate before publishing.</CardDescription></CardHeader>
            <CardContent className="space-y-4">
              <Textarea className="min-h-[420px] font-mono text-xs" value={template} onChange={(event) => setTemplate(event.target.value)} spellCheck={false} />
              <div className="flex gap-2">
                <Button variant="outline" disabled={saving} onClick={() => void save(true)}>Validate</Button>
                <Button disabled={saving || !etag} onClick={() => {
                  if (window.confirm("Publish this Remote Config template to the configured Firebase project?")) void save(false)
                }}><Save className="mr-2 h-4 w-4" />Publish</Button>
              </div>
            </CardContent>
          </Card> : null}
          {canTestPush ? <Card>
            <CardHeader><CardTitle>Test push notification</CardTitle><CardDescription>Target an authenticated MediGuide user who has registered an Android or iOS installation.</CardDescription></CardHeader>
            <CardContent className="space-y-4">
              <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={currentUser} onChange={(event) => { setCurrentUser(event.target.checked); setPushResult(null) }} />Send to my current administrator devices</label>
              {!currentUser ? <div className="space-y-2"><Label htmlFor="firebase-user-search">Recipient</Label><div className="flex gap-2"><Input id="firebase-user-search" placeholder="Search by name or email" value={recipientSearch} onChange={(event) => setRecipientSearch(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter") { event.preventDefault(); void searchRecipients() } }} /><Button type="button" variant="outline" disabled={searching || recipientSearch.trim().length < 2} onClick={() => void searchRecipients()}>{searching ? <Loader2 className="h-4 w-4 animate-spin" /> : "Search"}</Button></div>{recipients.length ? <div className="space-y-2 rounded-md border p-2">{recipients.map((recipient) => <button type="button" key={recipient.id} className={`w-full rounded p-2 text-left text-sm ${userId === recipient.id ? "bg-muted" : "hover:bg-muted/60"}`} onClick={() => { setUserId(recipient.id); setPushResult(null) }}><span className="font-medium">{recipient.name}</span><span className="ml-2 text-muted-foreground">{recipient.email} · {recipient.device_count} device(s) · {recipient.platforms.join(", ") || "no active platform"}</span></button>)}</div> : null}</div> : null}
              <div className="space-y-2"><Label htmlFor="firebase-title">Title</Label><Input id="firebase-title" value={title} onChange={(event) => setTitle(event.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="firebase-body">Message</Label><Textarea id="firebase-body" value={body} onChange={(event) => setBody(event.target.value)} /></div>
              <NotificationActionFields value={action} onChange={setAction} />
              <div className="flex gap-2">
                <Button variant="outline" disabled={sending || (!currentUser && !userId)} onClick={() => void sendPush(true)}>Validate delivery</Button>
                <Button disabled={sending || (!currentUser && !userId)} onClick={() => {
                  if (window.confirm("Send this test push to every enabled installation registered to this user?")) void sendPush(false)
                }}><Send className="mr-2 h-4 w-4" />Send push</Button>
              </div>
              {pushResult ? <div className="overflow-x-auto rounded-md border"><table className="w-full text-sm"><thead><tr className="border-b text-left"><th className="p-2">Platform</th><th className="p-2">App version</th><th className="p-2">Result</th><th className="p-2">Error</th></tr></thead><tbody>{pushResult.devices.map((device) => <tr key={device.device_id} className="border-b last:border-0"><td className="p-2">{device.platform}</td><td className="p-2">{device.app_version || "—"}</td><td className="p-2">{device.state}</td><td className="p-2">{device.error_category || "—"}</td></tr>)}</tbody></table></div> : null}
            </CardContent>
          </Card> : null}
        </>
      ) : null}
    </div>
  )
}
