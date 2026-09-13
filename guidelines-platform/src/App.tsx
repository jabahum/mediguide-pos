import { lazy, Suspense } from "react";
import { Route, Routes } from "react-router-dom";

import { PageLoading } from "./components/common/PageLoading";
import { NotFoundPage } from "./features/not-found/NotFoundPage";
import { PublicLayout } from "./layouts/PublicLayout";

const LandingPage = lazy(() =>
  import("./features/landing/LandingPage").then((module) => ({
    default: module.LandingPage,
  })),
);

const PublicGuidelineReaderPage = lazy(() =>
  import("./features/reader/PublicGuidelineReaderPage").then((module) => ({
    default: module.PublicGuidelineReaderPage,
  })),
);

const discovery = () => import("./features/discovery/DiscoveryPages");
const DiseaseDirectoryPage = lazy(() => discovery().then((module) => ({ default: module.DiseaseDirectoryPage })));
const DiseaseDetailPage = lazy(() => discovery().then((module) => ({ default: module.DiseaseDetailPage })));
const HubPage = lazy(() => discovery().then((module) => ({ default: module.HubPage })));
const PillarPage = lazy(() => discovery().then((module) => ({ default: module.PillarPage })));
const SearchPage = lazy(() => discovery().then((module) => ({ default: module.SearchPage })));

export default function App() {
  return (
    <Suspense fallback={<PageLoading label="Opening the guidelines…" />}>
      <Routes>
        <Route element={<PublicLayout />}>
          <Route index element={<LandingPage />} />
		  <Route path="diseases" element={<DiseaseDirectoryPage />} />
		  <Route path="diseases/:slug" element={<DiseaseDetailPage />} />
		  <Route path="hubs/:slug" element={<HubPage />} />
		  <Route path="hubs/:slug/pillars/:pillarSlug" element={<PillarPage />} />
		  <Route path="search" element={<SearchPage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Route>
        <Route
          path="/guidelines/:guidelineId/*"
          element={<PublicGuidelineReaderPage />}
        />
      </Routes>
    </Suspense>
  );
}
