import type { Metadata } from "next";
import type { CSSProperties } from "react";
import { ThemeProvider } from "@/components/theme-provider";
import { BackendClientInit } from "@/components/backend-client-init";
import { Toaster } from "@/components/ui/sonner";
import { QueryProvider } from "@/components/query-provider";
import { withDashboardBasePath } from "@/lib/dashboard-path";
import "./globals.css";

export const metadata: Metadata = {
  title: "MediGuide Dashboard",
  description: "Administrative dashboard for MediGuide health platform",
  icons: {
    icon: withDashboardBasePath("/coat_of_arms.png"),
    apple: withDashboardBasePath("/coat_of_arms.png"),
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className="antialiased"
        style={
          {
            "--font-geist-sans": "ui-sans-serif, system-ui, sans-serif",
            "--font-geist-mono": "ui-monospace, SFMono-Regular, monospace",
          } as CSSProperties
        }
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <QueryProvider>
            <BackendClientInit />
            {children}
            <Toaster />
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
