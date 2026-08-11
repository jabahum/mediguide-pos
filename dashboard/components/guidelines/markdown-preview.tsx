"use client"

import ReactMarkdown from "react-markdown"
import remarkGfm from "remark-gfm"

import { cn } from "@/lib/utils"

interface MarkdownPreviewProps {
  content: string
  className?: string
}

const calloutLabels: Record<string, string> = {
  recommendation: "Recommendation",
  warning: "Warning",
  caution: "Caution",
  "key-point": "Key point",
  contraindication: "Contraindication",
  dosage: "Dosage",
  evidence: "Evidence statement",
  definition: "Definition",
  procedure: "Procedure",
  algorithm: "Algorithm reference",
  "clinical-note": "Clinical note",
  "referral-criteria": "Referral criteria",
}

export function renderableClinicalMarkdown(content: string) {
  const output: string[] = []
  let callout: string | null = null
  for (const line of content.split("\n")) {
    const start = /^:::([a-z][a-z-]*)\s*$/u.exec(line)
    if (!callout && start && calloutLabels[start[1]]) {
      callout = start[1]
      output.push(`> **${calloutLabels[callout]}**`)
      continue
    }
    if (callout && /^:::\s*$/u.test(line)) {
      callout = null
      output.push("")
      continue
    }
    output.push(callout ? `> ${line || " "}` : line)
  }
  return output.join("\n")
}

export function MarkdownPreview({ content, className }: MarkdownPreviewProps) {
  if (!content.trim()) {
    return (
      <div className={cn("grid min-h-64 place-items-center text-sm text-muted-foreground", className)}>
        Nothing to preview yet.
      </div>
    )
  }

  return (
    <article
      aria-label="Rendered Markdown preview"
      className={cn(
        "min-w-0 break-words text-sm leading-7",
        "[&_h1]:mb-4 [&_h1]:mt-2 [&_h1]:text-3xl [&_h1]:font-bold",
        "[&_h2]:mb-3 [&_h2]:mt-8 [&_h2]:border-b [&_h2]:pb-2 [&_h2]:text-2xl [&_h2]:font-semibold",
        "[&_h3]:mb-2 [&_h3]:mt-6 [&_h3]:text-xl [&_h3]:font-semibold",
        "[&_h4]:mb-2 [&_h4]:mt-5 [&_h4]:text-lg [&_h4]:font-semibold",
        "[&_p]:my-3 [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-4",
        "[&_ul]:my-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ol]:my-3 [&_ol]:list-decimal [&_ol]:pl-6",
        "[&_li]:my-1 [&_blockquote]:my-4 [&_blockquote]:border-l-4 [&_blockquote]:pl-4 [&_blockquote]:italic",
        "[&_pre]:my-4 [&_pre]:overflow-x-auto [&_pre]:rounded-md [&_pre]:bg-muted [&_pre]:p-4",
        "[&_code]:rounded [&_code]:bg-muted [&_code]:px-1 [&_code]:py-0.5 [&_pre_code]:bg-transparent [&_pre_code]:p-0",
        "[&_table]:my-4 [&_table]:w-full [&_table]:border-collapse [&_th]:border [&_th]:bg-muted [&_th]:p-2 [&_th]:text-left",
        "[&_td]:border [&_td]:p-2 [&_hr]:my-8",
        className,
      )}
    >
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        skipHtml
        components={{
          a: ({ href, children, node, ...props }) => {
            void node
            return (
              <a
                {...props}
                href={href}
                target={href?.startsWith("http") ? "_blank" : undefined}
                rel={href?.startsWith("http") ? "noopener noreferrer" : undefined}
              >
                {children}
              </a>
            )
          },
        }}
      >
        {renderableClinicalMarkdown(content)}
      </ReactMarkdown>
    </article>
  )
}
