import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import {
  listPublicGuidelines,
  type PublicGuideline,
} from "../../api/public-guidelines";
import { ArrowIcon, BookIcon, ShieldIcon } from "../../components/common/Icons";
import { dashboardLoginUrl } from "../../config";

type LibraryState =
  | { status: "loading" }
  | { status: "ready"; items: PublicGuideline[]; total: number }
  | { status: "error" };

export function LandingPage() {
  const [search, setSearch] = useState("");
  const [programArea, setProgramArea] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [library, setLibrary] = useState<LibraryState>({ status: "loading" });

  useEffect(() => {
    document.title = "MediGuide Clinical Guidelines";
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      setLibrary({ status: "loading" });
      const startedAt = performance.now();
      listPublicGuidelines(
        { search, programArea, page: 1, perPage: 40 },
        controller.signal,
      )
        .then((result) => {
          setLibrary({
            status: "ready",
            items: result.items,
            total: result.total_items,
          });
          if (import.meta.env.DEV) {
            console.info("Public guideline list loaded", {
              durationMs: Math.round(performance.now() - startedAt),
              resultCount: result.items.length,
            });
          }
        })
        .catch(() => {
          if (!controller.signal.aborted) {
            setLibrary({ status: "error" });
            if (import.meta.env.DEV) {
              console.warn("Public guideline list request failed");
            }
          }
        });
    }, 250);

    return () => {
      window.clearTimeout(timer);
      controller.abort();
    };
  }, [search, programArea, reloadKey]);

  const programAreas = useMemo(() => {
    const areas = library.status === "ready"
      ? library.items.map((item) => item.program_area).filter(Boolean)
      : [];
    if (programArea) areas.push(programArea);
    return [...new Set(areas)].sort();
  }, [library, programArea]);

  return (
    <>
      <section className="landing-hero">
        <div className="page-shell hero-grid">
          <div className="hero-copy">
            <span className="eyebrow">Republic of Uganda · Ministry of Health</span>
            <h1>
              Clinical guidance,
              <span> ready when care decisions matter.</span>
            </h1>
            <p>
              Browse published clinical guidelines in a clear, searchable
              format designed for health workers at every level of care.
            </p>
            <div className="hero-actions">
              <a className="button button-primary" href="#guidelines">
                Browse guidelines <ArrowIcon />
              </a>
              <a className="button button-quiet" href={dashboardLoginUrl}>
                Open staff dashboard
              </a>
            </div>
            <div className="trust-line">
              <ShieldIcon />
              <span>Only reviewed and published guidance is shown</span>
            </div>
          </div>

          <div className="hero-publication" aria-hidden="true">
            <div className="hero-book">
              <span>Republic of Uganda</span>
              <div>
                <small>Ministry of Health</small>
                <strong>Clinical Guidelines</strong>
                <em>Published guidance for common health conditions</em>
              </div>
              <b>MEDIGUIDE</b>
            </div>
            <div className="hero-book-shadow" />
          </div>
        </div>
      </section>

      <section className="library-section page-shell" id="guidelines">
        <div className="section-intro">
          <div>
            <span className="eyebrow">Clinical library</span>
            <h2>Available publications</h2>
          </div>
          <p>Select a publication to read its current published version.</p>
        </div>

        <div className="library-filters" role="search">
          <label>
            <span>Search guidelines</span>
            <input
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search by title, source, or topic"
            />
          </label>
          <label>
            <span>Program area</span>
            <select
              value={programArea}
              onChange={(event) => setProgramArea(event.target.value)}
            >
              <option value="">All program areas</option>
              {programAreas.map((area) => (
                <option value={area} key={area}>{area}</option>
              ))}
            </select>
          </label>
        </div>

        <div className="visually-hidden" role="status" aria-live="polite">
          {library.status === "ready"
            ? `${library.total} guideline${library.total === 1 ? "" : "s"} found`
            : library.status === "loading"
              ? "Loading guidelines"
              : "Guidelines could not be loaded"}
        </div>

        {library.status === "loading" && <GuidelineSkeleton />}

        {library.status === "error" && (
          <div className="library-state">
            <h3>We could not load the guideline library.</h3>
            <p>Check your connection and try again.</p>
            <button className="button button-primary" onClick={() => setReloadKey((key) => key + 1)}>
              Try again
            </button>
          </div>
        )}

        {library.status === "ready" && library.items.length === 0 && (
          <div className="library-state">
            <h3>No published guidelines match these filters.</h3>
            <button className="button button-quiet" onClick={() => {
              setSearch("");
              setProgramArea("");
            }}>
              Clear filters
            </button>
          </div>
        )}

        {library.status === "ready" && (
          <div className="publication-grid">
            {library.items.map((guideline) => (
              <BackendGuidelineCard guideline={guideline} key={guideline.id} />
            ))}
          </div>
        )}

      </section>

      <section className="about-section" id="about">
        <div className="page-shell about-grid">
          <div>
            <span className="eyebrow">Built for practical use</span>
            <h2>Clinical guidance in a format that is easier to navigate.</h2>
          </div>
          <div className="about-points">
            <article>
              <BookIcon />
              <div>
                <h3>Current published content</h3>
                <p>New versions appear here after review and publication, without rebuilding this website.</p>
              </div>
            </article>
            <article>
              <SearchIcon />
              <div>
                <h3>Find guidance quickly</h3>
                <p>Search by publication title, source organization, or clinical topic.</p>
              </div>
            </article>
          </div>
        </div>
      </section>
    </>
  );
}

function BackendGuidelineCard({ guideline }: { guideline: PublicGuideline }) {
  return (
    <Link className="publication-card" to={`/guidelines/${guideline.id}`}>
      <div className="publication-cover">
        <span>{guideline.country || "Clinical guideline"}</span>
        <strong>{guideline.title.slice(0, 2).toUpperCase()}</strong>
        <small>{guideline.version}</small>
      </div>
      <div className="publication-card-content">
        <span className="publication-publisher">{guideline.source_org || guideline.program_area}</span>
        <h3>{guideline.title}</h3>
        <p>{guideline.description || "Open this publication to read the current clinical guidance."}</p>
        <dl className="publication-meta">
          <div><dt>Version</dt><dd>{guideline.version}</dd></div>
          <div><dt>Language</dt><dd>{guideline.language || "en"}</dd></div>
        </dl>
        <span className="card-action">Read guideline <ArrowIcon /></span>
      </div>
    </Link>
  );
}

function GuidelineSkeleton() {
  return (
    <div className="publication-grid" aria-hidden="true">
      {[0, 1].map((item) => (
        <div className="publication-card guideline-skeleton" key={item}>
          <div className="publication-cover" />
          <div className="publication-card-content">
            <i /><i /><i /><i />
          </div>
        </div>
      ))}
    </div>
  );
}

function SearchIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8">
      <circle cx="11" cy="11" r="6" />
      <path d="m16 16 4 4" />
    </svg>
  );
}
