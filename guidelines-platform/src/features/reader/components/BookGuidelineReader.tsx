import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-router-dom";

import type {
  PublicAICitation,
  PublicGuideline,
  PublicGuidelineManifest,
  PublicMarkdown,
} from "../../../api/public-guidelines";
import { Brand } from "../../../components/common/Brand";
import { ThemeToggle } from "../../../components/common/ThemeToggle";
import { getMarkdownHeadings } from "../../../lib/markdown/headings";
import {
  buildMarkdownSearchIndex,
  searchMarkdown,
} from "../../../lib/markdown/search";
import { SecureMarkdown } from "./SecureMarkdown";
import { GuidelineAssistant } from "./GuidelineAssistant";

export type SupplementalReaderView =
  | "overview"
  | "chapters"
  | "tables"
  | "figures"
  | "algorithms";

type BookGuidelineReaderProps = {
  guideline: PublicGuideline;
  manifest?: PublicGuidelineManifest;
  markdown: PublicMarkdown;
  supplementalViews: SupplementalReaderView[];
  partial: boolean;
  onSelectView: (view: SupplementalReaderView) => void;
  onOpenOriginal: (page?: number) => void;
  onCitation: (citation: PublicAICitation) => void;
};

export function BookGuidelineReader({
  guideline,
  manifest,
  markdown,
  supplementalViews,
  partial,
  onSelectView,
  onOpenOriginal,
  onCitation,
}: BookGuidelineReaderProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [activeHeading, setActiveHeading] = useState("");
  const [fontScale, setFontScale] = useState(1);
  const [assistantOpen, setAssistantOpen] = useState(false);
  const searchInput = useRef<HTMLInputElement>(null);
  const headings = useMemo(() => getMarkdownHeadings(markdown.content), [markdown.content]);
  const searchIndex = useMemo(() => buildMarkdownSearchIndex(markdown.content), [markdown.content]);
  const results = useMemo(() => searchMarkdown(searchIndex, query), [query, searchIndex]);
  const content = useMemo(() => removeLeadingTitle(markdown.content, guideline.title), [guideline.title, markdown.content]);

  useEffect(() => {
    const elements = headings
      .map((heading) => document.getElementById(heading.id))
      .filter((element): element is HTMLElement => Boolean(element));
    if (!elements.length || !("IntersectionObserver" in window)) return;
    const observer = new IntersectionObserver((entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (visible?.target.id) setActiveHeading(visible.target.id);
    }, { rootMargin: "-15% 0px -72%", threshold: [0, 1] });
    elements.forEach((element) => observer.observe(element));
    return () => observer.disconnect();
  }, [headings]);

  const openSearch = () => {
    setSidebarOpen(true);
    window.setTimeout(() => searchInput.current?.focus(), 0);
  };

  const visitHeading = (id: string) => {
    window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}#${encodeURIComponent(id)}`);
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
    setActiveHeading(id);
    setSidebarOpen(false);
  };

  const share = async () => {
    const shareData = { title: guideline.title, text: guideline.description, url: window.location.href };
    try {
      if (navigator.share) await navigator.share(shareData);
      else await navigator.clipboard.writeText(window.location.href);
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
    }
  };

  return (
    <div className="reader-site book-reader" style={{ "--reader-font-scale": fontScale } as React.CSSProperties}>
      <a className="skip-link" href="#guideline-document">Skip to clinical content</a>
      <header className="reader-header">
        <button className="reader-menu-button icon-button" type="button" aria-label="Open contents" onClick={() => setSidebarOpen(true)}><MenuIcon /></button>
        <Link className="reader-title" to="/"><span>MG</span><strong>{guideline.title}</strong></Link>
        <div className="reader-actions">
          <Link to="/">Guideline library</Link>
          <button className="icon-button" type="button" aria-label="Search this guideline" onClick={openSearch}><SearchIcon /></button>
          <button className="reader-font-button icon-button" type="button" aria-label="Change text size" title="Change text size" onClick={() => setFontScale((value) => value >= 1.2 ? 1 : Number((value + .1).toFixed(1)))}>A</button>
          <button className="reader-ai-button" type="button" onClick={() => setAssistantOpen(true)}><SparkleIcon /> Ask AI</button>
          <ThemeToggle />
          <button className="icon-button" type="button" aria-label="Share guideline" onClick={share}><ShareIcon /></button>
          <button className="icon-button" type="button" aria-label="Print guideline" onClick={() => window.print()}><PrintIcon /></button>
        </div>
      </header>

      <aside className={`reader-sidebar ${sidebarOpen ? "is-open" : ""}`} aria-label="Guideline contents">
        <div className="reader-sidebar-brand"><Brand /><button className="sidebar-close icon-button" type="button" aria-label="Close contents" onClick={() => setSidebarOpen(false)}>×</button></div>
        <div className="sidebar-publication"><span>Published guideline</span><strong>{guideline.title}</strong><small>{guideline.source_org}{guideline.version ? ` · Version ${guideline.version}` : ""}</small></div>
        <label className="reader-search"><SearchIcon /><span className="visually-hidden">Search this guideline</span><input ref={searchInput} type="search" value={query} placeholder="Search this guideline…" onChange={(event) => setQuery(event.target.value)} /></label>
        <nav className="contents-navigation" aria-label={query.trim() ? "Search results" : "Table of contents"}>
          {query.trim() ? <div className="search-results">
            <div className="results-label">{results.length} matching section{results.length === 1 ? "" : "s"}</div>
            {results.map((result) => <button type="button" key={result.id} onClick={() => visitHeading(result.id)}><small>{result.title}</small><span>{result.snippet || "Open this section"}</span></button>)}
            {!results.length && <p className="empty-search">No section matches “{query}”. Try a condition, treatment, medicine, or phrase from the guideline.</p>}
          </div> : <>
            <button type="button" className={`front-matter-link ${activeHeading ? "" : "active"}`} onClick={() => visitHeading("guideline-document")}>Guideline overview</button>
            {headings.map((heading) => <button type="button" className={`toc-link toc-depth-${heading.depth} ${activeHeading === heading.id ? "active" : ""}`} key={heading.id} aria-current={activeHeading === heading.id ? "location" : undefined} onClick={() => visitHeading(heading.id)}>{heading.text}</button>)}
          </>}
        </nav>
        <div className="reader-sidebar-footer">Ministry of Health · Published clinical guidance</div>
      </aside>
      {sidebarOpen && <button className="reader-scrim" type="button" aria-label="Close contents" onClick={() => setSidebarOpen(false)} />}

      <main className="reader-main" id="guideline-document">
        <article className="reader-column">
          <header className="guideline-metadata">
            <span className="eyebrow">{guideline.program_area || "Clinical guideline"}</span>
            <h1>{guideline.title}</h1>
            {guideline.description && <p>{guideline.description}</p>}
            <dl>
              <Meta label="Source" value={guideline.source_org} />
              <Meta label="Version" value={guideline.version} />
              <Meta label="Published" value={formatDate(guideline.publication_date)} />
              <Meta label="Review date" value={formatDate(guideline.review_date)} />
              <Meta label="Language" value={guideline.language} />
            </dl>
            <div className="book-reader-links">
              {supplementalViews.map((view) => <button type="button" key={view} onClick={() => onSelectView(view)}>{viewLabel(view)}</button>)}
              {manifest?.has_original_pdf !== false && <button type="button" onClick={() => onOpenOriginal()}>Original PDF</button>}
            </div>
          </header>
          {partial && <div className="partial-extraction-notice" role="status">Some supplemental structured content is unavailable. This published Markdown remains searchable; use the original document as the fidelity reference.</div>}
          <div className="markdown-content book-markdown"><SecureMarkdown content={content} /></div>
        </article>
      </main>
      <button className="assistant-fab" type="button" aria-label="Ask AI about this guideline" onClick={() => setAssistantOpen(true)}><SparkleIcon /><span>Ask AI</span></button>
      <GuidelineAssistant key={guideline.id} guideline={guideline} open={assistantOpen} onClose={() => setAssistantOpen(false)} onCitation={(citation) => { setAssistantOpen(false); onCitation(citation); }} />
    </div>
  );
}

