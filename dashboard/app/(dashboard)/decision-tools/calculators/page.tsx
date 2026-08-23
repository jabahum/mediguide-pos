"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Calculator, Loader2, Plus, Search } from "lucide-react";
import { NativeClinicalTool } from "@/components/clinical-tools/native-clinical-tool";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageHeader } from "@/components/ui/page-header";
import { Textarea } from "@/components/ui/textarea";
import { getCurrentUser } from "@/lib/backend-client";
import { usePermissionContext } from "@/lib/permission-context";
import { showToast } from "@/lib/toast";
import { calculatorService } from "@/services/calculator.service";
import {
  clinicalToolService,
  type ClinicalToolDefinition,
} from "@/services/clinical-tool.service";
import { SupportTicketsService } from "@/services/support-tickets.service";
import { SupportTicketsPriorityOptions } from "@/types/backend-types";

type ToolSummary = {
  id: string;
  name: string;
  description?: string;
  type?: string;
  status?: string;
  version?: string;
};

export default function CalculatorsPage() {
  const router = useRouter();
  const { hasPermission, loading: permissionLoading } = usePermissionContext();
  const [tools, setTools] = React.useState<ToolSummary[]>([]);
  const [selectedId, setSelectedId] = React.useState("");
  const [definition, setDefinition] =
    React.useState<ClinicalToolDefinition | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [definitionLoading, setDefinitionLoading] = React.useState(false);
  const [definitionError, setDefinitionError] = React.useState<string | null>(
    null,
  );
  const [search, setSearch] = React.useState("");
  const [requestOpen, setRequestOpen] = React.useState(false);
  const [requestSubmitting, setRequestSubmitting] = React.useState(false);
  const [requestForm, setRequestForm] = React.useState({
    name: "",
    category: "",
    description: "",
    justification: "",
  });

  React.useEffect(() => {
    if (!permissionLoading && !hasPermission("content", "read:any"))
      router.replace("/decision-tools");
  }, [permissionLoading, hasPermission, router]);
  React.useEffect(() => {
    let cancelled = false;
    setLoading(true);
    calculatorService
      .list({
        page: 1,
        perPage: 100,
        status: "active",
        sort: "name",
        order: "asc",
      })
      .then((result) => {
        if (cancelled) return;
        const items = result.items.map(
          (item) => item as unknown as ToolSummary,
        );
        setTools(items);
        setSelectedId((current) => current || items[0]?.id || "");
      })
      .catch((error) => {
        console.error("Failed to load clinical tools:", error);
        showToast.error(
          "Load failed",
          "Could not load the clinical-tool catalogue",
        );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  React.useEffect(() => {
    if (!selectedId) {
      setDefinition(null);
      setDefinitionError(null);
      return;
    }
    let cancelled = false;
    setDefinition(null);
    setDefinitionError(null);
    setDefinitionLoading(true);
    clinicalToolService
      .definition(selectedId)
      .then((value) => {
        if (!cancelled) setDefinition(value.definition);
      })
      .catch((error) => {
        console.error("Published schema unavailable:", error);
        if (!cancelled)
          setDefinitionError(
            "A clinically reviewed JSON-schema version has not been published for this tool yet.",
          );
      })
      .finally(() => {
        if (!cancelled) setDefinitionLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedId]);

  const selected = tools.find((tool) => tool.id === selectedId);
  const visibleTools = tools.filter((tool) =>
    `${tool.name} ${tool.description ?? ""}`
      .toLowerCase()
      .includes(search.trim().toLowerCase()),
  );

  async function submitRequest() {
    const user = getCurrentUser();
    if (!user?.id) {
      showToast.error(
        "Authentication required",
        "Please log in to submit a request",
      );
      return;
    }
    if (!requestForm.name.trim() || !requestForm.description.trim()) {
      showToast.error(
        "Missing fields",
        "Please provide a name and description",
      );
      return;
    }
    setRequestSubmitting(true);
    try {
      const details = [
        requestForm.description.trim(),
        requestForm.category.trim() &&
          `Category: ${requestForm.category.trim()}`,
        requestForm.justification.trim() &&
          `Clinical justification: ${requestForm.justification.trim()}`,
      ]
        .filter(Boolean)
        .join("\n\n");
      await SupportTicketsService.createTicket({
        subject: `Clinical Tool Request: ${requestForm.name.trim()}`,
        description: details,
        priority: SupportTicketsPriorityOptions.normal,
        category: "Clinical Tool Request",
        user_id: user.id,
      });
      showToast.success(
        "Request submitted",
        "The clinical-tool request was logged for review",
      );
      setRequestOpen(false);
      setRequestForm({
        name: "",
        category: "",
        description: "",
        justification: "",
      });
    } catch (error) {
      console.error("Failed to submit tool request:", error);
      showToast.error("Submission failed", "Could not submit the request");
    } finally {
      setRequestSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Clinical Tools"
        description="Run clinically reviewed calculators, decision tools, and checklists"
        actions={[
          {
            label: "Request Tool",
            icon: <Plus />,
            onClick: () => setRequestOpen(true),
          },
        ]}
      />
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Published tools</CardDescription>
            <CardTitle>{tools.length}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Schema runtime</CardDescription>
            <CardTitle className="text-base">JSON schema v1</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Execution policy</CardDescription>
            <CardTitle className="text-base">Native controls only</CardTitle>
          </CardHeader>
        </Card>
      </div>
      <div className="grid min-h-[620px] gap-5 lg:grid-cols-[340px_1fr]">
        <Card>
          <CardHeader>
            <CardTitle>Available tools</CardTitle>
            <CardDescription>Select a published tool to run</CardDescription>
            <div className="relative pt-2">
              <Search className="absolute left-3 top-4.5 h-4 w-4 text-muted-foreground" />
              <Input
                className="pl-9"
                placeholder="Search tools…"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
            </div>
          </CardHeader>
          <CardContent className="space-y-2">
            {loading ? (
              <div className="flex items-center gap-2 py-8 text-sm text-muted-foreground">
                <Loader2 className="animate-spin" />
                Loading tools…
              </div>
            ) : null}
            {!loading && visibleTools.length === 0 ? (
              <p className="py-8 text-center text-sm text-muted-foreground">
                No published tools found.
              </p>
            ) : null}
            {visibleTools.map((tool) => (
              <button
                key={tool.id}
                type="button"
                onClick={() => setSelectedId(tool.id)}
                className={`w-full rounded-lg border p-3 text-left transition-colors ${selectedId === tool.id ? "border-primary bg-primary/5" : "hover:bg-muted/50"}`}
              >
                <div className="flex items-start gap-3">
                  <span className="rounded-md bg-primary/10 p-2 text-primary">
                    <Calculator className="h-4 w-4" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate font-medium">
                      {tool.name}
                    </span>
                    <span className="mt-1 line-clamp-2 block text-xs text-muted-foreground">
                      {tool.description || "Clinical tool"}
                    </span>
                    <Badge className="mt-2" variant="outline">
                      {tool.type || "calculator"}
                    </Badge>
                  </span>
                </div>
              </button>
            ))}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>{selected?.name ?? "Select a clinical tool"}</CardTitle>
            <CardDescription>
              {selected?.description ?? "Inputs and results will appear here."}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {definitionLoading ? (
              <div className="flex min-h-80 items-center justify-center gap-2 text-muted-foreground">
                <Loader2 className="animate-spin" />
                Loading reviewed schema…
              </div>
            ) : null}
            {!definitionLoading && definitionError ? (
              <div className="flex min-h-80 flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center">
                <p className="font-medium">Native clinical tool unavailable</p>
                <p className="mt-2 max-w-md text-sm text-muted-foreground">
                  {definitionError}
                </p>
              </div>
            ) : null}
            {!definitionLoading && definition ? (
              <NativeClinicalTool key={selectedId} definition={definition} />
            ) : null}
          </CardContent>
        </Card>
      </div>
      <Dialog open={requestOpen} onOpenChange={setRequestOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Request a clinical tool</DialogTitle>
            <DialogDescription>
              Requests enter the clinical review workflow before publication.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="request-name">Name</Label>
              <Input
                id="request-name"
                value={requestForm.name}
                onChange={(event) =>
                  setRequestForm((value) => ({
                    ...value,
                    name: event.target.value,
                  }))
                }
              />
            </div>
            <div>
              <Label htmlFor="request-category">Category</Label>
              <Input
                id="request-category"
                value={requestForm.category}
                onChange={(event) =>
                  setRequestForm((value) => ({
                    ...value,
                    category: event.target.value,
                  }))
                }
              />
            </div>
            <div>
              <Label htmlFor="request-description">Description</Label>
              <Textarea
                id="request-description"
                value={requestForm.description}
                onChange={(event) =>
                  setRequestForm((value) => ({
                    ...value,
                    description: event.target.value,
                  }))
                }
              />
            </div>
            <div>
              <Label htmlFor="request-justification">
                Clinical justification
              </Label>
              <Textarea
                id="request-justification"
                value={requestForm.justification}
                onChange={(event) =>
                  setRequestForm((value) => ({
                    ...value,
                    justification: event.target.value,
                  }))
                }
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRequestOpen(false)}>
              Cancel
            </Button>
            <Button disabled={requestSubmitting} onClick={submitRequest}>
              {requestSubmitting ? <Loader2 className="animate-spin" /> : null}
              Submit request
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
