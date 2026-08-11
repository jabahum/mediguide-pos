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
  block_count: number;
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
  section: PublicGuidelineSection;
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

async function requestConditionalJson<T>(
  url: string,
  validate: (value: unknown) => value is T,
  signal?: AbortSignal,
): Promise<T> {
  const cached = structuredCache.get(url) as ConditionalCacheEntry<T> | undefined;
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
  rememberConditional(url, {
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
  const load = () => requestConditionalJson(url, isManifest, signal);
  return signal ? load() : deduplicated(`manifest:${url}`, load);
}

export function listPublicGuidelineSections(id: string, signal?: AbortSignal) {
  const query = new URLSearchParams({ page: "1", per_page: "500", sort: "sort_order", order: "asc" });
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/sections`, query);
  const load = () => requestConditionalJson(url, isSectionPage, signal);
  return signal ? load() : deduplicated(`sections:${url}`, load);
}

export function getPublicGuidelineSection(id: string, sectionId: string, signal?: AbortSignal) {
  const url = publicUrl(`/guidelines/${encodeURIComponent(id)}/sections/${encodeURIComponent(sectionId)}`);
  const load = () => requestConditionalJson(url, isSectionDetail, signal);
  return signal ? load() : deduplicated(`section:${url}`, load);
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

export function clearPublicMarkdownCache() {
  markdownCache.clear();
  listCache.clear();
  detailCache.clear();
  structuredCache.clear();
  inFlight.clear();
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

function isManifest(value: unknown): value is PublicGuidelineManifest {
  if (!isRecord(value)) return false;
  return ["guideline_id", "version_id", "version", "extraction_quality", "checksum", "etag", "generated_at"].every((key) => isString(value[key]))
    && ["schema_version", "package_version", "section_count", "block_count", "table_count", "figure_count", "algorithm_count"].every((key) => isNumber(value[key]))
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
  return isRecord(value) && isSection(value.section) && Array.isArray(value.blocks) && value.blocks.every(isBlock);
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
