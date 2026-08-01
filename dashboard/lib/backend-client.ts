const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL?.trim() || "http://127.0.0.1:8080"

const AUTH_COOKIE_NAME = "mediguide_auth"
const LIST_PAGE_SIZE = 100
const DOMAIN_COLLECTION_PATHS: Record<string, string> = {
  drugs: "/api/v2/drugs",
  drug_categories: "/api/v2/drug-categories",
  drug_tags: "/api/v2/drug-tags",
  drug_classes: "/api/v2/drug-classes",
  therapeutic_categories: "/api/v2/therapeutic-categories",
  medical_guidelines: "/api/v2/medical-guidelines",
  abbreviations: "/api/v2/abbreviations",
  emergency_protocols: "/api/v2/emergency-protocols",
  faqs: "/api/v2/faqs",
  faq_tags: "/api/v2/faq-tags",
  documentation: "/api/v2/documentation",
  generic_pages: "/api/v2/pages",
  guideline_categories: "/api/v2/guideline-categories",
  guideline_tags: "/api/v2/guideline-tags",
  guideline_index: "/api/v2/guideline-index",
  consultants: "/api/v2/consultants",
  ministry_directory: "/api/v2/ministry-directory",
  languages: "/api/v2/reference-languages",
  conversations: "/api/v2/conversations",
  messages: "/api/v2/messages",
  reading_progress: "/api/v2/reading-progress",
  guideline_usage_logs: "/api/v2/guideline-usage",
  abbreviation_usage_logs: "/api/v2/abbreviation-usage",
  consultant_usage_logs: "/api/v2/consultant-usage",
  ai_usage_logs: "/api/v2/ai-usage",
}

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
type ListResult<T> = {
  page: number
  perPage: number
  totalItems: number
  totalPages: number
  items: T[]
}

type RequestOptions = RequestInit & {
  params?: Record<string, string | number | boolean | undefined>
  query?: Record<string, string | number | boolean | undefined>
  responseType?: "json" | "blob" | "text"
}

