"use client"

import { BackendRequestError, getBackendClient } from "@/lib/backend-client"

export interface MarkdownUpdateResult {
  updated: boolean
  queued: boolean
  size: number
  job_id: string
}

export class GuidelineMarkdownError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
  ) {
    super(message)
    this.name = "GuidelineMarkdownError"
  }
}

function toGuidelineMarkdownError(error: unknown, fallback: string) {
  if (error instanceof BackendRequestError) {
    return new GuidelineMarkdownError(error.message || fallback, error.status)
  }
  if (error instanceof Error) {
    return new GuidelineMarkdownError(error.message || fallback)
  }
  return new GuidelineMarkdownError(fallback)
}

export class GuidelineMarkdownService {
  static async load(versionId: string): Promise<string> {
    try {
      return await getBackendClient().send<string>(
        `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
        { method: "GET", responseType: "text" },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to load extracted Markdown")
    }
  }

  static async update(versionId: string, content: string): Promise<MarkdownUpdateResult> {
    try {
      return await getBackendClient().send<MarkdownUpdateResult>(
        `/api/v2/guideline-versions/${versionId}/extracted/markdown`,
        {
          method: "PUT",
          body: JSON.stringify({ content }),
        },
      )
    } catch (error) {
      throw toGuidelineMarkdownError(error, "Failed to save extracted Markdown")
    }
  }
}
