import { useEffect, useState } from "react";
import {
  Link,
  useLocation,
  useParams,
  useSearchParams,
} from "react-router-dom";

import {
  getPublicGuideline,
  getPublicGuidelineManifest,
  getPublicGuidelineMarkdown,
  getPublicGuidelineOriginal,
  getPublicGuidelineSection,
  listPublicGuidelineAlgorithms,
  listPublicGuidelineFigures,
  listPublicGuidelineSections,
  listPublicGuidelineTables,
  PublicApiError,
  type PublicGuideline,
  type PublicAICitation,
  type PublicGuidelineAlgorithm,
  type PublicGuidelineFigure,
  type PublicGuidelineManifest,
  type PublicGuidelineSection,
  type PublicGuidelineSectionDetail,
  type PublicGuidelineTable,
  type PublicMarkdown,
} from "../../api/public-guidelines";
import { Brand } from "../../components/common/Brand";
import { PageLoading } from "../../components/common/PageLoading";
import { dashboardLoginUrl } from "../../config";
import {
  BookGuidelineReader,
  type SupplementalReaderView,
} from "./components/BookGuidelineReader";
import {
  GuidelineBlockRenderer,
  StructuredAlgorithm,
  StructuredTable,
} from "./components/GuidelineBlockRenderer";

type ReaderView = "read" | SupplementalReaderView;

type ReaderData = {
  guideline: PublicGuideline;
  manifest?: PublicGuidelineManifest;
  sections: PublicGuidelineSection[];
  tables: PublicGuidelineTable[];
  figures: PublicGuidelineFigure[];
  algorithms: PublicGuidelineAlgorithm[];
  markdown?: PublicMarkdown;
  partial: boolean;
};

type ReaderState =
  | { status: "loading" }
  | { status: "ready"; requestId: string; data: ReaderData }
  | { status: "not-found"; requestId: string }
  | { status: "error"; requestId: string };

type SectionState =
  | { status: "idle" }
  | { status: "ready"; sectionId: string; detail: PublicGuidelineSectionDetail }
  | { status: "error"; sectionId: string };

type SectionDisplayState = SectionState | { status: "loading" };

