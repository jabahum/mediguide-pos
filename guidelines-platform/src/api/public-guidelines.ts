import { publicApiBaseUrl } from "../config";

export type PublicGuideline = {
  id: string;
  slug: string;
  title: string;
  description: string;
  country: string;
  source_org: string;
  program_area: string;
  language: string;
  publication_date: string;
  review_date: string;
  version: string;
  last_updated: string;
};

export type PublicGuidelinePage = {
  items: PublicGuideline[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
};

type ApiEnvelope<T> = {
  success: boolean;
  data?: T;
  error?: string;
};

export type PublicGuidelineFilters = {
  search?: string;
  programArea?: string;
  country?: string;
  language?: string;
  page?: number;
  perPage?: number;
};

export type GuidelineExtractionQuality =
  | "reviewed"
  | "partially_reviewed"
  | "unreviewed"
  | "markdown_fallback";

export type PublicGuidelineManifest = {
  guideline_id: string;
  version_id: string;
  version: string;
  schema_version: number;
  package_version: number;
  extraction_quality: GuidelineExtractionQuality;
  has_chapters: boolean;
  has_key_points: boolean;
  has_tables: boolean;
  has_figures: boolean;
  has_algorithms: boolean;
  has_original_pdf: boolean;
  has_offline_package: boolean;
  section_count: number;
  reviewed_section_count?: number;
  leaf_section_count?: number;
  reviewed_leaf_section_count?: number;
  empty_leaf_section_count?: number;
  block_count: number;
  reviewed_paragraph_count?: number;
  table_count: number;
  figure_count: number;
  algorithm_count: number;
  checksum: string;
  etag: string;
  generated_at: string;
};

export type PublicGuidelineSection = {
  id: string;
  parent_id?: string;
  title: string;
  slug: string;
  level: number;
  page_start?: number;
  page_end?: number;
  sort_order: number;
};

export type PublicGuidelineBlockType =
  | "heading"
  | "paragraph"
  | "ordered_list"
  | "unordered_list"
  | "table"
  | "figure"
  | "recommendation"
  | "warning"
  | "caution"
  | "key_point"
  | "contraindication"
  | "dosage"
  | "evidence"
  | "definition"
  | "procedure"
  | "algorithm_reference"
  | "clinical_note"
  | "referral_criteria"
  | "algorithm"
  | "reference"
  | "page_break"
  | "unknown"
  | (string & Record<never, never>);

export type PublicGuidelineBlock = {
  id: string;
  section_id?: string;
  type: PublicGuidelineBlockType;
  sort_order: number;
  content: Record<string, unknown>;
  page_start?: number;
  page_end?: number;
};

export type PublicGuidelineSectionDetail = {
  guideline_id: string;
  version_id: string;
  package_version: number;
  checksum: string;
  section: PublicGuidelineSection;
  blocks: PublicGuidelineBlock[];
};

export type PublicGuidelineContent = {
  guideline_id: string;
  version_id: string;
  package_version: number;
  checksum: string;
  sections: PublicGuidelineSection[];
  blocks: PublicGuidelineBlock[];
};

export type PublicGuidelineTable = {
  id: string;
  section_id?: string;
  sort_order: number;
  page_start?: number;
  page_end?: number;
  content: {
    type: string;
    title?: string;
    columns: string[];
    rows: string[][];
    footnotes: string[];
  };
};

export type PublicGuidelineAssetLink = {
  asset_id?: string;
  type: string;
  mime_type: string;
  checksum?: string;
  size_bytes?: number;
  original_filename?: string;
  url: string;
  expires_at: string;
};

export type PublicGuidelineFigure = {
  id: string;
  section_id?: string;
  sort_order: number;
  page_start?: number;
  page_end?: number;
  content: {
    type: string;
    asset_id: string;
    caption?: string;
    alternative_text: string;
  };
  asset: PublicGuidelineAssetLink;
};

export type PublicGuidelineAlgorithm = {
  id: string;
  section_id?: string;
  sort_order: number;
  page_start?: number;
  page_end?: number;
  content: {
    type: string;
    title?: string;
    nodes: Array<{ id: string; label: string; kind: string; next?: string[] }>;
  };
};

export type PublicMarkdown = {
  content: string;
  etag?: string;
  lastModified?: string;
  fromCache: boolean;
};

export type PublicAICitation = {
  chunk_id: string;
  guideline_id?: string;
  guideline_version_id?: string;
  section_id?: string;
  block_id?: string;
  content_type?: string;
  route?: string;
  title: string;
  source_name: string;
  source_version: string;
  page_start?: number;
  page_end?: number;
  categories?: DiscoveryFacet[];
  diseases?: DiscoveryFacet[];
  hubs?: DiscoveryFacet[];
  pillars?: DiscoveryFacet[];
  metadata?: Record<string, unknown>;
};

export type PublicAIAnswer = {
  answer: string;
  citations: PublicAICitation[];
  session_id?: string;
  search_scope?: string;
  coverage_notice?: string;
};

export type DiscoveryFacet = { id: string; name: string; slug?: string };
export type PublicResource = {
  id: string; content_type: string; title: string; description?: string; route?: string;
  source_organization?: string; issuing_authority?: string; version?: string;
  publication_date?: string; effective_at?: string; review_at?: string; expires_at?: string;
  review_state?: string; provenance?: string;
};
export type PublicPillarItem = {
  id: string; content_type: string; label_override?: string; description_override?: string;
  icon_override?: string; sort_order: number; featured: boolean; resource?: PublicResource;
};
export type PublicPillar = {
  id: string; parent_id?: string; name: string; slug: string; description?: string;
  icon?: string; color?: string; sort_order: number; items: PublicPillarItem[]; children: PublicPillar[];
};
export type PublicHub = {
  id: string; name: string; slug: string; description?: string; icon?: string; color?: string;
  audience?: string; published_at?: string; diseases: DiscoveryFacet[]; pillars?: PublicPillar[];
  outbreak?: { id: string; title: string; status: string; disease_type?: string; geographic_area?: string;
    summary?: string; source_organization?: string; data_as_of?: string; last_verified_at?: string;
    metrics?: Array<Record<string, unknown>> };
};
export type PublicDiseaseSummary = DiscoveryFacet & {
  parent_id?: string; short_name?: string; description?: string; icon?: string; color?: string; sort_order: number;
};
export type PublicDisease = PublicDiseaseSummary & {
  aliases: string[]; codes: Array<{ code_system: string; code: string; display_name?: string }>;
  children: PublicDiseaseSummary[]; hubs: PublicHub[]; resources: PublicResource[];
};
export type PublicDiseasePage = { items: PublicDiseaseSummary[]; page: number; per_page: number; total_items: number; total_pages: number };
export type PublicHubPage = { items: PublicHub[]; page: number; per_page: number; total_items: number; total_pages: number };
export type PublicSearchResult = PublicResource & {
  result_type: string; guideline_id?: string; section_id?: string; block_id?: string;
  snippet: string; source_name: string; source_version: string; status?: string;
  categories?: DiscoveryFacet[]; diseases?: DiscoveryFacet[]; hubs?: DiscoveryFacet[]; pillars?: DiscoveryFacet[];
  metadata?: Record<string, unknown>;
};
export type PublicSearchFilters = { categoryId?: string; diseaseSlug?: string; hubSlug?: string; pillarSlug?: string; contentType?: string; limit?: number };

export type PublicApiErrorKind =
  | "not-found"
  | "timeout"
  | "network"
  | "rate-limited"
  | "server"
  | "invalid-response";

export class PublicApiError extends Error {
  readonly kind: PublicApiErrorKind;
  readonly status?: number;
  readonly retryAfterSeconds?: number;

  constructor(
    kind: PublicApiErrorKind,
    status?: number,
    retryAfterSeconds?: number,
  ) {
    super(
      kind === "not-found"
        ? "Guideline not found"
        : kind === "rate-limited"
          ? `Too many requests. Try again${retryAfterSeconds === undefined ? " shortly" : ` in ${retryAfterSeconds} seconds`}.`
          : "Unable to load guideline",
    );
    this.name = "PublicApiError";
    this.kind = kind;
    this.status = status;
    this.retryAfterSeconds = retryAfterSeconds;
  }
}

const requestTimeoutMs = 12_000;
const markdownCache = new Map<string, PublicMarkdown>();
const listCache = new Map<string, CacheEntry<PublicGuidelinePage>>();
const detailCache = new Map<string, CacheEntry<PublicGuideline>>();
const structuredCache = new Map<string, ConditionalCacheEntry<unknown>>();
const manifestIdentityByGuideline = new Map<string, string>();
const inFlight = new Map<string, Promise<unknown>>();
const maxCachedDocuments = 8;
const maxCachedLists = 16;
const maxCachedDetails = 40;
const listTtlMs = 60_000;
const detailTtlMs = 5 * 60_000;

type CacheEntry<T> = { value: T; expiresAt: number };
type ConditionalCacheEntry<T> = {
  value: T;
  etag?: string;
  lastModified?: string;
};

function publicUrl(path: string, query?: URLSearchParams) {
  const suffix = query?.size ? `?${query.toString()}` : "";
  return `${publicApiBaseUrl}/api/public${path}${suffix}`;
}

async function request(
  url: string,
  options: RequestInit = {},
  externalSignal?: AbortSignal,
) {
  const controller = new AbortController();
  const timeout = globalThis.setTimeout(() => controller.abort("timeout"), requestTimeoutMs);
  const abort = () => controller.abort(externalSignal?.reason);
  externalSignal?.addEventListener("abort", abort, { once: true });

  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (error) {
    if (controller.signal.aborted) {
      if (externalSignal?.aborted) throw error;
      throw new PublicApiError("timeout");
    }
    throw new PublicApiError("network");
  } finally {
    globalThis.clearTimeout(timeout);
    externalSignal?.removeEventListener("abort", abort);
  }
}

async function requestJson<T>(url: string, signal?: AbortSignal): Promise<T> {
  const response = await request(url, { headers: { Accept: "application/json" } }, signal);
  if (response.status === 404) throw new PublicApiError("not-found", 404);
  if (response.status === 429) {
    throw new PublicApiError("rate-limited", 429, parseRetryAfter(response.headers.get("Retry-After")));
  }
  if (!response.ok) throw new PublicApiError("server", response.status);
  let envelope: ApiEnvelope<T>;
  try {
    envelope = (await response.json()) as ApiEnvelope<T>;
  } catch {
    throw new PublicApiError("invalid-response", response.status);
  }
  if (!envelope.success || envelope.data === undefined) {
    throw new PublicApiError("invalid-response", response.status);
  }
  return envelope.data;
}

async function postJson<T>(url: string, body: unknown, signal?: AbortSignal): Promise<T> {
  const response = await request(url, {
    method: "POST",
    headers: { Accept: "application/json", "Content-Type": "application/json" },
    body: JSON.stringify(body),
  }, signal);
  if (response.status === 404) throw new PublicApiError("not-found", 404);
  if (response.status === 429) throw new PublicApiError("rate-limited", 429, parseRetryAfter(response.headers.get("Retry-After")));
  if (!response.ok) throw new PublicApiError(response.status >= 500 ? "server" : "invalid-response", response.status);
  let envelope: ApiEnvelope<T>;
  try { envelope = (await response.json()) as ApiEnvelope<T>; } catch { throw new PublicApiError("invalid-response", response.status); }
  if (!envelope.success || envelope.data === undefined) throw new PublicApiError("invalid-response", response.status);
  return envelope.data;
}

async function requestConditionalJson<T>(
  url: string,
  validate: (value: unknown) => value is T,
  signal?: AbortSignal,
  cacheKey = url,
): Promise<T> {
  const cached = structuredCache.get(cacheKey) as ConditionalCacheEntry<T> | undefined;
  const headers: Record<string, string> = { Accept: "application/json" };
  if (cached?.etag) headers["If-None-Match"] = cached.etag;
  if (!cached?.etag && cached?.lastModified) {
    headers["If-Modified-Since"] = cached.lastModified;
  }
  const response = await request(url, { headers }, signal);
  if (response.status === 304 && cached) return cached.value;
  if (response.status === 404) throw new PublicApiError("not-found", 404);
  if (response.status === 429) {
    throw new PublicApiError("rate-limited", 429, parseRetryAfter(response.headers.get("Retry-After")));
  }
  if (!response.ok) throw new PublicApiError("server", response.status);
  let envelope: ApiEnvelope<unknown>;
  try {
    envelope = (await response.json()) as ApiEnvelope<unknown>;
  } catch {
    throw new PublicApiError("invalid-response", response.status);
  }
  if (!envelope.success || !validate(envelope.data)) {
    throw new PublicApiError("invalid-response", response.status);
  }
  rememberConditional(cacheKey, {
    value: envelope.data,
    etag: response.headers.get("ETag") ?? undefined,
    lastModified: response.headers.get("Last-Modified") ?? undefined,
  });
  return envelope.data;
}

function rememberConditional<T>(key: string, value: ConditionalCacheEntry<T>) {
  structuredCache.delete(key);
  structuredCache.set(key, value);
  while (structuredCache.size > 80) {
    const oldest = structuredCache.keys().next().value;
    if (oldest === undefined) break;
    structuredCache.delete(oldest);
  }
}

function parseRetryAfter(value: string | null): number | undefined {
  if (!value) return undefined;
  const seconds = Number(value);
  if (Number.isFinite(seconds) && seconds >= 0) return Math.ceil(seconds);
  const date = Date.parse(value);
  if (Number.isNaN(date)) return undefined;
  return Math.max(0, Math.ceil((date - Date.now()) / 1000));
}

function cached<T>(cache: Map<string, CacheEntry<T>>, key: string): T | undefined {
  const entry = cache.get(key);
  if (!entry) return undefined;
  if (entry.expiresAt <= Date.now()) {
    cache.delete(key);
    return undefined;
  }
  cache.delete(key);
  cache.set(key, entry);
  return entry.value;
}

function remember<T>(cache: Map<string, CacheEntry<T>>, key: string, value: T, ttlMs: number, maximum: number) {
  cache.delete(key);
  cache.set(key, { value, expiresAt: Date.now() + ttlMs });
  while (cache.size > maximum) {
    const oldest = cache.keys().next().value;
    if (oldest === undefined) break;
    cache.delete(oldest);
  }
}

function deduplicated<T>(key: string, load: () => Promise<T>): Promise<T> {
  const existing = inFlight.get(key) as Promise<T> | undefined;
  if (existing) return existing;
  const pending = load().finally(() => inFlight.delete(key));
  inFlight.set(key, pending);
  return pending;
}

export function listPublicGuidelines(
  filters: PublicGuidelineFilters = {},
  signal?: AbortSignal,
) {
  const query = new URLSearchParams();
  if (filters.search?.trim()) query.set("search", filters.search.trim());
  if (filters.programArea) query.set("program_area", filters.programArea);
  if (filters.country) query.set("country", filters.country);
  if (filters.language) query.set("language", filters.language);
  if (filters.page) query.set("page", String(filters.page));
  if (filters.perPage) query.set("per_page", String(filters.perPage));
  const url = publicUrl("/guidelines", query);
  const hit = cached(listCache, url);
  if (hit) return Promise.resolve(hit);
  const load = async () => {
    const value = await requestJson<PublicGuidelinePage>(url, signal);
    remember(listCache, url, value, listTtlMs, maxCachedLists);
    return value;
  };
  return signal ? load() : deduplicated(`list:${url}`, load);
}

export function getPublicGuideline(id: string, signal?: AbortSignal) {
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}`);
  const hit = cached(detailCache, url);
  if (hit) return Promise.resolve(hit);
  const load = async () => {
    const value = await requestJson<PublicGuideline>(url, signal);
    remember(detailCache, url, value, detailTtlMs, maxCachedDetails);
    return value;
  };
  return signal ? load() : deduplicated(`detail:${url}`, load);
}

export function getPublicGuidelineManifest(id: string, signal?: AbortSignal) {
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/manifest`);
  const load = async () => {
    const manifest = await requestConditionalJson(url, isManifest, signal);
    const identity = publicationIdentity(manifest);
    const previous = manifestIdentityByGuideline.get(id);
    if (previous && previous !== identity) {
      invalidateGuidelineStructuredCache(id, url);
    }
    manifestIdentityByGuideline.set(id, identity);
    return manifest;
  };
  return signal ? load() : deduplicated(`manifest:${url}`, load);
}

