import type {
  PublicGuidelineBlock,
  PublicGuidelineFigure,
} from "../../../api/public-guidelines";

type GuidelineBlockRendererProps = {
  block: PublicGuidelineBlock;
  figure?: PublicGuidelineFigure;
  onOpenSourcePage?: (page: number) => void;
};

export function GuidelineBlockRenderer({
  block,
  figure,
  onOpenSourcePage,
}: GuidelineBlockRendererProps) {
  const content = block.content;
  const source = block.page_start ? (
    <button
      className="block-source"
      type="button"
      onClick={() => onOpenSourcePage?.(block.page_start!)}
      aria-label={`Open original document at page ${block.page_start}`}
    >
      Source page {pageRange(block.page_start, block.page_end)}
    </button>
  ) : null;

  let rendered: React.ReactNode;
  switch (block.type) {
    case "heading": {
      const text = textValue(content.text);
      const level = numberValue(content.level, 2);
      rendered = level <= 2 ? <h2>{text}</h2> : level === 3 ? <h3>{text}</h3> : <h4>{text}</h4>;
      break;
    }
    case "paragraph":
      rendered = <p>{textValue(content.text)}</p>;
      break;
    case "ordered_list":
      rendered = <ol>{stringList(content.items).map((item, index) => <li key={`${block.id}-${index}`}>{item}</li>)}</ol>;
      break;
    case "unordered_list":
      rendered = <ul>{stringList(content.items).map((item, index) => <li key={`${block.id}-${index}`}>{item}</li>)}</ul>;
      break;
    case "table":
      rendered = <StructuredTable content={content} />;
      break;
    case "figure":
      rendered = <StructuredFigure content={content} figure={figure} />;
      break;
    case "recommendation":
    case "warning":
    case "key_point":
      rendered = <ClinicalCallout kind={block.type} content={content} />;
      break;
    case "algorithm":
      rendered = <StructuredAlgorithm content={content} />;
      break;
    case "reference": {
      const url = safeAssetUrl(textValue(content.url));
      rendered = <p className="reference-block">
        {textValue(content.citation || content.text || content.content)}
        {url && <> <a href={url} target="_blank" rel="noopener noreferrer">Open source</a></>}
      </p>;
      break;
    }
    case "page_break":
      rendered = <hr aria-hidden="true" />;
      break;
    default:
      rendered = (
        <div className="unsupported-block" role="note">
          This content type is not available in the web reader. Use the original document to review it.
        </div>
      );
  }

  return (
    <section className={`guideline-block block-${safeToken(block.type)}`} id={`block-${block.id}`}>
      {rendered}
      {source}
    </section>
  );
}

export function StructuredTable({ content }: { content: Record<string, unknown> }) {
  const columns = stringList(content.columns);
  const rows = stringRows(content.rows);
  const footnotes = stringList(content.footnotes);
  return (
    <figure className="structured-table">
      {textValue(content.title) && <figcaption>{textValue(content.title)}</figcaption>}
      <div className="table-scroll" tabIndex={0} role="region" aria-label={textValue(content.title) || "Clinical table"}>
        <table>
          {columns.length > 0 && <thead><tr>{columns.map((column, index) => <th scope="col" key={`${column}-${index}`}>{column}</th>)}</tr></thead>}
          <tbody>{rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((cell, cellIndex) => <td key={cellIndex}>{cell}</td>)}</tr>)}</tbody>
        </table>
      </div>
      {footnotes.length > 0 && <ol className="table-footnotes">{footnotes.map((note, index) => <li key={index}>{note}</li>)}</ol>}
    </figure>
  );
}

function StructuredFigure({ content, figure }: { content: Record<string, unknown>; figure?: PublicGuidelineFigure }) {
  const alt = textValue(content.alternative_text) || "Guideline figure";
  const caption = textValue(content.caption);
  const url = safeAssetUrl(figure?.asset.url);
  return (
    <figure className="structured-figure">
      {url ? <img src={url} alt={alt} loading="lazy" /> : <div className="asset-placeholder" role="img" aria-label={alt}>Reviewed figure unavailable</div>}
      {caption && <figcaption>{caption}</figcaption>}
    </figure>
  );
}

function ClinicalCallout({ kind, content }: { kind: string; content: Record<string, unknown> }) {
  const title = textValue(content.title) || kind.replace("_", " ");
  return (
    <aside className={`clinical-callout callout-${safeToken(kind)}`} aria-label={title}>
      <strong>{title}</strong>
      <p>{textValue(content.content || content.text)}</p>
      {textValue(content.severity) && <small>Priority: {textValue(content.severity)}</small>}
    </aside>
  );
}

export function StructuredAlgorithm({ content }: { content: Record<string, unknown> }) {
  const nodes = Array.isArray(content.nodes)
    ? content.nodes.filter(isRecord).map((node) => ({
        id: textValue(node.id), label: textValue(node.label), kind: textValue(node.kind), next: stringList(node.next),
      })).filter((node) => node.id && node.label)
    : [];
  return (
    <figure className="structured-algorithm">
      {textValue(content.title) && <figcaption>{textValue(content.title)}</figcaption>}
      <ol>{nodes.map((node) => (
        <li key={node.id}>
          <span>{node.kind || "step"}</span><strong>{node.label}</strong>
          {node.next.length > 0 && <small>Next: {node.next.join(", ")}</small>}
        </li>
      ))}</ol>
    </figure>
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function textValue(value: unknown) { return typeof value === "string" ? value : ""; }
function numberValue(value: unknown, fallback: number) { return typeof value === "number" && Number.isFinite(value) ? value : fallback; }
function stringList(value: unknown) { return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : []; }
function stringRows(value: unknown) { return Array.isArray(value) ? value.map(stringList).filter((row) => row.length > 0) : []; }
function safeToken(value: string) { return value.replace(/[^a-z0-9_-]/gi, "-"); }
function safeAssetUrl(value: string | undefined) { return value && /^https?:\/\//i.test(value) ? value : undefined; }
function pageRange(start: number, end?: number) { return end && end !== start ? `${start}–${end}` : String(start); }