export function PublicGuidelineReaderPage() {
  const { guidelineId = "" } = useParams();
  const location = useLocation();
  const [searchParams, setSearchParams] = useSearchParams();
  const [reloadKey, setReloadKey] = useState(0);
  const [state, setState] = useState<ReaderState>({ status: "loading" });
  const [sectionState, setSectionState] = useState<SectionState>({
    status: "idle",
  });
  const selectedSectionId = searchParams.get("section") ?? "";
  const requestedView = parseView(searchParams.get("view"));

  useEffect(() => {
    const controller = new AbortController();
    loadReaderData(guidelineId, controller.signal)
      .then((data) =>
        setState({ status: "ready", requestId: guidelineId, data }),
      )
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        if (import.meta.env.DEV) {
          console.warn("Public guideline reader request failed", {
            kind: error instanceof PublicApiError ? error.kind : "unknown",
          });
        }
        setState(
          error instanceof PublicApiError && error.kind === "not-found"
            ? { status: "not-found", requestId: guidelineId }
            : { status: "error", requestId: guidelineId },
        );
      });
    return () => controller.abort();
  }, [guidelineId, reloadKey]);

  useEffect(() => {
    if (
      state.status !== "ready" ||
      state.requestId !== guidelineId ||
      !selectedSectionId
    )
      return;
    if (
      !state.data.sections.some((section) => section.id === selectedSectionId)
    )
      return;
    const controller = new AbortController();
    getPublicGuidelineSection(guidelineId, selectedSectionId, controller.signal)
      .then((detail) =>
        setSectionState({
          status: "ready",
          sectionId: selectedSectionId,
          detail,
        }),
      )
      .catch(() => {
        if (!controller.signal.aborted)
          setSectionState({ status: "error", sectionId: selectedSectionId });
      });
    return () => controller.abort();
  }, [guidelineId, selectedSectionId, state]);

  useEffect(() => {
    if (state.status !== "ready") return;
    document.title = `${state.data.guideline.title} | MediGuide`;
    updateMetaDescription(state.data.guideline.description);
  }, [state]);

  useEffect(() => {
    if (state.status !== "ready" || !location.hash) return;
    const id = decodeURIComponent(location.hash.slice(1));
    const frame = requestAnimationFrame(() =>
      document.getElementById(id)?.scrollIntoView({ block: "start" }),
    );
    return () => cancelAnimationFrame(frame);
  }, [location.hash, sectionState, state]);

  if (state.status === "loading" || state.requestId !== guidelineId)
    return <PageLoading label="Loading published clinical guidance…" />;
  if (state.status === "not-found")
    return (
      <ReaderMessage
        title="Guideline not found"
        message="This guideline is unavailable or has not been published."
      />
    );
  if (state.status === "error") {
    return (
      <ReaderMessage
        title="We could not load this guideline"
        message="Check your connection and try again."
      >
        <button
          className="button button-primary"
          onClick={() => {
            setState({ status: "loading" });
            setReloadKey((key) => key + 1);
          }}
        >
          Try again
        </button>
      </ReaderMessage>
    );
  }

  const { data } = state;
  const tabs = availableViews(data);
  const view = tabs.includes(requestedView) ? requestedView : tabs[0];
  const selectView = (nextView: ReaderView) => {
    const next = new URLSearchParams(searchParams);
    next.set("view", nextView);
    if (nextView !== "chapters") next.delete("section");
    setSearchParams(next);
  };
  const selectSection = (sectionId: string) => {
    const next = new URLSearchParams(searchParams);
    next.set("view", "chapters");
    next.set("section", sectionId);
    setSearchParams(next);
  };

  if (view === "read" && data.markdown) {
    return (
      <BookGuidelineReader
        guideline={data.guideline}
        manifest={data.manifest}
        markdown={data.markdown}
        supplementalViews={tabs.filter(
          (tab): tab is SupplementalReaderView => tab !== "read",
        )}
        partial={data.partial}
        onSelectView={selectView}
        onOpenOriginal={(page) => openOriginal(guidelineId, page)}
        onCitation={(citation) =>
          openCitation(citation, data.sections, selectSection, () =>
            openOriginal(guidelineId, citation.page_start),
          )
        }
      />
    );
  }

  return (
    <div className="backend-reader structured-reader">
      <a className="skip-link" href="#guideline-content">
        Skip to clinical content
      </a>
      <header className="backend-reader-header">
        <Link to="/" aria-label="MediGuide guideline library">
          <Brand />
        </Link>
        <nav aria-label="Reader actions">
          <Link to="/">All guidelines</Link>
          <button type="button" onClick={() => window.print()}>
            Print
          </button>
          <a href={dashboardLoginUrl}>Login</a>
        </nav>
      </header>

      <main id="guideline-content">
        <GuidelineHero
          data={data}
          onOpenOriginal={(page) => openOriginal(guidelineId, page)}
        />
        <div className="guideline-tabs-shell">
          <nav className="guideline-tabs" aria-label="Guideline content">
            {tabs.map((tab) => (
              <button
                key={tab}
                type="button"
                aria-current={view === tab ? "page" : undefined}
                onClick={() => selectView(tab)}
              >
                {viewLabel(tab)}
              </button>
            ))}
          </nav>
        </div>

        {data.partial && (
          <div className="partial-extraction-notice" role="status">
            Some structured content is unavailable. The original document
            remains the fidelity reference.
          </div>
        )}

        <div
          className={`structured-reader-body ${view === "chapters" ? "has-sections" : ""}`}
        >
          {view === "chapters" && (
            <SectionNavigation
              sections={data.sections}
              selectedId={selectedSectionId}
              onSelect={selectSection}
            />
          )}
          <div className="structured-reader-content">
            {view === "overview" && (
              <Overview data={data} onSelect={selectView} />
            )}
            {view === "chapters" && (
              <SectionReader
                data={data}
                state={sectionDisplayState(
                  sectionState,
                  selectedSectionId,
                  data.sections,
                )}
                onSelect={selectSection}
                onOpenSourcePage={(page) => openOriginal(guidelineId, page)}
              />
            )}
            {view === "tables" && (
              <TablesView
                items={data.tables}
                onOpenSourcePage={(page) => openOriginal(guidelineId, page)}
              />
            )}
            {view === "figures" && (
              <FiguresView
                items={data.figures}
                onOpenSourcePage={(page) => openOriginal(guidelineId, page)}
              />
            )}
            {view === "algorithms" && (
              <AlgorithmsView
                items={data.algorithms}
                onOpenSourcePage={(page) => openOriginal(guidelineId, page)}
              />
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

async function loadReaderData(
  id: string,
  signal: AbortSignal,
): Promise<ReaderData> {
  const guideline = await getPublicGuideline(id, signal);
  let manifest: PublicGuidelineManifest | undefined;
  let partial = false;
  try {
    manifest = await getPublicGuidelineManifest(id, signal);
  } catch (error) {
    if (signal.aborted) throw error;
    if (error instanceof PublicApiError && error.kind === "rate-limited")
      throw error;
    partial = true;
  }
  const structured =
    manifest !== undefined &&
    manifest.extraction_quality !== "markdown_fallback" &&
    manifest.section_count > 0;
  let sections: PublicGuidelineSection[] = [];
  let tables: PublicGuidelineTable[] = [];
  let figures: PublicGuidelineFigure[] = [];
  let algorithms: PublicGuidelineAlgorithm[] = [];
  if (structured && manifest) {
    const requests: Array<Promise<unknown>> = [
      listPublicGuidelineSections(id, signal),
    ];
    if (manifest.has_tables)
      requests.push(listPublicGuidelineTables(id, signal));
    if (manifest.has_figures)
      requests.push(listPublicGuidelineFigures(id, signal));
    if (manifest.has_algorithms)
      requests.push(listPublicGuidelineAlgorithms(id, signal));
    const results = await Promise.allSettled(requests);
    let cursor = 0;
    const sectionResult = results[cursor++];
    if (sectionResult.status === "fulfilled")
      sections = (
        sectionResult.value as Awaited<
          ReturnType<typeof listPublicGuidelineSections>
        >
      ).items;
    else partial = true;
    if (manifest.has_tables) {
      const result = results[cursor++];
      if (result.status === "fulfilled")
        tables = (
          result.value as Awaited<ReturnType<typeof listPublicGuidelineTables>>
        ).items;
      else partial = true;
    }
    if (manifest.has_figures) {
      const result = results[cursor++];
      if (result.status === "fulfilled")
        figures = (
          result.value as Awaited<ReturnType<typeof listPublicGuidelineFigures>>
        ).items;
      else partial = true;
    }
    if (manifest.has_algorithms) {
      const result = results[cursor];
      if (result.status === "fulfilled")
        algorithms = (
          result.value as Awaited<
            ReturnType<typeof listPublicGuidelineAlgorithms>
          >
        ).items;
      else partial = true;
    }
  }
  let markdown: PublicMarkdown | undefined;
  try {
    markdown = await getPublicGuidelineMarkdown(id, signal);
  } catch (error) {
    if (signal.aborted) throw error;
    if (error instanceof PublicApiError && error.kind === "rate-limited")
      throw error;
    if (!(error instanceof PublicApiError) || error.kind !== "not-found")
      partial = true;
  }
  return {
    guideline,
    manifest,
    sections,
    tables,
    figures,
    algorithms,
    markdown,
    partial,
  };
}

function GuidelineHero({
  data,
  onOpenOriginal,
}: {
  data: ReaderData;
  onOpenOriginal: (page?: number) => void;
}) {
  const { guideline, manifest } = data;
  return (
    <header className="guideline-home page-shell">
      <Link className="back-link" to="/">
        ← Guideline library
      </Link>
      <div className="guideline-home-grid">
        <div>
          <span className="eyebrow">
            {guideline.program_area || "Published clinical guideline"}
          </span>
          <h1>{guideline.title}</h1>
          {guideline.description && <p>{guideline.description}</p>}
          <div className="guideline-home-actions">
            {manifest?.has_chapters && (
              <a className="button button-primary" href="?view=chapters">
                Read guideline
              </a>
            )}
            {manifest?.has_original_pdf !== false && (
              <button
                className="button button-outline"
                type="button"
                onClick={() => onOpenOriginal()}
              >
                Open original PDF
              </button>
            )}
          </div>
        </div>
        <dl className="guideline-facts">
          <Meta label="Source" value={guideline.source_org} />
          <Meta label="Version" value={guideline.version} />
          <Meta
            label="Published"
            value={formatDate(guideline.publication_date)}
          />
          <Meta label="Review date" value={formatDate(guideline.review_date)} />
          <Meta label="Language" value={guideline.language} />
          <Meta
            label="Content quality"
            value={qualityLabel(manifest?.extraction_quality)}
          />
        </dl>
      </div>
    </header>
  );
}

function Overview({
  data,
  onSelect,
}: {
  data: ReaderData;
  onSelect: (view: ReaderView) => void;
}) {
  const manifest = data.manifest;
  return (
    <section className="guideline-overview">
      <div>
        <span className="eyebrow">About this guideline</span>
        <h2>Published content</h2>
        <p>
          {data.guideline.description ||
            "Review the current published clinical guidance and available source material."}
        </p>
      </div>
      {manifest ? (
        <div
          className="capability-grid"
          aria-label="Available guideline content"
        >
          {manifest.has_chapters && (
            <Capability
              title="Chapters"
              count={manifest.section_count}
              onClick={() => onSelect("chapters")}
            />
          )}
          {manifest.has_tables && (
            <Capability
              title="Tables"
              count={manifest.table_count}
              onClick={() => onSelect("tables")}
            />
          )}
          {manifest.has_figures && (
            <Capability
              title="Figures"
              count={manifest.figure_count}
              onClick={() => onSelect("figures")}
            />
          )}
          {manifest.has_algorithms && (
            <Capability
              title="Algorithms"
              count={manifest.algorithm_count}
              onClick={() => onSelect("algorithms")}
            />
          )}
        </div>
      ) : (
        <div className="partial-extraction-notice">
          A structured manifest is not available. This guideline is presented
          using its published compatibility format.
        </div>
      )}
    </section>
  );
}

function Capability({
  title,
  count,
  onClick,
}: {
  title: string;
  count: number;
  onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick}>
      <strong>{title}</strong>
      <span>{count} available</span>
      <b aria-hidden="true">→</b>
    </button>
  );
}

function SectionNavigation({
  sections,
  selectedId,
  onSelect,
}: {
  sections: PublicGuidelineSection[];
  selectedId: string;
  onSelect: (id: string) => void;
}) {
  return (
    <aside className="structured-section-nav">
      <p className="eyebrow">On this guideline</p>
      <nav aria-label="Guideline sections">
        {sections.map((section) => (
          <button
            style={
              {
                "--section-level": Math.max(0, section.level - 1),
              } as React.CSSProperties
            }
            type="button"
            key={section.id}
            aria-current={selectedId === section.id ? "page" : undefined}
            onClick={() => onSelect(section.id)}
          >
            {section.title}
            <small>{sourcePages(section.page_start, section.page_end)}</small>
          </button>
        ))}
      </nav>
    </aside>
  );
}

function SectionReader({
  data,
  state,
  onSelect,
  onOpenSourcePage,
}: {
  data: ReaderData;
  state: SectionDisplayState;
  onSelect: (id: string) => void;
  onOpenSourcePage: (page: number) => void;
}) {
  if (data.sections.length === 0)
    return (
      <ContentState
        title="Structured chapters are unavailable"
        message="Use the compatibility or original-document view for this publication."
      />
    );
  if (state.status === "idle")
    return (
      <section className="section-welcome">
        <span className="eyebrow">Chapters</span>
        <h2>Select a section</h2>
        <p>
          This publication has {data.sections.length} reviewed section
          {data.sections.length === 1 ? "" : "s"}. Its navigation follows the
          structure of the uploaded document.
        </p>
        <button
          className="button button-primary"
          onClick={() => onSelect(data.sections[0].id)}
        >
          Open first section
        </button>
      </section>
    );
  if (state.status === "loading")
    return <PageLoading label="Loading reviewed section…" />;
  if (state.status === "error")
    return (
      <ContentState
        title="Section unavailable"
        message="This section could not be loaded. Choose another section or use the original document."
      />
    );
  const figures = new Map(data.figures.map((figure) => [figure.id, figure]));
  return (
    <article className="structured-section">
      <header>
        <span className="eyebrow">
          {sourcePages(
            state.detail.section.page_start,
            state.detail.section.page_end,
          )}
        </span>
        <h2>{state.detail.section.title}</h2>
      </header>
      {state.detail.blocks.length > 0 ? (
        state.detail.blocks.map((block) => (
          <GuidelineBlockRenderer
            block={block}
            figure={figures.get(block.id)}
            key={block.id}
            onOpenSourcePage={onOpenSourcePage}
          />
        ))
      ) : (
        <ContentState
          title="No reviewed blocks"
          message="Use the original document for this section."
        />
      )}
    </article>
  );
}

function TablesView({
  items,
  onOpenSourcePage,
}: {
  items: PublicGuidelineTable[];
  onOpenSourcePage: (page: number) => void;
}) {
  if (!items.length)
    return (
      <ContentState
        title="No reviewed tables"
        message="This publication does not expose any reviewed structured tables."
      />
    );
  return (
    <section className="content-collection">
      <header>
        <span className="eyebrow">Tables</span>
        <h2>Reviewed tables</h2>
      </header>
      {items.map((item) => (
        <article key={item.id} id={`block-${item.id}`}>
          <StructuredTable content={item.content} />
          {item.page_start && (
            <button
              className="block-source"
              onClick={() => onOpenSourcePage(item.page_start!)}
            >
              Source page {sourcePages(item.page_start, item.page_end)}
            </button>
          )}
        </article>
      ))}
    </section>
  );
}

function FiguresView({
  items,
  onOpenSourcePage,
}: {
  items: PublicGuidelineFigure[];
  onOpenSourcePage: (page: number) => void;
}) {
  if (!items.length)
    return (
      <ContentState
        title="No reviewed figures"
        message="This publication does not expose any reviewed figures."
      />
    );
  return (
    <section className="content-collection">
      <header>
        <span className="eyebrow">Figures</span>
        <h2>Reviewed figures and diagrams</h2>
      </header>
      <div className="figure-grid">
        {items.map((item) => {
          const source = safeExternalAssetUrl(item.asset.url);
          return (
            <figure key={item.id} id={`block-${item.id}`}>
              {source ? (
                <img
                  src={source}
                  alt={item.content.alternative_text}
                  loading="lazy"
                />
              ) : (
                <div
                  className="asset-placeholder"
                  role="img"
                  aria-label={item.content.alternative_text}
                >
                  Reviewed figure unavailable
                </div>
              )}
              {item.content.caption && (
                <figcaption>{item.content.caption}</figcaption>
              )}
              {item.page_start && (
                <button
                  className="block-source"
                  onClick={() => onOpenSourcePage(item.page_start!)}
                >
                  Source page {sourcePages(item.page_start, item.page_end)}
                </button>
              )}
            </figure>
          );
        })}
      </div>
    </section>
  );
}

function AlgorithmsView({
  items,
  onOpenSourcePage,
}: {
  items: PublicGuidelineAlgorithm[];
  onOpenSourcePage: (page: number) => void;
}) {
  if (!items.length)
    return (
      <ContentState
        title="No reviewed algorithms"
        message="This publication does not expose a reviewed structured algorithm."
      />
    );
  return (
    <section className="content-collection">
      <header>
        <span className="eyebrow">Algorithms</span>
        <h2>Reviewed clinical pathways</h2>
        <p>
          These diagrams present published guidance and are not executable
          decision tools.
        </p>
      </header>
      {items.map((item) => (
        <article key={item.id} id={`block-${item.id}`}>
          <StructuredAlgorithm content={item.content} />
          {item.page_start && (
            <button
              className="block-source"
              onClick={() => onOpenSourcePage(item.page_start!)}
            >
              Source page {sourcePages(item.page_start, item.page_end)}
            </button>
          )}
        </article>
      ))}
    </section>
  );
}

function ContentState({ title, message }: { title: string; message: string }) {
  return (
    <div className="library-state">
      <h2>{title}</h2>
      <p>{message}</p>
    </div>
  );
}
function Meta({ label, value }: { label: string; value?: string }) {
  return value ? (
    <div>
      <dt>{label}</dt>
      <dd>{value}</dd>
    </div>
  ) : null;
}
function ReaderMessage({
  title,
  message,
  children,
}: {
  title: string;
  message: string;
  children?: React.ReactNode;
}) {
  return (
    <main className="reader-message">
      <Brand />
      <h1>{title}</h1>
      <p>{message}</p>
      {children}
      <Link to="/">Return to guideline library</Link>
    </main>
  );
}

function availableViews(data: ReaderData): ReaderView[] {
  const views: ReaderView[] = data.markdown?.content.trim()
    ? ["read", "overview"]
    : ["overview"];
  if (data.manifest?.has_chapters && data.sections.length)
    views.push("chapters");
  if (data.manifest?.has_tables) views.push("tables");
  if (data.manifest?.has_figures) views.push("figures");
  if (data.manifest?.has_algorithms) views.push("algorithms");
  return views;
}
function sectionDisplayState(
  state: SectionState,
  selectedId: string,
  sections: PublicGuidelineSection[],
): SectionDisplayState {
  if (!selectedId) return { status: "idle" };
  if (!sections.some((section) => section.id === selectedId))
    return { status: "error", sectionId: selectedId };
  if (state.status !== "idle" && state.sectionId === selectedId) return state;
  return { status: "loading" };
}
function parseView(value: string | null): ReaderView {
  return (
    [
      "read",
      "overview",
      "chapters",
      "tables",
      "figures",
      "algorithms",
    ] as ReaderView[]
  ).includes(value as ReaderView)
    ? (value as ReaderView)
    : "read";
}
function viewLabel(view: ReaderView) {
  return view === "read"
    ? "Read"
    : view === "chapters"
      ? "Chapters"
      : view.charAt(0).toUpperCase() + view.slice(1);
}
function qualityLabel(value?: string) {
  return value ? value.replaceAll("_", " ") : "Compatibility mode";
}
function sourcePages(start?: number, end?: number) {
  return start
    ? `Page${end && end !== start ? "s" : ""} ${end && end !== start ? `${start}–${end}` : start}`
    : "";
}
function formatDate(value?: string) {
  if (!value) return "";
  const parsed = new Date(value);
  return Number.isNaN(parsed.valueOf())
    ? value
    : new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(
        parsed,
      );
}
function safeExternalAssetUrl(value: string) {
  return /^https?:\/\//i.test(value) ? value : undefined;
}
async function openOriginal(id: string, page?: number) {
  try {
    const asset = await getPublicGuidelineOriginal(id);
    const url = new URL(asset.url);
    if (page) url.hash = `page=${page}`;
    window.open(url.toString(), "_blank", "noopener,noreferrer");
  } catch {
    window.alert(
      "The original document is currently unavailable. Please try again.",
    );
  }
}
function updateMetaDescription(description: string) {
  let element = document.querySelector<HTMLMetaElement>(
    'meta[name="description"]',
  );
  if (!element) {
    element = document.createElement("meta");
    element.name = "description";
    document.head.appendChild(element);
  }
  element.content =
    description || "Published clinical guidance from MediGuide.";
}
function openCitation(
  citation: PublicAICitation,
  sections: PublicGuidelineSection[],
  selectSection: (id: string) => void,
  openSource: () => void,
) {
  if (
    citation.section_id &&
    sections.some((section) => section.id === citation.section_id)
  ) {
    selectSection(citation.section_id);
    // The section may still need to be fetched. The reader's hash effect waits
    // for that request and scrolls once the cited block exists in the DOM.
    if (citation.block_id)
      window.location.hash = `block-${encodeURIComponent(citation.block_id)}`;
    return;
  }
  if (citation.page_start) openSource();
}
