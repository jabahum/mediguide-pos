import type { GuidelineAsset } from "@/services/guideline-assets.service"

function singleLine(value: string) {
  return value.replace(/\s+/gu, " ").trim()
}

function alternativeText(value: string) {
  return singleLine(value).replace(/[\[\]]/gu, " ").replace(/\s+/gu, " ").trim()
}

function quotedTitle(value: string) {
  return singleLine(value).replace(/\\/gu, "\\\\").replace(/"/gu, '\\"')
}

export function guidelineAssetMarkdown(asset: GuidelineAsset) {
  const alt = alternativeText(asset.alternative_text)
  const caption = quotedTitle(asset.caption)
  const title = caption ? ` "${caption}"` : ""
  const figure = `![${alt}](${asset.reference}${title})`
  const source = [asset.source, asset.attribution, asset.license]
    .map(singleLine)
    .filter((value, index, values) => value && values.indexOf(value) === index)
    .join(" · ")
  return source ? `${figure}\n\n*Source: ${source}*` : figure
}

export function insertMarkdownBlock(
  content: string,
  from: number,
  to: number,
  block: string,
) {
  const before = content.slice(0, from)
  const after = content.slice(to)
  const prefix = before.length === 0 || before.endsWith("\n\n")
    ? ""
    : before.endsWith("\n") ? "\n" : "\n\n"
  const suffix = after.length === 0 || after.startsWith("\n\n")
    ? ""
    : after.startsWith("\n") ? "\n" : "\n\n"
  return `${prefix}${block}${suffix}`
}
