"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Archive,
  ArrowDown,
  ArrowUp,
  Eye,
  FileUp,
  Plus,
  Save,
  Send,
  Trash2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { MultiSelect } from "@/components/ui/multi-select";
import { PageHeader } from "@/components/ui/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { hasBackendPermission } from "@/lib/backend-client";
import { showToast } from "@/lib/toast";
import { outbreaksService } from "@/services/outbreaks.service";
import {
  AssignableResource,
  ContentHubWorkspace,
  ContentPillar,
  HubAudit,
  HubTemplate,
  contentHubService,
  diseaseService,
} from "@/services/content-hubs.service";

const itemTypes = [
  "guideline",
  "outbreak_document",
  "situation_report",
  "algorithm",
  "clinical_tool",
  "form",
  "drug_reference",
  "internal_route",
  "approved_external_url",
];
const emptyHub = {
  name: "",
  slug: "",
  description: "",
  icon: "",
  color: "",
  audience: "all",
  sort_order: 0,
  disease_ids: [] as string[],
  outbreak_ids: [] as string[],
};

export function ContentHubEditor({ id }: { id?: string }) {
  const router = useRouter();
  const canManageHub = hasBackendPermission("content_hub.manage");
  const canPublishHub = hasBackendPermission("content_hub.publish");
  const canArchiveHub = hasBackendPermission("content_hub.archive");
  const canManagePillars = hasBackendPermission("content_pillar.manage");
  const canApplyTemplate = hasBackendPermission("content_hub.template.manage");
  const [workspace, setWorkspace] = React.useState<ContentHubWorkspace | null>(
    null,
  );
  const [form, setForm] = React.useState(emptyHub);
  const [diseases, setDiseases] = React.useState<
    Array<{ id: string; name: string; parent_name?: string; color?: string }>
  >([]);
  const [outbreaks, setOutbreaks] = React.useState<
    Array<{ id: string; title: string }>
  >([]);
  const [templates, setTemplates] = React.useState<HubTemplate[]>([]);
  const [audit, setAudit] = React.useState<HubAudit[]>([]);
  const [templateId, setTemplateId] = React.useState("");
  const [busy, setBusy] = React.useState(false);

  const load = React.useCallback(async () => {
    try {
      const [diseasePage, outbreakPage, templateRows] = await Promise.all([
        diseaseService.list("", "active"),
        outbreaksService.list({ page: 1, per_page: 100 }),
        contentHubService.templates(),
      ]);
      setDiseases(diseasePage.items || []);
      setOutbreaks(
        (outbreakPage.items || []).map((value) => ({
          id: value.id!,
          title: value.title || "Untitled outbreak",
        })),
      );
      setTemplates(templateRows || []);
      if (id) {
        const [value, events] = await Promise.all([
          contentHubService.workspace(id),
          contentHubService.audit(id),
        ]);
        setWorkspace(value);
        setAudit(events.items || []);
        setForm({
          name: value.hub.name,
          slug: value.hub.slug,
          description: value.hub.description || "",
          icon: value.hub.icon || "",
          color: value.hub.color || "",
          audience: value.hub.audience || "all",
          sort_order: value.hub.sort_order || 0,
          disease_ids: value.hub.diseases?.map((row) => row.id) || [],
          outbreak_ids: value.hub.outbreaks?.map((row) => row.id) || [],
        });
      }
    } catch (error) {
      showToast.error("Hub workspace unavailable", actionable(error));
    }
  }, [id]);
  React.useEffect(() => {
    void load();
  }, [load]);

  async function save() {
    if (!form.name.trim()) return;
    setBusy(true);
    try {
      if (!workspace) {
        const created = await contentHubService.create(form);
        showToast.success(
          "Hub created",
          "Add a template or create the first pillar.",
        );
        router.replace(`/content-hubs/${created.id}`);
        return;
      }
      await contentHubService.update(workspace.hub.id, {
        ...form,
        lock_version: workspace.hub.lock_version,
      });
      showToast.success(
        "Hub saved",
        "Public metadata and classifications were updated.",
      );
      await load();
    } catch (error) {
      showToast.error("Hub not saved", actionable(error));
    } finally {
      setBusy(false);
    }
  }
  async function transition(action: "publish" | "archive") {
    if (!workspace) return;
    if (!confirm(`${action === "publish" ? "Publish" : "Archive"} this hub?`))
      return;
    try {
      await contentHubService.transition(
        workspace.hub.id,
        action,
        workspace.hub.lock_version,
      );
      showToast.success(
        `Hub ${action === "publish" ? "published" : "archived"}`,
      );
      await load();
    } catch (error) {
      showToast.error("Workflow failed", actionable(error));
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={workspace?.hub.name || "Create content hub"}
        description="Configure reusable pillars and approved resources without an application release."
      />
      <div className="flex flex-wrap gap-2">
        <Button variant="outline" asChild>
          <Link href="/content-hubs">Back to hubs</Link>
        </Button>
        {canManageHub ? <Button
          disabled={busy || !form.name.trim()}
          onClick={() => void save()}
        >
          <Save className="mr-2 h-4 w-4" />
          Save
        </Button> : null}
        {workspace ? (
          <>
            {canPublishHub ? <Button
              disabled={workspace.hub.status !== "draft"}
              onClick={() => void transition("publish")}
            >
              <Send className="mr-2 h-4 w-4" />
              Publish
            </Button> : null}
            {canArchiveHub ? <Button
              variant="outline"
              disabled={workspace.hub.status === "archived"}
              onClick={() => void transition("archive")}
            >
              <Archive className="mr-2 h-4 w-4" />
              Archive
            </Button> : null}
          </>
        ) : null}
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Hub metadata and scope</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          <Field
            label="Name"
            value={form.name}
            disabled={!canManageHub}
            onChange={(value) =>
              setForm((current) => ({ ...current, name: value }))
            }
          />
          <Field
            label="Slug"
            value={form.slug}
            disabled={!canManageHub}
            onChange={(value) =>
              setForm((current) => ({ ...current, slug: value }))
            }
          />
          <Field
            label="Icon key"
            value={form.icon}
            disabled={!canManageHub}
            onChange={(value) =>
              setForm((current) => ({ ...current, icon: value }))
            }
          />
          <Field
            label="Colour or tone"
            value={form.color}
            disabled={!canManageHub}
            onChange={(value) =>
              setForm((current) => ({ ...current, color: value }))
            }
          />
          <div>
            <Label>Audience</Label>
            <select
              className="mt-2 h-10 w-full rounded-md border bg-background px-3"
              value={form.audience}
              disabled={!canManageHub}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  audience: event.target.value,
                }))
              }
            >
              {["all", "health-workers", "public"].map((value) => (
                <option key={value}>{value}</option>
              ))}
            </select>
          </div>
          <div>
            <Label>Diseases</Label>
            <MultiSelect
              className="mt-2"
              options={diseases.map((value) => ({
                value: value.id,
                label: `${value.parent_name ? `${value.parent_name} › ` : ""}${value.name}`,
                color: value.color,
              }))}
              value={form.disease_ids}
              disabled={!canManageHub}
              onValueChange={(value) =>
                setForm((current) => ({ ...current, disease_ids: value }))
              }
              placeholder="Search diseases"
            />
          </div>
          <div className="md:col-span-2">
            <Label>Outbreak presentation</Label>
            <MultiSelect
              className="mt-2"
              maxSelections={1}
              options={outbreaks.map((value) => ({
                value: value.id,
                label: value.title,
              }))}
              value={form.outbreak_ids}
              disabled={!canManageHub}
              onValueChange={(value) =>
                setForm((current) => ({ ...current, outbreak_ids: value }))
              }
              placeholder="Optional outbreak"
            />
          </div>
          <div className="md:col-span-2">
            <Label>Description</Label>
            <Textarea
              className="mt-2"
              value={form.description}
              disabled={!canManageHub}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  description: event.target.value,
                }))
              }
            />
          </div>
        </CardContent>
      </Card>
      {workspace ? (
        <>
          <Card>
            <CardHeader>
              <CardTitle>Template and pillars</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {canApplyTemplate ? <div className="flex gap-2">
                <select
                  className="h-10 flex-1 rounded-md border bg-background px-3"
                  value={templateId}
                  onChange={(event) => setTemplateId(event.target.value)}
                >
                  <option value="">Choose a template</option>
                  {templates.map((value) => (
                    <option key={value.id} value={value.id}>
                      {value.name}
                    </option>
                  ))}
                </select>
                <Button
                  variant="outline"
                  disabled={
                    !templateId ||
                    workspace.pillars.length > 0 ||
                    workspace.hub.status !== "draft"
                  }
                  onClick={async () => {
                    try {
                      await contentHubService.applyTemplate(
                        workspace.hub.id,
                        templateId,
                        workspace.hub.lock_version,
                      );
                      showToast.success(
                        "Template applied",
                        "The copied pillars can now be renamed, nested and reordered.",
                      );
                      await load();
                    } catch (error) {
                      showToast.error(
                        "Template not applied",
                        actionable(error),
                      );
                    }
                  }}
                >
                  Apply template
                </Button>
              </div> : null}
              {canManagePillars ? (
                <PillarEditor workspace={workspace} reload={load} />
              ) : (
                <p className="text-sm text-muted-foreground">
                  Pillars are read only for your role.
                </p>
              )}
            </CardContent>
          </Card>
          {canManagePillars ? (
            <ResourceAssignment workspace={workspace} reload={load} />
          ) : null}
          <HubPreview workspace={workspace} />
          <Card>
            <CardHeader>
              <CardTitle>Audit history</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {audit.length ? (
                audit.map((value) => (
                  <div key={value.id} className="rounded-md border p-3 text-sm">
                    <div className="font-medium">{value.action}</div>
                    <div className="text-muted-foreground">
                      {new Date(value.created_at).toLocaleString()} ·{" "}
                      {value.entity_type}
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-muted-foreground">
                  No hub changes have been recorded.
                </p>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}
    </div>
  );
}

function PillarEditor({
  workspace,
  reload,
}: {
  workspace: ContentHubWorkspace;
  reload: () => Promise<void>;
}) {
  const [draft, setDraft] = React.useState({
    name: "",
    slug: "",
    description: "",
    icon: "",
    parent_id: "",
  });
  async function add() {
    try {
      await contentHubService.createPillar(workspace.hub.id, {
        ...draft,
        parent_id: draft.parent_id || undefined,
        status: "active",
        sort_order: (workspace.pillars.length + 1) * 10,
      });
      setDraft({
        name: "",
        slug: "",
        description: "",
        icon: "",
        parent_id: "",
      });
      await reload();
      showToast.success("Pillar created");
    } catch (error) {
      showToast.error("Pillar not created", actionable(error));
    }
  }
  async function move(index: number, direction: number) {
    const rows = [...workspace.pillars];
    const target = index + direction;
    if (target < 0 || target >= rows.length) return;
    [rows[index], rows[target]] = [rows[target], rows[index]];
    try {
      await contentHubService.reorderPillars(workspace.hub.id, rows);
      await reload();
    } catch (error) {
      showToast.error("Reorder failed", actionable(error));
    }
  }
  return (
    <div className="space-y-3">
      <div className="grid gap-2 md:grid-cols-5">
        <Input
          placeholder="Pillar name"
          value={draft.name}
          onChange={(event) =>
            setDraft((current) => ({ ...current, name: event.target.value }))
          }
        />
        <Input
          placeholder="slug"
          value={draft.slug}
          onChange={(event) =>
            setDraft((current) => ({ ...current, slug: event.target.value }))
          }
        />
        <Input
          placeholder="icon key"
          value={draft.icon}
          onChange={(event) =>
            setDraft((current) => ({ ...current, icon: event.target.value }))
          }
        />
        <select
          className="rounded-md border bg-background px-3"
          value={draft.parent_id}
          onChange={(event) =>
            setDraft((current) => ({
              ...current,
              parent_id: event.target.value,
            }))
          }
        >
          <option value="">Root pillar</option>
          {workspace.pillars.map((value) => (
            <option key={value.id} value={value.id}>
              {value.name}
            </option>
          ))}
        </select>
        <Button disabled={!draft.name.trim()} onClick={() => void add()}>
          <Plus className="mr-2 h-4 w-4" />
          Add
        </Button>
      </div>
      {workspace.pillars.map((pillar, index) => (
        <PillarRow
          key={pillar.id}
          hubId={workspace.hub.id}
          pillar={pillar}
          pillars={workspace.pillars}
          index={index}
          move={move}
          reload={reload}
        />
      ))}
    </div>
  );
}

function PillarRow({
  hubId,
  pillar,
  pillars,
  index,
  move,
  reload,
}: {
  hubId: string;
  pillar: ContentPillar;
  pillars: ContentPillar[];
  index: number;
  move: (index: number, direction: number) => Promise<void>;
  reload: () => Promise<void>;
}) {
  const [value, setValue] = React.useState({
    name: pillar.name,
    icon: pillar.icon || "",
    parent_id: pillar.parent_id || "",
  });
  React.useEffect(
    () =>
      setValue({
        name: pillar.name,
        icon: pillar.icon || "",
        parent_id: pillar.parent_id || "",
      }),
    [pillar],
  );
  async function save() {
    try {
      await contentHubService.updatePillar(hubId, pillar.id, {
        name: value.name,
        icon: value.icon,
        parent_id: value.parent_id || undefined,
        clear_parent: !value.parent_id,
        lock_version: pillar.lock_version,
      });
      await reload();
      showToast.success("Pillar saved");
    } catch (error) {
      showToast.error("Pillar not saved", actionable(error));
    }
  }
  async function archive() {
    if (
      !confirm(
        `Archive ${pillar.name}? Its assignments will be retained but hidden publicly.`,
      )
    )
      return;
    try {
      await contentHubService.updatePillar(hubId, pillar.id, {
        status: "archived",
        lock_version: pillar.lock_version,
      });
      await reload();
      showToast.success(
        "Pillar archived",
        "Its assignments were retained and hidden from public views.",
      );
    } catch (error) {
      showToast.error("Pillar not archived", actionable(error));
    }
  }
  return (
    <div className="grid items-center gap-2 rounded-md border p-3 md:grid-cols-[1fr_1fr_1fr_auto]">
      <Input
        value={value.name}
        aria-label="Pillar name"
        onChange={(event) =>
          setValue((current) => ({ ...current, name: event.target.value }))
        }
      />
      <Input
        value={value.icon}
        aria-label="Pillar icon"
        placeholder="icon key"
        onChange={(event) =>
          setValue((current) => ({ ...current, icon: event.target.value }))
        }
      />
      <select
        className="h-10 rounded-md border bg-background px-3"
        value={value.parent_id}
        onChange={(event) =>
          setValue((current) => ({ ...current, parent_id: event.target.value }))
        }
      >
        <option value="">Root pillar</option>
        {pillars
          .filter((row) => row.id !== pillar.id)
          .map((row) => (
            <option key={row.id} value={row.id}>
              {row.name}
            </option>
          ))}
      </select>
      <div className="flex gap-1">
        <Button
          size="icon"
          variant="ghost"
          onClick={() => void move(index, -1)}
        >
          <ArrowUp className="h-4 w-4" />
        </Button>
        <Button size="icon" variant="ghost" onClick={() => void move(index, 1)}>
          <ArrowDown className="h-4 w-4" />
        </Button>
        <Button size="sm" variant="outline" onClick={() => void save()}>
          Save
        </Button>
        <Button
          size="icon"
          variant="ghost"
          aria-label={`Archive ${pillar.name}`}
          disabled={pillar.status === "archived"}
          onClick={() => void archive()}
        >
          <Archive className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

function ResourceAssignment({
  workspace,
  reload,
}: {
  workspace: ContentHubWorkspace;
  reload: () => Promise<void>;
}) {
  const [pillarId, setPillarId] = React.useState(
    workspace.pillars[0]?.id || "",
  );
  const [type, setType] = React.useState("outbreak_document");
  const [search, setSearch] = React.useState("");
  const [results, setResults] = React.useState<AssignableResource[]>([]);
  const [target, setTarget] = React.useState("");
  const [startsAt, setStartsAt] = React.useState("");
  const [endsAt, setEndsAt] = React.useState("");
  const selected = workspace.pillars.find((value) => value.id === pillarId);
  React.useEffect(() => {
    if (!pillarId && workspace.pillars[0]) setPillarId(workspace.pillars[0].id);
  }, [pillarId, workspace.pillars]);
  React.useEffect(() => {
    if (["internal_route", "approved_external_url"].includes(type)) {
      setResults([]);
      return;
    }
    const timer = setTimeout(() => {
      void contentHubService
        .searchResources(type, search, workspace.hub.outbreaks?.[0]?.id || "")
        .then((page) => setResults(page.items || []))
        .catch((error) =>
          showToast.error("Resource search failed", actionable(error)),
        );
    }, 250);
    return () => clearTimeout(timer);
  }, [type, search, workspace.hub.outbreaks]);
  async function add(resource?: AssignableResource) {
    if (!pillarId) return;
    try {
      await contentHubService.createItem(workspace.hub.id, pillarId, {
        content_type: type,
        content_id: resource?.id,
        target: resource ? "" : target,
        label_override: resource?.title || "",
        description_override: resource?.description || "",
        status: "draft",
        sort_order: ((selected?.items.length || 0) + 1) * 10,
        starts_at: startsAt ? new Date(startsAt).toISOString() : undefined,
        ends_at: endsAt ? new Date(endsAt).toISOString() : undefined,
      });
      await reload();
      showToast.success(
        "Resource assigned",
        "It remains draft until explicitly activated.",
      );
    } catch (error) {
      showToast.error("Resource not assigned", actionable(error));
    }
  }
  async function move(
    items: ContentPillar["items"],
    index: number,
    direction: number,
  ) {
    const rows = [...items];
    const next = index + direction;
    if (next < 0 || next >= rows.length) return;
    [rows[index], rows[next]] = [rows[next], rows[index]];
    try {
      await contentHubService.reorderItems(workspace.hub.id, pillarId, rows);
      await reload();
    } catch (error) {
      showToast.error("Reorder failed", actionable(error));
    }
  }
  return (
    <Card>
      <CardHeader>
        <CardTitle>Resource assignments and availability</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="rounded-md border bg-muted/30 p-4">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div className="max-w-3xl">
              <div className="font-medium">Add source documents first</div>
              <p className="mt-1 text-sm text-muted-foreground">
                A hub curates approved resources; it does not upload or publish
                files directly. Create and publish a guideline for general
                disease guidance, or upload a managed document inside the
                linked outbreak. Return here, search for the published resource,
                assign it to a pillar, and activate the assignment.
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" asChild>
                <Link href="/guidelines/create">
                  <FileUp className="mr-2 h-4 w-4" />
                  Create guideline
                </Link>
              </Button>
              {workspace.hub.outbreaks?.[0]?.id ? (
                <Button variant="outline" asChild>
                  <Link href={`/outbreaks/${workspace.hub.outbreaks[0].id}`}>
                    <FileUp className="mr-2 h-4 w-4" />
                    Upload outbreak document
                  </Link>
                </Button>
              ) : null}
            </div>
          </div>
        </div>
        <div className="grid gap-2 md:grid-cols-4">
          <select
            className="h-10 rounded-md border bg-background px-3"
            value={pillarId}
            onChange={(event) => setPillarId(event.target.value)}
          >
            <option value="">Select pillar</option>
            {workspace.pillars.map((value) => (
              <option key={value.id} value={value.id}>
                {value.name}
              </option>
            ))}
          </select>
          <select
            className="h-10 rounded-md border bg-background px-3"
            value={type}
            onChange={(event) => setType(event.target.value)}
          >
            {itemTypes.map((value) => (
              <option key={value}>{value}</option>
            ))}
          </select>
          <Input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search assignable resources"
            disabled={["internal_route", "approved_external_url"].includes(
              type,
            )}
          />
          <Input
            value={target}
            onChange={(event) => setTarget(event.target.value)}
            placeholder="Internal route or approved HTTPS URL"
            disabled={
              !["internal_route", "approved_external_url"].includes(type)
            }
          />
          <div>
            <Label>Available from</Label>
            <Input
              type="datetime-local"
              value={startsAt}
              onChange={(event) => setStartsAt(event.target.value)}
            />
          </div>
          <div>
            <Label>Available until</Label>
            <Input
              type="datetime-local"
              value={endsAt}
              onChange={(event) => setEndsAt(event.target.value)}
            />
          </div>
          {["internal_route", "approved_external_url"].includes(type) ? (
            <Button
              disabled={!pillarId || !target.trim()}
              onClick={() => void add()}
            >
              Assign target
            </Button>
          ) : null}
        </div>
        {results.length ? (
          <div className="max-h-64 space-y-2 overflow-auto rounded-md border p-2">
            {results.map((value) => (
              <div
                key={value.id}
                className="flex items-center justify-between gap-3 rounded p-2 hover:bg-muted"
              >
                <div>
                  <div className="font-medium">{value.title}</div>
                  <div className="text-xs text-muted-foreground">
                    {value.context} · {value.status}
                  </div>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => void add(value)}
                >
                  Assign
                </Button>
              </div>
            ))}
          </div>
        ) : null}
        <div className="space-y-2">
          {(selected?.items || []).map((item, index) => (
            <div
              key={item.id}
              className="flex flex-wrap items-center justify-between gap-2 rounded-md border p-3"
            >
              <div>
                <div className="font-medium">
                  {item.label_override || item.content_type}
                </div>
                <div className="text-xs text-muted-foreground">
                  {item.content_type} · {item.status}
                  {item.starts_at
                    ? ` · from ${new Date(item.starts_at).toLocaleString()}`
                    : ""}
                  {item.ends_at
                    ? ` · until ${new Date(item.ends_at).toLocaleString()}`
                    : ""}
                </div>
              </div>
              <div className="flex gap-1">
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={() => void move(selected!.items, index, -1)}
                >
                  <ArrowUp className="h-4 w-4" />
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={() => void move(selected!.items, index, 1)}
                >
                  <ArrowDown className="h-4 w-4" />
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={async () => {
                    try {
                      await contentHubService.updateItem(
                        workspace.hub.id,
                        pillarId,
                        item.id,
                        {
                          ...item,
                          status:
                            item.status === "active" ? "inactive" : "active",
                          lock_version: item.lock_version,
                        },
                      );
                      await reload();
                    } catch (error) {
                      showToast.error("Status not changed", actionable(error));
                    }
                  }}
                >
                  {item.status === "active" ? "Deactivate" : "Activate"}
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={async () => {
                    try {
                      await contentHubService.removeItem(
                        workspace.hub.id,
                        pillarId,
                        item,
                      );
                      await reload();
                    } catch (error) {
                      showToast.error(
                        "Assignment not removed",
                        actionable(error),
                      );
                    }
                  }}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

function HubPreview({ workspace }: { workspace: ContentHubWorkspace }) {
  const roots = workspace.pillars.filter(
    (value) => !value.parent_id && value.status === "active",
  );
  return (
    <Card>
      <CardHeader>
        <CardTitle>
          <Eye className="mr-2 inline h-4 w-4" />
          Presentation preview
        </CardTitle>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="mobile">
          <TabsList>
            <TabsTrigger value="mobile">Mobile</TabsTrigger>
            <TabsTrigger value="web">Public web</TabsTrigger>
          </TabsList>
          {["mobile", "web"].map((mode) => (
            <TabsContent key={mode} value={mode}>
              <div
                className={
                  mode === "mobile"
                    ? "mx-auto max-w-sm rounded-3xl border p-5"
                    : "rounded-md border p-6"
                }
              >
                <h3 className="text-xl font-bold">{workspace.hub.name}</h3>
                <p className="mb-4 text-sm text-muted-foreground">
                  {workspace.hub.description}
                </p>
                <div
                  className={
                    mode === "mobile"
                      ? "grid grid-cols-3 gap-2"
                      : "grid gap-3 md:grid-cols-4"
                  }
                >
                  {roots.map((value) => (
                    <div
                      key={value.id}
                      className="rounded-md border p-3 text-center"
                    >
                      <div className="font-medium">{value.name}</div>
                      <div className="text-xs text-muted-foreground">
                        {
                          value.items.filter((item) => item.status === "active")
                            .length
                        }{" "}
                        resources
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </CardContent>
    </Card>
  );
}
function Field({
  label,
  value,
  onChange,
  disabled = false,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <Input
        className="mt-2"
        value={value}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
      />
    </div>
  );
}
function actionable(value: unknown) {
  const message = value instanceof Error ? value.message : "Try again.";
  return /modified|conflict|lock/i.test(message)
    ? "Another administrator changed this hub. Reload it before retrying."
    : /not empty/i.test(message)
      ? "Templates can only be applied to an empty draft hub. Remove existing pillars or create a new hub."
      : /not allowed|unsafe/i.test(message)
        ? "Use an approved HTTPS domain or a supported internal application route."
        : message;
}
