import { getBackendClient } from "@/lib/backend-client"
import type { NotificationAction } from "@/services/notifications.service"

export type FirebaseStatus = { enabled: boolean }
export type RemoteConfigDocument = {
  template: Record<string, unknown>
  etag: string
}
export type TestPushInput = {
  user_id: string
  title: string
  body: string
  action: NotificationAction
  /** Compatibility field for clients predating typed actions. */
  action_url?: string
  data?: Record<string, string>
  dry_run: boolean
}
export type TestPushResult = { attempted: number; sent: number; failed: number }

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
}
