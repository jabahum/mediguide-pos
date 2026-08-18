"use client"

import { useCallback, useEffect, useState } from "react"
import { CloudCog, Loader2, Save, Send } from "lucide-react"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { PageHeader } from "@/components/ui/page-header"
import { Textarea } from "@/components/ui/textarea"
import { showToast } from "@/lib/toast"
import { firebaseService } from "@/services/firebase.service"

export default function FirebaseSettingsPage() {
  const [enabled, setEnabled] = useState<boolean | null>(null)
  const [template, setTemplate] = useState("")
  const [etag, setEtag] = useState("")
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [sending, setSending] = useState(false)
  const [userId, setUserId] = useState("")
  const [title, setTitle] = useState("MediGuide test notification")
  const [body, setBody] = useState("Firebase Cloud Messaging is configured correctly.")

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const status = await firebaseService.status()
      setEnabled(status.enabled)
      if (status.enabled) {
        const config = await firebaseService.remoteConfig()
        setTemplate(JSON.stringify(config.template, null, 2))
        setEtag(config.etag)
      }
    } catch (error) {
      showToast.error("Firebase", error instanceof Error ? error.message : "Unable to load Firebase settings")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => void load(), [load])

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
      const result = await firebaseService.sendTestPush({ user_id: userId, title, body, dry_run: dryRun })
      showToast.success("Push test", `${result.sent} sent, ${result.failed} failed, ${result.attempted} attempted`)
    } catch (error) {
      showToast.error("Push test", error instanceof Error ? error.message : "Push test failed")
    } finally {
      setSending(false)
    }
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
          <Card>
            <CardHeader><CardTitle>Remote Config template</CardTitle><CardDescription>Edit the Firebase template with optimistic concurrency protection. Validate before publishing.</CardDescription></CardHeader>
            <CardContent className="space-y-4">
              <Textarea className="min-h-[420px] font-mono text-xs" value={template} onChange={(event) => setTemplate(event.target.value)} spellCheck={false} />
              <div className="flex gap-2">
                <Button variant="outline" disabled={saving} onClick={() => void save(true)}>Validate</Button>
                <Button disabled={saving || !etag} onClick={() => void save(false)}><Save className="mr-2 h-4 w-4" />Publish</Button>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader><CardTitle>Test push notification</CardTitle><CardDescription>Target an authenticated MediGuide user who has registered an Android or iOS installation.</CardDescription></CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2"><Label htmlFor="firebase-user">User UUID</Label><Input id="firebase-user" value={userId} onChange={(event) => setUserId(event.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="firebase-title">Title</Label><Input id="firebase-title" value={title} onChange={(event) => setTitle(event.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="firebase-body">Message</Label><Textarea id="firebase-body" value={body} onChange={(event) => setBody(event.target.value)} /></div>
              <div className="flex gap-2">
                <Button variant="outline" disabled={sending || !userId} onClick={() => void sendPush(true)}>Validate delivery</Button>
                <Button disabled={sending || !userId} onClick={() => void sendPush(false)}><Send className="mr-2 h-4 w-4" />Send push</Button>
              </div>
            </CardContent>
          </Card>
        </>
      ) : null}
    </div>
  )
}
