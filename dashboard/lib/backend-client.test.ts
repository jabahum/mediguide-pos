import { afterEach, describe, expect, it, vi } from "vitest"

import { BackendClient } from "./backend-client"

describe("BackendClient authentication", () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it("logs in through the typed v2 endpoint and persists the session", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          success: true,
          data: {
            token: "access-token",
            refresh_token: "refresh-token",
            session_id: "session-id",
            expires_at: "2026-07-30T17:00:00Z",
            refresh_expires_at: "2026-08-30T17:00:00Z",
            user: { id: "user-id", name: "Admin", status: "active" },
          },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    )
    vi.stubGlobal("fetch", fetchMock)

    const client = new BackendClient()
    const result = await client.login({
      email: "admin@mediguide.local",
      password: "secret",
    })

    expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8080/api/v2/auth/login",
      expect.objectContaining({ method: "POST" }),
    )
    expect(result.record.id).toBe("user-id")
    expect(client.authStore.token).toBe("Bearer access-token")
    expect(client.authStore.refreshToken).toBe("refresh-token")
  })

  it("revokes the remote session before clearing local state", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, data: { logged_out: true } }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    )
    vi.stubGlobal("fetch", fetchMock)

    const client = new BackendClient()
    client.authStore.save("Bearer access-token", { id: "user-id" }, "refresh-token")
    await client.logout()

    expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8080/api/v2/auth/logout",
      expect.objectContaining({
        method: "POST",
        headers: expect.any(Headers),
      }),
    )
    expect(client.authStore.isValid).toBe(false)
  })
})
