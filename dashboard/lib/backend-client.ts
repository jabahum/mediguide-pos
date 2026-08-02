const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || "http://127.0.0.1:8080"

const AUTH_COOKIE_NAME = "mediguide_auth"
const AUTH_STORAGE_KEY = "mediguide.auth.v1"
const AUTH_SNAPSHOT_VERSION = 1
const EXPIRY_CLOCK_SKEW_MS = 30_000
type JsonRecord = Record<string, any>

export class BackendRequestError extends Error {
  constructor(
    message: string,
    public readonly status: number,
  ) {
    super(message)
    this.name = "BackendRequestError"
  }
}
type RequestOptions = RequestInit & {
  params?: Record<string, string | number | boolean | undefined>
  query?: Record<string, string | number | boolean | undefined>
  responseType?: "json" | "blob" | "text"
}

type AuthSnapshot = {
  version: typeof AUTH_SNAPSHOT_VERSION
  token: string
  refreshToken: string
  record: JsonRecord | null
  expiresAt: string
  refreshExpiresAt: string
}

export type LoginRequest = {
  email: string
  password: string
}

export type AuthSession = {
  token: string
  refresh_token: string
  session_id: string
  expires_at: string
  refresh_expires_at: string
  user: JsonRecord
}

export class BackendAuthStore {
  token = ""
  refreshToken = ""
  record: JsonRecord | null = null
  model: JsonRecord | null = null
  expiresAt = ""
  refreshExpiresAt = ""
  private listeners = new Set<() => void>()

  get isValid() {
    return Boolean(this.token && this.record)
  }

  save(
    token: string,
    record: JsonRecord | null,
    refreshToken = "",
    expiresAt = "",
    refreshExpiresAt = "",
  ) {
    this.token = token
    this.refreshToken = refreshToken
    this.record = record
    this.model = record
    this.expiresAt = expiresAt
    this.refreshExpiresAt = refreshExpiresAt
    this.emit()
  }

  clear() {
    this.token = ""
    this.refreshToken = ""
    this.record = null
    this.model = null
    this.expiresAt = ""
    this.refreshExpiresAt = ""
    this.emit()
  }

  serialize(): string {
    const snapshot: AuthSnapshot = {
      version: AUTH_SNAPSHOT_VERSION,
      token: this.token,
      refreshToken: this.refreshToken,
      record: this.record,
      expiresAt: this.expiresAt,
      refreshExpiresAt: this.refreshExpiresAt,
    }
    return JSON.stringify(snapshot)
  }

  restore(serialized: string): boolean {
    try {
      const snapshot = JSON.parse(serialized) as Partial<AuthSnapshot>
      if (!snapshot.token || !snapshot.record) return false
      this.token = snapshot.token || ""
      this.refreshToken = snapshot.refreshToken || ""
      this.record = snapshot.record || null
      this.model = this.record
      this.expiresAt = snapshot.expiresAt || ""
      this.refreshExpiresAt = snapshot.refreshExpiresAt || ""
      return true
    } catch {
      return false
    }
  }

  isAccessTokenExpired(now = Date.now()) {
    return isExpired(this.expiresAt, now)
  }

  isRefreshTokenExpired(now = Date.now()) {
    return isExpired(this.refreshExpiresAt, now)
  }

  onChange(listener: () => void) {
    this.listeners.add(listener)
    return () => {
      this.listeners.delete(listener)
    }
  }

  private emit() {
    for (const listener of this.listeners) {
      listener()
    }
  }
}

export class BackendClient {
  readonly baseUrl = API_BASE_URL
  readonly authStore = new BackendAuthStore()
  readonly files = {
    getURL: (record: JsonRecord, field: string) => {
      const value = record?.[field]
      return typeof value === "string" ? value : ""
    },
    getUrl: (record: JsonRecord, field: string) => {
      const value = record?.[field]
      return typeof value === "string" ? value : ""
    },
  }

  autoCancellation(_enabled: boolean) {}

  async send<T = any>(path: string, options: RequestOptions = {}) {
    return this.request<T>(path, options)
  }

  async login(credentials: LoginRequest) {
    const session = await this.request<AuthSession>("/api/v2/auth/login", {
      method: "POST",
      body: JSON.stringify(credentials),
    })
    return this.saveSession(session)
  }

