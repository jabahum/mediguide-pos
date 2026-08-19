import { afterEach, describe, expect, it, vi } from "vitest"

import { BackendAuthStore, BackendClient, BackendRequestError, getBackendClient, hasBackendPermission } from "./backend-client"

describe("BackendClient authentication", () => {
  afterEach(() => {
    getBackendClient().authStore.clear()
    vi.unstubAllGlobals()
  })

  it("checks focused backend permissions from the authenticated role snapshot", () => {
    getBackendClient().authStore.save("Bearer access-token", {
      id: "user-id",
      status: "active",
      roles: [{ permissions: [{ code: "notification.template.read" }] }],
    })

    expect(hasBackendPermission("notification.template.read")).toBe(true)
    expect(hasBackendPermission("notification.template.manage")).toBe(false)
  })

  it("treats admin.all as a backend permission wildcard", () => {
    getBackendClient().authStore.save("Bearer access-token", {
      id: "user-id",
      status: "active",
      roles: [{ permissions: [{ code: "admin.all" }] }],
    })

    expect(hasBackendPermission("firebase.config.manage")).toBe(true)
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

  it("restores a compact session snapshot after a page reload", () => {
    const original = new BackendAuthStore()
    original.save(
      "Bearer access-token",
      {
        id: "user-id",
        name: "Admin",
        status: "active",
        roles: [{ role_key: "admin", permissions: ["admin.all"] }],
      },
      "refresh-token",
      "2030-01-01T00:00:00Z",
      "2030-02-01T00:00:00Z",
    )

    const serialized = original.serialize()
    const restored = new BackendAuthStore()

    expect(JSON.parse(serialized)).not.toHaveProperty("model")
    expect(restored.restore(serialized)).toBe(true)
    expect(restored.token).toBe("Bearer access-token")
    expect(restored.refreshToken).toBe("refresh-token")
    expect(restored.record?.id).toBe("user-id")
    expect(restored.model).toBe(restored.record)
  })

  it("refreshes an expired access token while restoring a valid session", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          success: true,
          data: {
            token: "new-access-token",
            refresh_token: "new-refresh-token",
            session_id: "session-id",
            expires_at: "2030-01-01T00:00:00Z",
            refresh_expires_at: "2030-02-01T00:00:00Z",
            user: { id: "user-id", status: "active" },
          },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    )
    vi.stubGlobal("fetch", fetchMock)

    const client = new BackendClient()
    client.authStore.save(
      "Bearer expired-token",
      { id: "user-id", status: "active" },
      "valid-refresh-token",
      "2020-01-01T00:00:00Z",
      "2030-02-01T00:00:00Z",
    )

    await expect(client.ensureSession()).resolves.toBe(true)
    expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8080/api/v2/auth/refresh",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ refresh_token: "valid-refresh-token" }),
      }),
    )
    expect(client.authStore.token).toBe("Bearer new-access-token")
  })

  it("clears a session when both access and refresh tokens are expired", async () => {
    const fetchMock = vi.fn()
    vi.stubGlobal("fetch", fetchMock)

    const client = new BackendClient()
    client.authStore.save(
      "Bearer expired-token",
      { id: "user-id", status: "active" },
      "expired-refresh-token",
      "2020-01-01T00:00:00Z",
      "2020-02-01T00:00:00Z",
    )

    await expect(client.ensureSession()).resolves.toBe(false)
    expect(fetchMock).not.toHaveBeenCalled()
    expect(client.authStore.isValid).toBe(false)
  })

  it("exposes Retry-After metadata without retrying a 429 response", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: false, error: "rate limit exceeded" }), {
        status: 429,
        headers: { "Content-Type": "application/json", "Retry-After": "23" },
      }),
    )
    vi.stubGlobal("fetch", fetchMock)

    const client = new BackendClient()
    const error = await client.request("/api/v2/search").catch((value) => value)

    expect(error).toBeInstanceOf(BackendRequestError)
    expect(error).toMatchObject({ status: 429, retryAfterSeconds: 23 })
    expect(error.message).toContain("23 seconds")
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })
})