export async function getPublicGuidelineContent(
  id: string,
  manifest: PublicGuidelineManifest,
  signal?: AbortSignal,
) {
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/content`);
  const identity = publicationIdentity(manifest);
  const value = await requestConditionalJson(
    url,
    isContent,
    signal,
    `${url}#${identity}`,
  );
  assertPublicationIdentity(value, manifest);
  return value;
}

export function listPublicGuidelineSections(id: string, signal?: AbortSignal) {
  const query = new URLSearchParams({ page: "1", per_page: "500", sort: "sort_order", order: "asc" });
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/sections`, query);
  const load = () => requestConditionalJson(url, isSectionPage, signal);
  return signal ? load() : deduplicated(`sections:${url}`, load);
}

export async function getPublicGuidelineSection(id: string, sectionId: string, manifest: PublicGuidelineManifest, signal?: AbortSignal) {
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/sections/${encodeURIComponent(sectionId)}`);
  const identity = publicationIdentity(manifest);
  const load = () => requestConditionalJson(url, isSectionDetail, signal, `${url}#${identity}`);
  const value = signal ? await load() : await deduplicated(`section:${url}:${identity}`, load);
  assertPublicationIdentity(value, manifest);
  return value;
}

export function listPublicGuidelineTables(id: string, signal?: AbortSignal) {
  return listTypedContent(id, "tables", isTablePage, signal);
}