function Meta({ label, value }: { label: string; value?: string }) {
  return value ? <div><dt>{label}</dt><dd>{value}</dd></div> : null;
}

function formatDate(value?: string) {
  if (!value) return "";
  const parsed = new Date(value);
  return Number.isNaN(parsed.valueOf()) ? value : new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(parsed);
}

function viewLabel(view: SupplementalReaderView) {
  return view === "chapters" ? "Reviewed chapters" : `Reviewed ${view}`;
}

function removeLeadingTitle(content: string, title: string) {
  const match = /^\s*#\s+(.+?)\s*#*\r?\n+/.exec(content);
  if (!match) return content;
  const normalize = (value: string) => value.replace(/[*_`~]/g, "").trim().toLocaleLowerCase();
  return normalize(match[1]) === normalize(title) ? content.slice(match[0].length) : content;
}

function MenuIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 7h16M4 12h16M4 17h16" /></svg>; }
function SearchIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></svg>; }
function ShareIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="18" cy="5" r="2.5" /><circle cx="6" cy="12" r="2.5" /><circle cx="18" cy="19" r="2.5" /><path d="m8.2 10.8 7.6-4.5M8.2 13.2l7.6 4.5" /></svg>; }
function PrintIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M7 9V3h10v6M7 17H5a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2" /><path d="M7 14h10v7H7z" /></svg>; }
function SparkleIcon() { return <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="m12 3 1.3 3.7L17 8l-3.7 1.3L12 13l-1.3-3.7L7 8l3.7-1.3L12 3ZM18.5 13l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2ZM5 13l.7 1.8 1.8.7-1.8.7L5 18l-.7-1.8-1.8-.7 1.8-.7L5 13Z" /></svg>; }