  async refreshAuth() {
    if (!this.authStore.refreshToken) {
      throw new BackendRequestError("No refresh token is available", 401)
    }
    const session = await this.request<AuthSession>("/api/v2/auth/refresh", {
      method: "POST",
      body: JSON.stringify({ refresh_token: this.authStore.refreshToken }),
    })
    return this.saveSession(session)
  }

  async ensureSession() {
    if (!this.authStore.isValid) return false
    if (!this.authStore.isAccessTokenExpired()) return true
    if (
      !this.authStore.refreshToken ||
      this.authStore.isRefreshTokenExpired()
    ) {
      this.authStore.clear()
      return false
    }

    try {
      await this.refreshAuth()
      return true
    } catch {
      this.authStore.clear()
      return false
    }
  }

  async currentUser() {
    const user = await this.request<JsonRecord>("/api/v2/me")
    const record = normalizeRecord("users", user)
    this.authStore.save(
      this.authStore.token,
      record,
      this.authStore.refreshToken,
      this.authStore.expiresAt,
      this.authStore.refreshExpiresAt,
    )
    return record
  }

  async logout() {
    try {
      if (this.authStore.token) {
        await this.request<{ logged_out: boolean }>("/api/v2/auth/logout", {
          method: "POST",
        })
      }
    } finally {
      this.authStore.clear()
    }
  }

  async request<T = any>(path: string, options: RequestOptions = {}) {
    const url = new URL(path, this.baseUrl)
    const query = options.query || options.params || {}
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === "") continue
      url.searchParams.set(key, String(value))
    }

    const headers = new Headers(options.headers || {})
    if (!headers.has("Content-Type") && options.body && !(options.body instanceof FormData)) {
      headers.set("Content-Type", "application/json")
    }
    if (this.authStore.token && !headers.has("Authorization")) {
      headers.set("Authorization", this.authStore.token)
    }

    const response = await fetch(url.toString(), {
      ...options,
      headers,
    })

    if (!response.ok) {
      const errorMessage = await extractError(response)
      throw new BackendRequestError(errorMessage, response.status)
    }

    if (options.responseType === "blob") {
      return (await response.blob()) as T
    }
    if (options.responseType === "text") {
      return (await response.text()) as T
    }

    if (response.status === 204) {
      return undefined as T
    }

    const payload = (await response.json()) as { data?: T } & T
    if (payload && typeof payload === "object" && "data" in payload && payload.data !== undefined) {
      return payload.data
    }
    return payload as T
  }

  private saveSession(session: AuthSession) {
    const token = session.token.startsWith("Bearer ")
      ? session.token
      : `Bearer ${session.token}`
    const record = normalizeRecord("users", session.user)
    this.authStore.save(
      token,
      record,
      session.refresh_token,
      session.expires_at,
      session.refresh_expires_at,
    )
    return { token, record, session }
  }
}

let backendClientInstance: BackendClient | null = null

export function createBackendClient(): BackendClient {
  if (backendClientInstance) return backendClientInstance

  const client = new BackendClient()
  if (typeof window !== "undefined") {
    restoreBrowserSession(client)
    client.authStore.onChange(() => {
      persistBrowserSession(client)
    })
  }

  backendClientInstance = client
  return client
}

export function getBackendClient(): BackendClient {
  return backendClientInstance || createBackendClient()
}

export const backendClient = getBackendClient()

if (typeof window !== "undefined") {
  ;(window as unknown as { __backendClient: unknown }).__backendClient =
    backendClient
}

export function isAuthenticated(): boolean {
  if (typeof window === "undefined") return false
  return getBackendClient().authStore.isValid && isUserActive()
}

export function isUserActive(): boolean {
  if (typeof window === "undefined") return false
  const user = getCurrentUser()
  return user?.status === "active"
}

export function getCurrentUser() {
  if (typeof window === "undefined") return null
  return getBackendClient().authStore.record
}

export function getUserRole(): string | null {
  const user = getCurrentUser()
  return typeof user?.role === "string" ? user.role : null
}

export function hasRole(role: string): boolean {
  return getUserRole() === role
}

export function hasAnyRole(roles: string[]): boolean {
  const userRole = getUserRole()
  return userRole ? roles.includes(userRole) : false
}

export function canAccessDashboard(): boolean {
  const allowedRoles = [
    "super_admin",
    "admin",
    "content_manager",
    "reviewer",
    "healthcare_provider",
    "observer",
  ]
  return isAuthenticated() && hasAnyRole(allowedRoles)
}