type AuthSnapshot = {
  token: string
  refreshToken?: string
  record: JsonRecord | null
  model: JsonRecord | null
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

type ExpandConfig = {
  collection: string
  many?: boolean
}

const RELATION_MAP: Record<string, Record<string, ExpandConfig>> = {
  drugs: {
    drug_class: { collection: "drug_classes" },
    therapeutic_category: { collection: "therapeutic_categories" },
  },
  faqs: {
    author: { collection: "users" },
    reviewer: { collection: "users" },
    tags: { collection: "faq_tags", many: true },
    related_faqs: { collection: "faqs", many: true },
  },
}

class BackendAuthStore {
  token = ""
  refreshToken = ""
  record: JsonRecord | null = null
  model: JsonRecord | null = null
  private listeners = new Set<() => void>()

  get isValid() {
    return Boolean(this.token && this.record)
  }

  save(token: string, record: JsonRecord | null, refreshToken = "") {
    this.token = token
    this.refreshToken = refreshToken
    this.record = record
    this.model = record
    this.emit()
  }

  clear() {
    this.token = ""
    this.refreshToken = ""
    this.record = null
    this.model = null
    this.emit()
  }

  exportToCookie(): string {
    const snapshot: AuthSnapshot = {
      token: this.token,
      refreshToken: this.refreshToken,
      record: this.record,
      model: this.model,
    }
    const value = encodeURIComponent(JSON.stringify(snapshot))
    return `${AUTH_COOKIE_NAME}=${value}; Path=/; SameSite=Lax`
  }

  loadFromCookie(cookie: string) {
    const parsed = parseCookie(cookie, AUTH_COOKIE_NAME)
    if (!parsed) return
    try {
      const snapshot = JSON.parse(decodeURIComponent(parsed)) as AuthSnapshot
      this.token = snapshot.token || ""
      this.refreshToken = snapshot.refreshToken || ""
      this.record = snapshot.record || null
      this.model = snapshot.model || snapshot.record || null
    } catch {
      this.clear()
    }
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

class ResourceClient {
  constructor(
    private readonly client: BackendClient,
    private readonly name: string
  ) {}

  async requestPasswordReset(_email: string) {
    return { success: true }
  }

  async confirmPasswordReset(
    _token: string,
    _password: string,
    _passwordConfirm: string
  ) {
    return { success: true }
  }

  async requestVerification(_email: string) {
    return { success: true }
  }

  async getList<T = any>(
    page = 1,
    perPage = 20,
    options: {
      filter?: string
      sort?: string
      expand?: string
      fields?: string
    } = {}
  ): Promise<ListResult<T>> {
    const records = await this.fetchAllRecords(options.fields)
    const filtered = records.filter((record) => matchesFilter(record, options.filter))
    const sorted = sortRecords(filtered, options.sort)
    const paged = sorted.slice((page - 1) * perPage, page * perPage)
    const items = await this.client.expandRecords(this.name, paged, options.expand)

    return {
      page,
      perPage,
      totalItems: sorted.length,
      totalPages: Math.max(1, Math.ceil(sorted.length / perPage)),
      items: items as T[],
    }
  }

  async getFullList<T = any>(options: {
    filter?: string
    sort?: string
    expand?: string
    fields?: string
  } = {}): Promise<T[]> {
    const result = await this.getList<T>(1, Number.MAX_SAFE_INTEGER, options)
    return result.items
  }

  async getFirstListItem<T = any>(filter: string): Promise<T> {
    const result = await this.getList<T>(1, 1, { filter })
    if (!result.items[0]) {
      throw new Error(`No ${this.name} record matched the requested filter`)
    }
    return result.items[0]
  }

  async getOne<T = any>(
    id: string,
    options: { expand?: string; fields?: string } = {}
  ): Promise<T> {
    if (this.name === "calculators") {
      const item = await this.client.request<JsonRecord>(`/api/v2/calculators/${id}`)
      return normalizeRecord(this.name, item) as T
    }
    const domainPath = DOMAIN_COLLECTION_PATHS[this.name]
    if (domainPath) {
      const item = await this.client.request<JsonRecord>(`${domainPath}/${id}`)
      return normalizeRecord(this.name, item) as T
    }
    throw new BackendRequestError(
      `No typed backend endpoint is registered for ${this.name}`,
      501,
    )
  }

  async create<T = any>(data: JsonRecord): Promise<T> {
    if (this.name === "calculator_requests") {
      return {
        id: crypto.randomUUID(),
        ...data,
        created: new Date().toISOString(),
        updated: new Date().toISOString(),
      } as T
    }
    if (this.name === "calculators") {
      const item = await this.client.request<JsonRecord>("/api/v2/calculators", {
        method: "POST",
        body: JSON.stringify(await calculatorPayload(data, true)),
      })
      return normalizeRecord(this.name, item) as T
    }
    const domainPath = DOMAIN_COLLECTION_PATHS[this.name]
    if (domainPath) {
      const item = await this.client.request<JsonRecord>(domainPath, {
        method: "POST",
        body: JSON.stringify(data),
      })
      return normalizeRecord(this.name, item) as T
    }

    throw new BackendRequestError(
      `No typed backend endpoint is registered for ${this.name}`,
      501,
    )
  }

  async update<T = any>(id: string, data: JsonRecord): Promise<T> {
    if (this.name === "calculator_requests") {
      return {
        id,
        ...data,
        updated: new Date().toISOString(),
      } as T
    }
    if (this.name === "calculators") {
      const item = await this.client.request<JsonRecord>(`/api/v2/calculators/${id}`, {
        method: "PATCH",
        body: JSON.stringify(await calculatorPayload(data, false)),
      })
      return normalizeRecord(this.name, item) as T
    }
    const domainPath = DOMAIN_COLLECTION_PATHS[this.name]
    if (domainPath) {
      const item = await this.client.request<JsonRecord>(`${domainPath}/${id}`, {
        method: "PATCH",
        body: JSON.stringify(data),
      })
      return normalizeRecord(this.name, item) as T
    }

    throw new BackendRequestError(
      `No typed backend endpoint is registered for ${this.name}`,
      501,
    )
  }

  async delete(id: string): Promise<boolean> {
    if (this.name === "calculators") {
      await this.client.request<void>(`/api/v2/calculators/${id}`, {
        method: "DELETE",
        responseType: "text",
      })
      return true
    }
    const domainPath = DOMAIN_COLLECTION_PATHS[this.name]
    if (domainPath) {
      await this.client.request<void>(`${domainPath}/${id}`, {
        method: "DELETE",
        responseType: "text",
      })
      return true
    }
    throw new BackendRequestError(
      `No typed backend endpoint is registered for ${this.name}`,
      501,
    )
  }

  subscribe(
    _topic: string,
    _callback: (event: { action: string; record: JsonRecord }) => void,
    _options?: { expand?: string; fields?: string }
  ) {
    return Promise.resolve(() => {})
  }

  unsubscribe(_topic?: string) {
    return Promise.resolve()
  }

  private async fetchAllRecords(fields?: string) {
    const all: JsonRecord[] = []
    let page = 1

    while (true) {
      if (this.name === "calculators") {
        const response = await this.client.request<{
          items: JsonRecord[]
          page: number
          per_page: number
          total_items: number
        }>("/api/v2/calculators", {
          query: {
            page,
            per_page: LIST_PAGE_SIZE,
            sort: "name",
          },
        })
        const items = (response.items || []).map((item) => normalizeRecord(this.name, item))
        all.push(...items)
        const totalItems = Number(response.total_items || 0)
        if (all.length >= totalItems || items.length === 0) break
        page += 1
        continue
      }
      const domainPath = DOMAIN_COLLECTION_PATHS[this.name]
      if (domainPath) {
        const response = await this.client.request<{
          items: JsonRecord[]
          page: number
          per_page: number
          total_items: number
        }>(domainPath, {
          query: { page, per_page: LIST_PAGE_SIZE, sort: "name", order: "asc" },
        })
        const items = (response.items || []).map((item) => normalizeRecord(this.name, item))
        all.push(...items)
        const totalItems = Number(response.total_items || 0)
        if (all.length >= totalItems || items.length === 0) break
        page += 1
        continue
      }
      throw new BackendRequestError(
        `No typed backend endpoint is registered for ${this.name}`,
        501,
      )
    }

    return all
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

  private readonly resources = new Map<string, ResourceClient>()
  private readonly relationCache = new Map<string, Map<string, JsonRecord>>()

  autoCancellation(_enabled: boolean) {}

  resource(name: string) {
    if (!this.resources.has(name)) {
      this.resources.set(name, new ResourceClient(this, name))
    }
    return this.resources.get(name)!
  }

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

  async currentUser() {
    const user = await this.request<JsonRecord>("/api/v2/me")
    const record = normalizeRecord("users", user)
    this.authStore.save(
      this.authStore.token,
      record,
      this.authStore.refreshToken,
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

  async expandRecords(collection: string, records: JsonRecord[], expand?: string) {
    if (!expand || records.length === 0) return records
    const requested = expand.split(",").map((field) => field.trim()).filter(Boolean)
    const relationMap = RELATION_MAP[collection] || {}

    for (const field of requested) {
      const relation = relationMap[field]
      if (!relation) continue

      const relatedIndex = await this.loadCollectionIndex(relation.collection)
      for (const record of records) {
        if (!record.expand || typeof record.expand !== "object") {
          record.expand = {}
        }

        const current = record[field]
        if (relation.many) {
          const ids = Array.isArray(current) ? current : []
          ;(record.expand as JsonRecord)[field] = ids
            .map((id) => relatedIndex.get(String(id)))
            .filter(Boolean)
        } else if (current) {
          ;(record.expand as JsonRecord)[field] = relatedIndex.get(String(current)) || null
        }
      }
    }

    return records
  }

  private async loadCollectionIndex(collection: string) {
    const cacheKey = `${collection}:${this.authStore.token}`
    const cached = this.relationCache.get(cacheKey)
    if (cached) return cached

    const list = await this.resource(collection).getFullList<JsonRecord>()
    const index = new Map<string, JsonRecord>()
    for (const item of list) {
      index.set(String(item.id), item)
    }
    this.relationCache.set(cacheKey, index)
    return index
  }

  private saveSession(session: AuthSession) {
    const token = session.token.startsWith("Bearer ")
      ? session.token
      : `Bearer ${session.token}`
    const record = normalizeRecord("users", session.user)
    this.authStore.save(token, record, session.refresh_token)
    return { token, record, session }
  }
}

let backendClientInstance: BackendClient | null = null

export function createBackendClient(): BackendClient {
  if (backendClientInstance) return backendClientInstance

  const client = new BackendClient()
  if (typeof document !== "undefined") {
    client.authStore.loadFromCookie(document.cookie || "")
    client.authStore.onChange(() => {
      document.cookie = client.authStore.exportToCookie()
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

  if (collection === "calculators") {
    const artifact = parseJSONValue(raw.app_file_json)
    normalized.appFileJson = artifact
    normalized.appFile = calculatorArtifactPath(artifact)
    normalized.addedBy = raw.added_by_user_id
  }

  if (!normalized.created && normalized.created_at) {
    normalized.created = normalized.created_at
  }
  if (!normalized.updated && normalized.updated_at) {
    normalized.updated = normalized.updated_at
  }

  return normalized
}

async function calculatorPayload(
  input: JsonRecord | FormData,
  requireArtifact: boolean,
): Promise<JsonRecord> {
  const values: JsonRecord = {}
  if (input instanceof FormData) {
    for (const [key, value] of input.entries()) {
      values[key] = value
    }
  } else {
    Object.assign(values, input)
  }

  const payload: JsonRecord = {}
  const stringFields: Record<string, string> = {
    name: "name",
    description: "description",
    icon: "icon",
    color: "color",
    backgroundColor: "background_color",
    version: "version",
    type: "type",
    status: "status",
  }
  for (const [source, target] of Object.entries(stringFields)) {
    if (values[source] !== undefined && values[source] !== null) {
      payload[target] = String(values[source])
    }
  }
  if (values.featured !== undefined) {
    payload.featured = values.featured === true || String(values.featured) === "true"
  }

  const artifact = values.app_file_json ?? values.appFile ?? values.app_file
  if (typeof File !== "undefined" && artifact instanceof File) {
    const content = await artifact.text()
    if (artifact.name.toLowerCase().endsWith(".html")) {
      payload.app_file_json = {
        name: artifact.name,
        path: artifact.name,
        html: content,
      }
    } else {
      let parsed: unknown
      try {
        parsed = JSON.parse(content)
      } catch {
        throw new Error("Calculator artifact must be an HTML file or valid JSON")
      }
      payload.app_file_json = parsed
    }
  } else if (typeof artifact === "string" && artifact.trim()) {
    payload.app_file_json = { path: artifact.trim(), name: artifact.trim() }
  } else if (artifact && typeof artifact === "object") {
    payload.app_file_json = artifact
  } else if (requireArtifact) {
    throw new Error("Calculator artifact is required")
  }

  return payload
}

function calculatorArtifactPath(value: unknown): string {
  if (typeof value === "string") return value
  if (!value || typeof value !== "object") return ""
  const record = value as JsonRecord
  return typeof record.path === "string"
    ? record.path
    : typeof record.name === "string"
      ? record.name
      : ""
}

function parseJSONValue(value: unknown) {
  if (typeof value !== "string") return value
  try {
    return JSON.parse(value)
  } catch {
    return value
  }
}

function matchesFilter(record: JsonRecord, filter?: string): boolean {
  if (!filter || !filter.trim()) return true
  const expression = stripOuterParens(filter.trim())

  const orParts = splitTopLevel(expression, "||")
  if (orParts.length > 1) {
    return orParts.some((part) => matchesFilter(record, part))
  }

  const andParts = splitTopLevel(expression, "&&")
  if (andParts.length > 1) {
    return andParts.every((part) => matchesFilter(record, part))
  }

  return evaluateCondition(record, expression)
}

function evaluateCondition(record: JsonRecord, condition: string): boolean {
  const trimmed = stripOuterParens(condition.trim())
  const match = trimmed.match(/^(.+?)(>=|<=|!=|=|>|<|~)(.+)$/)
  if (!match) return true

  const [, rawField, operator, rawValue] = match
  const field = rawField.trim()
  const expected = parseFilterValue(rawValue.trim())
  const actual = getPathValue(record, field)

  switch (operator) {
    case "=":
      return compareValue(actual, expected)
    case "!=":
      return !compareValue(actual, expected)
    case "~":
      return containsValue(actual, expected)
    case ">":
      return compareComparable(actual, expected) > 0
    case ">=":
      return compareComparable(actual, expected) >= 0
    case "<":
      return compareComparable(actual, expected) < 0
    case "<=":
      return compareComparable(actual, expected) <= 0
    default:
      return true
  }
}

function sortRecords(records: JsonRecord[], sort?: string) {
  if (!sort) return [...records]
  const fields = sort.split(",").map((part) => part.trim()).filter(Boolean)
  return [...records].sort((left, right) => {
    for (const field of fields) {
      const desc = field.startsWith("-")
      const key = desc ? field.slice(1) : field
      const result = compareComparable(getPathValue(left, key), getPathValue(right, key))
      if (result !== 0) {
        return desc ? -result : result
      }
    }
    return 0
  })
}

function compareValue(actual: unknown, expected: unknown): boolean {
  if (Array.isArray(actual)) {
    return actual.some((item) => compareValue(item, expected))
  }
  if (actual === null || actual === undefined) {
    return expected === "" || expected === null
  }
  return String(actual) === String(expected)
}

function containsValue(actual: unknown, expected: unknown): boolean {
  if (Array.isArray(actual)) {
    return actual.some((item) => String(item) === String(expected))
  }
  if (actual === null || actual === undefined) return false
  const actualText = String(actual).toLowerCase()
  const expectedText = String(expected).toLowerCase()
  if (expectedText.startsWith("^")) {
    return actualText.startsWith(expectedText.slice(1))
  }
  if (expectedText.endsWith("$")) {
    return actualText.endsWith(expectedText.slice(0, -1))
  }
  return actualText.includes(expectedText)
}

function compareComparable(left: unknown, right: unknown) {
  const leftDate = toTime(left)
  const rightDate = toTime(right)
  if (leftDate !== null && rightDate !== null) {
    return leftDate - rightDate
  }

  const leftNumber = Number(left)
  const rightNumber = Number(right)
  if (!Number.isNaN(leftNumber) && !Number.isNaN(rightNumber)) {
    return leftNumber - rightNumber
  }

  return String(left ?? "").localeCompare(String(right ?? ""))
}

function toTime(value: unknown) {
  if (typeof value !== "string") return null
  const timestamp = Date.parse(value)
  return Number.isNaN(timestamp) ? null : timestamp
}

function parseFilterValue(value: string) {
  const trimmed = value.trim()
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1)
  }
  if (trimmed === "true") return true
  if (trimmed === "false") return false
  if (trimmed === "null") return null
  const numeric = Number(trimmed)
  if (!Number.isNaN(numeric)) return numeric
  return trimmed
}

function stripOuterParens(value: string) {
  let current = value.trim()
  while (current.startsWith("(") && current.endsWith(")") && isBalanced(current.slice(1, -1))) {
    current = current.slice(1, -1).trim()
  }
  return current
}

function splitTopLevel(value: string, separator: "&&" | "||") {
  const parts: string[] = []
  let depth = 0
  let quote = ""
  let start = 0

  for (let index = 0; index < value.length; index += 1) {
    const char = value[index]
    const next = value[index + 1]

    if (quote) {
      if (char === quote) quote = ""
      continue
    }
    if (char === '"' || char === "'") {
      quote = char
      continue
    }
    if (char === "(") depth += 1
    if (char === ")") depth -= 1

    if (depth === 0 && char === separator[0] && next === separator[1]) {
      parts.push(value.slice(start, index).trim())
      start = index + 2
      index += 1
    }
  }

  if (parts.length === 0) return [value]
  parts.push(value.slice(start).trim())
  return parts.filter(Boolean)
}

function isBalanced(value: string) {
  let depth = 0
  let quote = ""
  for (const char of value) {
    if (quote) {
      if (char === quote) quote = ""
      continue
    }
    if (char === '"' || char === "'") {
      quote = char
      continue
    }
    if (char === "(") depth += 1
    if (char === ")") depth -= 1
    if (depth < 0) return false
  }
  return depth === 0
}

function getPathValue(record: JsonRecord, path: string) {
  return path.split(".").reduce<unknown>((current, segment) => {
    if (!current || typeof current !== "object") return undefined
    return (current as JsonRecord)[segment]
  }, record)
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

async function extractError(response: Response) {
  try {
    const payload = (await response.json()) as { error?: string; message?: string }
    return payload.error || payload.message || `Request failed with status ${response.status}`
  } catch {
    return `Request failed with status ${response.status}`
  }
}
