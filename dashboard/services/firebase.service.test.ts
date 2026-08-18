import { beforeEach, describe, expect, it, vi } from "vitest"

const send = vi.fn()

vi.mock("@/lib/backend-client", () => ({
  getBackendClient: () => ({ send }),
}))

import { firebaseService } from "./firebase.service"

describe("firebaseService", () => {
  beforeEach(() => send.mockReset())

  it("loads status and Remote Config through typed endpoints", async () => {
    send.mockResolvedValue({})

    await firebaseService.status()
    await firebaseService.remoteConfig()

    expect(send).toHaveBeenNthCalledWith(1, "/api/v2/firebase/status")
    expect(send).toHaveBeenNthCalledWith(2, "/api/v2/firebase/remote-config")
  })

  it("uses the ETag when validating or publishing Remote Config", async () => {
    send.mockResolvedValue({})
    const template = { parameters: { maintenance_mode: { defaultValue: { value: "false" } } } }

    await firebaseService.updateRemoteConfig(template, "etag-123", true)

    expect(send).toHaveBeenCalledWith("/api/v2/firebase/remote-config", {
      method: "PUT",
      headers: { "If-Match": "etag-123" },
      body: JSON.stringify({ template, validate_only: true }),
    })
  })

  it("sends test notifications without generic resource transport", async () => {
    send.mockResolvedValue({ attempted: 1, sent: 1, failed: 0 })
    const input = {
      user_id: "7d2f83ea-e80c-4904-83f4-22d637aef51d",
      title: "Test",
      body: "MediGuide",
      dry_run: true,
    }

    await firebaseService.sendTestPush(input)

    expect(send).toHaveBeenCalledWith("/api/v2/firebase/push/test", {
      method: "POST",
      body: JSON.stringify(input),
    })
  })
})
