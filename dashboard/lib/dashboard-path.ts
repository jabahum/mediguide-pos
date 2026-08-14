const configuredBasePath =
  process.env.NEXT_PUBLIC_DASHBOARD_BASE_PATH?.trim() || "/admin"

export const dashboardBasePath =
  configuredBasePath === "/"
    ? ""
    : `/${configuredBasePath.replace(/^\/+|\/+$/g, "")}`

/** Prefixes browser-level dashboard navigation that Next.js cannot rewrite. */
export function withDashboardBasePath(path: string): string {
  if (!path || /^(?:[a-z][a-z0-9+.-]*:|\/\/|#)/i.test(path)) {
    return path
  }

  const normalizedPath = path.startsWith("/") ? path : `/${path}`
  if (
    !dashboardBasePath ||
    normalizedPath === dashboardBasePath ||
    normalizedPath.startsWith(`${dashboardBasePath}/`)
  ) {
    return normalizedPath
  }

  return `${dashboardBasePath}${normalizedPath}`
}
