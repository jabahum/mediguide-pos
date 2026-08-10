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

export default function App() {
  return (
    <Suspense fallback={<PageLoading label="Opening the guidelines…" />}>
      <Routes>
        <Route element={<PublicLayout />}>
          <Route index element={<LandingPage />} />
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
