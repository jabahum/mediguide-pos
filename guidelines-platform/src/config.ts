declare global {
  interface Window {
    __APP_CONFIG__?: {
      mediguidePosUrl?: string;
      mediguideApiUrl?: string;
    };
  }
}

const defaultMediguidePosUrl = "http://localhost:3000";
const defaultMediguideApiUrl = "http://localhost:8080";

function normalizeBaseUrl(value: string | undefined, fallback: string) {
  return (value?.trim() || fallback).replace(/\/+$/, "");
}

const runtimeConfig =
  typeof window === "undefined" ? undefined : window.__APP_CONFIG__;

const mediguidePosUrl = normalizeBaseUrl(
  runtimeConfig?.mediguidePosUrl ||
    import.meta.env.VITE_MEDIGUIDE_POS_URL,
  defaultMediguidePosUrl,
);

export const publicApiBaseUrl = normalizeBaseUrl(
  runtimeConfig?.mediguideApiUrl ||
    import.meta.env.VITE_MEDIGUIDE_API_URL,
  defaultMediguideApiUrl,
);

export const dashboardBaseUrl = mediguidePosUrl;
export const dashboardLoginUrl = `${dashboardBaseUrl}/login`;
export const mediguidePosLoginUrl = dashboardLoginUrl;