export function canAccessMobile(): boolean {
  const allowedRoles = ["healthcare_provider", "observer"]
  return isAuthenticated() && hasAnyRole(allowedRoles)
}

export async function logout() {
  if (typeof window === "undefined") return
  await getBackendClient().logout()
}

function normalizeRecord(collection: string, raw: JsonRecord) {
  const normalized: JsonRecord = {
    collectionId: collection,
    collectionName: collection,
    ...raw,
  }

  for (const [key, value] of Object.entries(raw)) {
    if (key === "created_at") {
      normalized.created = value
      continue
    }
    if (key === "updated_at") {
      normalized.updated = value
      continue
    }
    if (key.endsWith("_json")) {
      const base = key.slice(0, -5)
      const parsed = parseJSONValue(value)
      normalized[base] = parsed
      normalized[toCamelCase(base)] = parsed
      continue
    }
    if (key.endsWith("_id")) {
      normalized[key.slice(0, -3)] = value
    }
    if (key === "sort_order") {
      normalized.order = value
    }
    if (key === "added_by_user_id") {
      normalized.addedBy = value
    }
    normalized[toCamelCase(key)] = value
  }

  if (collection === "users") {
    const roles = Array.isArray(normalized.roles) ? normalized.roles : []
    if (!normalized.role && roles[0] && typeof roles[0] === "object") {
      const roleRecord = roles[0] as JsonRecord
      normalized.role =
        (typeof roleRecord.role_key === "string" && roleRecord.role_key) ||
        (typeof roleRecord.key === "string" && roleRecord.key) ||
        (typeof roleRecord.name === "string" && roleRecord.name) ||
        null
    }
    normalized.emailVisibility = true
    normalized.username = normalized.email
    normalized.tokenKey = ""
  }

  if (collection === "roles") {
    normalized.key = normalized.key || normalized.role_key
    normalized.isActive =
      normalized.isActive ?? normalized.is_active ?? true
    normalized.permissions = normalized.permissions ?? normalized.permissions_json ?? {}
  }


  if (!normalized.created && normalized.created_at) {
    normalized.created = normalized.created_at
  }
  if (!normalized.updated && normalized.updated_at) {
    normalized.updated = normalized.updated_at
  }

  return normalized
}

function parseJSONValue(value: unknown) {
  if (typeof value !== "string") return value
  try {
    return JSON.parse(value)
  } catch {
    return value
  }
}

function toCamelCase(value: string) {
  return value.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
}

function parseCookie(cookie: string, name: string) {
  const entry = cookie
    .split(";")
    .map((part) => part.trim())
    .find((part) => part.startsWith(`${name}=`))
  return entry ? entry.slice(name.length + 1) : null
}

function restoreBrowserSession(client: BackendClient) {
  try {
    const stored = window.localStorage.getItem(AUTH_STORAGE_KEY)
    if (stored && client.authStore.restore(stored)) {
      clearLegacyAuthCookie()
      return
    }
    if (stored) window.localStorage.removeItem(AUTH_STORAGE_KEY)

    const legacyValue = parseCookie(document.cookie || "", AUTH_COOKIE_NAME)
    if (legacyValue) {
      const decoded = decodeURIComponent(legacyValue)
      if (client.authStore.restore(decoded)) {
        persistBrowserSession(client)
      }
    }
  } catch {
    // Storage can be unavailable in hardened or private browser contexts.
  } finally {
    clearLegacyAuthCookie()
  }
}

function persistBrowserSession(client: BackendClient) {
  try {
    if (client.authStore.isValid) {
      window.localStorage.setItem(AUTH_STORAGE_KEY, client.authStore.serialize())
    } else {
      window.localStorage.removeItem(AUTH_STORAGE_KEY)
    }
  } catch {
    // Keep the in-memory session usable even when persistence is unavailable.
  }
}

function clearLegacyAuthCookie() {
  if (typeof document === "undefined") return
  document.cookie = `${AUTH_COOKIE_NAME}=; Path=/; Max-Age=0; SameSite=Lax`
}

function isExpired(value: string, now: number) {
  if (!value) return false
  const expiresAt = Date.parse(value)
  return Number.isNaN(expiresAt) || expiresAt <= now + EXPIRY_CLOCK_SKEW_MS
}

async function extractError(response: Response) {
  try {
    const payload = (await response.json()) as { error?: string; message?: string }
    return payload.error || payload.message || `Request failed with status ${response.status}`
  } catch {
    return `Request failed with status ${response.status}`
  }
}
