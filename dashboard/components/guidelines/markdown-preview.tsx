"use client"
/* eslint-disable @next/next/no-img-element -- guideline assets use short-lived signed URLs */

import ReactMarkdown, { defaultUrlTransform } from "react-markdown"
import remarkGfm from "remark-gfm"

import { cn } from "@/lib/utils"
import type { GuidelineAsset } from "@/services/guideline-assets.service"

interface MarkdownPreviewProps {
  content: string
  className?: string
  assets?: GuidelineAsset[]
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
  "algorithm-reference": "Algorithm reference",
  "clinical-note": "Clinical note",
  "referral-criteria": "Referral criteria",
}

export function renderableClinicalMarkdown(content: string) {
  const output: string[] = []
  let callout: string | null = null
  for (const line of content.split("\n")) {
    const start = /^:::([a-z][a-z-]*)(?:\s+(.*))?$/u.exec(line)
    if (!callout && start && calloutLabels[start[1]]) {
      callout = start[1]
      const title = /(?:^|\s)title=(?:"([^"]*)"|'([^']*)'|([^\s]+))/u.exec(start[2] || "")
      const severity = /(?:^|\s)severity=([^\s]+)/u.exec(start[2] || "")
      const evidence = /(?:^|\s)evidence_grade=(?:"([^"]*)"|'([^']*)'|([^\s]+))/u.exec(start[2] || "")
      const source = /(?:^|\s)source=(?:"([^"]*)"|'([^']*)'|([^\s]+))/u.exec(start[2] || "")
      output.push(`> **${title?.[1] || title?.[2] || title?.[3] || calloutLabels[callout]}**`)
      if (severity?.[1]) output.push(`> _Priority: ${severity[1]}_`)
      if (evidence) output.push(`> _Evidence grade: ${evidence[1] || evidence[2] || evidence[3]}_`)
      if (source) output.push(`> _Source: ${source[1] || source[2] || source[3]}_`)
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

export function MarkdownPreview({ content, className, assets = [] }: MarkdownPreviewProps) {
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
        urlTransform={(url) => typeof url === "string" && url.startsWith("guideline-asset://") ? url : defaultUrlTransform(url)}
        components={{
          table: ({ children, node, ...props }) => {
            void node
            return (
              <div className="my-4 min-w-0 max-w-full overflow-hidden rounded-md border">
                <table {...props} className="m-0 w-full table-fixed border-collapse">
                  {children}
                </table>
              </div>
            )
          },
          th: ({ children, node, ...props }) => {
            void node
            return <th {...props} className="break-words [overflow-wrap:anywhere]">{children}</th>
          },
          td: ({ children, node, ...props }) => {
            void node
            return <td {...props} className="break-words [overflow-wrap:anywhere]">{children}</td>
          },
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
          img: ({ src, alt, title, node, ...props }) => {
            void node
            const source = typeof src === "string" ? src : ""
            const asset = assets.find((item) => item.reference === source)
            if (source.startsWith("guideline-asset://") && !asset) {
              return <span role="img" aria-label={alt || "Broken guideline image"} className="my-3 block rounded border border-destructive p-3 text-destructive">Broken guideline asset reference</span>
            }
            const image = <img {...props} src={asset?.url || source} alt={alt || asset?.alternative_text || ""} loading="lazy" />
            return title ? <figure className="my-4">{image}<figcaption className="mt-2 text-sm text-muted-foreground">{title}</figcaption></figure> : image
          },
        }}
      >
        {renderableClinicalMarkdown(content)}
      </ReactMarkdown>
    </article>
  )
}
