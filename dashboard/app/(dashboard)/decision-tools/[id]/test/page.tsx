"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { NativeClinicalTool } from "@/components/clinical-tools/native-clinical-tool";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { PageHeader } from "@/components/ui/page-header";
import { usePermissionContext } from "@/lib/permission-context";
import { showToast } from "@/lib/toast";
import { calculatorService } from "@/services/calculator.service";
import {
  clinicalToolService,
  type ClinicalToolDefinition,
} from "@/services/clinical-tool.service";
import { DecisionToolWithRelations } from "../../types";

interface DecisionToolTestPageProps {
  params: Promise<{ id: string }>;
}

export function renderPreview({
  definition,
  previewError,
}: {
  definition: ClinicalToolDefinition | null;
  previewError: string | null;
}) {
  if (definition === null) {
    if (previewError)
      return (
        <div className="p-8 text-center text-sm text-muted-foreground">
          <p className="font-medium text-foreground">
            Native clinical tool unavailable
          </p>
          <p className="mt-2">{previewError}</p>
        </div>
      );
    return (
      <div className="flex min-h-72 items-center justify-center text-sm text-muted-foreground">
        Loading reviewed schema…
      </div>
    );
  }
  return <NativeClinicalTool definition={definition} />;
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
  const [definition, setDefinition] =
    React.useState<ClinicalToolDefinition | null>(null);
  const [previewError, setPreviewError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!permLoading && !hasPermission("content", "read:any"))
      router.replace("/decision-tools");
  }, [permLoading, hasPermission, router]);
  React.useEffect(() => {
    let cancelled = false;
    Promise.all([calculatorService.get(id), clinicalToolService.definition(id)])
      .then(([toolData, envelope]) => {
        if (!cancelled) {
          setTool(toolData as DecisionToolWithRelations);
          setDefinition(envelope.definition);
        }
      })
      .catch(async (error) => {
        console.error("Failed to load native decision tool:", error);
        if (cancelled) return;
        try {
          setTool(
            (await calculatorService.get(id)) as DecisionToolWithRelations,
          );
          setPreviewError(
            "A clinically reviewed JSON-schema version has not been published for this tool yet.",
          );
        } catch {
          showToast.error(
            "Load Failed",
            "Could not load the selected decision tool",
          );
          router.push("/decision-tools");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [id, router]);

  if (loading)
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          description="Preparing native test mode"
          showBackButton
          onBack={() => router.push(`/decision-tools/${id}`)}
        />
      </div>
    );
  if (!tool) return null;
  return (
    <div className="space-y-6">
      <PageHeader
        title={`Test ${tool.name}`}
        description="Run the published schema-v1 tool using native dashboard controls"
        showBackButton
        onBack={() => router.push(`/decision-tools/${tool.id}`)}
      />
      <div className="flex flex-wrap gap-3">
        <Badge variant="outline">{tool.type}</Badge>
        <Badge variant="secondary">{tool.status}</Badge>
        <Badge variant="outline">v{tool.version}</Badge>
        <Badge variant="outline">schema_v1</Badge>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Native Tool Preview</CardTitle>
          <CardDescription>
            Inputs and results are rendered directly from the reviewed JSON
            definition
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-lg border bg-background p-6">
            {renderPreview({ definition, previewError })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
