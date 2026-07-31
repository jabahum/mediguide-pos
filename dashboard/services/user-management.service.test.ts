import { afterEach, describe, expect, it, vi } from "vitest"

import { usersService } from "./user-management.service"

describe("usersService", () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it("uses the typed password-reset endpoint and preserves delivery status", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        success: true,
        data: { accepted: true, delivery_accepted: false, development_token: "dev-token" },
      }), { status: 200, headers: { "Content-Type": "application/json" } }),
    )
    vi.stubGlobal("fetch", fetchMock)

    const result = await usersService.requestPasswordReset("user@example.test")

    expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8080/api/v2/auth/password-reset/request",
      expect.objectContaining({ method: "POST", body: JSON.stringify({ email: "user@example.test" }) }),
    )
    expect(result).toEqual({ accepted: true, delivery_accepted: false, development_token: "dev-token" })
  })

  it("uses the typed administrative verification endpoint", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ success: true, data: { id: "user-id", verified: true } }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    )
    vi.stubGlobal("fetch", fetchMock)

    const result = await usersService.verify<{ id: string; verified: boolean }>("user-id")

    expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8080/api/v2/users/user-id/verification",
      expect.objectContaining({ method: "POST" }),
    )
    expect(result.verified).toBe(true)
  })

	it("uses the typed user-owned email verification endpoints", async () => {
		const fetchMock = vi
			.fn()
			.mockResolvedValueOnce(new Response(JSON.stringify({
				success: true,
				data: { accepted: true, delivery_accepted: false, development_token: "verify-token" },
			}), { status: 200, headers: { "Content-Type": "application/json" } }))
			.mockResolvedValueOnce(new Response(JSON.stringify({
				success: true,
				data: { verified: true },
			}), { status: 200, headers: { "Content-Type": "application/json" } }))
		vi.stubGlobal("fetch", fetchMock)

		await usersService.requestEmailVerification("user@example.test")
		const result = await usersService.confirmEmailVerification("verify-token")

		expect(fetchMock).toHaveBeenNthCalledWith(
			1,
			"http://127.0.0.1:8080/api/v2/auth/email-verification/request",
			expect.objectContaining({ method: "POST", body: JSON.stringify({ email: "user@example.test" }) }),
		)
		expect(fetchMock).toHaveBeenNthCalledWith(
			2,
			"http://127.0.0.1:8080/api/v2/auth/email-verification/confirm",
			expect.objectContaining({ method: "POST", body: JSON.stringify({ token: "verify-token" }) }),
		)
		expect(result.verified).toBe(true)
	})
})
