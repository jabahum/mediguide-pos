import { readFile } from "node:fs/promises"
import path from "node:path"

import { NextResponse } from "next/server"

export const runtime = "nodejs"

interface SampleToolRouteProps {
  params: Promise<{ filename: string }>
}

export async function GET(
  _request: Request,
  { params }: SampleToolRouteProps,
) {
  const { filename } = await params
  if (!/^[a-z0-9-]+\.html$/i.test(filename)) {
    return new NextResponse("Tool not found", { status: 404 })
  }

  try {
    const html = await readFile(
      path.join(process.cwd(), "samples", filename),
      "utf8",
    )

    return new NextResponse(html, {
      headers: {
        "Cache-Control": "public, max-age=3600",
        "Content-Security-Policy":
          "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data:; font-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'self'",
        "Content-Type": "text/html; charset=utf-8",
        "X-Content-Type-Options": "nosniff",
      },
    })
  } catch {
    return new NextResponse("Tool not found", { status: 404 })
  }
}
