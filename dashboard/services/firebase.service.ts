import { getBackendClient } from "@/lib/backend-client"
import type { NotificationAction } from "@/services/notifications.service"

export type FirebaseStatus = { enabled: boolean; project_id?: string; last_successful_health_check_at?: string; active_device_count: number; stale_device_count: number; platforms: Record<string, number>; delivery_reporting: string; email_status: "unsupported"; sms_status: "unsupported" }
export type RemoteConfigDocument = {
  template: Record<string, unknown>
  etag: string
}
export type TestPushInput = {
  user_id?: string
  current_user?: boolean
  title: string
  body: string
  action: NotificationAction
  /** Compatibility field for clients predating typed actions. */
  action_url?: string
  data?: Record<string, string>
  dry_run: boolean
}
export type TestPushDeviceResult = { device_id: string; platform: string; app_version?: string; state: "validated" | "accepted" | "rejected"; provider_message_id?: string; error_category?: string }
export type TestPushResult = { attempted: number; validated: number; accepted: number; failed: number; devices: TestPushDeviceResult[] }
export type FirebaseTestRecipient = { id: string; name: string; email: string; device_count: number; platforms: string[] }

const client = () => getBackendClient()

export const firebaseService = {
  status() {
    return client().send<FirebaseStatus>("/api/v2/firebase/status")
  },
  remoteConfig() {
    return client().send<RemoteConfigDocument>("/api/v2/firebase/remote-config")
  },
  updateRemoteConfig(template: Record<string, unknown>, etag: string, validateOnly: boolean) {
    return client().send<RemoteConfigDocument>("/api/v2/firebase/remote-config", {
      method: "PUT",
      headers: { "If-Match": etag },
      body: JSON.stringify({ template, validate_only: validateOnly }),
    })
  },
  sendTestPush(input: TestPushInput) {
    return client().send<TestPushResult>("/api/v2/firebase/push/test", {
      method: "POST",
      body: JSON.stringify(input),
    })
  },
  searchTestRecipients(search: string) {
    return client().send<FirebaseTestRecipient[]>("/api/v2/firebase/test-recipients", { query: { search } })
  },
}
