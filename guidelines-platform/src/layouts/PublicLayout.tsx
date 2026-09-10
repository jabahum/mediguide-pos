import { Outlet } from "react-router-dom";

import { Brand } from "../components/common/Brand";
import { ThemeToggle } from "../components/common/ThemeToggle";
import { dashboardLoginUrl } from "../config";

export function PublicLayout() {
  return (
    <div className="public-site">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <header className="public-header">
        <div className="page-shell public-header-inner">
          <Brand />
          <nav className="public-nav" aria-label="Main navigation">
            <a href="#guidelines">Guidelines</a>
            <a href="#about">About</a>
            <ThemeToggle />
            <a
              className="button button-small button-outline"
              href={dashboardLoginUrl}
            >
              Login
            </a>
          </nav>
        </div>
      </header>
      <main id="main-content">
        <Outlet />
      </main>
      <footer className="public-footer">
        <div className="page-shell footer-grid">
          <div>
            <Brand />
            <p>Trusted clinical guidance for health workers across Uganda.</p>
          </div>
          <div>
            <strong>Published by</strong>
            <p>Republic of Uganda · Ministry of Health</p>
          </div>
          <div>
            <strong>For authorized staff</strong>
            <a href={dashboardLoginUrl}>Open the MediGuide dashboard</a>
          </div>
        </div>
      </footer>
    </div>
  );
}
