import type { NextConfig } from "next";

const configuredBasePath =
  process.env.NEXT_PUBLIC_DASHBOARD_BASE_PATH?.trim() || "/admin";
const basePath =
  configuredBasePath === "/"
    ? ""
    : `/${configuredBasePath.replace(/^\/+|\/+$/g, "")}`;

const nextConfig: NextConfig = {
  output: "standalone",
  basePath,
  turbopack: {
    root: __dirname,
  },
};

export default nextConfig;
