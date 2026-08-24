import { getMarkdownHeadings, stripMarkdown } from "./headings";

export type MarkdownSearchEntry = {
  id: string;
  title: string;
  depth: number;
  text: string;
  snippet: string;
};

export function buildMarkdownSearchIndex(content: string): MarkdownSearchEntry[] {
  const headings = getMarkdownHeadings(content);
  if (!headings.length) {
    const text = plainMarkdown(content);
    return text ? [{ id: "guideline-document", title: "Guideline", depth: 1, text, snippet: text.slice(0, 150) }] : [];
  }
  const lines = content.split("\n");
  const headingLines = lines.flatMap((line, index) => /^(#{2,4})\s+/.test(line) ? [index] : []);
  return headings.map((heading, index) => {
    const start = headingLines[index] + 1;
    const end = headingLines[index + 1] ?? lines.length;
    const text = plainMarkdown(lines.slice(start, end).join(" "));
    return {
      id: heading.id,
      title: heading.text,
      depth: heading.depth,
      text,
      snippet: text.slice(0, 150),
    };
  });
}

function plainMarkdown(value: string) {
  return stripMarkdown(value
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/[#>|]/g, " "))
    .replace(/\s+/g, " ")
    .trim();
}

export function searchMarkdown(index: MarkdownSearchEntry[], query: string) {
  const terms = query.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
  if (!terms.length) return [];
  return index.filter((entry) => {
    const haystack = `${entry.title} ${entry.text}`.toLocaleLowerCase();
    return terms.every((term) => haystack.includes(term));
  }).slice(0, 40);
}