export function listPublicGuidelineFigures(id: string, signal?: AbortSignal) {
  return listTypedContent(id, "figures", isFigurePage, signal);
}

export function listPublicGuidelineAlgorithms(id: string, signal?: AbortSignal) {
  return listTypedContent(id, "algorithms", isAlgorithmPage, signal);
}

function listTypedContent<T>(
  id: string,
  kind: "tables" | "figures" | "algorithms",
  validate: (value: unknown) => value is PublicGuidelinePageOf<T>,
  signal?: AbortSignal,
) {
  const query = new URLSearchParams({ page: "1", per_page: "200", sort: "sort_order", order: "asc" });
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/${kind}`, query);
  const load = () => requestConditionalJson(url, validate, signal);
  return signal ? load() : deduplicated(`${kind}:${url}`, load);
}

export function getPublicGuidelineOriginal(id: string, signal?: AbortSignal) {
  return requestJson<PublicGuidelineAssetLink>(
    publicUrl(`/guidelines/${encodeURIComponent(id)}/original`), signal,
  ).then((value) => {
    if (!isAssetLink(value)) throw new PublicApiError("invalid-response");
    return value;
  });
}

export function getPublicGuidelineOfflinePackage(id: string, signal?: AbortSignal) {
  return requestJson<PublicGuidelineAssetLink>(
    publicUrl(`/guidelines/${encodeURIComponent(id)}/offline-package`), signal,
  ).then((value) => {
    if (!isAssetLink(value)) throw new PublicApiError("invalid-response");
    return value;
  });
}

export async function getPublicGuidelineMarkdown(
  id: string,
  signal?: AbortSignal,
): Promise<PublicMarkdown> {
  const cacheKey = id;
  const cached = markdownCache.get(cacheKey);
  const headers: HeadersInit = { Accept: "text/markdown" };
  if (cached?.etag) headers["If-None-Match"] = cached.etag;

  const response = await request(
    publicUrl(`/guidelines/${encodeURIComponent(id)}/markdown`),
    { headers },
    signal,
  );
  if (response.status === 304 && cached) {
    markdownCache.delete(cacheKey);
    markdownCache.set(cacheKey, cached);
    return { ...cached, fromCache: true };
  }
  if (response.status === 404) throw new PublicApiError("not-found", 404);
  if (response.status === 429) {
    throw new PublicApiError("rate-limited", 429, parseRetryAfter(response.headers.get("Retry-After")));
  }
  if (!response.ok) throw new PublicApiError("server", response.status);

  const result: PublicMarkdown = {
    content: await response.text(),
    etag: response.headers.get("ETag") ?? undefined,
    lastModified: response.headers.get("Last-Modified") ?? undefined,
    fromCache: false,
  };
  markdownCache.set(cacheKey, result);
  while (markdownCache.size > maxCachedDocuments) {
    const oldest = markdownCache.keys().next().value;
    if (oldest === undefined) break;
    markdownCache.delete(oldest);
  }
  return result;
}

export async function askPublicGuideline(
  id: string,
  question: string,
  signal?: AbortSignal,
): Promise<PublicAIAnswer> {
  const answer = await postJson<unknown>(
    publicUrl(`/guidelines/${encodeURIComponent(id)}/ask`),
    { question: question.trim() },
    signal,
  );
  if (!isAIAnswer(answer)) throw new PublicApiError("invalid-response");
  return answer;
}

async function requestDiscovery<T>(key: string, url: string, signal?: AbortSignal): Promise<T & { offline?: boolean }> {
  try {
    const value = await requestJson<T>(url, signal);
    try { localStorage.setItem(`mediguide:${key}`, JSON.stringify(value)); } catch { /* storage is optional */ }
    return value as T & { offline?: boolean };
  } catch (error) {
    if (signal?.aborted) throw error;
    try {
      const stored = localStorage.getItem(`mediguide:${key}`);
      if (stored) return { ...(JSON.parse(stored) as T), offline: true };
    } catch { /* retain the original network error */ }
    throw error;
  }
}

export function listPublicDiseases(search = "", signal?: AbortSignal) {
  const query = new URLSearchParams({ page: "1", per_page: "100" });
  if (search.trim()) query.set("search", search.trim());
  return requestDiscovery<PublicDiseasePage>(`diseases:${search.trim().toLowerCase()}`, publicUrl("/diseases", query), signal);
}

export function getPublicDisease(slug: string, signal?: AbortSignal) {
  return requestDiscovery<PublicDisease>(`disease:${slug}`, publicUrl(`/diseases/${encodeURIComponent(slug)}`), signal);
}

export function listPublicHubs(diseaseSlug = "", signal?: AbortSignal) {
  const query = new URLSearchParams({ page: "1", per_page: "100" });
  if (diseaseSlug) query.set("disease_slug", diseaseSlug);
  return requestDiscovery<PublicHubPage>(`hubs:${diseaseSlug}`, publicUrl("/hubs", query), signal);
}

export function getPublicHub(slug: string, signal?: AbortSignal) {
  return requestDiscovery<PublicHub>(`hub:${slug}`, publicUrl(`/hubs/${encodeURIComponent(slug)}`), signal);
}

export async function searchPublicContent(queryText: string, filters: PublicSearchFilters = {}, signal?: AbortSignal) {
  const query = new URLSearchParams({ q: queryText.trim(), limit: String(filters.limit ?? 30) });
  if (filters.categoryId) query.set("category_id", filters.categoryId);
  if (filters.diseaseSlug) query.set("disease_slug", filters.diseaseSlug);
  if (filters.hubSlug) query.set("hub_slug", filters.hubSlug);
  if (filters.pillarSlug) query.set("pillar_slug", filters.pillarSlug);
  if (filters.contentType) query.set("content_type", filters.contentType);
  return requestJson<PublicSearchResult[]>(publicUrl("/search", query), signal);
}

export function clearPublicMarkdownCache() {
  markdownCache.clear();
  listCache.clear();
  detailCache.clear();
  structuredCache.clear();
  manifestIdentityByGuideline.clear();
  inFlight.clear();
}

function publicationIdentity(manifest: PublicGuidelineManifest) {
  return [manifest.guideline_id, manifest.version_id, manifest.package_version, manifest.checksum].join(":");
}

function assertPublicationIdentity(
  value: Pick<PublicGuidelineContent, "guideline_id" | "version_id" | "package_version" | "checksum">,
  manifest: PublicGuidelineManifest,
) {
  if (
    value.guideline_id !== manifest.guideline_id ||
    value.version_id !== manifest.version_id ||
    value.package_version !== manifest.package_version ||
    value.checksum !== manifest.checksum
  ) {
    throw new PublicApiError("invalid-response");
  }
}

function invalidateGuidelineStructuredCache(id: string, preserveKey?: string) {
  const encoded = `/guidelines/${encodeURIComponent(id)}/`;
  for (const key of structuredCache.keys()) {
    if (key !== preserveKey && key.includes(encoded)) structuredCache.delete(key);
  }
  markdownCache.delete(id);
}

type PublicGuidelinePageOf<T> = {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function isString(value: unknown): value is string { return typeof value === "string"; }
function isNumber(value: unknown): value is number { return typeof value === "number" && Number.isFinite(value); }
function isBoolean(value: unknown): value is boolean { return typeof value === "boolean"; }
function isAICitation(value: unknown): value is PublicAICitation {
  return isRecord(value) && isString(value.chunk_id) && isString(value.title)
    && isString(value.source_name) && isString(value.source_version);
}
function isAIAnswer(value: unknown): value is PublicAIAnswer {
  return isRecord(value) && isString(value.answer) && Array.isArray(value.citations)
    && value.citations.every(isAICitation);
}

function isManifest(value: unknown): value is PublicGuidelineManifest {
  if (!isRecord(value)) return false;
  return ["guideline_id", "version_id", "version", "extraction_quality", "checksum", "etag", "generated_at"].every((key) => isString(value[key]))
    && ["schema_version", "package_version", "section_count", "block_count", "table_count", "figure_count", "algorithm_count"].every((key) => isNumber(value[key]))
    && ["reviewed_section_count", "leaf_section_count", "reviewed_leaf_section_count", "empty_leaf_section_count", "reviewed_paragraph_count"].every((key) => value[key] === undefined || isNumber(value[key]))
    && ["has_chapters", "has_key_points", "has_tables", "has_figures", "has_algorithms", "has_original_pdf", "has_offline_package"].every((key) => isBoolean(value[key]));
}

function isSection(value: unknown): value is PublicGuidelineSection {
  return isRecord(value) && isString(value.id) && isString(value.title) && isString(value.slug)
    && isNumber(value.level) && isNumber(value.sort_order)
    && (value.parent_id === undefined || isString(value.parent_id));
}

function isBlock(value: unknown): value is PublicGuidelineBlock {
  return isRecord(value) && isString(value.id) && isString(value.type)
    && isNumber(value.sort_order) && isRecord(value.content);
}

function isPage<T>(value: unknown, itemGuard: (item: unknown) => item is T): value is PublicGuidelinePageOf<T> {
  return isRecord(value) && Array.isArray(value.items) && value.items.every(itemGuard)
    && isNumber(value.page) && isNumber(value.per_page) && isNumber(value.total_items) && isNumber(value.total_pages);
}

function isSectionPage(value: unknown): value is PublicGuidelinePageOf<PublicGuidelineSection> { return isPage(value, isSection); }
function isSectionDetail(value: unknown): value is PublicGuidelineSectionDetail {
  if (!isRecord(value) || !isPublicationPayload(value)) return false;
  const record = value as Record<string, unknown>;
  return isSection(record.section) && Array.isArray(record.blocks) && record.blocks.every(isBlock);
}
type PublicGuidelinePublicationIdentity = {
  guideline_id: string;
  version_id: string;
  package_version: number;
  checksum: string;
};
function isPublicationPayload(value: unknown): value is PublicGuidelinePublicationIdentity {
  return isRecord(value) && isString(value.guideline_id) && isString(value.version_id)
    && isNumber(value.package_version) && isString(value.checksum);
}
function isContent(value: unknown): value is PublicGuidelineContent {
  if (!isRecord(value) || !isPublicationPayload(value)) return false;
  const record = value as Record<string, unknown>;
  return Array.isArray(record.sections) && record.sections.every(isSection)
    && Array.isArray(record.blocks) && record.blocks.every(isBlock);
}
function isTable(value: unknown): value is PublicGuidelineTable {
  return isRecord(value) && isString(value.id) && isNumber(value.sort_order) && isRecord(value.content)
    && Array.isArray(value.content.columns) && value.content.columns.every(isString)
    && Array.isArray(value.content.rows) && value.content.rows.every((row) => Array.isArray(row) && row.every(isString));
}
function isAssetLink(value: unknown): value is PublicGuidelineAssetLink {
  return isRecord(value) && isString(value.type) && isString(value.mime_type) && isString(value.url) && isString(value.expires_at);
}
function isFigure(value: unknown): value is PublicGuidelineFigure {
  return isRecord(value) && isString(value.id) && isNumber(value.sort_order) && isRecord(value.content)
    && isString(value.content.asset_id) && isString(value.content.alternative_text) && isAssetLink(value.asset);
}
function isAlgorithm(value: unknown): value is PublicGuidelineAlgorithm {
  return isRecord(value) && isString(value.id) && isNumber(value.sort_order) && isRecord(value.content)
    && Array.isArray(value.content.nodes) && value.content.nodes.every((node) => isRecord(node) && isString(node.id) && isString(node.label) && isString(node.kind));
}
function isTablePage(value: unknown): value is PublicGuidelinePageOf<PublicGuidelineTable> { return isPage(value, isTable); }
function isFigurePage(value: unknown): value is PublicGuidelinePageOf<PublicGuidelineFigure> { return isPage(value, isFigure); }
function isAlgorithmPage(value: unknown): value is PublicGuidelinePageOf<PublicGuidelineAlgorithm> { return isPage(value, isAlgorithm); }
