"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/page-header";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { calculatorService, getCalculatorContent } from "@/services/calculator.service";
import { showToast } from "@/lib/toast";
import { DecisionToolWithRelations } from "../../types";
import { usePermissionContext } from "@/lib/permission-context";
import { getAppFileLabel } from "../../app-file";

interface DecisionToolTestPageProps {
  params: Promise<{ id: string }>;
}

export function renderPreview({
  html,
  previewError,
  title,
}: {
  html: string | null;
  previewError: string | null;
  title: string;
}) {
  if (html === null) {
    if (previewError) {
      return (
        <div className="p-8 text-center text-sm text-muted-foreground">
          {previewError}
        </div>
      );
    }

    return (
      <div className="flex h-[70vh] items-center justify-center text-sm text-muted-foreground">
        Loading preview…
      </div>
    );
  }

  return (
    <iframe
      srcDoc={html}
      title={`${title} preview`}
      className="h-[70vh] w-full"
      sandbox="allow-scripts"
      referrerPolicy="no-referrer"
    />
  );
}

export default function DecisionToolTestPage({
  params,
}: DecisionToolTestPageProps) {
  const router = useRouter();
  const { hasPermission, loading: permLoading } = usePermissionContext();
  const { id } = React.use(params);
  const [tool, setTool] = React.useState<DecisionToolWithRelations | null>(
    null,
  );
  const [loading, setLoading] = React.useState(true);
  const [html, setHtml] = React.useState<string | null>(null);
  const [previewError, setPreviewError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (permLoading) return;
    if (!hasPermission("content", "read:any")) {
      router.replace("/decision-tools");
    }
  }, [permLoading, hasPermission, router]);

  React.useEffect(() => {
    const fetchTool = async () => {
      try {
        const toolData = await calculatorService.get(id) as DecisionToolWithRelations;

        setTool(toolData);
      } catch (error) {
        console.error("Failed to load decision tool test page:", error);
        showToast.error(
          "Load Failed",
          "Could not load the selected decision tool",
        );
        router.push("/decision-tools");
      } finally {
        setLoading(false);
      }
    };

    fetchTool();
  }, [id, router]);

  React.useEffect(() => {
    if (!tool?.id) {
      setHtml(null);
      setPreviewError(null);
      return;
    }

    let cancelled = false;
    setHtml(null);
    setPreviewError(null);

    getCalculatorContent(tool.id)
      .then((text) => {
        if (!cancelled) setHtml(text);
      })
      .catch((error) => {
        console.error("Failed to fetch tool preview:", error);
        if (!cancelled) {
          setPreviewError(
            "Could not load the preview. Try reloading the page.",
          );
        }
      });

    return () => {
      cancelled = true;
    };
  }, [tool?.id]);

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          description="Preparing test mode"
          showBackButton={true}
          onBack={() => router.push(`/decision-tools/${id}`)}
        />
      </div>
    );
  }

  if (!tool) {
    return null;
  }

  const appFileLabel = getAppFileLabel(tool.appFile);

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Test ${tool.name}`}
        description="Preview the uploaded tool artifact in the dashboard"
        showBackButton={true}
        onBack={() => router.push(`/decision-tools/${tool.id}`)}
      />

      <div className="flex flex-wrap gap-3">
        <Badge variant="outline">{tool.type}</Badge>
        <Badge variant="secondary">{tool.status}</Badge>
        <Badge variant="outline">v{tool.version}</Badge>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Tool Preview</CardTitle>
          <CardDescription>
            Uploaded calculator or checklist asset attached to this record
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {tool.id ? (
            <>
              <div className="flex items-center gap-3">
                <span className="text-sm text-muted-foreground">
                  {appFileLabel}
                </span>
              </div>

              <div className="overflow-hidden rounded-lg border bg-background">
                {renderPreview({ html, previewError, title: tool.name })}
              </div>
            </>
          ) : (
            <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
              No uploaded app file is attached to this tool, so there is nothing
              to preview.
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
